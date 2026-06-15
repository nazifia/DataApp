import json
import logging
from decimal import Decimal
from django.conf import settings
from django.core.cache import cache
from django.db import transaction as db_transaction
from django.db.models import F
from django.views.decorators.csrf import csrf_exempt
from django.utils.decorators import method_decorator
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import AllowAny
from apps.transactions.models import Transaction
from core.runtime import is_dev_mode
from .models import Wallet, Withdrawal
from . import paystack as ps

logger = logging.getLogger(__name__)


def _get_wallet(user):
    try:
        return user.wallet
    except Wallet.DoesNotExist:
        return None


# ─── Balance ─────────────────────────────────────────────────────────────────

class WalletBalanceView(APIView):
    def get(self, request):
        wallet = _get_wallet(request.user)
        if not wallet:
            return Response({'detail': 'Wallet not found.'}, status=404)
        return Response({'balance': float(wallet.balance)})


# ─── Dedicated Virtual Account (Bank Transfer) ───────────────────────────────

class BankDetailsView(APIView):
    def get(self, request):
        wallet = _get_wallet(request.user)
        if not wallet:
            return Response({'detail': 'Wallet not found.'}, status=404)

        if is_dev_mode():
            # Use last 10 digits of phone number as the mock account number
            digits = ''.join(c for c in request.user.phone_number if c.isdigit())
            account_number = digits[-10:] if len(digits) >= 10 else digits.zfill(10)
            return Response({
                'bank_name': 'Wema Bank (Paystack)',
                'account_number': account_number,
                'account_name': f'TUN/{(request.user.full_name or "USER").split()[0].upper()}',
                'note': 'Transfer exact amount. Wallet credited automatically. (dev mode)',
            })

        # Return cached account if provisioned
        if wallet.paystack_account_number:
            return Response({
                'bank_name': wallet.paystack_bank_name,
                'account_number': wallet.paystack_account_number,
                'account_name': wallet.paystack_account_name,
                'note': 'Transfer any amount to this account. Your wallet is credited automatically within minutes.',
            })

        # Provision: create or retrieve Paystack customer then create DVA
        try:
            user = request.user
            email = user.email or f'{str(user.id)[:8]}@topupnaija.app'

            if not wallet.paystack_customer_code:
                customer_data = ps.create_customer(
                    email=email,
                    phone=user.phone_number,
                    full_name=user.full_name or 'TopUpNaija User',
                )
                wallet.paystack_customer_code = customer_data['customer_code']
                wallet.save(update_fields=['paystack_customer_code'])

            # Try fetching existing DVA first
            existing = ps.fetch_dedicated_account(wallet.paystack_customer_code)
            if existing:
                account = existing
            else:
                dva_data = ps.create_dedicated_account(wallet.paystack_customer_code)
                account = dva_data

            bank_name = account.get('bank', {}).get('name', 'Wema Bank')
            account_number = account.get('account_number', '')
            account_name = account.get('account_name', '')

            wallet.paystack_account_number = account_number
            wallet.paystack_bank_name = bank_name
            wallet.paystack_account_name = account_name
            wallet.save(update_fields=['paystack_account_number', 'paystack_bank_name', 'paystack_account_name'])

            return Response({
                'bank_name': bank_name,
                'account_number': account_number,
                'account_name': account_name,
                'note': 'Transfer any amount to this account. Your wallet is credited automatically within minutes.',
            })
        except Exception as exc:
            logger.error('Paystack DVA provisioning error for user %s: %s', request.user.id, exc)
            return Response({'detail': 'Could not provision bank account. Please try again.'}, status=503)


# ─── Paystack Card / Online Payment Initiation ───────────────────────────────

class InitiatePaymentView(APIView):
    def post(self, request):
        wallet = _get_wallet(request.user)
        if not wallet:
            return Response({'detail': 'Wallet not found.'}, status=404)

        try:
            amount = Decimal(str(request.data.get('amount', 0)))
        except Exception:
            return Response({'detail': 'Invalid amount.'}, status=400)

        min_fund = request.tenant.min_wallet_fund if request.tenant else Decimal('50')
        if amount < min_fund:
            return Response({'detail': f'Minimum funding amount is ₦{min_fund}.'}, status=400)

        if is_dev_mode():
            return Response({
                'authorization_url': 'https://checkout.paystack.com/dev-demo',
                'reference': f'DEV-{Transaction.generate_reference()}',
                'status': 'success',
                'message': 'Payment initiated (dev mode)',
            })

        try:
            user = request.user
            email = user.email or f'{str(user.id)[:8]}@topupnaija.app'
            amount_kobo = int(amount * 100)

            txn_data = ps.initialize_transaction(
                email=email,
                amount_kobo=amount_kobo,
                metadata={
                    'user_id': str(user.id),
                    'wallet_id': str(wallet.id),
                    'tenant_id': str(request.tenant.id) if request.tenant else '',
                    'type': 'wallet_fund',
                },
            )
            return Response({
                'authorization_url': txn_data['authorization_url'],
                'reference': txn_data['reference'],
                'access_code': txn_data['access_code'],
            })
        except Exception as exc:
            logger.error('Paystack init error for user %s: %s', request.user.id, exc)
            return Response({'detail': 'Payment gateway error. Please try again.'}, status=503)


# ─── Bank list / Account resolve / Withdrawal ────────────────────────────────

_DEV_BANKS = [
    {'name': 'Access Bank', 'code': '044', 'type': 'nuban'},
    {'name': 'Guaranty Trust Bank', 'code': '058', 'type': 'nuban'},
    {'name': 'First Bank of Nigeria', 'code': '011', 'type': 'nuban'},
    {'name': 'Zenith Bank', 'code': '057', 'type': 'nuban'},
    {'name': 'United Bank For Africa', 'code': '033', 'type': 'nuban'},
    {'name': 'Opay', 'code': '999992', 'type': 'nuban'},
    {'name': 'Moniepoint MFB', 'code': '50515', 'type': 'nuban'},
    {'name': 'Kuda Microfinance Bank', 'code': '50211', 'type': 'nuban'},
]


class BankListView(APIView):
    """List all NGN banks (commercial + microfinance) for the withdrawal flow.

    Cached for 24h since the bank list is near-static."""

    def get(self, request):
        if is_dev_mode():
            return Response({'banks': _DEV_BANKS})

        banks = cache.get('paystack_bank_list')
        if banks is None:
            try:
                raw = ps.list_banks()
            except Exception as exc:
                logger.error('Paystack bank list error: %s', exc)
                return Response({'detail': 'Could not load banks. Please try again.'}, status=503)
            # Keep only the fields the client needs, de-dup by code
            seen = set()
            banks = []
            for b in raw:
                code = b.get('code')
                if not code or code in seen:
                    continue
                seen.add(code)
                banks.append({'name': b.get('name', ''), 'code': code, 'type': b.get('type', 'nuban')})
            banks.sort(key=lambda b: b['name'].lower())
            cache.set('paystack_bank_list', banks, 60 * 60 * 24)
        return Response({'banks': banks})


class ResolveAccountView(APIView):
    """Verify a bank account number and return the registered account name."""

    def post(self, request):
        account_number = str(request.data.get('account_number', '')).strip()
        bank_code = str(request.data.get('bank_code', '')).strip()

        if len(account_number) != 10 or not account_number.isdigit():
            return Response({'detail': 'Enter a valid 10-digit account number.'}, status=400)
        if not bank_code:
            return Response({'detail': 'Select a bank.'}, status=400)

        if is_dev_mode():
            return Response({'account_number': account_number, 'account_name': 'JOHN DOE (dev mode)'})

        try:
            data = ps.resolve_account(account_number, bank_code)
            return Response({
                'account_number': data.get('account_number', account_number),
                'account_name': data.get('account_name', ''),
            })
        except Exception as exc:
            logger.warning('Account resolve failed (%s/%s): %s', account_number, bank_code, exc)
            return Response({'detail': 'Could not verify account. Check the number and bank.'}, status=422)


class WithdrawView(APIView):
    """Debit the wallet and initiate a Paystack transfer to a bank account."""

    def post(self, request):
        wallet = _get_wallet(request.user)
        if not wallet:
            return Response({'detail': 'Wallet not found.'}, status=404)

        try:
            amount = Decimal(str(request.data.get('amount', 0)))
        except Exception:
            return Response({'detail': 'Invalid amount.'}, status=400)

        bank_code = str(request.data.get('bank_code', '')).strip()
        bank_name = str(request.data.get('bank_name', '')).strip()
        account_number = str(request.data.get('account_number', '')).strip()
        account_name = str(request.data.get('account_name', '')).strip()

        if not (bank_code and account_number and account_name):
            return Response({'detail': 'Bank, account number and account name are required.'}, status=400)

        tenant = request.tenant
        min_wd = tenant.min_withdrawal if tenant else Decimal('100')
        fee = tenant.withdrawal_fee if tenant else Decimal('0')

        if amount < min_wd:
            return Response({'detail': f'Minimum withdrawal is ₦{min_wd}.'}, status=400)

        total = amount + fee
        reference = f'WD-{Transaction.generate_reference()}'

        # Atomically check balance and debit (amount + fee) to prevent races / overdraw.
        with db_transaction.atomic():
            locked = Wallet.objects.select_for_update().get(pk=wallet.pk)
            if locked.balance < total:
                return Response(
                    {'detail': f'Insufficient balance. You need ₦{total} (incl. ₦{fee} fee).'},
                    status=400,
                )
            locked.balance = F('balance') - total
            locked.save(update_fields=['balance'])

            withdrawal = Withdrawal.objects.create(
                tenant=tenant,
                user=request.user,
                amount=amount,
                fee=fee,
                bank_code=bank_code,
                bank_name=bank_name,
                account_number=account_number,
                account_name=account_name,
                reference=reference,
                status='pending',
            )
            Transaction.objects.create(
                tenant=tenant,
                user=request.user,
                type='withdrawal',
                amount=total,
                status='pending',
                reference=reference,
            )

        if is_dev_mode():
            # Settle immediately in dev mode.
            self._mark_success(withdrawal)
            locked.refresh_from_db()
            return Response({
                'status': 'success',
                'message': 'Withdrawal successful (dev mode).',
                'reference': reference,
                'balance': float(locked.balance),
            })

        # Initiate the real transfer. On any failure, reverse the debit.
        try:
            recipient = ps.create_transfer_recipient(account_name, account_number, bank_code)
            recipient_code = recipient['recipient_code']
            transfer = ps.initiate_transfer(
                amount_kobo=int(amount * 100),
                recipient_code=recipient_code,
                reason='Wallet withdrawal',
                reference=reference,
            )
            withdrawal.recipient_code = recipient_code
            withdrawal.transfer_code = transfer.get('transfer_code', '')
            transfer_status = (transfer.get('status') or 'pending').lower()
            if transfer_status in ('success', 'pending', 'otp', 'queued'):
                withdrawal.status = 'success' if transfer_status == 'success' else 'pending'
                withdrawal.save(update_fields=['recipient_code', 'transfer_code', 'status', 'updated_at'])
                if transfer_status == 'success':
                    Transaction.all_objects.filter(reference=reference).update(status='success')
                locked.refresh_from_db()
                return Response({
                    'status': 'success',
                    'message': 'Withdrawal is being processed.',
                    'reference': reference,
                    'balance': float(locked.balance),
                })
            raise ValueError(f'Transfer rejected: {transfer_status}')
        except Exception as exc:
            logger.error('Withdrawal transfer failed (%s): %s', reference, exc)
            self._reverse(withdrawal, reason=str(exc))
            return Response(
                {'detail': 'Withdrawal could not be processed. Your balance was not charged.'},
                status=503,
            )

    @staticmethod
    def _mark_success(withdrawal: Withdrawal):
        withdrawal.status = 'success'
        withdrawal.save(update_fields=['status', 'updated_at'])
        Transaction.all_objects.filter(reference=withdrawal.reference).update(status='success')

    @staticmethod
    def _reverse(withdrawal: Withdrawal, reason: str = ''):
        """Refund the debited amount + fee and mark the withdrawal reversed/failed."""
        with db_transaction.atomic():
            wd = Withdrawal.objects.select_for_update().get(pk=withdrawal.pk)
            if wd.status in ('failed', 'reversed'):
                return
            Wallet.objects.filter(user=wd.user).update(balance=F('balance') + wd.total_debit)
            wd.status = 'reversed'
            wd.failure_reason = reason[:500]
            wd.save(update_fields=['status', 'failure_reason', 'updated_at'])
            Transaction.all_objects.filter(reference=wd.reference).update(status='failed')


def settle_pending_withdrawal(withdrawal: Withdrawal, source: str = 'poll') -> str:
    """Webhook fallback: query Paystack for a pending transfer and settle it.

    Returns the resulting status. Safe to call repeatedly — no-ops once the
    withdrawal has left the 'pending' state."""
    if withdrawal.status != 'pending':
        return withdrawal.status
    try:
        data = ps.verify_transfer(withdrawal.reference)
    except Exception as exc:
        logger.warning('Withdrawal poll failed (%s): %s', withdrawal.reference, exc)
        return withdrawal.status
    st = (data.get('status') or '').lower()
    if st == 'success':
        WithdrawView._mark_success(withdrawal)
    elif st in ('failed', 'reversed', 'abandoned'):
        WithdrawView._reverse(withdrawal, reason=f'Transfer {st} ({source})')
    withdrawal.refresh_from_db()
    return withdrawal.status


class WithdrawalStatusView(APIView):
    """Poll a withdrawal's status. Acts as a webhook fallback by reconciling
    a still-pending transfer against Paystack on demand."""

    def get(self, request, reference):
        withdrawal = Withdrawal.all_objects.filter(
            reference=reference, user=request.user
        ).first()
        if not withdrawal:
            return Response({'detail': 'Withdrawal not found.'}, status=404)

        if withdrawal.status == 'pending' and not is_dev_mode():
            settle_pending_withdrawal(withdrawal, source='poll')

        wallet = _get_wallet(request.user)
        return Response({
            'reference': reference,
            'status': withdrawal.status,
            'amount': float(withdrawal.amount),
            'balance': float(wallet.balance) if wallet else 0.0,
        })


# ─── Paystack Webhook ─────────────────────────────────────────────────────────

@method_decorator(csrf_exempt, name='dispatch')
class PaystackWebhookView(APIView):
    permission_classes = [AllowAny]
    authentication_classes = []

    def post(self, request):
        signature = request.headers.get('X-Paystack-Signature', '')
        payload_bytes = request.body

        if not ps.verify_webhook_signature(payload_bytes, signature):
            logger.warning('Paystack webhook: invalid signature')
            return Response({'detail': 'Invalid signature.'}, status=400)

        try:
            event = json.loads(payload_bytes)
        except json.JSONDecodeError:
            return Response({'detail': 'Invalid payload.'}, status=400)

        event_type = event.get('event')

        if event_type == 'charge.success':
            self._handle_charge_success(event.get('data', {}))
        elif event_type == 'dedicatedaccount.assign.success':
            self._handle_dva_assigned(event.get('data', {}))
        elif event_type == 'transfer.success':
            self._handle_transfer_result(event.get('data', {}), success=True)
        elif event_type in ('transfer.failed', 'transfer.reversed'):
            self._handle_transfer_result(event.get('data', {}), success=False)

        return Response({'status': 'ok'})

    def _handle_transfer_result(self, data: dict, success: bool):
        reference = data.get('reference', '')
        if not reference:
            return
        try:
            withdrawal = Withdrawal.all_objects.get(reference=reference)
        except Withdrawal.DoesNotExist:
            return

        if success:
            if withdrawal.status == 'success':
                return
            with db_transaction.atomic():
                withdrawal.status = 'success'
                withdrawal.save(update_fields=['status', 'updated_at'])
                Transaction.all_objects.filter(reference=reference).update(status='success')
            from core.notifications import notify
            notify(
                withdrawal.user,
                title='Withdrawal Successful',
                body=f'₦{withdrawal.amount:,.2f} has been sent to your {withdrawal.bank_name} account.',
                type='withdrawal',
                data={'reference': reference},
                tenant=withdrawal.tenant,
            )
        else:
            # Failed/reversed transfer — refund the wallet if not already done.
            WithdrawView._reverse(withdrawal, reason='Transfer failed/reversed (webhook)')
            from core.notifications import notify
            notify(
                withdrawal.user,
                title='Withdrawal Reversed',
                body=f'₦{withdrawal.total_debit:,.2f} has been refunded to your wallet.',
                type='withdrawal',
                data={'reference': reference},
                tenant=withdrawal.tenant,
            )

    def _handle_charge_success(self, data: dict):
        reference = data.get('reference', '')
        amount_kobo = data.get('amount', 0)
        amount = Decimal(str(amount_kobo)) / 100
        metadata = data.get('metadata') or {}

        # Ignore if already processed
        if Transaction.all_objects.filter(reference=f'PSK-{reference}').exists():
            return

        user_id = metadata.get('user_id')
        tenant_id = metadata.get('tenant_id')

        if not user_id:
            logger.warning('Paystack webhook charge.success missing user_id in metadata: %s', reference)
            return

        try:
            from apps.authentication.models import User
            from apps.tenants.models import Tenant
            user = User.objects.get(id=user_id)
            tenant = Tenant.all_objects.get(id=tenant_id) if tenant_id else user.tenant

            with db_transaction.atomic():
                wallet = Wallet.objects.select_for_update().get(user=user)
                wallet.balance += amount
                wallet.save()
                Transaction.objects.create(
                    tenant=tenant,
                    user=user,
                    type='wallet_fund',
                    amount=amount,
                    status='success',
                    reference=f'PSK-{reference}',
                )

            from core.notifications import notify
            notify(
                user,
                title='Wallet Funded',
                body=f'₦{amount:,.2f} has been added to your wallet.',
                type='wallet_fund',
                data={'amount': str(amount)},
                tenant=tenant,
            )
        except Exception as exc:
            logger.error('Paystack webhook charge.success processing error: %s', exc)

    def _handle_dva_assigned(self, data: dict):
        customer = data.get('customer') or {}
        customer_code = customer.get('customer_code', '')
        account = data.get('dedicated_account') or {}
        account_number = account.get('account_number', '')
        account_name = account.get('account_name', '')
        bank_name = (account.get('bank') or {}).get('name', '')

        if not customer_code or not account_number:
            return

        try:
            Wallet.objects.filter(paystack_customer_code=customer_code).update(
                paystack_account_number=account_number,
                paystack_account_name=account_name,
                paystack_bank_name=bank_name,
            )
        except Exception as exc:
            logger.error('DVA assign update error: %s', exc)


# ─── Admin manual fund (kept for admin portal use) ───────────────────────────

class FundWalletView(APIView):
    """Direct wallet credit — only used by admin portal / tests. Not exposed to end users."""

    def post(self, request):
        wallet = _get_wallet(request.user)
        if not wallet:
            return Response({'detail': 'Wallet not found.'}, status=404)

        try:
            amount = Decimal(str(request.data.get('amount', 0)))
        except Exception:
            return Response({'detail': 'Invalid amount.'}, status=400)

        min_fund = request.tenant.min_wallet_fund if request.tenant else Decimal('50')
        if amount < min_fund:
            return Response({'detail': f'Minimum funding amount is ₦{min_fund}.'}, status=400)

        with db_transaction.atomic():
            wallet.balance += amount
            wallet.save()
            Transaction.objects.create(
                tenant=request.tenant,
                user=request.user,
                type='wallet_fund',
                amount=amount,
                status='success',
                reference=Transaction.generate_reference(),
            )
        return Response({'message': 'Wallet funded.', 'balance': float(wallet.balance)})

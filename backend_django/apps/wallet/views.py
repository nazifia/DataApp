import json
import logging
from decimal import Decimal
from django.conf import settings
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
from .models import Wallet
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

        return Response({'status': 'ok'})

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

            from core.notifications import send_push_notification
            send_push_notification(
                user,
                title='Wallet Funded',
                body=f'₦{amount:,.2f} has been added to your wallet.',
                data={'type': 'wallet_fund', 'amount': str(amount)},
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

import hashlib
import hmac
import json
from decimal import Decimal
from unittest.mock import patch
from django.core.cache import cache
from django.test import TestCase
from django.urls import reverse
from rest_framework.test import APIClient
from rest_framework_simplejwt.tokens import RefreshToken
from apps.tenants.models import Tenant
from apps.authentication.models import User
from apps.wallet.models import Wallet, Withdrawal
from apps.transactions.models import Transaction
from django.conf import settings


def make_user_with_wallet(tenant, phone='+2348000000001', balance=Decimal('1000')):
    user = User.objects.create_user(phone_number=phone, tenant=tenant, password='pass')
    wallet = Wallet.objects.create(tenant=tenant, user=user, balance=balance)
    return user, wallet


class PaystackWebhookTests(TestCase):
    def setUp(self):
        self.tenant = Tenant.objects.create(
            name='Test', slug='test-tenant', owner_email='t@t.com', owner_phone='+2348000000000'
        )
        self.user, self.wallet = make_user_with_wallet(self.tenant)
        self.client = APIClient()
        settings.PAYSTACK_SECRET_KEY = 'test_secret_key'
        settings.DEV_MODE = False

    def _make_signature(self, payload: bytes) -> str:
        return hmac.new(b'test_secret_key', payload, hashlib.sha512).hexdigest()

    def _post_webhook(self, event_data: dict, signature: str = None):
        payload = json.dumps(event_data).encode()
        sig = signature or self._make_signature(payload)
        return self.client.post(
            '/api/v1/wallet/webhook/paystack/',
            data=payload,
            content_type='application/json',
            HTTP_X_PAYSTACK_SIGNATURE=sig,
        )

    def test_valid_charge_success_credits_wallet(self):
        event = {
            'event': 'charge.success',
            'data': {
                'reference': 'PSK-REF-001',
                'amount': 500000,  # ₦5000 in kobo
                'metadata': {
                    'user_id': str(self.user.id),
                    'wallet_id': str(self.wallet.id),
                    'tenant_id': str(self.tenant.id),
                    'type': 'wallet_fund',
                },
            },
        }
        response = self._post_webhook(event)
        self.assertEqual(response.status_code, 200)
        self.wallet.refresh_from_db()
        self.assertEqual(self.wallet.balance, Decimal('6000'))
        self.assertTrue(Transaction.all_objects.filter(reference='PSK-PSK-REF-001').exists())

    def test_invalid_signature_returns_400(self):
        event = {'event': 'charge.success', 'data': {}}
        response = self._post_webhook(event, signature='invalid_sig')
        self.assertEqual(response.status_code, 400)
        self.wallet.refresh_from_db()
        self.assertEqual(self.wallet.balance, Decimal('1000'))

    def test_duplicate_webhook_does_not_double_credit(self):
        event = {
            'event': 'charge.success',
            'data': {
                'reference': 'PSK-REF-DUP',
                'amount': 100000,
                'metadata': {'user_id': str(self.user.id), 'tenant_id': str(self.tenant.id)},
            },
        }
        self._post_webhook(event)
        self._post_webhook(event)
        self.wallet.refresh_from_db()
        self.assertEqual(self.wallet.balance, Decimal('2000'))

    def tearDown(self):
        settings.DEV_MODE = True


def _auth_client(user, tenant):
    client = APIClient()
    token = RefreshToken.for_user(user).access_token
    client.credentials(
        HTTP_AUTHORIZATION=f'Bearer {token}',
        HTTP_X_TENANT_SLUG=tenant.slug,
    )
    return client


class WithdrawDevModeTests(TestCase):
    """Withdrawals in dev mode settle synchronously without hitting Paystack."""

    def setUp(self):
        cache.clear()
        settings.DEV_MODE = True
        self.tenant = Tenant.objects.create(
            name='Test', slug='test-tenant', owner_email='t@t.com',
            owner_phone='+2348000000000', min_withdrawal=Decimal('100'),
            withdrawal_fee=Decimal('0'),
        )
        self.user, self.wallet = make_user_with_wallet(self.tenant, balance=Decimal('1000'))
        self.client = _auth_client(self.user, self.tenant)

    def _withdraw(self, amount):
        return self.client.post('/api/v1/wallet/withdraw/', {
            'amount': amount,
            'bank_code': '058',
            'bank_name': 'GTBank',
            'account_number': '0123456789',
            'account_name': 'JOHN DOE',
        }, format='json')

    def test_successful_withdrawal_debits_wallet(self):
        resp = self._withdraw(500)
        self.assertEqual(resp.status_code, 200)
        self.wallet.refresh_from_db()
        self.assertEqual(self.wallet.balance, Decimal('500'))
        wd = Withdrawal.all_objects.get(user=self.user)
        self.assertEqual(wd.status, 'success')
        txn = Transaction.all_objects.get(reference=wd.reference)
        self.assertEqual(txn.type, 'withdrawal')
        self.assertEqual(txn.status, 'success')

    def test_fee_is_added_to_debit(self):
        self.tenant.withdrawal_fee = Decimal('25')
        self.tenant.save(update_fields=['withdrawal_fee'])
        resp = self._withdraw(500)
        self.assertEqual(resp.status_code, 200)
        self.wallet.refresh_from_db()
        self.assertEqual(self.wallet.balance, Decimal('475'))  # 1000 - 500 - 25

    def test_insufficient_balance_rejected(self):
        resp = self._withdraw(2000)
        self.assertEqual(resp.status_code, 400)
        self.wallet.refresh_from_db()
        self.assertEqual(self.wallet.balance, Decimal('1000'))
        self.assertFalse(Withdrawal.all_objects.filter(user=self.user).exists())

    def test_below_minimum_rejected(self):
        resp = self._withdraw(50)
        self.assertEqual(resp.status_code, 400)
        self.wallet.refresh_from_db()
        self.assertEqual(self.wallet.balance, Decimal('1000'))

    def tearDown(self):
        cache.clear()


class WithdrawLiveModeTests(TestCase):
    """Non-dev withdrawals: Paystack transfer is mocked; failures must reverse."""

    def setUp(self):
        cache.clear()
        settings.DEV_MODE = False
        self.tenant = Tenant.objects.create(
            name='Test', slug='test-tenant', owner_email='t@t.com',
            owner_phone='+2348000000000', min_withdrawal=Decimal('100'),
        )
        self.user, self.wallet = make_user_with_wallet(self.tenant, balance=Decimal('1000'))
        self.client = _auth_client(self.user, self.tenant)

    def _withdraw(self, amount=500):
        return self.client.post('/api/v1/wallet/withdraw/', {
            'amount': amount, 'bank_code': '058', 'bank_name': 'GTBank',
            'account_number': '0123456789', 'account_name': 'JOHN DOE',
        }, format='json')

    @patch('apps.wallet.views.ps.initiate_transfer')
    @patch('apps.wallet.views.ps.create_transfer_recipient')
    def test_pending_transfer_keeps_debit(self, mock_recipient, mock_transfer):
        mock_recipient.return_value = {'recipient_code': 'RCP_1'}
        mock_transfer.return_value = {'status': 'pending', 'transfer_code': 'TRF_1'}
        resp = self._withdraw(500)
        self.assertEqual(resp.status_code, 200)
        self.wallet.refresh_from_db()
        self.assertEqual(self.wallet.balance, Decimal('500'))
        wd = Withdrawal.all_objects.get(user=self.user)
        self.assertEqual(wd.status, 'pending')

    @patch('apps.wallet.views.ps.create_transfer_recipient',
           side_effect=Exception('paystack down'))
    def test_transfer_failure_reverses_debit(self, _mock):
        resp = self._withdraw(500)
        self.assertEqual(resp.status_code, 503)
        self.wallet.refresh_from_db()
        self.assertEqual(self.wallet.balance, Decimal('1000'))  # refunded
        wd = Withdrawal.all_objects.get(user=self.user)
        self.assertEqual(wd.status, 'reversed')

    @patch('apps.wallet.views.ps.verify_transfer')
    def test_status_poll_settles_success(self, mock_verify):
        # Seed a pending withdrawal with the wallet already debited.
        self.wallet.balance = Decimal('500')
        self.wallet.save()
        wd = Withdrawal.objects.create(
            tenant=self.tenant, user=self.user, amount=Decimal('500'),
            fee=Decimal('0'), bank_code='058', bank_name='GTBank',
            account_number='0123456789', account_name='JOHN DOE',
            reference='WD-POLL-1', status='pending',
        )
        Transaction.objects.create(
            tenant=self.tenant, user=self.user, type='withdrawal',
            amount=Decimal('500'), status='pending', reference='WD-POLL-1',
        )
        mock_verify.return_value = {'status': 'success'}
        resp = self.client.get('/api/v1/wallet/withdraw/WD-POLL-1/status/')
        self.assertEqual(resp.status_code, 200)
        self.assertEqual(resp.json()['status'], 'success')
        wd.refresh_from_db()
        self.assertEqual(wd.status, 'success')

    def tearDown(self):
        cache.clear()
        settings.DEV_MODE = True


class WithdrawWebhookTests(TestCase):
    """transfer.failed / transfer.reversed webhooks must refund the wallet."""

    def setUp(self):
        cache.clear()
        settings.DEV_MODE = False
        settings.PAYSTACK_SECRET_KEY = 'test_secret_key'
        self.tenant = Tenant.objects.create(
            name='Test', slug='test-tenant', owner_email='t@t.com',
            owner_phone='+2348000000000',
        )
        self.user, self.wallet = make_user_with_wallet(self.tenant, balance=Decimal('500'))
        self.client = APIClient()
        # Pending withdrawal: ₦500 already debited (wallet started at 1000).
        self.wd = Withdrawal.objects.create(
            tenant=self.tenant, user=self.user, amount=Decimal('500'),
            fee=Decimal('0'), bank_code='058', bank_name='GTBank',
            account_number='0123456789', account_name='JOHN DOE',
            reference='WD-HOOK-1', status='pending',
        )
        Transaction.objects.create(
            tenant=self.tenant, user=self.user, type='withdrawal',
            amount=Decimal('500'), status='pending', reference='WD-HOOK-1',
        )

    def _post(self, event):
        payload = json.dumps(event).encode()
        sig = hmac.new(b'test_secret_key', payload, hashlib.sha512).hexdigest()
        return self.client.post(
            '/api/v1/wallet/webhook/paystack/', data=payload,
            content_type='application/json', HTTP_X_PAYSTACK_SIGNATURE=sig,
        )

    def test_transfer_failed_refunds_wallet(self):
        resp = self._post({'event': 'transfer.failed',
                           'data': {'reference': 'WD-HOOK-1'}})
        self.assertEqual(resp.status_code, 200)
        self.wallet.refresh_from_db()
        self.assertEqual(self.wallet.balance, Decimal('1000'))  # 500 refunded
        self.wd.refresh_from_db()
        self.assertEqual(self.wd.status, 'reversed')

    def test_transfer_success_marks_success(self):
        resp = self._post({'event': 'transfer.success',
                           'data': {'reference': 'WD-HOOK-1'}})
        self.assertEqual(resp.status_code, 200)
        self.wallet.refresh_from_db()
        self.assertEqual(self.wallet.balance, Decimal('500'))  # no refund
        self.wd.refresh_from_db()
        self.assertEqual(self.wd.status, 'success')

    def tearDown(self):
        cache.clear()
        settings.DEV_MODE = True

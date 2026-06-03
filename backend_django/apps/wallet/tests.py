import hashlib
import hmac
import json
from decimal import Decimal
from unittest.mock import patch
from django.test import TestCase
from django.urls import reverse
from rest_framework.test import APIClient
from rest_framework_simplejwt.tokens import RefreshToken
from apps.tenants.models import Tenant
from apps.authentication.models import User
from apps.wallet.models import Wallet
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

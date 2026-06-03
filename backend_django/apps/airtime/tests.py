import json
from decimal import Decimal
from unittest.mock import patch, AsyncMock
from django.test import TestCase
from django.urls import reverse
from rest_framework.test import APIClient
from rest_framework_simplejwt.tokens import RefreshToken
from apps.tenants.models import Tenant
from apps.authentication.models import User
from apps.wallet.models import Wallet
from apps.transactions.models import Transaction


def make_user_with_wallet(tenant, phone='+2348000000001', balance=Decimal('5000')):
    user = User.objects.create_user(phone_number=phone, tenant=tenant, password='pass')
    wallet = Wallet.objects.create(tenant=tenant, user=user, balance=balance)
    return user, wallet


def auth_client(user):
    client = APIClient()
    token = RefreshToken.for_user(user)
    client.credentials(HTTP_AUTHORIZATION=f'Bearer {token.access_token}')
    client.credentials(HTTP_AUTHORIZATION=f'Bearer {token.access_token}', HTTP_X_TENANT_SLUG='test-tenant')
    return client


class AirtimePurchaseTests(TestCase):
    def setUp(self):
        self.tenant = Tenant.objects.create(
            name='Test', slug='test-tenant', owner_email='t@t.com', owner_phone='+2348000000000'
        )
        self.user, self.wallet = make_user_with_wallet(self.tenant)
        self.client = APIClient()
        token = RefreshToken.for_user(self.user)
        token['tenant_id'] = str(self.tenant.id)
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {token.access_token}')
        self.client.defaults['HTTP_X_TENANT_SLUG'] = 'test-tenant'

    @patch('apps.airtime.views.purchase_airtime')
    def test_successful_purchase_debits_wallet_and_creates_transaction(self, mock_purchase):
        mock_purchase.return_value = {'success': True, 'reference': 'GL-001', 'message': 'ok'}

        response = self.client.post('/api/v1/airtime/purchase/', {
            'network': 'mtn',
            'phone_number': '+2348011111111',
            'amount': '500',
        })

        self.assertEqual(response.status_code, 200)
        self.wallet.refresh_from_db()
        self.assertEqual(self.wallet.balance, Decimal('4500'))
        txn = Transaction.objects.get(reference='GL-001')
        self.assertEqual(txn.status, 'success')
        self.assertEqual(txn.amount, Decimal('500'))

    @patch('apps.airtime.views.purchase_airtime')
    def test_failed_purchase_refunds_wallet(self, mock_purchase):
        mock_purchase.return_value = {'success': False, 'reference': 'GL-002', 'message': 'Network error'}

        initial_balance = self.wallet.balance
        response = self.client.post('/api/v1/airtime/purchase/', {
            'network': 'mtn',
            'phone_number': '+2348011111111',
            'amount': '500',
        })

        self.assertEqual(response.status_code, 502)
        self.wallet.refresh_from_db()
        self.assertEqual(self.wallet.balance, initial_balance)
        txn = Transaction.objects.filter(network='mtn', status='failed').first()
        self.assertIsNotNone(txn)

    def test_insufficient_balance_returns_400(self):
        self.wallet.balance = Decimal('10')
        self.wallet.save()

        with patch('apps.airtime.views.purchase_airtime') as mock_purchase:
            response = self.client.post('/api/v1/airtime/purchase/', {
                'network': 'mtn',
                'phone_number': '+2348011111111',
                'amount': '500',
            })

        self.assertEqual(response.status_code, 400)
        self.assertIn('Insufficient', response.data['detail'])
        self.wallet.refresh_from_db()
        self.assertEqual(self.wallet.balance, Decimal('10'))

    def test_invalid_network_returns_400(self):
        response = self.client.post('/api/v1/airtime/purchase/', {
            'network': 'invalid_net',
            'phone_number': '+2348011111111',
            'amount': '500',
        })
        self.assertEqual(response.status_code, 400)

    def test_amount_below_minimum_returns_400(self):
        response = self.client.post('/api/v1/airtime/purchase/', {
            'network': 'mtn',
            'phone_number': '+2348011111111',
            'amount': '10',
        })
        self.assertEqual(response.status_code, 400)

from decimal import Decimal
from unittest.mock import patch
from django.test import TestCase
from rest_framework.test import APIClient
from rest_framework_simplejwt.tokens import RefreshToken
from apps.tenants.models import Tenant
from apps.authentication.models import User
from apps.wallet.models import Wallet
from apps.transactions.models import Transaction


def auth_client(user, tenant):
    client = APIClient()
    token = RefreshToken.for_user(user)
    token['tenant_id'] = str(tenant.id)
    client.credentials(HTTP_AUTHORIZATION=f'Bearer {token.access_token}')
    client.defaults['HTTP_X_TENANT_SLUG'] = tenant.slug
    return client


class BillPaymentTests(TestCase):
    def setUp(self):
        self.tenant = Tenant.objects.create(
            name='Test', slug='test-tenant', owner_email='t@t.com', owner_phone='+2348000000000'
        )
        self.user = User.objects.create_user(phone_number='+2348000000001', tenant=self.tenant, password='pass')
        self.wallet = Wallet.objects.create(tenant=self.tenant, user=self.user, balance=Decimal('20000'))
        self.client = auth_client(self.user, self.tenant)

    def test_providers_list(self):
        resp = self.client.get('/api/v1/bills/providers/?category=tv')
        self.assertEqual(resp.status_code, 200)
        self.assertTrue(any(p['id'] == 'dstv' for p in resp.data['providers']))

    @patch('apps.bills.services.pay_bill')
    def test_electricity_payment_success_returns_token(self, mock_pay):
        mock_pay.return_value = {'success': True, 'reference': 'VT-1', 'message': 'ok', 'token': '1234567890123456'}
        resp = self.client.post('/api/v1/bills/pay/', {
            'category': 'electricity',
            'service_id': 'ikeja-electric',
            'customer_id': '1111111111',
            'variation_code': 'prepaid',
            'amount': '5000',
            'phone_number': '+2348011111111',
        })
        self.assertEqual(resp.status_code, 200)
        self.assertEqual(resp.data['status'], 'success')
        self.assertEqual(resp.data['token'], '1234567890123456')
        self.wallet.refresh_from_db()
        self.assertEqual(self.wallet.balance, Decimal('15000'))
        txn = Transaction.objects.get(type='electricity')
        self.assertEqual(txn.token, '1234567890123456')
        self.assertEqual(txn.customer_id, '1111111111')

    @patch('apps.bills.services.pay_bill')
    def test_failed_payment_enters_retrying(self, mock_pay):
        mock_pay.return_value = {'success': False, 'reference': 'VT-2', 'message': 'biller down', 'token': ''}
        resp = self.client.post('/api/v1/bills/pay/', {
            'category': 'tv',
            'service_id': 'dstv',
            'customer_id': '2222222222',
            'variation_code': 'dstv-padi',
            'amount': '2950',
            'phone_number': '+2348011111111',
        })
        self.assertEqual(resp.status_code, 200)
        self.assertEqual(resp.data['status'], 'retrying')
        txn = Transaction.objects.get(type='tv')
        self.assertEqual(txn.status, 'retrying')

from decimal import Decimal
from unittest.mock import patch
from django.test import TestCase
from rest_framework.test import APIClient
from rest_framework_simplejwt.tokens import RefreshToken
from apps.tenants.models import Tenant
from apps.authentication.models import User
from apps.wallet.models import Wallet
from apps.transactions.models import Transaction
from .models import Agent


def auth_client(user, tenant):
    client = APIClient()
    token = RefreshToken.for_user(user)
    token['tenant_id'] = str(tenant.id)
    client.credentials(HTTP_AUTHORIZATION=f'Bearer {token.access_token}')
    client.defaults['HTTP_X_TENANT_SLUG'] = tenant.slug
    return client


class AgentTests(TestCase):
    def setUp(self):
        self.tenant = Tenant.objects.create(
            name='Test', slug='test-tenant', owner_email='t@t.com', owner_phone='+2348000000000'
        )
        self.user = User.objects.create_user(phone_number='+2348000000001', tenant=self.tenant, password='p')
        self.wallet = Wallet.objects.create(tenant=self.tenant, user=self.user, balance=Decimal('10000'))
        self.client = auth_client(self.user, self.tenant)

    def test_apply_creates_pending_agent(self):
        resp = self.client.post('/api/v1/agents/apply/', {'business_name': 'Naz Telecom'})
        self.assertEqual(resp.status_code, 201)
        self.assertEqual(resp.data['status'], 'pending')
        self.assertTrue(resp.data['agent_code'].startswith('AG'))

    def test_inactive_agent_cannot_sell(self):
        Agent.objects.create(tenant=self.tenant, user=self.user, agent_code='AG111111',
                             business_name='X', status='pending')
        resp = self.client.post('/api/v1/agents/sale/', {
            'type': 'airtime', 'network': 'mtn', 'phone_number': '+2348011111111', 'amount': '500',
        })
        self.assertEqual(resp.status_code, 403)

    @patch('apps.airtime.services.purchase_airtime')
    def test_active_agent_sale_debits_float_and_earns_commission(self, mock_purchase):
        mock_purchase.return_value = {'success': True, 'reference': 'GL-A', 'message': 'ok'}
        Agent.objects.create(tenant=self.tenant, user=self.user, agent_code='AG222222',
                             business_name='X', status='active', commission_percent=Decimal('2.00'))

        resp = self.client.post('/api/v1/agents/sale/', {
            'type': 'airtime', 'network': 'mtn', 'phone_number': '+2348011111111', 'amount': '500',
        })
        self.assertEqual(resp.status_code, 200)
        self.assertEqual(resp.data['status'], 'success')

        self.wallet.refresh_from_db()
        # -500 sale + 2% commission (10)
        self.assertEqual(self.wallet.balance, Decimal('9510'))
        self.assertTrue(Transaction.all_objects.filter(type='commission', amount=Decimal('10.00')).exists())

    @patch('apps.bills.services.pay_bill')
    def test_active_agent_electricity_sale(self, mock_pay):
        mock_pay.return_value = {'success': True, 'reference': 'VT-A', 'message': 'ok', 'token': '9999000011112222'}
        Agent.objects.create(tenant=self.tenant, user=self.user, agent_code='AG333333',
                             business_name='X', status='active', commission_percent=Decimal('1.00'))

        resp = self.client.post('/api/v1/agents/sale/', {
            'type': 'electricity', 'service_id': 'ikeja-electric', 'customer_id': '1111111111',
            'variation_code': 'prepaid', 'amount': '3000', 'phone_number': '+2348011111111',
        })
        self.assertEqual(resp.status_code, 200)
        self.assertEqual(resp.data['status'], 'success')
        self.assertEqual(resp.data['token'], '9999000011112222')

        self.wallet.refresh_from_db()
        # -3000 sale + 1% commission (30)
        self.assertEqual(self.wallet.balance, Decimal('7030'))
        txn = Transaction.all_objects.get(type='electricity')
        self.assertEqual(txn.customer_id, '1111111111')
        self.assertEqual(txn.provider, 'ikeja-electric')

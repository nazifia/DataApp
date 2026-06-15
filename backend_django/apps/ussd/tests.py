from decimal import Decimal
from unittest.mock import patch
from django.test import TestCase
from rest_framework.test import APIClient
from apps.tenants.models import Tenant
from apps.authentication.models import User
from apps.wallet.models import Wallet
from apps.transactions.models import Transaction


class USSDTests(TestCase):
    def setUp(self):
        self.tenant = Tenant.objects.create(
            name='Test', slug='test-tenant', owner_email='t@t.com', owner_phone='+2348000000000'
        )
        self.user = User.objects.create_user(phone_number='+2348000000001', tenant=self.tenant, password='p')
        self.user.set_ussd_pin('1234')
        self.user.save()
        self.wallet = Wallet.objects.create(tenant=self.tenant, user=self.user, balance=Decimal('5000'))
        self.client = APIClient()

    def _ussd(self, text):
        resp = self.client.post('/api/v1/ussd/callback/', {
            'sessionId': 'sess-1', 'phoneNumber': '+2348000000001', 'text': text,
        })
        return resp.content.decode()

    def test_main_menu(self):
        body = self._ussd('')
        self.assertTrue(body.startswith('CON'))
        self.assertIn('Buy Airtime', body)

    def test_unregistered_number_ends(self):
        resp = self.client.post('/api/v1/ussd/callback/', {
            'sessionId': 's', 'phoneNumber': '+2349099999999', 'text': '',
        })
        self.assertTrue(resp.content.decode().startswith('END'))

    def test_balance_requires_correct_pin(self):
        self.assertIn('Incorrect PIN', self._ussd('1*0000'))
        body = self._ussd('1*1234')
        self.assertTrue(body.startswith('END'))
        self.assertIn('5,000', body)

    @patch('apps.airtime.services.purchase_airtime')
    def test_airtime_full_flow(self, mock_purchase):
        mock_purchase.return_value = {'success': True, 'reference': 'GL-U', 'message': 'ok'}
        # menu -> network -> amount -> pin
        self.assertIn('network', self._ussd('2').lower())
        self.assertIn('amount', self._ussd('2*1').lower())
        self.assertIn('PIN', self._ussd('2*1*500'))
        body = self._ussd('2*1*500*1234')
        self.assertTrue(body.startswith('END'))
        self.wallet.refresh_from_db()
        self.assertEqual(self.wallet.balance, Decimal('4500'))
        self.assertTrue(Transaction.objects.filter(type='airtime', status='success').exists())

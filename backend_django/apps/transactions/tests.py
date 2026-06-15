from decimal import Decimal
from unittest.mock import patch
from django.core.management import call_command
from django.test import TestCase
from django.utils import timezone
from apps.tenants.models import Tenant
from apps.authentication.models import User
from apps.wallet.models import Wallet
from apps.transactions.models import Transaction
from apps.transactions.fulfillment import fulfill


class RetryFulfillmentTests(TestCase):
    def setUp(self):
        self.tenant = Tenant.objects.create(
            name='Test', slug='test-tenant', owner_email='t@t.com', owner_phone='+2348000000000'
        )
        self.user = User.objects.create_user(phone_number='+2348000000001', tenant=self.tenant, password='pass')
        self.wallet = Wallet.objects.create(tenant=self.tenant, user=self.user, balance=Decimal('0'))

    def _pending_airtime(self, charge=Decimal('500')):
        # Simulate the view having already debited the wallet for this txn.
        return Transaction.objects.create(
            tenant=self.tenant, user=self.user, type='airtime',
            amount=charge, face_value=charge, status='pending',
            reference=Transaction.generate_reference(),
            network='mtn', phone_number='+2348011111111',
        )

    @patch('apps.airtime.services.purchase_airtime')
    def test_retry_then_success(self, mock_purchase):
        mock_purchase.return_value = {'success': False, 'message': 'down'}
        txn = self._pending_airtime()
        fulfill(txn)
        self.assertEqual(txn.status, 'retrying')

        # Make it due, then let the next attempt succeed.
        Transaction.all_objects.filter(pk=txn.pk).update(next_retry_at=timezone.now())
        mock_purchase.return_value = {'success': True, 'reference': 'GL-OK', 'message': 'ok'}
        call_command('retry_transactions')
        txn.refresh_from_db()
        self.assertEqual(txn.status, 'success')

    @patch('apps.airtime.services.purchase_airtime')
    def test_retries_exhausted_refunds_wallet(self, mock_purchase):
        mock_purchase.return_value = {'success': False, 'message': 'permanently down'}
        txn = self._pending_airtime(Decimal('500'))

        fulfill(txn)  # retry_count 1
        for _ in range(5):  # drive through remaining retries
            Transaction.all_objects.filter(pk=txn.pk).update(next_retry_at=timezone.now())
            call_command('retry_transactions')
            txn.refresh_from_db()
            if txn.status == 'failed':
                break

        self.assertEqual(txn.status, 'failed')
        self.wallet.refresh_from_db()
        self.assertEqual(self.wallet.balance, Decimal('500'))  # refunded exactly once

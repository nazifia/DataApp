from django.test import TestCase
from rest_framework.test import APIClient
from rest_framework_simplejwt.tokens import RefreshToken
from apps.tenants.models import Tenant
from apps.authentication.models import User
from .models import Dispute


def make_user(tenant, phone='+2348000000001'):
    return User.objects.create_user(phone_number=phone, tenant=tenant, password='pass')


class DisputeTests(TestCase):
    def setUp(self):
        self.tenant = Tenant.objects.create(
            name='Test', slug='test-tenant', owner_email='t@t.com', owner_phone='+2348000000000'
        )
        self.user = make_user(self.tenant)
        self.client = APIClient()
        token = RefreshToken.for_user(self.user)
        token['tenant_id'] = str(self.tenant.id)
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {token.access_token}')
        self.client.defaults['HTTP_X_TENANT_SLUG'] = 'test-tenant'

    def test_create_dispute(self):
        response = self.client.post('/api/v1/disputes/', {
            'subject': 'Missing refund',
            'message': 'I was charged but received no airtime.',
            'transaction_reference': 'TUN-001',
        })
        self.assertEqual(response.status_code, 201)
        self.assertEqual(Dispute.objects.filter(user=self.user).count(), 1)
        self.assertEqual(response.data['status'], 'open')

    def test_list_disputes(self):
        Dispute.objects.create(
            tenant=self.tenant, user=self.user,
            subject='Test', message='A long enough message here.',
        )
        response = self.client.get('/api/v1/disputes/')
        self.assertEqual(response.status_code, 200)
        self.assertGreaterEqual(response.data['total'], 1)

    def test_subject_too_short_returns_400(self):
        response = self.client.post('/api/v1/disputes/', {
            'subject': 'Hi',
            'message': 'A long enough message here.',
        })
        self.assertEqual(response.status_code, 400)

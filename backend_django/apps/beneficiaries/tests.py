from django.test import TestCase
from rest_framework.test import APIClient
from rest_framework_simplejwt.tokens import RefreshToken
from apps.tenants.models import Tenant
from apps.authentication.models import User
from .models import Beneficiary


def make_user(tenant, phone='+2348000000001'):
    return User.objects.create_user(phone_number=phone, tenant=tenant, password='pass')


class BeneficiaryTests(TestCase):
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

    def test_create_beneficiary(self):
        response = self.client.post('/api/v1/beneficiaries/', {
            'phone_number': '+2348011111111',
            'network': 'mtn',
            'type': 'airtime',
            'nickname': 'Mum',
        })
        self.assertEqual(response.status_code, 201)
        self.assertEqual(response.data['nickname'], 'Mum')
        self.assertEqual(Beneficiary.objects.filter(user=self.user).count(), 1)

    def test_list_beneficiaries(self):
        Beneficiary.objects.create(
            tenant=self.tenant, user=self.user,
            phone_number='+2348011111111', network='mtn', type='airtime',
        )
        response = self.client.get('/api/v1/beneficiaries/')
        self.assertEqual(response.status_code, 200)
        self.assertEqual(len(response.data), 1)

    def test_delete_beneficiary(self):
        b = Beneficiary.objects.create(
            tenant=self.tenant, user=self.user,
            phone_number='+2348011111111', network='mtn', type='airtime',
        )
        response = self.client.delete(f'/api/v1/beneficiaries/{b.id}/')
        self.assertEqual(response.status_code, 204)
        self.assertEqual(Beneficiary.objects.filter(user=self.user).count(), 0)

    def test_duplicate_beneficiary_returns_200_not_201(self):
        data = {'phone_number': '+2348011111111', 'network': 'mtn', 'type': 'airtime', 'nickname': 'Mum'}
        self.client.post('/api/v1/beneficiaries/', data)
        response = self.client.post('/api/v1/beneficiaries/', data)
        self.assertEqual(response.status_code, 200)
        self.assertEqual(Beneficiary.objects.filter(user=self.user).count(), 1)

    def test_filter_by_type(self):
        Beneficiary.objects.create(
            tenant=self.tenant, user=self.user,
            phone_number='+2348011111111', network='mtn', type='airtime',
        )
        Beneficiary.objects.create(
            tenant=self.tenant, user=self.user,
            phone_number='+2348022222222', network='mtn', type='data',
        )
        response = self.client.get('/api/v1/beneficiaries/?type=airtime')
        self.assertEqual(len(response.data), 1)
        self.assertEqual(response.data[0]['type'], 'airtime')

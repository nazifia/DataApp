from django.core.management.base import BaseCommand
from apps.tenants.models import Tenant
from apps.authentication.models import User
from apps.wallet.models import Wallet


class Command(BaseCommand):
    help = 'Create a default tenant and test user for local development'

    def add_arguments(self, parser):
        parser.add_argument('--phone', default='+2348000000001', help='Test user phone number')
        parser.add_argument('--password', default='password123', help='Test user password')
        parser.add_argument('--tenant', default='default', help='Tenant slug')

    def handle(self, *args, **options):
        slug = options['tenant']
        phone = options['phone']
        password = options['password']

        tenant, created = Tenant.all_objects.get_or_create(
            slug=slug,
            defaults={
                'name': 'Default Tenant',
                'owner_email': 'admin@topupnaija.com',
                'owner_phone': phone,
                'is_active': True,
            },
        )
        if created:
            self.stdout.write(self.style.SUCCESS(f'Created tenant: {slug}'))
        else:
            self.stdout.write(f'Tenant already exists: {slug}')

        user, created = User.objects.get_or_create(
            tenant=tenant,
            phone_number=phone,
            defaults={'full_name': 'Test User', 'is_active': True},
        )
        user.set_password(password)
        user.save()

        Wallet.objects.get_or_create(tenant=tenant, user=user, defaults={'balance': 5000})

        action = 'Created' if created else 'Updated'
        self.stdout.write(self.style.SUCCESS(
            f'{action} test user:\n'
            f'  Tenant : {slug}\n'
            f'  Phone  : {phone}\n'
            f'  Password: {password}\n'
        ))

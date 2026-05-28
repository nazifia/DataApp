import getpass
import os

from django.contrib.auth import get_user_model
from django.core.management.base import BaseCommand, CommandError


class Command(BaseCommand):
    help = 'Create a superuser (phone_number + password only; id is auto-generated)'

    def add_arguments(self, parser):
        parser.add_argument('--phone-number', dest='phone_number')
        parser.add_argument('--password', dest='password')
        parser.add_argument(
            '--no-input', '--noinput',
            action='store_false', dest='interactive', default=True,
        )

    def handle(self, *args, **options):
        User = get_user_model()
        interactive = options['interactive']
        phone_number = options.get('phone_number')
        password = options.get('password')

        if interactive:
            if not phone_number:
                phone_number = input('Phone number: ')
            if not password:
                password = getpass.getpass('Password: ')
                confirm = getpass.getpass('Password (again): ')
                if password != confirm:
                    raise CommandError("Passwords do not match.")
        else:
            phone_number = phone_number or os.environ.get('DJANGO_SUPERUSER_PHONE_NUMBER')
            password = password or os.environ.get('DJANGO_SUPERUSER_PASSWORD')
            if not phone_number or not password:
                raise CommandError(
                    'Provide --phone-number and --password (or set '
                    'DJANGO_SUPERUSER_PHONE_NUMBER / DJANGO_SUPERUSER_PASSWORD).'
                )

        User.objects.create_superuser(phone_number=phone_number, password=password)
        self.stdout.write(self.style.SUCCESS('Superuser created successfully.'))

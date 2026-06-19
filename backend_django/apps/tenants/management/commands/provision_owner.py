from django.core.management.base import BaseCommand, CommandError

from apps.tenants.models import Tenant
from apps.tenants.services import provision_tenant_owner


class Command(BaseCommand):
    help = (
        "Provision (or repair) the owner admin login for an existing tenant. "
        "Use this for tenants created via the Django admin or super-admin API, "
        "which otherwise have no login-capable user."
    )

    def add_arguments(self, parser):
        parser.add_argument('slug', help='Tenant slug (X-Tenant-Slug value)')
        parser.add_argument(
            '--password',
            help='Owner password to set. Omit to auto-generate one.',
        )
        parser.add_argument(
            '--reset-password',
            action='store_true',
            help="Reset the password even if the owner already has a usable one.",
        )

    def handle(self, *args, **options):
        slug = options['slug']
        try:
            tenant = Tenant.all_objects.get(slug=slug)
        except Tenant.DoesNotExist:
            raise CommandError(f'No tenant with slug "{slug}".')

        if not tenant.is_active:
            self.stdout.write(self.style.WARNING(
                f'Tenant "{slug}" is INACTIVE — login will 404 until it is '
                f'reactivated.'
            ))

        user, raw_password = provision_tenant_owner(
            tenant,
            password=options.get('password'),
            reset_password=options['reset_password'],
        )

        self.stdout.write(self.style.SUCCESS(
            f'Owner ready for tenant "{slug}":\n'
            f'  Phone   : {user.phone_number}\n'
            f'  Role    : {user.role}\n'
            f'  Active  : {user.is_active}\n'
        ))
        if raw_password:
            self.stdout.write(self.style.SUCCESS(
                f'  Password: {raw_password}  (shown once — save it)\n'
            ))
        else:
            self.stdout.write(
                '  Password: unchanged (use --reset-password to set a new one)\n'
            )
        self.stdout.write(
            f'Login with header  X-Tenant-Slug: {slug}  '
            f'and phone {user.phone_number}.'
        )

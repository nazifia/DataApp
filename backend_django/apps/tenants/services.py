"""Tenant provisioning helpers shared by the register serializer, the
super-admin create API, the Django admin, and management commands.

A tenant is only usable once its owner has a login-capable User account and a
wallet. Centralising that here keeps every tenant-creation path consistent so
"created a tenant but can't log in" can't happen again.
"""
import secrets
from django.db import transaction

from core.validators import normalize_phone_number


def provision_tenant_owner(tenant, password=None, *, reset_password=False):
    """Ensure ``tenant`` has an owner admin User (+ wallet) able to log in.

    - Creates the owner User (role='admin') if missing.
    - Creates the owner Wallet if missing.
    - Sets the password when creating, or when ``reset_password`` is True.

    Returns ``(user, raw_password)``. ``raw_password`` is the password that was
    set (the given one, or a generated one), or ``None`` if an existing user's
    password was left untouched. Callers should surface a generated password to
    the operator — it is not recoverable afterwards.
    """
    from apps.authentication.models import User
    from apps.wallet.models import Wallet

    phone = normalize_phone_number(tenant.owner_phone) or tenant.owner_phone

    with transaction.atomic():
        user, created = User.objects.get_or_create(
            tenant=tenant,
            phone_number=phone,
            defaults={
                'email': tenant.owner_email,
                'role': 'admin',
                'is_active': True,
            },
        )

        raw_password = None
        if created or reset_password or not user.has_usable_password():
            raw_password = password or secrets.token_urlsafe(9)
            user.set_password(raw_password)
            # Keep the owner an admin and active even when repairing an
            # account that was created some other way.
            user.role = 'admin'
            user.is_active = True
            user.save()

        Wallet.objects.get_or_create(
            tenant=tenant, user=user, defaults={'balance': 0},
        )

    return user, raw_password

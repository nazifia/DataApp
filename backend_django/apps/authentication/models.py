import uuid
from django.contrib.auth.models import AbstractBaseUser, BaseUserManager, PermissionsMixin
from django.db import models
from django.utils import timezone


class UserManager(BaseUserManager):
    def create_user(self, phone_number, tenant, password=None, **extra):
        if not phone_number:
            raise ValueError('Phone number is required')
        user = self.model(phone_number=phone_number, tenant=tenant, **extra)
        if password:
            user.set_password(password)
        user.save(using=self._db)
        return user

    def create_superuser(self, phone_number, password, **extra):
        from apps.tenants.models import Tenant
        tenant, _ = Tenant.all_objects.get_or_create(
            slug='platform',
            defaults={'name': 'Platform', 'owner_email': 'admin@topupnaija.com', 'owner_phone': phone_number},
        )
        extra.setdefault('role', 'super_admin')
        extra.setdefault('is_staff', True)
        extra.setdefault('is_superuser', True)
        return self.create_user(phone_number, tenant=tenant, password=password, **extra)


class User(AbstractBaseUser, PermissionsMixin):
    ROLE_CHOICES = [
        ('user', 'User'),
        ('support', 'Support'),
        ('moderator', 'Moderator'),
        ('admin', 'Admin'),
        ('super_admin', 'Super Admin'),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    tenant = models.ForeignKey(
        'tenants.Tenant',
        on_delete=models.CASCADE,
        related_name='users',
    )
    phone_number = models.CharField(max_length=20, db_index=True)
    full_name = models.CharField(max_length=255, blank=True)
    email = models.EmailField(blank=True)
    device_id = models.CharField(max_length=255, blank=True)
    profile_picture_url = models.CharField(max_length=500, blank=True)
    fcm_token = models.CharField(max_length=500, blank=True)
    role = models.CharField(max_length=20, choices=ROLE_CHOICES, default='user')
    is_active = models.BooleanField(default=True)
    is_staff = models.BooleanField(default=False)
    created_at = models.DateTimeField(default=timezone.now)
    updated_at = models.DateTimeField(auto_now=True)

    objects = UserManager()

    # Use id (UUID) as Django's USERNAME_FIELD so uniqueness constraint is satisfied.
    # App-level login is always via phone_number — see LoginView / VerifyOTPView.
    USERNAME_FIELD = 'id'
    REQUIRED_FIELDS = ['phone_number']

    class Meta:
        db_table = 'users'
        unique_together = [('tenant', 'phone_number')]

    def __str__(self):
        return f'{self.phone_number} ({self.tenant.slug})'


class OTPRecord(models.Model):
    """Persisted OTP storage — replaces the in-memory dict from FastAPI."""
    tenant = models.ForeignKey('tenants.Tenant', on_delete=models.CASCADE)
    phone_number = models.CharField(max_length=20)
    otp = models.CharField(max_length=6)
    expires_at = models.DateTimeField()
    used = models.BooleanField(default=False)
    created_at = models.DateTimeField(default=timezone.now)

    class Meta:
        db_table = 'otp_records'
        indexes = [models.Index(fields=['tenant', 'phone_number'])]

    @property
    def is_expired(self):
        return timezone.now() > self.expires_at

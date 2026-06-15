import uuid
from django.db import models
from django.utils import timezone


class Tenant(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    name = models.CharField(max_length=255)
    slug = models.SlugField(unique=True, help_text='Used in X-Tenant-Slug header and subdomain routing')
    owner_email = models.EmailField()
    owner_phone = models.CharField(max_length=20)
    is_active = models.BooleanField(default=True)

    # Branding
    logo_url = models.URLField(blank=True)
    primary_color = models.CharField(max_length=7, default='#6C63FF', help_text='Hex color')
    support_email = models.EmailField(blank=True)
    support_phone = models.CharField(max_length=20, blank=True)

    # Business config
    airtime_markup_percent = models.DecimalField(
        max_digits=5, decimal_places=2, default=0,
        help_text='Extra % charged on airtime purchases'
    )
    data_markup_percent = models.DecimalField(
        max_digits=5, decimal_places=2, default=0,
        help_text='Extra % charged on data purchases'
    )
    bill_markup_percent = models.DecimalField(
        max_digits=5, decimal_places=2, default=0,
        help_text='Extra % charged on electricity/TV bill payments'
    )
    referral_bonus = models.DecimalField(
        max_digits=10, decimal_places=2, default=0,
        help_text='Wallet bonus credited to referrer on referee first successful purchase'
    )
    min_wallet_fund = models.DecimalField(max_digits=10, decimal_places=2, default=50)
    max_daily_transaction = models.DecimalField(
        max_digits=12, decimal_places=2, default=500000,
        help_text='Max total daily spend per user (NGN)'
    )

    created_at = models.DateTimeField(default=timezone.now)
    updated_at = models.DateTimeField(auto_now=True)

    all_objects = models.Manager()
    objects = models.Manager()

    class Meta:
        db_table = 'tenants'

    def __str__(self):
        return f'{self.name} ({self.slug})'

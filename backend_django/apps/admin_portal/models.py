import uuid
from django.core.cache import cache
from django.db import models
from django.utils import timezone
from core.models import TenantAwareModel, UUIDModel


class RuntimeConfig(models.Model):
    """Singleton runtime switch edited from the Django admin.

    dev_mode=True  -> providers (airtime/data/bills/payments) return mocks and
                      the TEST_OTP is accepted. Use for development/staging.
    dev_mode=False -> hit live providers and require real OTPs. Use in prod.

    NOTE: this does NOT change DEBUG, the database, or ALLOWED_HOSTS — those are
    deploy-time settings (topupnaija.settings.dev / .prod) and need a restart.
    Read it via core.runtime.is_dev_mode() / ais_dev_mode(), never directly.
    """

    SINGLETON_PK = 1
    CACHE_KEY = 'runtime:dev_mode'

    dev_mode = models.BooleanField(
        default=True,
        help_text='ON: mock providers + test OTP (development). '
                  'OFF: live providers + real OTP (production).',
    )
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = 'Runtime configuration'
        verbose_name_plural = 'Runtime configuration'

    def __str__(self):
        return f"Runtime: {'DEV' if self.dev_mode else 'PROD'} mode"

    def save(self, *args, **kwargs):
        self.pk = self.SINGLETON_PK
        super().save(*args, **kwargs)
        cache.delete(self.CACHE_KEY)

    def delete(self, *args, **kwargs):
        # Singleton — keep the row, just reset the cache.
        cache.delete(self.CACHE_KEY)

    @classmethod
    def load(cls):
        obj, _ = cls.objects.get_or_create(pk=cls.SINGLETON_PK)
        return obj


class AdminAuditLog(TenantAwareModel, UUIDModel):
    admin = models.ForeignKey(
        'authentication.User',
        on_delete=models.SET_NULL,
        null=True,
        related_name='audit_logs',
    )
    action = models.CharField(max_length=100, db_index=True)
    target_type = models.CharField(max_length=50, blank=True)
    target_id = models.CharField(max_length=100, blank=True)
    details = models.TextField(blank=True)
    ip_address = models.GenericIPAddressField(null=True, blank=True)
    created_at = models.DateTimeField(default=timezone.now, db_index=True)

    class Meta:
        db_table = 'admin_audit_logs'
        ordering = ['-created_at']

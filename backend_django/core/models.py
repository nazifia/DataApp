import uuid
from django.db import models
from django.utils import timezone


class TenantAwareManager(models.Manager):
    """Automatically filters queryset to the current request's tenant."""

    def get_queryset(self):
        from core.middleware import get_current_tenant
        qs = super().get_queryset()
        tenant = get_current_tenant()
        if tenant is not None:
            qs = qs.filter(tenant=tenant)
        return qs


class TenantAwareModel(models.Model):
    """Base model for all tenant-scoped data."""

    tenant = models.ForeignKey(
        'tenants.Tenant',
        on_delete=models.CASCADE,
        related_name='+',
        db_index=True,
    )

    objects = TenantAwareManager()
    all_objects = models.Manager()

    class Meta:
        abstract = True


class TimestampedModel(models.Model):
    created_at = models.DateTimeField(default=timezone.now)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        abstract = True


class UUIDModel(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)

    class Meta:
        abstract = True

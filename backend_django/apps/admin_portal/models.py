import uuid
from django.db import models
from django.utils import timezone
from core.models import TenantAwareModel, UUIDModel


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

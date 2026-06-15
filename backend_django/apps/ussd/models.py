from django.db import models
from django.utils import timezone


class USSDSession(models.Model):
    """Audit/state record for a USSD session. State carried by the gateway's
    accumulating `text` param; persisted here for debugging and analytics."""
    tenant = models.ForeignKey('tenants.Tenant', on_delete=models.CASCADE, null=True, blank=True)
    session_id = models.CharField(max_length=128, db_index=True)
    phone_number = models.CharField(max_length=20, db_index=True)
    last_input = models.CharField(max_length=255, blank=True)
    last_response = models.TextField(blank=True)
    ended = models.BooleanField(default=False)
    created_at = models.DateTimeField(default=timezone.now)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'ussd_sessions'
        indexes = [models.Index(fields=['session_id'])]
        ordering = ['-created_at']

    def __str__(self):
        return f'{self.session_id} ({self.phone_number})'

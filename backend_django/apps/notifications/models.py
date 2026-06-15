from django.db import models
from django.utils import timezone
from core.models import TenantAwareModel, UUIDModel


class Notification(TenantAwareModel, UUIDModel):
    user = models.ForeignKey(
        'authentication.User',
        on_delete=models.CASCADE,
        related_name='notifications',
    )
    title = models.CharField(max_length=200)
    body = models.TextField(blank=True)
    type = models.CharField(max_length=50, blank=True, db_index=True)
    data = models.JSONField(default=dict, blank=True)
    is_read = models.BooleanField(default=False, db_index=True)
    created_at = models.DateTimeField(default=timezone.now, db_index=True)

    class Meta:
        db_table = 'notifications'
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['user', 'is_read']),
        ]

    def __str__(self):
        return f'{self.title} -> {self.user_id}'

from django.db import models
from django.utils import timezone
from core.models import TenantAwareModel, UUIDModel


class Dispute(TenantAwareModel, UUIDModel):
    STATUS_CHOICES = [
        ('open', 'Open'),
        ('in_review', 'In Review'),
        ('resolved', 'Resolved'),
        ('closed', 'Closed'),
    ]

    user = models.ForeignKey(
        'authentication.User',
        on_delete=models.CASCADE,
        related_name='disputes',
    )
    transaction_reference = models.CharField(max_length=100, blank=True, db_index=True)
    subject = models.CharField(max_length=200)
    message = models.TextField()
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='open', db_index=True)
    admin_notes = models.TextField(blank=True)
    created_at = models.DateTimeField(default=timezone.now, db_index=True)
    resolved_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        db_table = 'disputes'
        ordering = ['-created_at']

    def __str__(self):
        return f'Dispute({self.reference_display}) - {self.status}'

    @property
    def reference_display(self):
        return self.transaction_reference or str(self.id)[:8]

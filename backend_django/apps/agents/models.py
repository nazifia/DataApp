from decimal import Decimal
from django.db import models
from django.utils import timezone
from core.models import TenantAwareModel, UUIDModel


class Agent(TenantAwareModel, UUIDModel):
    STATUS_CHOICES = [
        ('pending', 'Pending Approval'),
        ('active', 'Active'),
        ('suspended', 'Suspended'),
    ]

    user = models.OneToOneField(
        'authentication.User',
        on_delete=models.CASCADE,
        related_name='agent',
    )
    agent_code = models.CharField(max_length=20, unique=True, db_index=True)
    business_name = models.CharField(max_length=255)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending')
    commission_percent = models.DecimalField(
        max_digits=5, decimal_places=2, default=Decimal('1.00'),
        help_text='% commission earned on each facilitated sale',
    )
    created_at = models.DateTimeField(default=timezone.now)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'agents'
        ordering = ['-created_at']

    @staticmethod
    def generate_code() -> str:
        import random
        return f'AG{random.randint(100000, 999999)}'

    def __str__(self):
        return f'{self.agent_code} ({self.business_name})'

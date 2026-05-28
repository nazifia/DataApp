import random
import time
from django.db import models
from django.utils import timezone
from core.models import TenantAwareModel, UUIDModel


class Transaction(TenantAwareModel, UUIDModel):
    TYPE_CHOICES = [
        ('airtime', 'Airtime'),
        ('data', 'Data'),
        ('wallet_fund', 'Wallet Fund'),
        ('refund', 'Refund'),
    ]
    STATUS_CHOICES = [
        ('pending', 'Pending'),
        ('success', 'Success'),
        ('failed', 'Failed'),
    ]
    NETWORK_CHOICES = [
        ('mtn', 'MTN'),
        ('airtel', 'Airtel'),
        ('glo', 'Glo'),
        ('etisalat', '9mobile'),
    ]

    user = models.ForeignKey(
        'authentication.User',
        on_delete=models.CASCADE,
        related_name='transactions',
    )
    type = models.CharField(max_length=20, choices=TYPE_CHOICES)
    amount = models.DecimalField(max_digits=12, decimal_places=2)
    status = models.CharField(max_length=10, choices=STATUS_CHOICES, default='pending')
    reference = models.CharField(max_length=100, unique=True, db_index=True)
    network = models.CharField(max_length=20, choices=NETWORK_CHOICES, blank=True)
    phone_number = models.CharField(max_length=20, blank=True)
    plan_id = models.CharField(max_length=100, blank=True)
    created_at = models.DateTimeField(default=timezone.now, db_index=True)

    class Meta:
        db_table = 'transactions'
        ordering = ['-created_at']

    @staticmethod
    def generate_reference() -> str:
        ts = int(time.time() * 1000)
        rand = random.randint(1000, 9999)
        return f'TUN-{ts}-{rand}'

    @property
    def is_reversed(self) -> bool:
        return Transaction.all_objects.filter(
            reference=f'REV-{self.reference}'
        ).exists()

    def __str__(self):
        return f'{self.reference} {self.type} ₦{self.amount}'

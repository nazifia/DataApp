import random
import time
from django.db import models
from django.utils import timezone
from core.models import TenantAwareModel, UUIDModel


class Transaction(TenantAwareModel, UUIDModel):
    TYPE_CHOICES = [
        ('airtime', 'Airtime'),
        ('data', 'Data'),
        ('electricity', 'Electricity'),
        ('tv', 'Cable TV'),
        ('wallet_fund', 'Wallet Fund'),
        ('refund', 'Refund'),
        ('commission', 'Agent Commission'),
    ]
    STATUS_CHOICES = [
        ('pending', 'Pending'),
        ('retrying', 'Retrying'),
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
    # Bill payment fields (electricity / TV)
    customer_id = models.CharField(max_length=100, blank=True, help_text='Meter or smartcard number')
    provider = models.CharField(max_length=50, blank=True, help_text='Disco / cable provider code')
    variation_code = models.CharField(max_length=100, blank=True)
    token = models.CharField(max_length=255, blank=True, help_text='Electricity token returned by provider')
    # Value actually delivered to the provider (pre-markup). `amount` is what the wallet was charged.
    face_value = models.DecimalField(max_digits=12, decimal_places=2, null=True, blank=True)
    # Auto-retry tracking
    retry_count = models.PositiveIntegerField(default=0)
    next_retry_at = models.DateTimeField(null=True, blank=True, db_index=True)
    last_error = models.TextField(blank=True)
    # POS agent that facilitated this transaction (null = direct customer purchase)
    agent = models.ForeignKey(
        'agents.Agent',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='transactions',
    )
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

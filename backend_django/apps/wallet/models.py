import uuid
from decimal import Decimal
from django.db import models
from django.utils import timezone
from core.models import TenantAwareModel, UUIDModel


class Wallet(TenantAwareModel, UUIDModel):
    user = models.OneToOneField(
        'authentication.User',
        on_delete=models.CASCADE,
        related_name='wallet',
    )
    balance = models.DecimalField(max_digits=12, decimal_places=2, default=Decimal('0'))
    # Paystack dedicated virtual account fields
    paystack_customer_code = models.CharField(max_length=100, blank=True)
    paystack_account_number = models.CharField(max_length=20, blank=True)
    paystack_bank_name = models.CharField(max_length=100, blank=True)
    paystack_account_name = models.CharField(max_length=200, blank=True)
    created_at = models.DateTimeField(default=timezone.now)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'wallets'

    def __str__(self):
        return f'Wallet({self.user.phone_number}) ₦{self.balance}'


class Withdrawal(TenantAwareModel, UUIDModel):
    STATUS_CHOICES = [
        ('pending', 'Pending'),
        ('success', 'Success'),
        ('failed', 'Failed'),
        ('reversed', 'Reversed'),
    ]

    user = models.ForeignKey(
        'authentication.User',
        on_delete=models.CASCADE,
        related_name='withdrawals',
    )
    amount = models.DecimalField(max_digits=12, decimal_places=2)
    fee = models.DecimalField(max_digits=12, decimal_places=2, default=Decimal('0'))
    bank_code = models.CharField(max_length=20)
    bank_name = models.CharField(max_length=100)
    account_number = models.CharField(max_length=20)
    account_name = models.CharField(max_length=200)
    reference = models.CharField(max_length=100, unique=True, db_index=True)
    recipient_code = models.CharField(max_length=100, blank=True)
    transfer_code = models.CharField(max_length=100, blank=True)
    status = models.CharField(max_length=10, choices=STATUS_CHOICES, default='pending')
    failure_reason = models.TextField(blank=True)
    created_at = models.DateTimeField(default=timezone.now, db_index=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'withdrawals'
        ordering = ['-created_at']

    @property
    def total_debit(self) -> Decimal:
        return self.amount + self.fee

    def __str__(self):
        return f'Withdrawal({self.user.phone_number}) ₦{self.amount} {self.status}'

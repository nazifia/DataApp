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

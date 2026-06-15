from decimal import Decimal
from django.db import models
from django.utils import timezone
from core.models import TenantAwareModel, UUIDModel


class ReferralReward(TenantAwareModel, UUIDModel):
    STATUS_CHOICES = [
        ('pending', 'Pending'),
        ('paid', 'Paid'),
    ]

    referrer = models.ForeignKey(
        'authentication.User',
        on_delete=models.CASCADE,
        related_name='referral_rewards',
    )
    referee = models.OneToOneField(
        'authentication.User',
        on_delete=models.CASCADE,
        related_name='referral_reward_as_referee',
    )
    amount = models.DecimalField(max_digits=12, decimal_places=2, default=Decimal('0'))
    status = models.CharField(max_length=10, choices=STATUS_CHOICES, default='pending')
    transaction = models.ForeignKey(
        'transactions.Transaction',
        on_delete=models.SET_NULL,
        null=True, blank=True,
        related_name='+',
        help_text="Referee's first successful purchase that triggered the reward",
    )
    created_at = models.DateTimeField(default=timezone.now)

    class Meta:
        db_table = 'referral_rewards'
        ordering = ['-created_at']

    def __str__(self):
        return f'{self.referrer.phone_number} ← {self.referee.phone_number} ₦{self.amount}'

from django.db import models
from django.utils import timezone
from core.models import TenantAwareModel, UUIDModel

NETWORK_CHOICES = [
    ('mtn', 'MTN'),
    ('airtel', 'Airtel'),
    ('glo', 'Glo'),
    ('etisalat', '9mobile'),
]

TYPE_CHOICES = [
    ('airtime', 'Airtime'),
    ('data', 'Data'),
]


class Beneficiary(TenantAwareModel, UUIDModel):
    user = models.ForeignKey(
        'authentication.User',
        on_delete=models.CASCADE,
        related_name='beneficiaries',
    )
    nickname = models.CharField(max_length=100, blank=True)
    phone_number = models.CharField(max_length=20)
    network = models.CharField(max_length=20, choices=NETWORK_CHOICES)
    type = models.CharField(max_length=10, choices=TYPE_CHOICES, default='airtime')
    created_at = models.DateTimeField(default=timezone.now)

    class Meta:
        db_table = 'beneficiaries'
        unique_together = [('user', 'phone_number', 'network', 'type')]
        ordering = ['nickname', 'phone_number']

    def __str__(self):
        label = self.nickname or self.phone_number
        return f'{label} ({self.network})'

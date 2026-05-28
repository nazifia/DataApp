from rest_framework import serializers
from .models import Transaction


class TransactionSerializer(serializers.ModelSerializer):
    is_reversed = serializers.BooleanField(read_only=True)

    class Meta:
        model = Transaction
        fields = [
            'id', 'type', 'amount', 'status', 'reference',
            'network', 'phone_number', 'plan_id', 'created_at', 'is_reversed',
        ]

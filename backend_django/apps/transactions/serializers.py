from rest_framework import serializers
from .models import Transaction


class TransactionSerializer(serializers.ModelSerializer):
    is_reversed = serializers.BooleanField(read_only=True)
    description = serializers.SerializerMethodField()

    class Meta:
        model = Transaction
        fields = [
            'id', 'type', 'amount', 'status', 'reference',
            'network', 'phone_number', 'plan_id', 'created_at', 'is_reversed',
            'customer_id', 'provider', 'variation_code', 'description',
        ]

    def get_description(self, obj) -> str:
        network = (obj.network or '').upper()
        phone = obj.phone_number or ''
        if obj.type == 'airtime':
            parts = [p for p in [network, phone] if p]
            target = ' '.join(parts)
            return f'Airtime to {target}'.strip() if target else 'Airtime purchase'
        if obj.type == 'data':
            parts = [p for p in [network, phone] if p]
            target = ' '.join(parts)
            return f'Data to {target}'.strip() if target else 'Data purchase'
        if obj.type == 'electricity':
            meter = obj.customer_id or ''
            prov = obj.provider or ''
            label = ' '.join([p for p in [prov, meter] if p])
            return f'Electricity {label}'.strip() if label else 'Electricity payment'
        if obj.type == 'tv':
            sc = obj.customer_id or ''
            prov = obj.provider or ''
            label = ' '.join([p for p in [prov, sc] if p])
            return f'Cable TV {label}'.strip() if label else 'Cable TV payment'
        if obj.type == 'wallet_fund':
            return 'Wallet funding'
        if obj.type == 'withdrawal':
            return 'Wallet withdrawal'
        if obj.type == 'refund':
            return 'Refund'
        if obj.type == 'commission':
            return 'Agent commission'
        return obj.get_type_display()

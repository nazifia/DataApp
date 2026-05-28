from rest_framework import serializers
from .models import Tenant


class TenantSerializer(serializers.ModelSerializer):
    class Meta:
        model = Tenant
        fields = [
            'id', 'name', 'slug', 'owner_email', 'owner_phone', 'is_active',
            'logo_url', 'primary_color', 'support_email', 'support_phone',
            'airtime_markup_percent', 'data_markup_percent',
            'min_wallet_fund', 'max_daily_transaction',
            'created_at', 'updated_at',
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']


class TenantPublicSerializer(serializers.ModelSerializer):
    """Safe subset returned to app clients."""
    class Meta:
        model = Tenant
        fields = [
            'id', 'name', 'slug', 'logo_url', 'primary_color',
            'support_email', 'support_phone',
            'airtime_markup_percent', 'data_markup_percent',
            'min_wallet_fund',
        ]


class TenantCreateSerializer(serializers.ModelSerializer):
    class Meta:
        model = Tenant
        fields = [
            'name', 'slug', 'owner_email', 'owner_phone',
            'logo_url', 'primary_color', 'support_email', 'support_phone',
            'airtime_markup_percent', 'data_markup_percent',
            'min_wallet_fund', 'max_daily_transaction',
        ]

    def validate_slug(self, value):
        if Tenant.all_objects.filter(slug=value).exists():
            raise serializers.ValidationError('A tenant with this slug already exists.')
        return value

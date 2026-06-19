from decimal import Decimal
from django.db import transaction
from django.utils.text import slugify
from rest_framework import serializers
from core.validators import NigerianPhoneField
from .models import Tenant


class TenantSerializer(serializers.ModelSerializer):
    class Meta:
        model = Tenant
        fields = [
            'id', 'name', 'slug', 'owner_email', 'owner_phone', 'is_active',
            'logo_url', 'primary_color', 'support_email', 'support_phone',
            'airtime_markup_percent', 'data_markup_percent', 'bill_markup_percent',
            'referral_bonus', 'min_wallet_fund', 'min_withdrawal', 'withdrawal_fee',
            'max_daily_transaction',
            'created_at', 'updated_at',
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']


class BusinessSettingsSerializer(serializers.ModelSerializer):
    """Self-service settings the business owner edits for their own tenant.

    Excludes identity/super-admin fields (slug, owner_email/phone, is_active) —
    those are not changeable by the owner from the app.
    """
    class Meta:
        model = Tenant
        fields = [
            # Branding
            'name', 'logo_url', 'primary_color', 'support_email', 'support_phone',
            # Markups / pricing
            'airtime_markup_percent', 'data_markup_percent', 'bill_markup_percent',
            'referral_bonus',
            # Wallet / limits
            'min_wallet_fund', 'min_withdrawal', 'withdrawal_fee', 'max_daily_transaction',
        ]
        extra_kwargs = {
            'airtime_markup_percent': {'min_value': Decimal('0'), 'max_value': Decimal('100')},
            'data_markup_percent': {'min_value': Decimal('0'), 'max_value': Decimal('100')},
            'bill_markup_percent': {'min_value': Decimal('0'), 'max_value': Decimal('100')},
            'referral_bonus': {'min_value': Decimal('0')},
            'min_wallet_fund': {'min_value': Decimal('0')},
            'min_withdrawal': {'min_value': Decimal('0')},
            'withdrawal_fee': {'min_value': Decimal('0')},
            'max_daily_transaction': {'min_value': Decimal('0')},
        }

    def validate_name(self, value):
        value = value.strip()
        if len(value) < 2:
            raise serializers.ValidationError('Business name must be at least 2 characters.')
        return value


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
    owner_phone = NigerianPhoneField()
    # Optional. When given, the owner admin account is provisioned with this
    # password; when omitted a random one is generated and returned once.
    owner_password = serializers.CharField(write_only=True, min_length=6, required=False)

    class Meta:
        model = Tenant
        fields = [
            'name', 'slug', 'owner_email', 'owner_phone', 'owner_password',
            'logo_url', 'primary_color', 'support_email', 'support_phone',
            'airtime_markup_percent', 'data_markup_percent',
            'min_wallet_fund', 'max_daily_transaction',
        ]

    def validate_slug(self, value):
        if Tenant.all_objects.filter(slug=value).exists():
            raise serializers.ValidationError('A tenant with this slug already exists.')
        return value

    def create(self, validated_data):
        from .services import provision_tenant_owner

        owner_password = validated_data.pop('owner_password', None)
        with transaction.atomic():
            tenant = Tenant.objects.create(**validated_data)
            _, raw_password = provision_tenant_owner(tenant, password=owner_password)
        # Stash the (possibly generated) password so the view can return it once.
        tenant._owner_password = raw_password
        return tenant


class TenantRegisterSerializer(serializers.ModelSerializer):
    """Public self-service signup. Accepts only a safe subset; business config
    (markup, limits) stays at model defaults and is tuned later by the owner.
    Slug is optional — derived from the name when omitted and made unique."""
    slug = serializers.SlugField(required=False, allow_blank=True)
    owner_phone = NigerianPhoneField()
    # Owner's login password. Provisions the owner admin account at signup so
    # they can sign in immediately (no separate OTP onboarding needed).
    owner_password = serializers.CharField(write_only=True, min_length=6)

    class Meta:
        model = Tenant
        fields = [
            'name', 'slug', 'owner_email', 'owner_phone', 'owner_password',
            'logo_url', 'primary_color', 'support_email', 'support_phone',
        ]

    def validate_name(self, value):
        value = value.strip()
        if len(value) < 2:
            raise serializers.ValidationError('Business name must be at least 2 characters.')
        return value

    def validate_slug(self, value):
        if value and Tenant.all_objects.filter(slug=value).exists():
            raise serializers.ValidationError('This workspace slug is already taken.')
        return value

    @staticmethod
    def _unique_slug(base):
        base = slugify(base) or 'tenant'
        slug, n = base, 1
        while Tenant.all_objects.filter(slug=slug).exists():
            n += 1
            slug = f'{base}-{n}'
        return slug

    def create(self, validated_data):
        from .services import provision_tenant_owner

        owner_password = validated_data.pop('owner_password')
        slug = validated_data.get('slug') or validated_data['name']
        validated_data['slug'] = self._unique_slug(slug)
        validated_data['is_active'] = True

        with transaction.atomic():
            tenant = Tenant.objects.create(**validated_data)
            # Provision the owner admin account + wallet so password login
            # works at once.
            provision_tenant_owner(tenant, password=owner_password)
        return tenant

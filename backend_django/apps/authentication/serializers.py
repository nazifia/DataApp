from rest_framework import serializers
from core.validators import NigerianPhoneField
from .models import User


class SendOTPSerializer(serializers.Serializer):
    phone_number = NigerianPhoneField()


class VerifyOTPSerializer(serializers.Serializer):
    phone_number = NigerianPhoneField()
    otp = serializers.CharField(min_length=6, max_length=6)


class LoginSerializer(serializers.Serializer):
    phone_number = NigerianPhoneField()
    password = serializers.CharField(write_only=True)


class CreateProfileSerializer(serializers.Serializer):
    phone_number = NigerianPhoneField()
    full_name = serializers.CharField(min_length=2)
    password = serializers.CharField(min_length=6, write_only=True)
    email = serializers.EmailField(required=False, allow_blank=True)
    device_id = serializers.CharField(required=False, allow_blank=True)
    referral_code = serializers.CharField(required=False, allow_blank=True, default='')


class UpdateProfileSerializer(serializers.Serializer):
    full_name = serializers.CharField(min_length=2, required=False)
    email = serializers.EmailField(required=False, allow_blank=True)


class ChangePasswordSerializer(serializers.Serializer):
    current_password = serializers.CharField(write_only=True)
    new_password = serializers.CharField(min_length=6, write_only=True)


class SetUssdPinSerializer(serializers.Serializer):
    pin = serializers.RegexField(r'^\d{4}$', write_only=True, error_messages={
        'invalid': 'PIN must be exactly 4 digits.',
    })


class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = [
            'id', 'phone_number', 'full_name', 'email', 'device_id',
            'profile_picture_url', 'role', 'referral_code', 'is_active',
            'created_at', 'updated_at',
        ]
        read_only_fields = fields

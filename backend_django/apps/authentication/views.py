import os
import uuid
from asgiref.sync import async_to_sync
from django.conf import settings
from rest_framework import status
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import AllowAny
from rest_framework.throttling import AnonRateThrottle
from rest_framework_simplejwt.tokens import RefreshToken
from .models import User
from .serializers import (
    SendOTPSerializer, VerifyOTPSerializer, LoginSerializer,
)
from .otp_service import save_otp, verify_otp, send_otp_sms


class OTPThrottle(AnonRateThrottle):
    scope = 'otp'


class LoginThrottle(AnonRateThrottle):
    scope = 'login'


def _tokens_for_user(user):
    refresh = RefreshToken.for_user(user)
    refresh['tenant_id'] = str(user.tenant_id)
    refresh['role'] = user.role
    return {
        'access_token': str(refresh.access_token),
        'refresh_token': str(refresh),
    }


class SendOTPView(APIView):
    permission_classes = [AllowAny]
    throttle_classes = [OTPThrottle]

    def post(self, request):
        if not request.tenant:
            return Response({'detail': 'Tenant context required.'}, status=400)
        serializer = SendOTPSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        phone = serializer.validated_data['phone_number']
        otp = save_otp(request.tenant, phone)
        async_to_sync(send_otp_sms)(phone, otp)
        return Response({'message': 'OTP sent.', 'phone_number': phone})


class VerifyOTPView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        if not request.tenant:
            return Response({'detail': 'Tenant context required.'}, status=400)
        serializer = VerifyOTPSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        phone = serializer.validated_data['phone_number']
        otp = serializer.validated_data['otp']

        if not verify_otp(request.tenant, phone, otp):
            return Response({'detail': 'Invalid or expired OTP.'}, status=400)

        user, created = User.objects.get_or_create(
            tenant=request.tenant,
            phone_number=phone,
            defaults={'is_active': True},
        )
        # A user who never finished profile setup has no usable password.
        # Treat them as new so the client routes back to profile setup
        # instead of dropping them at the dashboard with an unusable account.
        is_new_user = created or not user.password or not user.has_usable_password()
        tokens = _tokens_for_user(user)
        return Response({
            'message': 'OTP verified.',
            **tokens,
            'is_new_user': is_new_user,
        })


class LoginView(APIView):
    permission_classes = [AllowAny]
    throttle_classes = [LoginThrottle]

    def post(self, request):
        if not request.tenant:
            return Response({'detail': 'Tenant context required.'}, status=400)
        serializer = LoginSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        phone = serializer.validated_data['phone_number']
        password = serializer.validated_data['password']

        try:
            user = User.objects.get(tenant=request.tenant, phone_number=phone)
        except User.DoesNotExist:
            return Response({'detail': 'Invalid credentials.'}, status=401)

        if not user.check_password(password):
            return Response({'detail': 'Invalid credentials.'}, status=401)
        if not user.is_active:
            return Response({'detail': 'Account is deactivated.'}, status=403)

        tokens = _tokens_for_user(user)
        return Response({'message': 'Login successful.', **tokens})

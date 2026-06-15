import os
import uuid
from django.conf import settings
from rest_framework import status
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.parsers import MultiPartParser
from apps.wallet.models import Wallet
from .serializers import (
    CreateProfileSerializer, UpdateProfileSerializer,
    ChangePasswordSerializer, UserSerializer, SetUssdPinSerializer,
)
from .models import User


class RegisterFCMTokenView(APIView):
    def post(self, request):
        token = (request.data.get('fcm_token') or '').strip()
        if not token:
            return Response({'detail': 'fcm_token is required.'}, status=400)
        request.user.fcm_token = token
        request.user.save(update_fields=['fcm_token'])
        return Response({'message': 'FCM token registered.'})


class CreateProfileView(APIView):
    def post(self, request):
        serializer = CreateProfileSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        d = serializer.validated_data

        # Profile setup may only target the authenticated user's own account.
        # The phone_number in the body is informational — never trust it to pick
        # the user, or any logged-in user could overwrite another's password.
        if d['phone_number'] != request.user.phone_number:
            return Response({'detail': 'You can only set up your own profile.'}, status=403)
        user = request.user

        user.full_name = d['full_name']
        user.email = d.get('email', '')
        user.device_id = d.get('device_id', '')
        user.set_password(d['password'])

        # Apply referral code (once, can't refer self)
        code = (d.get('referral_code') or '').strip().upper()
        if code and not user.referred_by_id:
            referrer = User.objects.filter(
                tenant=request.tenant, referral_code=code,
            ).exclude(pk=user.pk).first()
            if referrer:
                user.referred_by = referrer

        user.save()

        Wallet.objects.get_or_create(tenant=request.tenant, user=user, defaults={'balance': 0})
        return Response({'message': 'Profile created.', 'user': UserSerializer(user).data})


class ProfileView(APIView):
    def get(self, request):
        return Response({'user': UserSerializer(request.user).data})

    def put(self, request):
        serializer = UpdateProfileSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        d = serializer.validated_data
        if 'full_name' in d:
            request.user.full_name = d['full_name']
        if 'email' in d:
            request.user.email = d['email']
        request.user.save()
        return Response({'message': 'Profile updated.', 'user': UserSerializer(request.user).data})


class ChangePasswordView(APIView):
    def put(self, request):
        serializer = ChangePasswordSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        d = serializer.validated_data
        if not request.user.check_password(d['current_password']):
            return Response({'detail': 'Current password is incorrect.'}, status=400)
        request.user.set_password(d['new_password'])
        request.user.save()
        return Response({'message': 'Password changed.'})


class SetUssdPinView(APIView):
    def put(self, request):
        serializer = SetUssdPinSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        request.user.set_ussd_pin(serializer.validated_data['pin'])
        request.user.save(update_fields=['ussd_pin'])
        return Response({'message': 'USSD PIN set.'})


class ProfilePictureView(APIView):
    parser_classes = [MultiPartParser]

    def put(self, request):
        file = request.FILES.get('picture')
        if not file:
            return Response({'detail': 'No file provided.'}, status=400)
        ext = os.path.splitext(file.name)[1].lower()
        if ext not in ('.jpg', '.jpeg', '.png', '.webp'):
            return Response({'detail': 'Only JPG, PNG, WebP allowed.'}, status=400)
        if file.size > 5 * 1024 * 1024:
            return Response({'detail': 'File too large (max 5 MB).'}, status=400)

        upload_dir = settings.MEDIA_ROOT / 'profile_pictures'
        upload_dir.mkdir(parents=True, exist_ok=True)

        if request.user.profile_picture_url:
            old_rel = request.user.profile_picture_url.removeprefix(settings.MEDIA_URL)
            old_path = (settings.MEDIA_ROOT / old_rel).resolve()
            if old_path.is_relative_to(settings.MEDIA_ROOT) and old_path.exists():
                old_path.unlink()

        filename = f'{request.user.id}_{uuid.uuid4().hex}{ext}'
        path = upload_dir / filename
        with open(path, 'wb') as f:
            for chunk in file.chunks():
                f.write(chunk)

        request.user.profile_picture_url = f'{settings.MEDIA_URL}profile_pictures/{filename}'
        request.user.save()
        return Response({'profile_picture_url': request.user.profile_picture_url})

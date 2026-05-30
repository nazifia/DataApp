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
    ChangePasswordSerializer, UserSerializer,
)
from .models import User


class CreateProfileView(APIView):
    def post(self, request):
        serializer = CreateProfileSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        d = serializer.validated_data

        try:
            user = User.objects.get(tenant=request.tenant, phone_number=d['phone_number'])
        except User.DoesNotExist:
            return Response({'detail': 'User not found. Verify OTP first.'}, status=404)

        user.full_name = d['full_name']
        user.email = d.get('email', '')
        user.device_id = d.get('device_id', '')
        user.set_password(d['password'])
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

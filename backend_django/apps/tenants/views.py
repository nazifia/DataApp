from rest_framework import status, serializers as drf_serializers
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import AllowAny
from rest_framework.throttling import ScopedRateThrottle
from core.permissions import IsSuperAdmin, IsTenantOwnerOrSuperAdmin, IsAdminOrAbove
from .models import Tenant
from .serializers import (
    TenantSerializer, TenantPublicSerializer, TenantCreateSerializer,
    TenantRegisterSerializer,
)


class MarkupSerializer(drf_serializers.Serializer):
    airtime_markup_percent = drf_serializers.DecimalField(
        max_digits=5, decimal_places=2, min_value=0, max_value=100, required=False,
    )
    data_markup_percent = drf_serializers.DecimalField(
        max_digits=5, decimal_places=2, min_value=0, max_value=100, required=False,
    )


class TenantInfoView(APIView):
    """GET /api/v1/tenants/info — public, returns current tenant config."""
    permission_classes = [AllowAny]

    def get(self, request):
        if not request.tenant:
            return Response({'detail': 'No tenant context.'}, status=400)
        return Response(TenantPublicSerializer(request.tenant).data)


class TenantRegisterView(APIView):
    """POST /api/v1/tenants/register — public self-service tenant signup.

    No auth, no X-Tenant-Slug header required. Heavily throttled to curb abuse.
    Creates an active tenant; returns its public config so the client can
    immediately set X-Tenant-Slug and onboard the owner.
    """
    permission_classes = [AllowAny]
    throttle_classes = [ScopedRateThrottle]
    throttle_scope = 'tenant_register'

    def post(self, request):
        serializer = TenantRegisterSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        tenant = serializer.save()
        return Response(TenantPublicSerializer(tenant).data, status=status.HTTP_201_CREATED)


class TenantListCreateView(APIView):
    """Super-admin: list and create tenants."""
    permission_classes = [IsSuperAdmin]

    def get(self, request):
        tenants = Tenant.all_objects.all().order_by('-created_at')
        return Response(TenantSerializer(tenants, many=True).data)

    def post(self, request):
        serializer = TenantCreateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        tenant = serializer.save()
        return Response(TenantSerializer(tenant).data, status=status.HTTP_201_CREATED)


class TenantDetailView(APIView):
    """Super-admin or tenant admin: retrieve/update a tenant."""
    permission_classes = [IsTenantOwnerOrSuperAdmin]

    def get_object(self, pk):
        try:
            return Tenant.all_objects.get(pk=pk)
        except Tenant.DoesNotExist:
            return None

    def get(self, request, pk):
        tenant = self.get_object(pk)
        if not tenant:
            return Response({'detail': 'Not found.'}, status=404)
        return Response(TenantSerializer(tenant).data)

    def patch(self, request, pk):
        tenant = self.get_object(pk)
        if not tenant:
            return Response({'detail': 'Not found.'}, status=404)
        serializer = TenantSerializer(tenant, data=request.data, partial=True)
        serializer.is_valid(raise_exception=True)
        serializer.save()
        return Response(serializer.data)

    def delete(self, request, pk):
        if request.user.role != 'super_admin':
            return Response({'detail': 'Forbidden.'}, status=403)
        tenant = self.get_object(pk)
        if not tenant:
            return Response({'detail': 'Not found.'}, status=404)
        tenant.is_active = False
        tenant.save()
        return Response(status=status.HTTP_204_NO_CONTENT)


class MarkupUpdateView(APIView):
    """PATCH /api/v1/tenants/markup/ — tenant admin updates their own markup rates."""
    permission_classes = [IsAdminOrAbove]

    def patch(self, request):
        if not request.tenant:
            return Response({'detail': 'Tenant context required.'}, status=400)
        ser = MarkupSerializer(data=request.data)
        ser.is_valid(raise_exception=True)
        if not ser.validated_data:
            return Response({'detail': 'Provide airtime_markup_percent or data_markup_percent.'}, status=400)
        for field, value in ser.validated_data.items():
            setattr(request.tenant, field, value)
        request.tenant.save(update_fields=list(ser.validated_data.keys()))
        return Response({
            'airtime_markup_percent': request.tenant.airtime_markup_percent,
            'data_markup_percent': request.tenant.data_markup_percent,
        })

from rest_framework import status
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import AllowAny
from core.permissions import IsSuperAdmin, IsTenantOwnerOrSuperAdmin
from .models import Tenant
from .serializers import TenantSerializer, TenantPublicSerializer, TenantCreateSerializer


class TenantInfoView(APIView):
    """GET /api/v1/tenants/info — public, returns current tenant config."""
    permission_classes = [AllowAny]

    def get(self, request):
        if not request.tenant:
            return Response({'detail': 'No tenant context.'}, status=400)
        return Response(TenantPublicSerializer(request.tenant).data)


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

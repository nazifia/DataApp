from django.utils import timezone
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import serializers
from core.pagination import StandardPagination
from core.permissions import IsModeratorOrAbove
from .models import Dispute


class DisputeSerializer(serializers.ModelSerializer):
    class Meta:
        model = Dispute
        fields = [
            'id', 'transaction_reference', 'subject', 'message',
            'status', 'admin_notes', 'created_at', 'resolved_at',
        ]


class DisputeCreateSerializer(serializers.Serializer):
    transaction_reference = serializers.CharField(max_length=100, allow_blank=True, default='')
    subject = serializers.CharField(max_length=200, min_length=5)
    message = serializers.CharField(min_length=10)


# ─── User endpoints ───────────────────────────────────────────────────────────

class UserDisputeListCreateView(APIView):
    def get(self, request):
        qs = Dispute.objects.filter(tenant=request.tenant, user=request.user)
        paginator = StandardPagination()
        page = paginator.paginate_queryset(qs, request)
        return paginator.get_paginated_response(DisputeSerializer(page, many=True).data)

    def post(self, request):
        ser = DisputeCreateSerializer(data=request.data)
        ser.is_valid(raise_exception=True)
        d = ser.validated_data
        dispute = Dispute.objects.create(
            tenant=request.tenant,
            user=request.user,
            transaction_reference=d['transaction_reference'],
            subject=d['subject'],
            message=d['message'],
        )
        return Response(DisputeSerializer(dispute).data, status=201)


# ─── Admin endpoints ──────────────────────────────────────────────────────────

class AdminDisputeListView(APIView):
    permission_classes = [IsModeratorOrAbove]

    def get(self, request):
        qs = Dispute.objects.filter(tenant=request.tenant).select_related('user')
        if status := request.query_params.get('status'):
            qs = qs.filter(status=status)
        if user_id := request.query_params.get('user_id'):
            qs = qs.filter(user_id=user_id)
        paginator = StandardPagination()
        page = paginator.paginate_queryset(qs, request)
        data = []
        for d in page:
            item = DisputeSerializer(d).data
            item['user_phone'] = d.user.phone_number
            item['user_name'] = d.user.full_name
            data.append(item)
        return paginator.get_paginated_response(data)


class AdminDisputeDetailView(APIView):
    permission_classes = [IsModeratorOrAbove]

    def _get(self, request, pk):
        try:
            return Dispute.objects.get(tenant=request.tenant, pk=pk)
        except Dispute.DoesNotExist:
            return None

    def get(self, request, pk):
        dispute = self._get(request, pk)
        if not dispute:
            return Response({'detail': 'Not found.'}, status=404)
        data = DisputeSerializer(dispute).data
        data['user_phone'] = dispute.user.phone_number
        data['user_name'] = dispute.user.full_name
        return Response(data)

    def put(self, request, pk):
        dispute = self._get(request, pk)
        if not dispute:
            return Response({'detail': 'Not found.'}, status=404)

        new_status = request.data.get('status')
        if new_status and new_status not in dict(Dispute.STATUS_CHOICES):
            return Response({'detail': 'Invalid status.'}, status=400)

        if new_status:
            dispute.status = new_status
            if new_status in ('resolved', 'closed') and not dispute.resolved_at:
                dispute.resolved_at = timezone.now()
        if 'admin_notes' in request.data:
            dispute.admin_notes = request.data['admin_notes']
        dispute.save()
        return Response(DisputeSerializer(dispute).data)

from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import serializers
from .models import Notification


class NotificationSerializer(serializers.ModelSerializer):
    class Meta:
        model = Notification
        fields = ['id', 'title', 'body', 'type', 'data', 'is_read', 'created_at']


class NotificationListView(APIView):
    """GET list (newest first). ?unread=true filters to unread only."""

    def get(self, request):
        qs = Notification.objects.filter(user=request.user)
        if request.query_params.get('unread') in ('1', 'true', 'True'):
            qs = qs.filter(is_read=False)
        type_filter = request.query_params.get('type')
        if type_filter:
            qs = qs.filter(type=type_filter)
        qs = qs[:200]
        return Response({
            'unread_count': Notification.objects.filter(user=request.user, is_read=False).count(),
            'results': NotificationSerializer(qs, many=True).data,
        })


class UnreadCountView(APIView):
    def get(self, request):
        count = Notification.objects.filter(user=request.user, is_read=False).count()
        return Response({'unread_count': count})


class MarkAllReadView(APIView):
    def post(self, request):
        updated = Notification.objects.filter(
            user=request.user, is_read=False,
        ).update(is_read=True)
        return Response({'marked': updated})


class NotificationDetailView(APIView):
    def patch(self, request, pk):
        """Mark a single notification read/unread."""
        try:
            obj = Notification.objects.get(user=request.user, pk=pk)
        except Notification.DoesNotExist:
            return Response({'detail': 'Not found.'}, status=404)
        is_read = request.data.get('is_read', True)
        obj.is_read = bool(is_read)
        obj.save(update_fields=['is_read'])
        return Response(NotificationSerializer(obj).data)

    def delete(self, request, pk):
        try:
            obj = Notification.objects.get(user=request.user, pk=pk)
        except Notification.DoesNotExist:
            return Response({'detail': 'Not found.'}, status=404)
        obj.delete()
        return Response(status=204)

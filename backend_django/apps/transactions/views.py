from rest_framework.views import APIView
from rest_framework.response import Response
from core.pagination import StandardPagination
from .models import Transaction
from .serializers import TransactionSerializer


class TransactionListView(APIView):
    def get(self, request):
        qs = Transaction.objects.filter(user=request.user)
        paginator = StandardPagination()
        page = paginator.paginate_queryset(qs, request)
        serializer = TransactionSerializer(page, many=True)
        return paginator.get_paginated_response(serializer.data)

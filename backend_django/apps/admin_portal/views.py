from decimal import Decimal
from django.db import transaction as db_transaction
from django.db.models import Sum, Count, Q
from django.utils import timezone
from datetime import timedelta
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import serializers, status
from core.permissions import IsModeratorOrAbove, IsAdminOrAbove, IsSuperAdmin
from core.pagination import StandardPagination
from apps.authentication.models import User
from apps.authentication.serializers import UserSerializer
from apps.wallet.models import Wallet
from apps.transactions.models import Transaction
from apps.transactions.serializers import TransactionSerializer
from .models import AdminAuditLog
from .audit import log_action


# ─── Dashboard ──────────────────────────────────────────────────────────────

class DashboardStatsView(APIView):
    permission_classes = [IsModeratorOrAbove]

    def get(self, request):
        today = timezone.now().date()
        users = User.objects.filter(tenant=request.tenant)
        txns = Transaction.objects.filter(tenant=request.tenant)
        success_txns = txns.filter(status='success')
        today_txns = txns.filter(created_at__date=today)

        return Response({
            'total_users': users.count(),
            'active_users': users.filter(is_active=True).count(),
            'total_transactions': txns.count(),
            'successful_transactions': success_txns.count(),
            'total_revenue': float(success_txns.filter(type__in=['airtime', 'data']).aggregate(s=Sum('amount'))['s'] or 0),
            'total_wallet_balance': float(Wallet.objects.filter(tenant=request.tenant).aggregate(s=Sum('balance'))['s'] or 0),
            'today_transactions': today_txns.count(),
            'today_revenue': float(today_txns.filter(status='success', type__in=['airtime', 'data']).aggregate(s=Sum('amount'))['s'] or 0),
        })


class RecentTransactionsView(APIView):
    permission_classes = [IsModeratorOrAbove]

    def get(self, request):
        txns = Transaction.objects.filter(tenant=request.tenant).select_related('user')[:20]
        return Response(TransactionSerializer(txns, many=True).data)


class RecentUsersView(APIView):
    permission_classes = [IsModeratorOrAbove]

    def get(self, request):
        users = User.objects.filter(tenant=request.tenant).order_by('-created_at')[:10]
        return Response(UserSerializer(users, many=True).data)


# ─── Users ───────────────────────────────────────────────────────────────────

class AdminUserListView(APIView):
    permission_classes = [IsModeratorOrAbove]

    def get(self, request):
        qs = User.objects.filter(tenant=request.tenant)
        search = request.query_params.get('search')
        if search:
            qs = qs.filter(Q(phone_number__icontains=search) | Q(full_name__icontains=search))
        is_active = request.query_params.get('is_active')
        if is_active is not None:
            qs = qs.filter(is_active=is_active.lower() == 'true')
        paginator = StandardPagination()
        page = paginator.paginate_queryset(qs.order_by('-created_at'), request)
        return paginator.get_paginated_response(UserSerializer(page, many=True).data)

    def post(self, request):
        if not IsAdminOrAbove().has_permission(request, self):
            return Response({'detail': 'Forbidden.'}, status=403)
        ser = AdminCreateUserSerializer(data=request.data)
        ser.is_valid(raise_exception=True)
        d = ser.validated_data
        user = User.objects.create_user(
            phone_number=d['phone_number'],
            tenant=request.tenant,
            password=d['password'],
            full_name=d.get('full_name', ''),
            role=d.get('role', 'user'),
            is_active=d.get('is_active', True),
        )
        Wallet.objects.create(tenant=request.tenant, user=user)
        log_action(request, 'create_user', 'user', user.id, f'Created user {user.phone_number}')
        return Response(UserSerializer(user).data, status=201)


class AdminUserDetailView(APIView):
    permission_classes = [IsModeratorOrAbove]

    def _get_user(self, request, pk):
        try:
            return User.objects.get(tenant=request.tenant, pk=pk)
        except User.DoesNotExist:
            return None

    def get(self, request, pk):
        user = self._get_user(request, pk)
        if not user:
            return Response({'detail': 'Not found.'}, status=404)
        txns = Transaction.objects.filter(tenant=request.tenant, user=user)
        data = UserSerializer(user).data
        data['total_transactions'] = txns.count()
        data['total_spent'] = float(txns.filter(status='success', type__in=['airtime', 'data']).aggregate(s=Sum('amount'))['s'] or 0)
        try:
            data['wallet_balance'] = float(user.wallet.balance)
        except Wallet.DoesNotExist:
            data['wallet_balance'] = 0
        return Response(data)

    def put(self, request, pk):
        if not IsAdminOrAbove().has_permission(request, self):
            return Response({'detail': 'Forbidden.'}, status=403)
        user = self._get_user(request, pk)
        if not user:
            return Response({'detail': 'Not found.'}, status=404)
        action = request.data.get('action')
        if action == 'toggle_active':
            user.is_active = not user.is_active
            user.save()
            log_action(request, 'toggle_active', 'user', user.id, f'Set is_active={user.is_active}')
        elif action == 'set_role':
            if not IsSuperAdmin().has_permission(request, self):
                return Response({'detail': 'Only super_admin can change roles.'}, status=403)
            user.role = request.data.get('role', user.role)
            user.save()
            log_action(request, 'set_role', 'user', user.id, f'Role set to {user.role}')
        return Response(UserSerializer(user).data)


# ─── Wallet Management ────────────────────────────────────────────────────────

class AdminWalletListView(APIView):
    permission_classes = [IsModeratorOrAbove]

    def get(self, request):
        qs = Wallet.objects.filter(tenant=request.tenant).select_related('user')
        search = request.query_params.get('search')
        if search:
            qs = qs.filter(Q(user__phone_number__icontains=search) | Q(user__full_name__icontains=search))
        min_bal = request.query_params.get('min_balance')
        if min_bal:
            qs = qs.filter(balance__gte=min_bal)
        max_bal = request.query_params.get('max_balance')
        if max_bal:
            qs = qs.filter(balance__lte=max_bal)
        paginator = StandardPagination()
        page = paginator.paginate_queryset(qs, request)
        data = [
            {'id': str(w.id), 'user_id': str(w.user_id), 'user_phone': w.user.phone_number,
             'user_name': w.user.full_name, 'balance': float(w.balance), 'updated_at': w.updated_at}
            for w in page
        ]
        return paginator.get_paginated_response(data)


class AdminWalletAdjustView(APIView):
    permission_classes = [IsAdminOrAbove]

    def post(self, request, user_id, action):
        try:
            wallet = Wallet.objects.select_related('user').get(tenant=request.tenant, user_id=user_id)
        except Wallet.DoesNotExist:
            return Response({'detail': 'Wallet not found.'}, status=404)

        try:
            amount = Decimal(str(request.data['amount']))
            if amount <= 0:
                raise ValueError
        except (KeyError, ValueError, Exception):
            return Response({'detail': 'Invalid amount.'}, status=400)

        reason = request.data.get('reason', '')
        if len(reason) < 3:
            return Response({'detail': 'Reason must be at least 3 characters.'}, status=400)

        if action == 'credit':
            with db_transaction.atomic():
                wallet.balance += amount
                wallet.save()
                txn_type = 'wallet_fund'
        elif action == 'debit':
            if wallet.balance < amount:
                return Response({'detail': 'Insufficient balance.'}, status=400)
            with db_transaction.atomic():
                wallet.balance -= amount
                wallet.save()
                txn_type = 'refund'
        else:
            return Response({'detail': 'Invalid action.'}, status=400)

        Transaction.objects.create(
            tenant=request.tenant,
            user=wallet.user,
            type=txn_type,
            amount=amount,
            status='success',
            reference=f'ADM-{action.upper()}-{Transaction.generate_reference()}',
        )
        log_action(request, f'wallet_{action}', 'wallet', wallet.id, f'{action} ₦{amount}: {reason}')
        return Response({'message': f'Wallet {action}ed.', 'balance': float(wallet.balance)})


# ─── Transactions ─────────────────────────────────────────────────────────────

class AdminTransactionListView(APIView):
    permission_classes = [IsModeratorOrAbove]

    def get(self, request):
        qs = Transaction.objects.filter(tenant=request.tenant).select_related('user')
        for param, field in [('type', 'type'), ('status', 'status'), ('network', 'network')]:
            if val := request.query_params.get(param):
                qs = qs.filter(**{field: val})
        if date_from := request.query_params.get('date_from'):
            qs = qs.filter(created_at__date__gte=date_from)
        if date_to := request.query_params.get('date_to'):
            qs = qs.filter(created_at__date__lte=date_to)
        if search := request.query_params.get('search'):
            qs = qs.filter(Q(reference__icontains=search) | Q(user__phone_number__icontains=search))
        paginator = StandardPagination()
        page = paginator.paginate_queryset(qs, request)
        return paginator.get_paginated_response(TransactionSerializer(page, many=True).data)


class AdminTransactionDetailView(APIView):
    permission_classes = [IsModeratorOrAbove]

    def get(self, request, pk):
        try:
            txn = Transaction.objects.get(tenant=request.tenant, pk=pk)
        except Transaction.DoesNotExist:
            return Response({'detail': 'Not found.'}, status=404)
        return Response(TransactionSerializer(txn).data)


class AdminReverseTransactionView(APIView):
    permission_classes = [IsAdminOrAbove]

    def post(self, request, pk):
        try:
            txn = Transaction.objects.select_related('user').get(tenant=request.tenant, pk=pk)
        except Transaction.DoesNotExist:
            return Response({'detail': 'Not found.'}, status=404)

        if txn.status != 'failed' or txn.type not in ('airtime', 'data'):
            return Response({'detail': 'Only failed airtime/data transactions can be reversed.'}, status=400)
        rev_ref = f'REV-{txn.reference}'
        if Transaction.all_objects.filter(reference=rev_ref).exists():
            return Response({'detail': 'Transaction already reversed.'}, status=400)

        with db_transaction.atomic():
            wallet = txn.user.wallet
            wallet.balance += txn.amount
            wallet.save()
            Transaction.objects.create(
                tenant=request.tenant,
                user=txn.user,
                type='refund',
                amount=txn.amount,
                status='success',
                reference=rev_ref,
            )
        log_action(request, 'reverse_transaction', 'transaction', txn.id, f'Reversed {txn.reference}')
        return Response({'message': 'Transaction reversed and wallet refunded.'})


# ─── Analytics ────────────────────────────────────────────────────────────────

class AnalyticsRevenueView(APIView):
    permission_classes = [IsModeratorOrAbove]

    def get(self, request):
        days = int(request.query_params.get('days', 30))
        since = timezone.now() - timedelta(days=days)
        txns = Transaction.objects.filter(
            tenant=request.tenant, status='success',
            type__in=['airtime', 'data'], created_at__gte=since,
        )
        daily = txns.extra(select={'day': "date(created_at)"}).values('day').annotate(
            revenue=Sum('amount'), count=Count('id')
        ).order_by('day')
        return Response(list(daily))


class AnalyticsNetworkView(APIView):
    permission_classes = [IsModeratorOrAbove]

    def get(self, request):
        data = Transaction.objects.filter(
            tenant=request.tenant, status='success', type__in=['airtime', 'data']
        ).values('network').annotate(count=Count('id'), revenue=Sum('amount'))
        return Response(list(data))


class AnalyticsTopUsersView(APIView):
    permission_classes = [IsModeratorOrAbove]

    def get(self, request):
        limit = int(request.query_params.get('limit', 10))
        data = Transaction.objects.filter(
            tenant=request.tenant, status='success', type__in=['airtime', 'data']
        ).values('user__id', 'user__phone_number', 'user__full_name').annotate(
            total_spent=Sum('amount'), transaction_count=Count('id')
        ).order_by('-total_spent')[:limit]
        return Response(list(data))


class AnalyticsTypeBreakdownView(APIView):
    permission_classes = [IsModeratorOrAbove]

    def get(self, request):
        data = Transaction.objects.filter(tenant=request.tenant).values('type').annotate(count=Count('id'))
        return Response(list(data))


# ─── Audit Log ───────────────────────────────────────────────────────────────

class AuditLogListView(APIView):
    permission_classes = [IsAdminOrAbove]

    def get(self, request):
        qs = AdminAuditLog.objects.filter(tenant=request.tenant).select_related('admin')
        if action := request.query_params.get('action'):
            qs = qs.filter(action=action)
        if admin_id := request.query_params.get('admin_id'):
            qs = qs.filter(admin_id=admin_id)
        if date_from := request.query_params.get('date_from'):
            qs = qs.filter(created_at__date__gte=date_from)
        if date_to := request.query_params.get('date_to'):
            qs = qs.filter(created_at__date__lte=date_to)
        paginator = StandardPagination()
        page = paginator.paginate_queryset(qs, request)
        data = [
            {
                'id': str(l.id), 'admin_id': str(l.admin_id),
                'admin_phone': l.admin.phone_number if l.admin else '',
                'action': l.action, 'target_type': l.target_type,
                'target_id': l.target_id, 'details': l.details,
                'ip_address': l.ip_address, 'created_at': l.created_at,
            }
            for l in page
        ]
        return paginator.get_paginated_response(data)


# ─── Serializers used inline ─────────────────────────────────────────────────

class AdminCreateUserSerializer(serializers.Serializer):
    from core.validators import NigerianPhoneField as _Phone
    phone_number = _Phone()
    full_name = serializers.CharField(min_length=2, required=False, default='')
    password = serializers.CharField(min_length=6, write_only=True)
    role = serializers.ChoiceField(choices=['user', 'support', 'moderator', 'admin'], default='user')
    is_active = serializers.BooleanField(default=True)

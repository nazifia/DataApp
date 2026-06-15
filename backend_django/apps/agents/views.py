from decimal import Decimal
from django.db import transaction as db_transaction
from django.db.models import Sum, Count
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import serializers
from rest_framework.throttling import UserRateThrottle
from asgiref.sync import async_to_sync
from core.validators import NigerianPhoneField
from apps.wallet.models import Wallet
from apps.transactions.models import Transaction
from apps.transactions.fulfillment import fulfill
from apps.data_plans.services import get_data_plans
from .models import Agent

VALID_NETWORKS = ('mtn', 'airtel', 'glo', 'etisalat')


class PurchaseThrottle(UserRateThrottle):
    scope = 'purchase'


class AgentSerializer(serializers.ModelSerializer):
    class Meta:
        model = Agent
        fields = ['id', 'agent_code', 'business_name', 'status', 'commission_percent', 'created_at']
        read_only_fields = ['id', 'agent_code', 'status', 'commission_percent', 'created_at']


# ─── Apply to become an agent ────────────────────────────────────────────────

class AgentApplyView(APIView):
    def post(self, request):
        if hasattr(request.user, 'agent'):
            return Response(AgentSerializer(request.user.agent).data, status=200)
        business_name = (request.data.get('business_name') or '').strip()
        if len(business_name) < 2:
            return Response({'detail': 'business_name is required.'}, status=400)

        code = Agent.generate_code()
        while Agent.all_objects.filter(agent_code=code).exists():
            code = Agent.generate_code()

        agent = Agent.objects.create(
            tenant=request.tenant, user=request.user,
            agent_code=code, business_name=business_name, status='pending',
        )
        return Response(AgentSerializer(agent).data, status=201)


# ─── Dashboard ───────────────────────────────────────────────────────────────

class AgentDashboardView(APIView):
    def get(self, request):
        agent = getattr(request.user, 'agent', None)
        if agent is None:
            return Response({'detail': 'Not an agent.'}, status=403)

        sales = Transaction.all_objects.filter(agent=agent, status='success').exclude(type='commission')
        volume = sales.aggregate(total=Sum('amount'), count=Count('id'))
        commission = (
            Transaction.all_objects
            .filter(agent=agent, type='commission', status='success')
            .aggregate(total=Sum('amount'))['total'] or Decimal('0')
        )
        wallet = Wallet.all_objects.filter(user=agent.user).first()
        return Response({
            'agent': AgentSerializer(agent).data,
            'total_sales_volume': float(volume['total'] or 0),
            'total_sales_count': volume['count'] or 0,
            'total_commission': float(commission),
            'float_balance': float(wallet.balance) if wallet else 0.0,
        })


# ─── Agent sale on behalf of a customer ──────────────────────────────────────

class AgentSaleSerializer(serializers.Serializer):
    type = serializers.ChoiceField(choices=('airtime', 'data', 'electricity', 'tv'))
    phone_number = NigerianPhoneField()
    # airtime / data
    network = serializers.ChoiceField(choices=VALID_NETWORKS, required=False)
    plan_id = serializers.CharField(required=False)
    # airtime / bills
    amount = serializers.DecimalField(
        max_digits=10, decimal_places=2, required=False,
        min_value=Decimal('50'), max_value=Decimal('500000'),
    )
    # bills (electricity / tv)
    service_id = serializers.CharField(required=False)
    customer_id = serializers.CharField(required=False)
    variation_code = serializers.CharField(required=False, allow_blank=True, default='')

    def validate(self, attrs):
        t = attrs['type']
        if t in ('airtime', 'data') and not attrs.get('network'):
            raise serializers.ValidationError({'network': 'Required for airtime/data sales.'})
        if t == 'airtime' and attrs.get('amount') is None:
            raise serializers.ValidationError({'amount': 'Required for airtime sales.'})
        if t == 'data' and not attrs.get('plan_id'):
            raise serializers.ValidationError({'plan_id': 'Required for data sales.'})
        if t in ('electricity', 'tv'):
            if not attrs.get('service_id'):
                raise serializers.ValidationError({'service_id': 'Required for bill sales.'})
            if not attrs.get('customer_id'):
                raise serializers.ValidationError({'customer_id': 'Required for bill sales.'})
            if attrs.get('amount') is None:
                raise serializers.ValidationError({'amount': 'Required for bill sales.'})
        return attrs


class AgentSaleView(APIView):
    throttle_classes = [PurchaseThrottle]

    def post(self, request):
        agent = getattr(request.user, 'agent', None)
        if agent is None:
            return Response({'detail': 'Not an agent.'}, status=403)
        if agent.status != 'active':
            return Response({'detail': 'Agent account is not active.'}, status=403)

        ser = AgentSaleSerializer(data=request.data)
        ser.is_valid(raise_exception=True)
        d = ser.validated_data

        # Resolve the value delivered to the provider per product type.
        network = d.get('network', '')
        plan_id = ''
        customer_id = provider = variation_code = ''
        if d['type'] == 'airtime':
            face_value = d['amount']
        elif d['type'] == 'data':
            plans = async_to_sync(get_data_plans)(network)
            plan = next((p for p in plans if p['id'] == d['plan_id']), None)
            if not plan:
                return Response({'detail': 'Plan not found.'}, status=404)
            face_value = Decimal(str(plan['price']))
            plan_id = d['plan_id']
        else:  # electricity / tv
            face_value = d['amount']
            customer_id = d['customer_id']
            provider = d['service_id']
            variation_code = d.get('variation_code', '')

        # Agent pays from their own wallet (no markup — agent earns commission instead).
        charge = Decimal(face_value).quantize(Decimal('0.01'))
        try:
            with db_transaction.atomic():
                wallet = Wallet.objects.select_for_update().get(user=agent.user)
                if wallet.balance < charge:
                    return Response({'detail': 'Insufficient agent float balance.'}, status=400)
                wallet.balance -= charge
                wallet.save()
                txn = Transaction.objects.create(
                    tenant=request.tenant, user=agent.user, agent=agent,
                    type=d['type'], amount=charge, face_value=face_value, status='pending',
                    reference=Transaction.generate_reference(),
                    network=network, phone_number=d['phone_number'], plan_id=plan_id,
                    customer_id=customer_id, provider=provider, variation_code=variation_code,
                )
        except Wallet.DoesNotExist:
            return Response({'detail': 'Agent wallet not found.'}, status=404)

        fulfill(txn)

        if txn.status == 'failed':
            return Response({'detail': f'Sale failed: {txn.last_error}'}, status=502)
        return Response({
            'message': 'Sale completed.' if txn.status == 'success' else 'Sale is being processed.',
            'reference': txn.reference,
            'status': txn.status,
            'type': d['type'],
            'amount': float(charge),
            'customer_phone': d['phone_number'],
            'token': txn.token,
        })

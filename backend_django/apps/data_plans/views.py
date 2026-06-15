from asgiref.sync import async_to_sync
from decimal import Decimal
from django.db import transaction as db_transaction
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import serializers
from rest_framework.throttling import UserRateThrottle
from core.validators import NigerianPhoneField, NetworkChoiceField, NETWORK_ALIASES
from apps.transactions.models import Transaction
from apps.transactions.fulfillment import fulfill
from apps.wallet.models import Wallet
from .services import get_data_plans

VALID_NETWORKS = ('mtn', 'airtel', 'glo', 'etisalat')


class PurchaseThrottle(UserRateThrottle):
    scope = 'purchase'


class DataPurchaseSerializer(serializers.Serializer):
    network = NetworkChoiceField()
    plan_id = serializers.CharField()
    phone_number = NigerianPhoneField()


class DataPlansView(APIView):
    def get(self, request):
        network = (request.query_params.get('network') or '').strip().lower()
        network = NETWORK_ALIASES.get(network, network)
        if network not in VALID_NETWORKS:
            return Response({'detail': f'Invalid network. Choose from {VALID_NETWORKS}.'}, status=400)
        plans = async_to_sync(get_data_plans)(network)
        if request.tenant and request.tenant.data_markup_percent:
            markup = request.tenant.data_markup_percent / 100
            plans = [
                {**p, 'price': float((Decimal(str(p['price'])) * (1 + markup)).quantize(Decimal('0.01')))}
                for p in plans
            ]
        return Response({'plans': plans})


class DataPurchaseView(APIView):
    throttle_classes = [PurchaseThrottle]

    def post(self, request):
        ser = DataPurchaseSerializer(data=request.data)
        ser.is_valid(raise_exception=True)
        d = ser.validated_data

        plans = async_to_sync(get_data_plans)(d['network'])
        plan = next((p for p in plans if p['id'] == d['plan_id']), None)
        if not plan:
            return Response({'detail': 'Plan not found.'}, status=404)

        markup = (request.tenant.data_markup_percent / 100) if request.tenant else Decimal('0')
        price = Decimal(str(plan['price']))
        charge = (price * (1 + markup)).quantize(Decimal('0.01'))

        try:
            with db_transaction.atomic():
                wallet = Wallet.objects.select_for_update().get(user=request.user)
                if wallet.balance < charge:
                    return Response({'detail': 'Insufficient wallet balance.'}, status=400)
                wallet.balance -= charge
                wallet.save()
                txn = Transaction.objects.create(
                    tenant=request.tenant,
                    user=request.user,
                    type='data',
                    amount=charge,
                    face_value=price,
                    status='pending',
                    reference=Transaction.generate_reference(),
                    network=d['network'],
                    phone_number=d['phone_number'],
                    plan_id=d['plan_id'],
                )
        except Wallet.DoesNotExist:
            return Response({'detail': 'Wallet not found.'}, status=404)

        fulfill(txn)

        if txn.status == 'failed':
            return Response({'detail': f'Purchase failed: {txn.last_error}'}, status=502)
        return Response({
            'message': 'Data purchased.' if txn.status == 'success' else 'Data purchase is being processed.',
            'reference': txn.reference,
            'status': txn.status,
            'plan_id': d['plan_id'],
            'plan_name': plan.get('name', ''),
            'amount': float(charge),
            'data': plan.get('name', ''),
            'validity': plan.get('validity', ''),
            'network': d['network'],
            'phone_number': d['phone_number'],
        })

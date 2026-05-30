from asgiref.sync import async_to_sync
from decimal import Decimal
from django.db import transaction as db_transaction
from django.db.models import F
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import serializers
from core.validators import NigerianPhoneField
from apps.transactions.models import Transaction
from apps.wallet.models import Wallet
from .services import get_data_plans, purchase_data

VALID_NETWORKS = ('mtn', 'airtel', 'glo', 'etisalat')


class DataPurchaseSerializer(serializers.Serializer):
    network = serializers.ChoiceField(choices=VALID_NETWORKS)
    plan_id = serializers.CharField()
    phone_number = NigerianPhoneField()


class DataPlansView(APIView):
    def get(self, request):
        network = request.query_params.get('network')
        if network not in VALID_NETWORKS:
            return Response({'detail': f'Invalid network. Choose from {VALID_NETWORKS}.'}, status=400)
        plans = async_to_sync(get_data_plans)(network)
        return Response({'plans': plans})


class DataPurchaseView(APIView):
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
        charge = price * (1 + markup)

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
                    status='pending',
                    reference=Transaction.generate_reference(),
                    network=d['network'],
                    phone_number=d['phone_number'],
                    plan_id=d['plan_id'],
                )
        except Wallet.DoesNotExist:
            return Response({'detail': 'Wallet not found.'}, status=404)

        result = async_to_sync(purchase_data)(d['network'], d['plan_id'], d['phone_number'])

        if result['success']:
            txn.status = 'success'
            txn.reference = result['reference']
            txn.save()
            return Response({
                'message': 'Data purchased.',
                'reference': txn.reference,
                'plan_id': d['plan_id'],
                'plan_name': plan.get('name', ''),
                'amount': float(charge),
                'data': plan.get('name', ''),
                'validity': plan.get('validity', ''),
                'network': d['network'],
                'phone_number': d['phone_number'],
            })
        else:
            with db_transaction.atomic():
                Wallet.objects.filter(pk=wallet.pk).update(balance=F('balance') + charge)
                txn.status = 'failed'
                txn.save()
            return Response({'detail': f"Purchase failed: {result['message']}"}, status=502)

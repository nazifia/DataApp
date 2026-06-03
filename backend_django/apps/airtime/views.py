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
from .services import purchase_airtime

VALID_NETWORKS = ('mtn', 'airtel', 'glo', 'etisalat')


class AirtimePurchaseSerializer(serializers.Serializer):
    network = serializers.ChoiceField(choices=VALID_NETWORKS)
    phone_number = NigerianPhoneField()
    amount = serializers.DecimalField(max_digits=10, decimal_places=2, min_value=Decimal('50'), max_value=Decimal('50000'))


class AirtimePurchaseView(APIView):
    def post(self, request):
        ser = AirtimePurchaseSerializer(data=request.data)
        ser.is_valid(raise_exception=True)
        d = ser.validated_data

        markup = (request.tenant.airtime_markup_percent / 100) if request.tenant else Decimal('0')
        charge = (d['amount'] * (1 + markup)).quantize(Decimal('0.01'))

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
                    type='airtime',
                    amount=charge,
                    status='pending',
                    reference=Transaction.generate_reference(),
                    network=d['network'],
                    phone_number=d['phone_number'],
                )
        except Wallet.DoesNotExist:
            return Response({'detail': 'Wallet not found.'}, status=404)

        result = async_to_sync(purchase_airtime)(d['network'], d['phone_number'], float(d['amount']))

        if result['success']:
            txn.status = 'success'
            txn.reference = result['reference']
            txn.save()
            return Response({
                'message': 'Airtime purchased.',
                'reference': txn.reference,
                'amount': float(charge),
                'network': d['network'],
                'phone_number': d['phone_number'],
            })
        else:
            with db_transaction.atomic():
                Wallet.objects.filter(pk=wallet.pk).update(balance=F('balance') + charge)
                txn.status = 'failed'
                txn.save()
            return Response({'detail': f"Purchase failed: {result['message']}"}, status=502)

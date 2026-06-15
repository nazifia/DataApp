from decimal import Decimal
from django.db import transaction as db_transaction
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import serializers
from rest_framework.throttling import UserRateThrottle
from core.validators import NigerianPhoneField, NetworkChoiceField
from apps.transactions.models import Transaction
from apps.transactions.fulfillment import fulfill
from apps.wallet.models import Wallet

VALID_NETWORKS = ('mtn', 'airtel', 'glo', 'etisalat')


class PurchaseThrottle(UserRateThrottle):
    scope = 'purchase'


class AirtimePurchaseSerializer(serializers.Serializer):
    network = NetworkChoiceField()
    phone_number = NigerianPhoneField()
    amount = serializers.DecimalField(max_digits=10, decimal_places=2, min_value=Decimal('50'), max_value=Decimal('50000'))


class AirtimePurchaseView(APIView):
    throttle_classes = [PurchaseThrottle]

    def post(self, request):
        ser = AirtimePurchaseSerializer(data=request.data)
        ser.is_valid(raise_exception=True)
        d = ser.validated_data

        markup = (request.tenant.airtime_markup_percent / 100) if request.tenant else Decimal('0')
        charge = (d['amount'] * (1 + markup)).quantize(Decimal('0.01'))

        try:
            with db_transaction.atomic():
                wallet, _ = Wallet.objects.select_for_update().get_or_create(
                    user=request.user,
                    defaults={'tenant_id': request.user.tenant_id, 'balance': 0},
                )
                if wallet.balance < charge:
                    return Response({'detail': 'Insufficient wallet balance.'}, status=400)
                wallet.balance -= charge
                wallet.save()
                txn = Transaction.objects.create(
                    tenant=request.tenant,
                    user=request.user,
                    type='airtime',
                    amount=charge,
                    face_value=d['amount'],
                    status='pending',
                    reference=Transaction.generate_reference(),
                    network=d['network'],
                    phone_number=d['phone_number'],
                )
        except Wallet.DoesNotExist:
            return Response({'detail': 'Wallet not found.'}, status=404)

        fulfill(txn)

        if txn.status == 'failed':
            return Response({'detail': f'Purchase failed: {txn.last_error}'}, status=502)
        return Response({
            'message': 'Airtime purchased.' if txn.status == 'success' else 'Airtime purchase is being processed.',
            'reference': txn.reference,
            'status': txn.status,
            'amount': float(charge),
            'network': d['network'],
            'phone_number': d['phone_number'],
        })

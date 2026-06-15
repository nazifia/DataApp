from asgiref.sync import async_to_sync
from decimal import Decimal
from django.db import transaction as db_transaction
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import serializers
from rest_framework.throttling import UserRateThrottle
from core.validators import NigerianPhoneField
from apps.transactions.models import Transaction
from apps.transactions.fulfillment import fulfill
from apps.wallet.models import Wallet
from .services import get_providers, get_variations, verify_customer, pay_bill

CATEGORIES = ('electricity', 'tv')


class PurchaseThrottle(UserRateThrottle):
    scope = 'purchase'


class ProvidersView(APIView):
    def get(self, request):
        category = request.query_params.get('category', 'electricity')
        if category not in CATEGORIES:
            return Response({'detail': f'Invalid category. Choose from {CATEGORIES}.'}, status=400)
        return Response({'category': category, 'providers': get_providers(category)})


class VariationsView(APIView):
    def get(self, request):
        category = request.query_params.get('category', 'tv')
        service_id = request.query_params.get('service_id', '')
        if category not in CATEGORIES:
            return Response({'detail': f'Invalid category. Choose from {CATEGORIES}.'}, status=400)
        if not service_id:
            return Response({'detail': 'service_id is required.'}, status=400)
        variations = async_to_sync(get_variations)(service_id, category)
        return Response({'service_id': service_id, 'variations': variations})


class VerifyCustomerSerializer(serializers.Serializer):
    service_id = serializers.CharField()
    customer_id = serializers.CharField()
    variation_code = serializers.CharField(required=False, allow_blank=True, default='')


class VerifyCustomerView(APIView):
    def post(self, request):
        ser = VerifyCustomerSerializer(data=request.data)
        ser.is_valid(raise_exception=True)
        d = ser.validated_data
        result = async_to_sync(verify_customer)(d['service_id'], d['customer_id'], d.get('variation_code', ''))
        status_code = 200 if result.get('success') else 400
        return Response(result, status=status_code)


class BillPaymentSerializer(serializers.Serializer):
    category = serializers.ChoiceField(choices=CATEGORIES)
    service_id = serializers.CharField()
    customer_id = serializers.CharField()
    variation_code = serializers.CharField(required=False, allow_blank=True, default='')
    amount = serializers.DecimalField(
        max_digits=10, decimal_places=2,
        min_value=Decimal('50'), max_value=Decimal('500000'),
    )
    phone_number = NigerianPhoneField()


class BillPaymentView(APIView):
    throttle_classes = [PurchaseThrottle]

    def post(self, request):
        ser = BillPaymentSerializer(data=request.data)
        ser.is_valid(raise_exception=True)
        d = ser.validated_data

        amount = d['amount']
        markup = (request.tenant.bill_markup_percent / 100) if request.tenant else Decimal('0')
        charge = (amount * (1 + markup)).quantize(Decimal('0.01'))
        txn_type = 'electricity' if d['category'] == 'electricity' else 'tv'

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
                    type=txn_type,
                    amount=charge,
                    face_value=amount,
                    status='pending',
                    reference=Transaction.generate_reference(),
                    phone_number=d['phone_number'],
                    customer_id=d['customer_id'],
                    provider=d['service_id'],
                    variation_code=d.get('variation_code', ''),
                )
        except Wallet.DoesNotExist:
            return Response({'detail': 'Wallet not found.'}, status=404)

        fulfill(txn)

        if txn.status == 'failed':
            return Response({'detail': f'Payment failed: {txn.last_error}'}, status=502)
        return Response({
            'message': 'Bill paid.' if txn.status == 'success' else 'Bill payment is being processed.',
            'reference': txn.reference,
            'status': txn.status,
            'amount': float(charge),
            'category': d['category'],
            'provider': d['service_id'],
            'customer_id': d['customer_id'],
            'token': txn.token,
        })

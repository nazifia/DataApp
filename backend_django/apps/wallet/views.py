from decimal import Decimal
from django.db import transaction as db_transaction
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from apps.transactions.models import Transaction
from .models import Wallet


def _get_wallet(user):
    try:
        return user.wallet
    except Wallet.DoesNotExist:
        return None


class WalletBalanceView(APIView):
    def get(self, request):
        wallet = _get_wallet(request.user)
        if not wallet:
            return Response({'detail': 'Wallet not found.'}, status=404)
        return Response({'balance': float(wallet.balance)})


class BankDetailsView(APIView):
    def get(self, request):
        uid = str(request.user.id).replace('-', '')
        account_number = '9' + uid[:9]
        first_name = (request.user.full_name or 'USER').split()[0].upper()
        return Response({
            'bank_name': 'Providus Bank',
            'account_number': account_number,
            'account_name': f'TUN/{first_name}',
            'note': 'Transfer exact amount. Wallet credited automatically.',
        })


class FundWalletView(APIView):
    def post(self, request):
        wallet = _get_wallet(request.user)
        if not wallet:
            return Response({'detail': 'Wallet not found.'}, status=404)

        try:
            amount = Decimal(str(request.data.get('amount', 0)))
        except Exception:
            return Response({'detail': 'Invalid amount.'}, status=400)

        min_fund = request.tenant.min_wallet_fund if request.tenant else Decimal('50')
        if amount < min_fund:
            return Response({'detail': f'Minimum funding amount is ₦{min_fund}.'}, status=400)

        with db_transaction.atomic():
            wallet.balance += amount
            wallet.save()
            Transaction.objects.create(
                tenant=request.tenant,
                user=request.user,
                type='wallet_fund',
                amount=amount,
                status='success',
                reference=Transaction.generate_reference(),
            )
        return Response({'message': 'Wallet funded.', 'balance': float(wallet.balance)})


class WalletApps(APIView):
    pass

"""Provider-agnostic USSD webhook.

Accepts the Africa's-Talking-style payload used by most Nigerian aggregators:
    sessionId, phoneNumber, text  (text is the '*'-joined history of inputs)
Responds with plain text prefixed `CON ` (expect more input) or `END ` (terminate).

A gateway must send the shared secret in the `X-USSD-Secret` header (when configured).
Purchases reuse apps.transactions.fulfillment.fulfill, the same path as the REST API.
"""
from decimal import Decimal, InvalidOperation

from django.conf import settings
from django.db import transaction as db_transaction
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import AllowAny
from rest_framework.renderers import StaticHTMLRenderer

from core.validators import normalize_phone_number
from apps.authentication.models import User
from apps.wallet.models import Wallet
from apps.transactions.models import Transaction
from apps.transactions.fulfillment import fulfill
from .models import USSDSession

NETWORKS = {'1': 'mtn', '2': 'airtel', '3': 'glo', '4': 'etisalat'}
NETWORK_LABELS = {'1': 'MTN', '2': 'Airtel', '3': 'Glo', '4': '9mobile'}


def con(msg):
    return f'CON {msg}'


def end(msg):
    return f'END {msg}'


class USSDCallbackView(APIView):
    permission_classes = [AllowAny]
    authentication_classes = []
    renderer_classes = [StaticHTMLRenderer]

    def post(self, request):
        secret = getattr(settings, 'USSD_WEBHOOK_SECRET', '')
        if not secret:
            # An unset secret leaves this money-moving webhook open to anyone.
            # Tolerate it only in DEBUG; refuse to serve it on a prod build.
            if not settings.DEBUG:
                return Response(end('USSD gateway not configured.'), status=503)
        elif request.headers.get('X-USSD-Secret') != secret:
            return Response(end('Unauthorized.'), status=403)

        session_id = request.data.get('sessionId', '')
        raw_phone = request.data.get('phoneNumber', '')
        text = (request.data.get('text', '') or '').strip()
        phone = normalize_phone_number(raw_phone) or raw_phone

        user = User.objects.filter(phone_number=phone).select_related('tenant').first()
        response_text = self._route(user, phone, text)

        USSDSession.objects.create(
            tenant=getattr(user, 'tenant', None),
            session_id=session_id, phone_number=phone,
            last_input=text, last_response=response_text,
            ended=response_text.startswith('END '),
        )
        return Response(response_text)

    # ─── Menu router ─────────────────────────────────────────────────────────

    def _route(self, user, phone, text):
        if user is None:
            return end('Number not registered. Download the TopUpNaija app to get started.')

        parts = [p for p in text.split('*') if p != ''] if text else []

        if not parts:
            return con(
                'Welcome to TopUpNaija\n'
                '1. Check Balance\n'
                '2. Buy Airtime\n'
                '3. Buy Data'
            )

        choice = parts[0]
        if choice == '1':
            return self._balance(user, parts)
        if choice == '2':
            return self._airtime(user, phone, parts)
        if choice == '3':
            return self._data(user, phone, parts)
        return end('Invalid option.')

    # ─── 1. Balance (PIN-gated) ──────────────────────────────────────────────

    def _balance(self, user, parts):
        if not user.ussd_pin:
            return end('Set a USSD PIN in the app first.')
        if len(parts) < 2:
            return con('Enter your USSD PIN:')
        if not user.check_ussd_pin(parts[1]):
            return end('Incorrect PIN.')
        wallet = _wallet(user)
        bal = wallet.balance if wallet else Decimal('0')
        return end(f'Your wallet balance is N{bal:,.2f}.')

    # ─── 2. Airtime: network -> amount -> PIN ────────────────────────────────

    def _airtime(self, user, phone, parts):
        if len(parts) < 2:
            return con('Select network:\n1. MTN\n2. Airtel\n3. Glo\n4. 9mobile')
        if parts[1] not in NETWORKS:
            return end('Invalid network.')
        if len(parts) < 3:
            return con(f'{NETWORK_LABELS[parts[1]]} airtime\nEnter amount (50 - 50000):')
        amount = _parse_amount(parts[2])
        if amount is None or amount < 50 or amount > 50000:
            return end('Invalid amount.')
        if not user.ussd_pin:
            return end('Set a USSD PIN in the app first.')
        if len(parts) < 4:
            return con(f'Confirm N{amount:,.0f} {NETWORK_LABELS[parts[1]]} airtime to {phone}.\nEnter PIN:')
        if not user.check_ussd_pin(parts[3]):
            return end('Incorrect PIN.')
        return self._purchase_airtime(user, phone, NETWORKS[parts[1]], amount)

    def _purchase_airtime(self, user, phone, network, amount):
        tenant = user.tenant
        markup = (tenant.airtime_markup_percent / 100) if tenant else Decimal('0')
        charge = (amount * (1 + markup)).quantize(Decimal('0.01'))
        try:
            with db_transaction.atomic():
                wallet = Wallet.all_objects.select_for_update().get(user=user)
                if wallet.balance < charge:
                    return end('Insufficient wallet balance.')
                wallet.balance -= charge
                wallet.save()
                txn = Transaction.objects.create(
                    tenant=tenant, user=user, type='airtime',
                    amount=charge, face_value=amount, status='pending',
                    reference=Transaction.generate_reference(),
                    network=network, phone_number=phone,
                )
        except Wallet.DoesNotExist:
            return end('Wallet not found.')

        fulfill(txn)
        if txn.status == 'failed':
            return end('Purchase failed. Your wallet was refunded.')
        if txn.status == 'retrying':
            return end(f'N{amount:,.0f} airtime is processing. You will be notified shortly.')
        return end(f'N{amount:,.0f} {network.upper()} airtime sent to {phone}.')

    # ─── 3. Data: network -> plan -> PIN ─────────────────────────────────────

    def _data(self, user, phone, parts):
        from asgiref.sync import async_to_sync
        from apps.data_plans.services import get_data_plans

        if len(parts) < 2:
            return con('Select network:\n1. MTN\n2. Airtel\n3. Glo\n4. 9mobile')
        if parts[1] not in NETWORKS:
            return end('Invalid network.')
        network = NETWORKS[parts[1]]
        plans = async_to_sync(get_data_plans)(network)[:5]
        if not plans:
            return end('No data plans available right now.')
        if len(parts) < 3:
            menu = '\n'.join(f'{i + 1}. {p["name"]} - N{p["price"]:,.0f}' for i, p in enumerate(plans))
            return con(f'{NETWORK_LABELS[parts[1]]} data:\n{menu}')
        try:
            plan = plans[int(parts[2]) - 1]
        except (ValueError, IndexError):
            return end('Invalid plan.')
        if not user.ussd_pin:
            return end('Set a USSD PIN in the app first.')
        if len(parts) < 4:
            return con(f'Confirm {plan["name"]} (N{plan["price"]:,.0f}) to {phone}.\nEnter PIN:')
        if not user.check_ussd_pin(parts[3]):
            return end('Incorrect PIN.')
        return self._purchase_data(user, phone, network, plan)

    def _purchase_data(self, user, phone, network, plan):
        tenant = user.tenant
        markup = (tenant.data_markup_percent / 100) if tenant else Decimal('0')
        price = Decimal(str(plan['price']))
        charge = (price * (1 + markup)).quantize(Decimal('0.01'))
        try:
            with db_transaction.atomic():
                wallet = Wallet.all_objects.select_for_update().get(user=user)
                if wallet.balance < charge:
                    return end('Insufficient wallet balance.')
                wallet.balance -= charge
                wallet.save()
                txn = Transaction.objects.create(
                    tenant=tenant, user=user, type='data',
                    amount=charge, face_value=price, status='pending',
                    reference=Transaction.generate_reference(),
                    network=network, phone_number=phone, plan_id=plan['id'],
                )
        except Wallet.DoesNotExist:
            return end('Wallet not found.')

        fulfill(txn)
        if txn.status == 'failed':
            return end('Purchase failed. Your wallet was refunded.')
        if txn.status == 'retrying':
            return end(f'{plan["name"]} data is processing. You will be notified shortly.')
        return end(f'{plan["name"]} data sent to {phone}.')


def _wallet(user):
    return Wallet.all_objects.filter(user=user).first()


def _parse_amount(raw):
    try:
        return Decimal(raw)
    except (InvalidOperation, ValueError):
        return None

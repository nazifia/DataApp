"""Central provider-fulfilment for purchase transactions.

Both the purchase views and the `retry_transactions` management command call
``fulfill(txn)`` so success/failure/refund/commission/referral logic lives in one
place. A transaction enters here already ``pending`` (or ``retrying``) with the
paying wallet already debited.

State machine:
    pending/retrying --success--> success   (+ commission, + referral bonus)
                     --fail, retries left--> retrying (wallet stays debited)
                     --fail, exhausted----> failed   (wallet refunded)
"""
import logging
from datetime import timedelta
from decimal import Decimal

from asgiref.sync import async_to_sync
from django.conf import settings
from django.db import transaction as db_transaction
from django.db.models import F
from django.utils import timezone

from core.notifications import send_push_notification
from apps.wallet.models import Wallet

logger = logging.getLogger(__name__)

# Backoff schedule (minutes) indexed by retry_count.
RETRY_BACKOFF_MINUTES = [5, 15, 45]


def _max_retries() -> int:
    return int(getattr(settings, 'TXN_MAX_RETRIES', 3))


def _paying_user(txn):
    """Wallet owner that was charged: the agent's own user for agent sales, else the buyer."""
    if txn.agent_id:
        return txn.agent.user
    return txn.user


def _call_provider(txn) -> dict:
    """Dispatch to the right provider by transaction type. Returns {success, message, token?}."""
    if txn.type == 'airtime':
        from apps.airtime.services import purchase_airtime
        value = float(txn.face_value if txn.face_value is not None else txn.amount)
        return async_to_sync(purchase_airtime)(txn.network, txn.phone_number, value)
    if txn.type == 'data':
        from apps.data_plans.services import purchase_data
        return async_to_sync(purchase_data)(txn.network, txn.plan_id, txn.phone_number)
    if txn.type in ('electricity', 'tv'):
        from apps.bills.services import pay_bill
        value = float(txn.face_value if txn.face_value is not None else txn.amount)
        return async_to_sync(pay_bill)(
            txn.provider, txn.customer_id, txn.variation_code, value,
            txn.phone_number, request_id=txn.reference,
        )
    return {'success': False, 'message': f'Unknown transaction type: {txn.type}'}


def fulfill(txn):
    """Attempt provider fulfilment for a pending/retrying transaction. Mutates and saves txn."""
    if txn.status not in ('pending', 'retrying'):
        return txn

    try:
        result = _call_provider(txn)
    except Exception as exc:  # network/provider crash — treat as retryable
        logger.exception('Provider call crashed for %s', txn.reference)
        result = {'success': False, 'message': str(exc)}

    if result.get('success'):
        _mark_success(txn, result)
    else:
        _handle_failure(txn, result.get('message', 'Purchase failed'))
    return txn


def _mark_success(txn, result):
    txn.status = 'success'
    txn.last_error = ''
    txn.next_retry_at = None
    if result.get('token'):
        txn.token = result['token']
    txn.save()

    _notify_success(txn)
    _credit_agent_commission(txn)
    _grant_referral_reward(txn)


def _handle_failure(txn, message):
    txn.last_error = message[:2000]
    if txn.retry_count < _max_retries():
        delay = RETRY_BACKOFF_MINUTES[min(txn.retry_count, len(RETRY_BACKOFF_MINUTES) - 1)]
        txn.retry_count += 1
        txn.status = 'retrying'
        txn.next_retry_at = timezone.now() + timedelta(minutes=delay)
        txn.save()
        logger.info('Txn %s scheduled for retry #%s in %sm', txn.reference, txn.retry_count, delay)
    else:
        finalize_failure(txn)


def finalize_failure(txn):
    """Refund the paying wallet (once) and mark the transaction failed."""
    with db_transaction.atomic():
        user = _paying_user(txn)
        Wallet.all_objects.filter(user=user).update(balance=F('balance') + txn.amount)
        txn.status = 'failed'
        txn.next_retry_at = None
        txn.save()
    _notify_failure(txn)


# ─── Side effects ────────────────────────────────────────────────────────────

def _credit_agent_commission(txn):
    if not txn.agent_id or txn.type == 'commission':
        return
    from .models import Transaction
    agent = txn.agent
    commission = (txn.amount * agent.commission_percent / 100).quantize(Decimal('0.01'))
    if commission <= 0:
        return
    with db_transaction.atomic():
        wallet = Wallet.all_objects.select_for_update().get(user=agent.user)
        wallet.balance += commission
        wallet.save()
        Transaction.objects.create(
            tenant=txn.tenant,
            user=agent.user,
            type='commission',
            amount=commission,
            status='success',
            reference=f'COM-{txn.reference}',
            agent=agent,
        )


def _grant_referral_reward(txn):
    if txn.type not in ('airtime', 'data', 'electricity', 'tv'):
        return
    user = txn.user
    if not user.referred_by_id:
        return
    from apps.referrals.models import ReferralReward
    if ReferralReward.all_objects.filter(referee=user).exists():
        return
    bonus = txn.tenant.referral_bonus if txn.tenant else Decimal('0')
    if not bonus or bonus <= 0:
        return
    with db_transaction.atomic():
        wallet = Wallet.all_objects.select_for_update().filter(user_id=user.referred_by_id).first()
        if not wallet:
            return
        wallet.balance += bonus
        wallet.save()
        ReferralReward.objects.create(
            tenant=txn.tenant,
            referrer_id=user.referred_by_id,
            referee=user,
            amount=bonus,
            status='paid',
            transaction=txn,
        )
    send_push_notification(
        user.referred_by,
        title='Referral Bonus Earned',
        body=f'You earned ₦{float(bonus):,.2f} because {user.full_name or user.phone_number} made their first purchase.',
        data={'type': 'referral_bonus', 'amount': str(bonus)},
    )


# ─── Notifications ───────────────────────────────────────────────────────────

_LABELS = {
    'airtime': 'Airtime', 'data': 'Data',
    'electricity': 'Electricity', 'tv': 'Cable TV',
}


def _notify_success(txn):
    label = _LABELS.get(txn.type, txn.type.title())
    target = txn.customer_id or txn.phone_number
    body = f'Your {label} purchase of ₦{float(txn.amount):,.2f} for {target} was successful.'
    if txn.type == 'electricity' and txn.token:
        body += f' Token: {txn.token}'
    send_push_notification(
        txn.user, title=f'{label} Successful', body=body,
        data={'type': txn.type, 'reference': txn.reference, 'token': txn.token},
    )


def _notify_failure(txn):
    label = _LABELS.get(txn.type, txn.type.title())
    send_push_notification(
        txn.user, title=f'{label} Failed',
        body=f'Your {label} purchase of ₦{float(txn.amount):,.2f} failed. Your wallet has been refunded.',
        data={'type': f'{txn.type}_failed', 'reference': txn.reference},
    )

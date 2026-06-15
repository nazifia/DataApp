import hashlib
import hmac
import httpx
from django.conf import settings

BASE_URL = 'https://api.paystack.co'


def _headers():
    return {
        'Authorization': f'Bearer {settings.PAYSTACK_SECRET_KEY}',
        'Content-Type': 'application/json',
    }


def verify_webhook_signature(payload_bytes: bytes, signature: str) -> bool:
    expected = hmac.new(
        settings.PAYSTACK_SECRET_KEY.encode(),
        payload_bytes,
        hashlib.sha512,
    ).hexdigest()
    return hmac.compare_digest(expected, signature or '')


def create_customer(email: str, phone: str, full_name: str) -> dict:
    first, *rest = (full_name or 'User').split()
    resp = httpx.post(
        f'{BASE_URL}/customer',
        json={'email': email, 'phone': phone, 'first_name': first, 'last_name': ' '.join(rest) or first},
        headers=_headers(),
        timeout=15,
    )
    resp.raise_for_status()
    return resp.json()['data']


def create_dedicated_account(customer_code: str, preferred_bank: str = 'wema-bank') -> dict:
    resp = httpx.post(
        f'{BASE_URL}/dedicated_account',
        json={'customer': customer_code, 'preferred_bank': preferred_bank},
        headers=_headers(),
        timeout=15,
    )
    resp.raise_for_status()
    return resp.json()['data']


def fetch_dedicated_account(customer_code: str) -> dict | None:
    resp = httpx.get(
        f'{BASE_URL}/dedicated_account',
        params={'customer': customer_code},
        headers=_headers(),
        timeout=15,
    )
    if resp.status_code != 200:
        return None
    data = resp.json().get('data', [])
    return data[0] if data else None


def initialize_transaction(email: str, amount_kobo: int, metadata: dict | None = None) -> dict:
    resp = httpx.post(
        f'{BASE_URL}/transaction/initialize',
        json={
            'email': email,
            'amount': amount_kobo,
            'metadata': metadata or {},
            'channels': ['card', 'bank', 'ussd', 'mobile_money'],
        },
        headers=_headers(),
        timeout=15,
    )
    resp.raise_for_status()
    return resp.json()['data']


def verify_transaction(reference: str) -> dict:
    resp = httpx.get(
        f'{BASE_URL}/transaction/verify/{reference}',
        headers=_headers(),
        timeout=15,
    )
    resp.raise_for_status()
    return resp.json()['data']


# ─── Bank list / Transfers (Withdrawals) ─────────────────────────────────────

def list_banks() -> list[dict]:
    """Return all NGN banks (commercial + microfinance), paginating through results.

    Each item: {'name', 'code', 'type', ...}. Paystack lists nuban banks which
    include microfinance banks, so a single call covers both categories.
    """
    banks: list[dict] = []
    next_cursor = None
    for _ in range(20):  # safety bound; Paystack returns ~50/page
        params = {'currency': 'NGN', 'country': 'nigeria', 'perPage': 100}
        if next_cursor:
            params['next'] = next_cursor
        resp = httpx.get(f'{BASE_URL}/bank', params=params, headers=_headers(), timeout=15)
        resp.raise_for_status()
        body = resp.json()
        banks.extend(body.get('data', []))
        next_cursor = (body.get('meta') or {}).get('next')
        if not next_cursor:
            break
    return banks


def resolve_account(account_number: str, bank_code: str) -> dict:
    """Verify an account number against a bank. Returns {'account_name', 'account_number'}."""
    resp = httpx.get(
        f'{BASE_URL}/bank/resolve',
        params={'account_number': account_number, 'bank_code': bank_code},
        headers=_headers(),
        timeout=15,
    )
    resp.raise_for_status()
    return resp.json()['data']


def create_transfer_recipient(name: str, account_number: str, bank_code: str) -> dict:
    resp = httpx.post(
        f'{BASE_URL}/transferrecipient',
        json={
            'type': 'nuban',
            'name': name,
            'account_number': account_number,
            'bank_code': bank_code,
            'currency': 'NGN',
        },
        headers=_headers(),
        timeout=15,
    )
    resp.raise_for_status()
    return resp.json()['data']


def verify_transfer(reference: str) -> dict:
    """Fetch the current status of a transfer by reference (webhook fallback)."""
    resp = httpx.get(
        f'{BASE_URL}/transfer/verify/{reference}',
        headers=_headers(),
        timeout=15,
    )
    resp.raise_for_status()
    return resp.json()['data']


def initiate_transfer(amount_kobo: int, recipient_code: str, reason: str, reference: str) -> dict:
    resp = httpx.post(
        f'{BASE_URL}/transfer',
        json={
            'source': 'balance',
            'amount': amount_kobo,
            'recipient': recipient_code,
            'reason': reason,
            'reference': reference,
        },
        headers=_headers(),
        timeout=15,
    )
    resp.raise_for_status()
    return resp.json()['data']

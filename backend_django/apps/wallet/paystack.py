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

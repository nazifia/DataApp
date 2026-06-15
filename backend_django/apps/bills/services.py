"""VTpass integration for electricity & cable-TV bill payments.

Mirrors the airtime/data service pattern: DEV_MODE returns deterministic mocks,
otherwise calls the live VTpass REST API. Every purchase fn returns a dict shaped
{success, reference, message, token} so apps.transactions.fulfillment can treat all
providers uniformly.
"""
import time
import random
import httpx
from django.conf import settings

# Static provider catalogues (also used as DEV_MODE fallbacks).
ELECTRICITY_PROVIDERS = [
    {'id': 'ikeja-electric', 'name': 'Ikeja Electric (IKEDC)'},
    {'id': 'eko-electric', 'name': 'Eko Electric (EKEDC)'},
    {'id': 'kano-electric', 'name': 'Kano Electric (KEDCO)'},
    {'id': 'portharcourt-electric', 'name': 'Port Harcourt Electric (PHED)'},
    {'id': 'jos-electric', 'name': 'Jos Electric (JED)'},
    {'id': 'ibadan-electric', 'name': 'Ibadan Electric (IBEDC)'},
    {'id': 'abuja-electric', 'name': 'Abuja Electric (AEDC)'},
    {'id': 'enugu-electric', 'name': 'Enugu Electric (EEDC)'},
    {'id': 'benin-electric', 'name': 'Benin Electric (BEDC)'},
    {'id': 'kaduna-electric', 'name': 'Kaduna Electric (KAEDCO)'},
]

TV_PROVIDERS = [
    {'id': 'dstv', 'name': 'DStv'},
    {'id': 'gotv', 'name': 'GOtv'},
    {'id': 'startimes', 'name': 'StarTimes'},
    {'id': 'showmax', 'name': 'Showmax'},
]

MOCK_VARIATIONS = {
    'dstv': [
        {'variation_code': 'dstv-padi', 'name': 'DStv Padi', 'amount': 2950},
        {'variation_code': 'dstv-yanga', 'name': 'DStv Yanga', 'amount': 4200},
        {'variation_code': 'dstv-confam', 'name': 'DStv Confam', 'amount': 7400},
        {'variation_code': 'dstv-compact', 'name': 'DStv Compact', 'amount': 12500},
    ],
    'gotv': [
        {'variation_code': 'gotv-smallie', 'name': 'GOtv Smallie', 'amount': 1300},
        {'variation_code': 'gotv-jinja', 'name': 'GOtv Jinja', 'amount': 3300},
        {'variation_code': 'gotv-max', 'name': 'GOtv Max', 'amount': 5700},
    ],
    'startimes': [
        {'variation_code': 'nova', 'name': 'Nova (Antenna)', 'amount': 1700},
        {'variation_code': 'basic', 'name': 'Basic (Antenna)', 'amount': 3700},
    ],
}

ELECTRICITY_VARIATIONS = [
    {'variation_code': 'prepaid', 'name': 'Prepaid Meter'},
    {'variation_code': 'postpaid', 'name': 'Postpaid Meter'},
]


def _ref() -> str:
    return f'TUN-{int(time.time() * 1000)}-{random.randint(1000, 9999)}'


def get_providers(category: str) -> list:
    if category == 'tv':
        return TV_PROVIDERS
    return ELECTRICITY_PROVIDERS


async def get_variations(service_id: str, category: str) -> list:
    if category == 'electricity':
        return ELECTRICITY_VARIATIONS
    if settings.DEV_MODE:
        return MOCK_VARIATIONS.get(service_id, [])
    try:
        async with httpx.AsyncClient() as client:
            resp = await client.get(
                f'{settings.VTPASS_BASE_URL}/service-variations',
                params={'serviceID': service_id},
                headers=_auth_headers(),
                timeout=15,
            )
            content = resp.json().get('content', {})
            variations = content.get('variations') or content.get('varations') or []
            return [
                {
                    'variation_code': v.get('variation_code', ''),
                    'name': v.get('name', ''),
                    'amount': float(v.get('variation_amount', 0)),
                }
                for v in variations
            ]
    except Exception:
        return MOCK_VARIATIONS.get(service_id, [])


async def verify_customer(service_id: str, customer_id: str, variation_code: str = '') -> dict:
    """Look up the account/meter holder's name before payment."""
    if settings.DEV_MODE:
        return {
            'success': True,
            'customer_name': 'JOHN DOE',
            'customer_id': customer_id,
            'message': 'Customer verified (mock)',
        }
    try:
        payload = {'serviceID': service_id, 'billersCode': customer_id}
        if variation_code:
            payload['type'] = variation_code
        async with httpx.AsyncClient() as client:
            resp = await client.post(
                f'{settings.VTPASS_BASE_URL}/merchant-verify',
                json=payload,
                headers=_auth_headers(),
                timeout=20,
            )
            content = resp.json().get('content', {})
            if content.get('error'):
                return {'success': False, 'message': content['error'], 'customer_id': customer_id}
            name = content.get('Customer_Name') or content.get('customer_name') or ''
            return {
                'success': bool(name),
                'customer_name': name,
                'customer_id': customer_id,
                'message': 'Customer verified' if name else 'Could not verify customer',
            }
    except Exception as e:
        return {'success': False, 'message': str(e), 'customer_id': customer_id}


async def pay_bill(service_id: str, customer_id: str, variation_code: str,
                   amount: float, phone: str, request_id: str = '') -> dict:
    request_id = request_id or _ref()
    if settings.DEV_MODE:
        token = ''.join(random.choices('0123456789', k=16))
        return {
            'success': True,
            'reference': request_id,
            'message': 'Bill paid (mock)',
            'token': token,
        }
    try:
        payload = {
            'request_id': request_id,
            'serviceID': service_id,
            'billersCode': customer_id,
            'variation_code': variation_code,
            'amount': amount,
            'phone': phone,
        }
        async with httpx.AsyncClient() as client:
            resp = await client.post(
                f'{settings.VTPASS_BASE_URL}/pay',
                json=payload,
                headers=_auth_headers(),
                timeout=60,
            )
            data = resp.json()
            code = str(data.get('code', ''))
            content = data.get('content', {}) or {}
            txn = content.get('transactions', {}) or {}
            status_ok = code == '000' and txn.get('status') in ('delivered', 'pending', None)
            token = (data.get('purchased_code') or data.get('Token')
                     or content.get('token') or '')
            return {
                'success': bool(status_ok),
                'reference': request_id,
                'message': data.get('response_description', 'Payment failed'),
                'token': token,
            }
    except Exception as e:
        return {'success': False, 'reference': request_id, 'message': str(e), 'token': ''}


def _auth_headers() -> dict:
    return {
        'api-key': settings.VTPASS_API_KEY,
        'secret-key': settings.VTPASS_SECRET_KEY,
        'Content-Type': 'application/json',
    }

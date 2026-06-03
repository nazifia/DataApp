import time
import random
import httpx
from django.conf import settings

NETWORK_ID_MAP = {'mtn': '1', 'glo': '2', 'airtel': '3', 'etisalat': '4'}


async def purchase_airtime(network: str, phone: str, amount: float) -> dict:
    reference = f'TUN-{int(time.time() * 1000)}-{random.randint(1000, 9999)}'
    if settings.DEV_MODE:
        return {'success': True, 'reference': reference, 'message': 'Airtime sent (mock)'}

    headers = {'Authorization': f'Token {settings.GLADTIDING_API_KEY}'}
    try:
        async with httpx.AsyncClient() as client:
            resp = await client.post(
                f'{settings.GLADTIDING_BASE_URL}/topup/',
                json={
                    'network': NETWORK_ID_MAP[network],
                    'amount': amount,
                    'mobile_number': phone,
                    'Ported_number': True,
                    'airtime_type': 'VTU',
                },
                headers=headers,
                timeout=30,
            )
            data = resp.json()
            success = data.get('Status') == 'successful'
            return {
                'success': success,
                'reference': reference,
                'message': data.get('api_response', 'Purchase failed'),
            }
    except Exception as e:
        return {'success': False, 'reference': reference, 'message': str(e)}

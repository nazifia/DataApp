import time
import random
import httpx
from django.conf import settings


async def purchase_airtime(network: str, phone: str, amount: float) -> dict:
    reference = f'TUN-{int(time.time() * 1000)}-{random.randint(1000, 9999)}'
    if settings.DEV_MODE:
        return {'success': True, 'reference': reference, 'message': 'Airtime sent (mock)'}

    service_map = {'mtn': 'mtn', 'airtel': 'airtel', 'glo': 'glo', 'etisalat': 'etisalat-sme'}
    try:
        async with httpx.AsyncClient(auth=(settings.VTPASS_API_KEY, settings.VTPASS_SECRET_KEY)) as client:
            resp = await client.post(
                f'{settings.VTPASS_BASE_URL}/pay',
                json={
                    'request_id': reference,
                    'serviceID': service_map[network],
                    'amount': amount,
                    'phone': phone,
                },
                timeout=30,
            )
            data = resp.json()
            success = data.get('code') == '000'
            return {
                'success': success,
                'reference': reference,
                'message': data.get('response_description', 'Purchase failed'),
            }
    except Exception as e:
        return {'success': False, 'reference': reference, 'message': str(e)}

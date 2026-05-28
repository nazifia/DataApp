import time
import random
import httpx
from django.conf import settings

MOCK_PLANS = {
    'mtn': [
        {'id': 'mtn-100mb', 'name': '100MB', 'price': 100, 'validity': '1 day'},
        {'id': 'mtn-1gb', 'name': '1GB', 'price': 300, 'validity': '30 days'},
        {'id': 'mtn-2gb', 'name': '2GB', 'price': 500, 'validity': '30 days'},
        {'id': 'mtn-5gb', 'name': '5GB', 'price': 1500, 'validity': '30 days'},
        {'id': 'mtn-10gb', 'name': '10GB', 'price': 2500, 'validity': '30 days'},
    ],
    'airtel': [
        {'id': 'airtel-100mb', 'name': '100MB', 'price': 50, 'validity': '1 day'},
        {'id': 'airtel-1gb', 'name': '1GB', 'price': 250, 'validity': '30 days'},
        {'id': 'airtel-5gb', 'name': '5GB', 'price': 1200, 'validity': '30 days'},
        {'id': 'airtel-10gb', 'name': '10GB', 'price': 2000, 'validity': '30 days'},
    ],
    'glo': [
        {'id': 'glo-1gb', 'name': '1GB', 'price': 300, 'validity': '30 days'},
        {'id': 'glo-2gb', 'name': '2GB', 'price': 500, 'validity': '30 days'},
        {'id': 'glo-5gb', 'name': '5GB', 'price': 1500, 'validity': '30 days'},
    ],
    'etisalat': [
        {'id': '9mobile-1gb', 'name': '1GB', 'price': 300, 'validity': '30 days'},
        {'id': '9mobile-2gb', 'name': '2GB', 'price': 500, 'validity': '30 days'},
        {'id': '9mobile-5gb', 'name': '5GB', 'price': 1500, 'validity': '30 days'},
    ],
}

SERVICE_ID_MAP = {'mtn': 'mtn-data', 'airtel': 'airtel-data', 'glo': 'glo-data', 'etisalat': 'etisalat-data'}


async def get_data_plans(network: str) -> list:
    if settings.DEV_MODE:
        return MOCK_PLANS.get(network, [])
    try:
        async with httpx.AsyncClient(auth=(settings.VTPASS_API_KEY, settings.VTPASS_SECRET_KEY)) as client:
            resp = await client.get(
                f'{settings.VTPASS_BASE_URL}/service-variations',
                params={'serviceID': SERVICE_ID_MAP.get(network, network)},
                timeout=10,
            )
            variations = resp.json().get('content', {}).get('varations', [])
            return [
                {'id': v['variation_code'], 'name': v['name'], 'price': float(v['variation_amount']), 'validity': '30 days'}
                for v in variations
            ]
    except Exception:
        return MOCK_PLANS.get(network, [])


async def purchase_data(network: str, plan_id: str, phone: str) -> dict:
    reference = f'TUN-{int(time.time() * 1000)}-{random.randint(1000, 9999)}'
    if settings.DEV_MODE:
        return {'success': True, 'reference': reference, 'message': 'Data purchased (mock)'}
    try:
        async with httpx.AsyncClient(auth=(settings.VTPASS_API_KEY, settings.VTPASS_SECRET_KEY)) as client:
            resp = await client.post(
                f'{settings.VTPASS_BASE_URL}/pay',
                json={
                    'request_id': reference,
                    'serviceID': SERVICE_ID_MAP.get(network, network),
                    'variation_code': plan_id,
                    'phone': phone,
                    'billersCode': phone,
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

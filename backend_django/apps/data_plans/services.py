import time
import random
import httpx
from django.conf import settings

NETWORK_ID_MAP = {'mtn': '1', 'glo': '2', 'airtel': '3', 'etisalat': '4'}

MOCK_PLANS = {
    'mtn': [
        {'id': '1', 'name': '100MB', 'price': 100, 'validity': '1 day'},
        {'id': '2', 'name': '1GB', 'price': 300, 'validity': '30 days'},
        {'id': '3', 'name': '2GB', 'price': 500, 'validity': '30 days'},
        {'id': '4', 'name': '5GB', 'price': 1500, 'validity': '30 days'},
        {'id': '5', 'name': '10GB', 'price': 2500, 'validity': '30 days'},
    ],
    'airtel': [
        {'id': '10', 'name': '100MB', 'price': 50, 'validity': '1 day'},
        {'id': '11', 'name': '1GB', 'price': 250, 'validity': '30 days'},
        {'id': '12', 'name': '5GB', 'price': 1200, 'validity': '30 days'},
        {'id': '13', 'name': '10GB', 'price': 2000, 'validity': '30 days'},
    ],
    'glo': [
        {'id': '20', 'name': '1GB', 'price': 300, 'validity': '30 days'},
        {'id': '21', 'name': '2GB', 'price': 500, 'validity': '30 days'},
        {'id': '22', 'name': '5GB', 'price': 1500, 'validity': '30 days'},
    ],
    'etisalat': [
        {'id': '30', 'name': '1GB', 'price': 300, 'validity': '30 days'},
        {'id': '31', 'name': '2GB', 'price': 500, 'validity': '30 days'},
        {'id': '32', 'name': '5GB', 'price': 1500, 'validity': '30 days'},
    ],
}


async def get_data_plans(network: str) -> list:
    if settings.DEV_MODE:
        return MOCK_PLANS.get(network, [])
    headers = {'Authorization': f'Token {settings.GLADTIDING_API_KEY}'}
    try:
        async with httpx.AsyncClient() as client:
            resp = await client.get(
                f'{settings.GLADTIDING_BASE_URL}/data-plans/',
                params={'network': NETWORK_ID_MAP.get(network, network)},
                headers=headers,
                timeout=10,
            )
            plans = resp.json()
            return [
                {
                    'id': str(p['id']),
                    'name': p.get('data', ''),
                    'price': float(p.get('plan_amount', 0)),
                    'validity': p.get('month_validate', '30 days'),
                }
                for p in plans
            ]
    except Exception:
        return MOCK_PLANS.get(network, [])


async def purchase_data(network: str, plan_id: str, phone: str) -> dict:
    reference = f'TUN-{int(time.time() * 1000)}-{random.randint(1000, 9999)}'
    if settings.DEV_MODE:
        return {'success': True, 'reference': reference, 'message': 'Data purchased (mock)'}
    headers = {'Authorization': f'Token {settings.GLADTIDING_API_KEY}'}
    try:
        async with httpx.AsyncClient() as client:
            resp = await client.post(
                f'{settings.GLADTIDING_BASE_URL}/data/',
                json={
                    'network': NETWORK_ID_MAP.get(network, network),
                    'mobile_number': phone,
                    'plan': int(plan_id),
                    'Ported_number': True,
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

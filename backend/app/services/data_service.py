import logging
import random
import time
from typing import Any, Dict, List

import httpx

from app.config import settings

logger = logging.getLogger(__name__)

# VTPass service IDs for data bundles
NETWORK_DATA_SERVICE_ID: Dict[str, str] = {
    "mtn": "mtn-data",
    "airtel": "airtel-data",
    "glo": "glo-data",
    "etisalat": "etisalat-data",
}

# Mock data plans keyed by network
MOCK_DATA_PLANS: Dict[str, List[Dict[str, Any]]] = {
    "mtn": [
        {"id": "mtn-100mb-1day", "name": "100MB", "price": 100.0, "validity": "1 Day"},
        {"id": "mtn-1gb-1month", "name": "1GB", "price": 300.0, "validity": "30 Days"},
        {"id": "mtn-2gb-1month", "name": "2GB", "price": 500.0, "validity": "30 Days"},
        {"id": "mtn-5gb-1month", "name": "5GB", "price": 1500.0, "validity": "30 Days"},
        {"id": "mtn-10gb-1month", "name": "10GB", "price": 2500.0, "validity": "30 Days"},
    ],
    "airtel": [
        {"id": "airtel-100mb-1day", "name": "100MB", "price": 100.0, "validity": "1 Day"},
        {"id": "airtel-1gb-1month", "name": "1GB", "price": 300.0, "validity": "30 Days"},
        {"id": "airtel-2gb-1month", "name": "2GB", "price": 500.0, "validity": "30 Days"},
        {"id": "airtel-5gb-1month", "name": "5GB", "price": 1500.0, "validity": "30 Days"},
        {"id": "airtel-10gb-1month", "name": "10GB", "price": 2500.0, "validity": "30 Days"},
    ],
    "glo": [
        {"id": "glo-100mb-1day", "name": "100MB", "price": 50.0, "validity": "1 Day"},
        {"id": "glo-1gb-1month", "name": "1GB", "price": 250.0, "validity": "30 Days"},
        {"id": "glo-2gb-1month", "name": "2GB", "price": 500.0, "validity": "30 Days"},
        {"id": "glo-5gb-1month", "name": "5GB", "price": 1200.0, "validity": "30 Days"},
        {"id": "glo-10gb-1month", "name": "10GB", "price": 2000.0, "validity": "30 Days"},
    ],
    "etisalat": [
        {"id": "etisalat-100mb-1day", "name": "100MB", "price": 100.0, "validity": "1 Day"},
        {"id": "etisalat-1gb-1month", "name": "1GB", "price": 300.0, "validity": "30 Days"},
        {"id": "etisalat-2gb-1month", "name": "2GB", "price": 500.0, "validity": "30 Days"},
        {"id": "etisalat-5gb-1month", "name": "5GB", "price": 1500.0, "validity": "30 Days"},
        {"id": "etisalat-10gb-1month", "name": "10GB", "price": 2500.0, "validity": "30 Days"},
    ],
}


def _generate_reference() -> str:
    """Generate a unique transaction reference in TUN-{timestamp}-{random4} format."""
    timestamp = int(time.time() * 1000)
    suffix = random.randint(1000, 9999)
    return f"TUN-{timestamp}-{suffix}"


async def get_data_plans(network: str) -> List[Dict[str, Any]]:
    """
    Fetch available data plans for a network from VTPass.

    In DEV_MODE, returns mock plans.

    Args:
        network: One of mtn, airtel, glo, etisalat.

    Returns:
        List of plan dicts with keys: id, name, price, validity.
    """
    if settings.dev_mode:
        logger.info("[DEV MODE] Returning mock data plans for network: %s", network)
        return MOCK_DATA_PLANS.get(network, [])

    service_id = NETWORK_DATA_SERVICE_ID.get(network)
    if not service_id:
        logger.error("Unknown network for data plans: %s", network)
        return []

    url = f"{settings.vtpass_base_url}/service-variations"
    params = {"serviceID": service_id}
    headers = {
        "api-key": settings.vtpass_api_key,
        "secret-key": settings.vtpass_secret_key,
    }

    try:
        async with httpx.AsyncClient(timeout=15.0) as client:
            response = await client.get(url, params=params, headers=headers)
            response.raise_for_status()
            data = response.json()
            logger.info("VTPass data plans response: %s", data)

            variations = data.get("content", {}).get("varations", [])
            plans: List[Dict[str, Any]] = []
            for v in variations:
                plans.append({
                    "id": v.get("variation_code", ""),
                    "name": v.get("name", ""),
                    "price": float(v.get("variation_amount", 0)),
                    "validity": v.get("fixedPrice", "N/A"),
                })
            return plans

    except httpx.HTTPError as exc:
        logger.error("VTPass HTTP error fetching data plans: %s", exc)
        return []


async def purchase_data(
    network: str,
    plan_id: str,
    phone: str,
) -> Dict[str, Any]:
    """
    Purchase a data bundle via VTPass.

    In DEV_MODE, returns a mock success response.

    Args:
        network: One of mtn, airtel, glo, etisalat.
        plan_id: The variation code / plan ID.
        phone:   Recipient phone in +234XXXXXXXXX format.

    Returns:
        Dict with keys: success (bool), reference (str), message (str).
    """
    reference = _generate_reference()

    if settings.dev_mode:
        logger.info(
            "[DEV MODE] Mock data purchase — network=%s, plan_id=%s, phone=%s, ref=%s",
            network, plan_id, phone, reference,
        )
        return {
            "success": True,
            "reference": reference,
            "message": "Data purchase successful (dev mode)",
        }

    service_id = NETWORK_DATA_SERVICE_ID.get(network)
    if not service_id:
        return {"success": False, "reference": reference, "message": f"Unknown network: {network}"}

    vtpass_phone = phone.lstrip("+")

    payload = {
        "request_id": reference,
        "serviceID": service_id,
        "variation_code": plan_id,
        "phone": vtpass_phone,
        "billersCode": vtpass_phone,
    }

    headers = {
        "api-key": settings.vtpass_api_key,
        "secret-key": settings.vtpass_secret_key,
        "Content-Type": "application/json",
    }

    url = f"{settings.vtpass_base_url}/pay"

    try:
        async with httpx.AsyncClient(timeout=30.0) as client:
            response = await client.post(url, json=payload, headers=headers)
            response.raise_for_status()
            data = response.json()
            logger.info("VTPass data response: %s", data)

            vtpass_code = data.get("code", "")
            if vtpass_code == "000":
                return {
                    "success": True,
                    "reference": reference,
                    "message": "Data purchase successful",
                }
            else:
                error_msg = data.get("response_description", "VTPass data purchase failed")
                logger.error("VTPass data failed: %s", data)
                return {"success": False, "reference": reference, "message": error_msg}

    except httpx.HTTPError as exc:
        logger.error("VTPass HTTP error during data purchase: %s", exc)
        return {"success": False, "reference": reference, "message": "Network error contacting VTPass"}

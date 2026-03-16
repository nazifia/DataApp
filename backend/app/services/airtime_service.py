import logging
import random
import time
from typing import Any, Dict

import httpx

from app.config import settings

logger = logging.getLogger(__name__)

# VTPass network service IDs for airtime
NETWORK_AIRTIME_SERVICE_ID: Dict[str, str] = {
    "mtn": "mtn",
    "airtel": "airtel",
    "glo": "glo",
    "etisalat": "etisalat",
}


def _generate_reference() -> str:
    """Generate a unique transaction reference in TUN-{timestamp}-{random4} format."""
    timestamp = int(time.time() * 1000)
    suffix = random.randint(1000, 9999)
    return f"TUN-{timestamp}-{suffix}"


async def purchase_airtime(
    network: str,
    phone: str,
    amount: float,
) -> Dict[str, Any]:
    """
    Purchase airtime via VTPass.

    In DEV_MODE, returns a mock success response without calling VTPass.

    Args:
        network: One of mtn, airtel, glo, etisalat.
        phone:   Recipient phone number in +234XXXXXXXXX format.
        amount:  Amount in NGN.

    Returns:
        Dict with keys: success (bool), reference (str), message (str).
    """
    reference = _generate_reference()

    if settings.dev_mode:
        logger.info(
            "[DEV MODE] Mock airtime purchase — network=%s, phone=%s, amount=%.2f, ref=%s",
            network, phone, amount, reference,
        )
        return {
            "success": True,
            "reference": reference,
            "message": "Airtime purchase successful (dev mode)",
        }

    service_id = NETWORK_AIRTIME_SERVICE_ID.get(network)
    if not service_id:
        return {"success": False, "reference": reference, "message": f"Unknown network: {network}"}

    # Strip the '+' sign for VTPass — it expects the number without it
    vtpass_phone = phone.lstrip("+")

    payload = {
        "request_id": reference,
        "serviceID": service_id,
        "amount": str(int(amount)),
        "phone": vtpass_phone,
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
            logger.info("VTPass airtime response: %s", data)

            vtpass_code = data.get("code", "")
            if vtpass_code == "000":
                return {
                    "success": True,
                    "reference": reference,
                    "message": "Airtime purchase successful",
                }
            else:
                error_msg = data.get("response_description", "VTPass purchase failed")
                logger.error("VTPass airtime failed: %s", data)
                return {"success": False, "reference": reference, "message": error_msg}

    except httpx.HTTPError as exc:
        logger.error("VTPass HTTP error during airtime purchase: %s", exc)
        return {"success": False, "reference": reference, "message": "Network error contacting VTPass"}

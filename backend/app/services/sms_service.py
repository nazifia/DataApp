import logging

import httpx

from app.config import settings

logger = logging.getLogger(__name__)

TERMII_SMS_URL = "https://api.ng.termii.com/api/sms/send"


async def send_otp_sms(phone: str, otp: str) -> bool:
    """
    Send an OTP via SMS using Termii.

    In DEV_MODE, the OTP is only logged and no real SMS is sent.

    Args:
        phone: Phone number in +234XXXXXXXXX format.
        otp:   The 6-digit OTP to send.

    Returns:
        True on success, False on failure.
    """
    message = f"Your ADP verification code is {otp}. It expires in 10 minutes. Do not share it with anyone."

    if settings.dev_mode:
        logger.info(
            "[DEV MODE] SMS not sent. OTP for %s is: %s",
            phone,
            otp,
        )
        print(f"[DEV MODE] OTP for {phone}: {otp}")
        return True

    payload = {
        "api_key": settings.termii_api_key,
        "to": phone,
        "from": settings.termii_sender_id,
        "sms": message,
        "type": "plain",
        "channel": "dnd",
    }

    try:
        async with httpx.AsyncClient(timeout=15.0) as client:
            response = await client.post(TERMII_SMS_URL, json=payload)
            response.raise_for_status()
            data = response.json()
            logger.info("Termii SMS response: %s", data)
            # Termii returns a message_id on success
            if "message_id" in data or data.get("code") == "ok":
                return True
            logger.warning("Termii unexpected response: %s", data)
            return False
    except httpx.HTTPError as exc:
        logger.error("Failed to send SMS via Termii: %s", exc)
        return False

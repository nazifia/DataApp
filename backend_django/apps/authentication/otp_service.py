import random
import httpx
from django.utils import timezone
from datetime import timedelta
from django.conf import settings
from .models import OTPRecord


def generate_otp() -> str:
    return str(random.randint(100000, 999999))


def save_otp(tenant, phone: str) -> str:
    otp = generate_otp()
    OTPRecord.objects.filter(tenant=tenant, phone_number=phone, used=False).update(used=True)
    OTPRecord.objects.create(
        tenant=tenant,
        phone_number=phone,
        otp=otp,
        expires_at=timezone.now() + timedelta(minutes=10),
    )
    return otp


def verify_otp(tenant, phone: str, otp: str) -> bool:
    if settings.DEV_MODE and otp == settings.TEST_OTP:
        return True
    try:
        record = OTPRecord.objects.get(
            tenant=tenant,
            phone_number=phone,
            otp=otp,
            used=False,
        )
        if record.is_expired:
            return False
        record.used = True
        record.save()
        return True
    except OTPRecord.DoesNotExist:
        return False


async def send_otp_sms(phone: str, otp: str) -> bool:
    if settings.DEV_MODE:
        print(f'[DEV] OTP for {phone}: {otp}')
        return True
    try:
        async with httpx.AsyncClient() as client:
            resp = await client.post(
                'https://api.ng.termii.com/api/sms/send',
                json={
                    'api_key': settings.TERMII_API_KEY,
                    'to': phone,
                    'from': settings.TERMII_SENDER_ID,
                    'sms': f'Your TopUpNaija OTP is {otp}. Valid for 10 minutes. Do not share.',
                    'type': 'plain',
                    'channel': 'dnd',
                },
                timeout=10,
            )
            return resp.status_code == 200
    except Exception:
        return False

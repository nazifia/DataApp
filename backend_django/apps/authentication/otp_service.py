import random
import httpx
from django.utils import timezone
from datetime import timedelta
from django.conf import settings
from core.runtime import is_dev_mode, ais_dev_mode
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
    if is_dev_mode() and otp == settings.TEST_OTP:
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
    if await ais_dev_mode():
        print(f'[DEV] OTP for {phone}: {otp}')
        return True
    try:
        async with httpx.AsyncClient() as client:
            resp = await client.post(
                'https://api.africastalking.com/version1/messaging',
                headers={
                    'apiKey': settings.AT_API_KEY,
                    'Content-Type': 'application/x-www-form-urlencoded',
                    'Accept': 'application/json',
                },
                data={
                    'username': settings.AT_USERNAME,
                    'to': phone,
                    'from': settings.AT_SENDER_ID,
                    'message': f'Your TopUpNaija OTP is {otp}. Valid for 10 minutes. Do not share.',
                },
                timeout=10,
            )
            return resp.status_code == 201
    except Exception:
        return False

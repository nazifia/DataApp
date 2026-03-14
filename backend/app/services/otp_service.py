import random
import string
from datetime import datetime, timedelta
from typing import Dict, Optional, Tuple

from app.config import settings

# In-memory OTP store: {phone_number: (otp, expires_at)}
_otp_store: Dict[str, Tuple[str, datetime]] = {}

OTP_EXPIRY_MINUTES = 10


def generate_otp() -> str:
    """Generate a random 6-digit OTP string."""
    return "".join(random.choices(string.digits, k=6))


def save_otp(phone: str, otp: str) -> None:
    """Store the OTP for the given phone number with a 10-minute expiry."""
    expires_at = datetime.utcnow() + timedelta(minutes=OTP_EXPIRY_MINUTES)
    _otp_store[phone] = (otp, expires_at)


def verify_otp(phone: str, otp: str) -> bool:
    """
    Verify an OTP for the given phone number.

    In DEV_MODE, the TEST_OTP is always accepted without being stored.
    On success, the OTP is removed from the store.

    Returns True if valid, False otherwise.
    """
    # In dev mode, always accept the test OTP
    if settings.dev_mode and otp == settings.test_otp:
        # Remove any stored OTP for this phone to keep store clean
        _otp_store.pop(phone, None)
        return True

    entry = _otp_store.get(phone)
    if entry is None:
        return False

    stored_otp, expires_at = entry

    # Check expiry
    if datetime.utcnow() > expires_at:
        _otp_store.pop(phone, None)
        return False

    # Check OTP value
    if otp != stored_otp:
        return False

    # Valid — remove so it cannot be reused
    _otp_store.pop(phone, None)
    return True


def clear_expired_otps() -> None:
    """Remove all expired OTPs from the store. Call periodically if needed."""
    now = datetime.utcnow()
    expired_keys = [phone for phone, (_, exp) in _otp_store.items() if now > exp]
    for key in expired_keys:
        _otp_store.pop(key, None)

import re
from typing import Optional


# Regex patterns for Nigerian phone numbers
_LOCAL_PATTERN = re.compile(r"^0([7-9][01]\d{8})$")           # 0XXXXXXXXXX (11 digits)
_INTL_PATTERN = re.compile(r"^\+234([7-9][01]\d{8})$")        # +234XXXXXXXXX (international)
_INTL_NO_PLUS = re.compile(r"^234([7-9][01]\d{8})$")          # 234XXXXXXXXX (no plus sign)


def normalize_phone_number(phone: str) -> Optional[str]:
    """
    Normalize a Nigerian phone number to international format (+234XXXXXXXXX).

    Accepts:
      - 08XXXXXXXXX  (local format, 11 digits)
      - 07XXXXXXXXX  (local format, 11 digits)
      - 09XXXXXXXXX  (local format, 11 digits)
      - +2348XXXXXXXXX (international format)
      - 2348XXXXXXXXX  (international without plus)

    Returns:
      +234XXXXXXXXX string, or None if invalid.
    """
    phone = phone.strip().replace(" ", "").replace("-", "")

    # Already in +234 format
    match = _INTL_PATTERN.match(phone)
    if match:
        return phone

    # 234XXXXXXXXX format (no plus)
    match = _INTL_NO_PLUS.match(phone)
    if match:
        return f"+234{match.group(1)}"

    # 0XXXXXXXXXX local format
    match = _LOCAL_PATTERN.match(phone)
    if match:
        return f"+234{match.group(1)}"

    return None


def to_local_format(phone: str) -> Optional[str]:
    """
    Convert a +234XXXXXXXXX number to local format 0XXXXXXXXXX.

    Returns:
      0XXXXXXXXXX string, or None if invalid.
    """
    phone = phone.strip()
    match = _INTL_PATTERN.match(phone)
    if match:
        return f"0{match.group(1)}"
    return None

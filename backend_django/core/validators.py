import re
from rest_framework import serializers


def normalize_phone_number(phone: str) -> str | None:
    """Normalize any Nigerian phone format to +234XXXXXXXXXX."""
    phone = re.sub(r'\s+', '', phone)
    if re.match(r'^\+234[789][01]\d{8}$', phone):
        return phone
    if re.match(r'^234[789][01]\d{8}$', phone):
        return '+' + phone
    if re.match(r'^0[789][01]\d{8}$', phone):
        return '+234' + phone[1:]
    return None


def to_local_format(phone: str) -> str:
    """Convert +234XXXXXXXXXX to 0XXXXXXXXXX."""
    if phone.startswith('+234'):
        return '0' + phone[4:]
    return phone


class NigerianPhoneField(serializers.CharField):
    def to_internal_value(self, data):
        value = super().to_internal_value(data)
        normalized = normalize_phone_number(value)
        if normalized is None:
            raise serializers.ValidationError('Enter a valid Nigerian phone number.')
        return normalized

from pydantic import BaseModel, field_validator
from app.utils.validators import normalize_phone_number


class SendOTPRequest(BaseModel):
    phone_number: str

    @field_validator("phone_number")
    @classmethod
    def validate_phone_number(cls, v: str) -> str:
        normalized = normalize_phone_number(v)
        if normalized is None:
            raise ValueError("Invalid Nigerian phone number. Use format: 08XXXXXXXXX or +2348XXXXXXXXX")
        return normalized


class SendOTPResponse(BaseModel):
    message: str
    phone_number: str


class VerifyOTPRequest(BaseModel):
    phone_number: str
    otp: str

    @field_validator("phone_number")
    @classmethod
    def validate_phone_number(cls, v: str) -> str:
        normalized = normalize_phone_number(v)
        if normalized is None:
            raise ValueError("Invalid Nigerian phone number. Use format: 08XXXXXXXXX or +2348XXXXXXXXX")
        return normalized


class VerifyOTPResponse(BaseModel):
    message: str
    access_token: str
    refresh_token: str
    is_new_user: bool


class TokenData(BaseModel):
    user_id: str


class RefreshTokenRequest(BaseModel):
    refresh_token: str


class RefreshTokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"

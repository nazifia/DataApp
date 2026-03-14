from datetime import datetime
from typing import Optional
from uuid import UUID

from pydantic import BaseModel, field_validator
from app.utils.validators import normalize_phone_number


class CreateProfileRequest(BaseModel):
    phone_number: str
    full_name: str
    password: str
    device_id: Optional[str] = None

    @field_validator("phone_number")
    @classmethod
    def validate_phone_number(cls, v: str) -> str:
        normalized = normalize_phone_number(v)
        if normalized is None:
            raise ValueError("Invalid Nigerian phone number.")
        return normalized

    @field_validator("full_name")
    @classmethod
    def validate_full_name(cls, v: str) -> str:
        v = v.strip()
        if len(v) < 2:
            raise ValueError("Full name must be at least 2 characters.")
        return v


class UpdateProfileRequest(BaseModel):
    full_name: str

    @field_validator("full_name")
    @classmethod
    def validate_full_name(cls, v: str) -> str:
        v = v.strip()
        if len(v) < 2:
            raise ValueError("Full name must be at least 2 characters.")
        return v


class UserResponse(BaseModel):
    id: UUID
    phone_number: str
    full_name: Optional[str]
    device_id: Optional[str]
    is_active: bool
    created_at: datetime
    updated_at: datetime

    model_config = {"from_attributes": True}


class UserProfileResponse(BaseModel):
    user: UserResponse


class UpdateProfileResponse(BaseModel):
    message: str
    user: UserResponse

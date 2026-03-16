from datetime import datetime
from typing import List, Optional
from uuid import UUID

from pydantic import BaseModel, field_validator
from app.utils.validators import normalize_phone_number

VALID_NETWORKS = {"mtn", "airtel", "glo", "etisalat"}


class AirtimePurchaseRequest(BaseModel):
    network: str
    phone_number: str
    amount: float

    @field_validator("network")
    @classmethod
    def validate_network(cls, v: str) -> str:
        v = v.lower().strip()
        if v not in VALID_NETWORKS:
            raise ValueError(f"Invalid network. Must be one of: {', '.join(VALID_NETWORKS)}")
        return v

    @field_validator("phone_number")
    @classmethod
    def validate_phone_number(cls, v: str) -> str:
        normalized = normalize_phone_number(v)
        if normalized is None:
            raise ValueError("Invalid Nigerian phone number.")
        return normalized

    @field_validator("amount")
    @classmethod
    def validate_amount(cls, v: float) -> float:
        if v < 50:
            raise ValueError("Minimum airtime purchase is NGN 50.")
        if v > 50000:
            raise ValueError("Maximum airtime purchase is NGN 50,000.")
        return v


class AirtimePurchaseResponse(BaseModel):
    message: str
    reference: str
    amount: float
    network: str
    phone_number: str


class DataPlanItem(BaseModel):
    id: str
    name: str
    price: float
    validity: str


class DataPlansResponse(BaseModel):
    plans: List[DataPlanItem]


class DataPurchaseRequest(BaseModel):
    network: str
    plan_id: str
    phone_number: str

    @field_validator("network")
    @classmethod
    def validate_network(cls, v: str) -> str:
        v = v.lower().strip()
        if v not in VALID_NETWORKS:
            raise ValueError(f"Invalid network. Must be one of: {', '.join(VALID_NETWORKS)}")
        return v

    @field_validator("phone_number")
    @classmethod
    def validate_phone_number(cls, v: str) -> str:
        normalized = normalize_phone_number(v)
        if normalized is None:
            raise ValueError("Invalid Nigerian phone number.")
        return normalized


class DataPurchaseResponse(BaseModel):
    message: str
    reference: str
    plan_id: str
    network: str
    phone_number: str


class TransactionItem(BaseModel):
    id: UUID
    type: str
    amount: float
    status: str
    reference: str
    network: Optional[str]
    phone_number: Optional[str]
    created_at: datetime
    is_reversed: bool = False

    model_config = {"from_attributes": True}


class TransactionListResponse(BaseModel):
    transactions: List[TransactionItem]

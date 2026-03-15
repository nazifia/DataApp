from datetime import datetime
from decimal import Decimal
from typing import Generic, List, Optional, TypeVar

from pydantic import BaseModel, Field

T = TypeVar("T")


# --- Dashboard ---
class DashboardStats(BaseModel):
    total_users: int
    active_users: int
    total_transactions: int
    successful_transactions: int
    total_revenue: float
    total_wallet_balance: float
    today_transactions: int
    today_revenue: float


# --- Users ---
class AdminUserListItem(BaseModel):
    id: str
    phone_number: str
    full_name: Optional[str]
    is_active: bool
    role: str
    created_at: datetime
    wallet_balance: Optional[float] = None

    class Config:
        from_attributes = True


class AdminUserDetail(BaseModel):
    id: str
    phone_number: str
    full_name: Optional[str]
    device_id: Optional[str]
    is_active: bool
    role: str
    created_at: datetime
    updated_at: datetime
    wallet_balance: float = 0.0
    total_transactions: int = 0
    total_spent: float = 0.0

    class Config:
        from_attributes = True


# --- Transactions ---
class AdminTransactionItem(BaseModel):
    id: str
    user_id: str
    user_phone: Optional[str] = None
    user_name: Optional[str] = None
    type: str
    amount: float
    status: str
    reference: str
    network: Optional[str]
    phone_number: Optional[str]
    plan_id: Optional[str]
    created_at: datetime

    class Config:
        from_attributes = True


# --- Wallets ---
class AdminWalletItem(BaseModel):
    id: str
    user_id: str
    user_phone: str
    user_name: Optional[str]
    balance: float
    updated_at: datetime

    class Config:
        from_attributes = True


class AdminWalletCreditRequest(BaseModel):
    amount: float = Field(..., gt=0, description="Amount to credit (must be positive)")
    reason: str = Field(..., min_length=3, description="Reason for crediting")


class AdminWalletDebitRequest(BaseModel):
    amount: float = Field(..., gt=0, description="Amount to debit (must be positive)")
    reason: str = Field(..., min_length=3, description="Reason for debiting")


# --- Data Plans ---
class AdminDataPlanItem(BaseModel):
    id: str
    network: str
    plan_code: str
    name: str
    price: float
    validity: str
    is_active: bool
    created_at: Optional[datetime] = None


class AdminDataPlanCreateRequest(BaseModel):
    network: str = Field(..., min_length=2)
    plan_code: str = Field(..., min_length=1)
    name: str = Field(..., min_length=1)
    price: float = Field(..., gt=0)
    validity: str = Field(..., min_length=1)
    is_active: bool = True


# --- Settings ---
class AdminSettingsResponse(BaseModel):
    dev_mode: bool
    database_type: str
    sms_provider: str
    vtpass_configured: bool


# --- Audit Logs ---
class AdminAuditLogItem(BaseModel):
    id: str
    admin_id: str
    admin_phone: Optional[str] = None
    admin_name: Optional[str] = None
    action: str
    target_type: Optional[str]
    target_id: Optional[str]
    details: Optional[str]
    ip_address: Optional[str]
    created_at: datetime

    class Config:
        from_attributes = True


# --- Pagination ---
class PaginatedResponse(BaseModel, Generic[T]):
    items: List[T]
    total: int
    page: int
    page_size: int
    total_pages: int

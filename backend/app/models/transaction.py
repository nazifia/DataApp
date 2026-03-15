import uuid
import enum
from datetime import datetime

from sqlalchemy import Column, DateTime, Enum, ForeignKey, Numeric, String
from sqlalchemy.orm import relationship

from app.database import Base
from app.models.user import GUID


class TransactionType(str, enum.Enum):
    airtime = "airtime"
    data = "data"
    wallet_fund = "wallet_fund"
    refund = "refund"


class TransactionStatus(str, enum.Enum):
    pending = "pending"
    success = "success"
    failed = "failed"


class Transaction(Base):
    __tablename__ = "transactions"

    id = Column(GUID(), primary_key=True, default=uuid.uuid4, index=True)
    user_id = Column(GUID(), ForeignKey("users.id"), nullable=False, index=True)
    type = Column(Enum(TransactionType), nullable=False)
    amount = Column(Numeric(10, 2), nullable=False)
    status = Column(Enum(TransactionStatus), nullable=False, default=TransactionStatus.pending)
    reference = Column(String, unique=True, nullable=False, index=True)
    network = Column(String, nullable=True)
    phone_number = Column(String, nullable=True)
    plan_id = Column(String, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)

    # Relationships
    user = relationship("User", back_populates="transactions")

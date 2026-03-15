import uuid
from datetime import datetime

from sqlalchemy import Column, DateTime, ForeignKey, Numeric
from sqlalchemy.orm import relationship

from app.database import Base
from app.models.user import GUID


class Wallet(Base):
    __tablename__ = "wallets"

    id = Column(GUID(), primary_key=True, default=uuid.uuid4, index=True)
    user_id = Column(GUID(), ForeignKey("users.id"), unique=True, nullable=False)
    balance = Column(Numeric(10, 2), default=0, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False)

    # Relationships
    user = relationship("User", back_populates="wallet")

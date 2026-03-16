import uuid
import enum
from datetime import datetime

from sqlalchemy import Boolean, Column, DateTime, Enum, String
from sqlalchemy.orm import relationship
from sqlalchemy.types import TypeDecorator, CHAR
import sqlalchemy as sa

from app.database import Base


class UserRole(str, enum.Enum):
    user = "user"
    support = "support"
    moderator = "moderator"
    admin = "admin"
    super_admin = "super_admin"


class GUID(TypeDecorator):
    """Platform-independent GUID type: uses PostgreSQL UUID, falls back to CHAR(36) for SQLite."""
    impl = CHAR
    cache_ok = True

    def load_dialect_impl(self, dialect):
        if dialect.name == 'postgresql':
            from sqlalchemy.dialects.postgresql import UUID as PG_UUID
            return dialect.type_descriptor(PG_UUID(as_uuid=True))
        return dialect.type_descriptor(CHAR(36))

    def process_bind_param(self, value, dialect):
        if value is None:
            return value
        if dialect.name == 'postgresql':
            return str(value)
        return str(value)

    def process_result_value(self, value, dialect):
        if value is None:
            return value
        return uuid.UUID(str(value))


class User(Base):
    __tablename__ = "users"

    id = Column(GUID(), primary_key=True, default=uuid.uuid4, index=True)
    phone_number = Column(String, unique=True, nullable=False, index=True)
    full_name = Column(String, nullable=True)
    password_hash = Column(String, nullable=True)
    device_id = Column(String, nullable=True)
    profile_picture_url = Column(String, nullable=True)
    is_active = Column(Boolean, default=True, nullable=False)
    role = Column(Enum(UserRole, create_constraint=False), default=UserRole.user, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False)

    # Relationships
    wallet = relationship("Wallet", back_populates="user", uselist=False)
    transactions = relationship("Transaction", back_populates="user")

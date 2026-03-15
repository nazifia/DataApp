import uuid
from datetime import datetime

from sqlalchemy import Column, DateTime, ForeignKey, String, Text

from app.database import Base
from app.models.user import GUID


class AdminAuditLog(Base):
    __tablename__ = "admin_audit_logs"

    id = Column(GUID(), primary_key=True, default=uuid.uuid4, index=True)
    admin_id = Column(GUID(), ForeignKey("users.id"), nullable=False, index=True)
    action = Column(String, nullable=False, index=True)
    target_type = Column(String, nullable=True)
    target_id = Column(String, nullable=True)
    details = Column(Text, nullable=True)
    ip_address = Column(String, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False, index=True)

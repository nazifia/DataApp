import uuid
from datetime import datetime, timedelta
from typing import Optional

from fastapi import Depends, HTTPException, Request, status
from jose import JWTError, jwt
from sqlalchemy.orm import Session

from app.config import settings
from app.database import get_db
from app.models.user import User, UserRole
from app.models.audit_log import AdminAuditLog


def create_admin_session_token(user_id: str) -> str:
    """Create a JWT token for admin session with 8-hour expiry."""
    expire = datetime.utcnow() + timedelta(hours=8)
    payload = {
        "sub": str(user_id),
        "type": "admin_session",
        "exp": expire,
    }
    return jwt.encode(payload, settings.secret_key, algorithm=settings.algorithm)


def decode_admin_token(token: str) -> dict:
    """Decode and validate an admin session JWT token."""
    try:
        payload = jwt.decode(token, settings.secret_key, algorithms=[settings.algorithm])
        return payload
    except JWTError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired admin session",
        )


async def get_current_admin(
    request: Request,
    db: Session = Depends(get_db),
) -> User:
    """
    Dependency that extracts admin session from cookie or Authorization header,
    validates it, and returns the admin User.
    """
    token = None

    # Try cookie first
    token = request.cookies.get("admin_session")

    # Fall back to Authorization header
    if not token:
        auth_header = request.headers.get("Authorization")
        if auth_header and auth_header.startswith("Bearer "):
            token = auth_header.split(" ", 1)[1]

    if not token:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="No admin session found",
        )

    payload = decode_admin_token(token)

    # Verify token type
    token_type = payload.get("type")
    if token_type != "admin_session":
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token type for admin access",
        )

    user_id = payload.get("sub")
    if not user_id:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token payload",
        )

    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Admin user not found",
        )

    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Admin account is inactive",
        )

    if user.role != UserRole.admin:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Access denied: admin role required",
        )

    return user


def log_admin_action(
    db: Session,
    admin_id: uuid.UUID,
    action: str,
    target_type: Optional[str] = None,
    target_id: Optional[str] = None,
    details: Optional[str] = None,
    ip: Optional[str] = None,
) -> AdminAuditLog:
    """Insert an admin audit log entry."""
    log_entry = AdminAuditLog(
        admin_id=admin_id,
        action=action,
        target_type=target_type,
        target_id=target_id,
        details=details,
        ip_address=ip,
    )
    db.add(log_entry)
    db.commit()
    db.refresh(log_entry)
    return log_entry

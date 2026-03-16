import math
from datetime import datetime
from typing import Optional

from fastapi import APIRouter, Depends, Query
from sqlalchemy import or_
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.user import User, UserRole
from app.models.audit_log import AdminAuditLog
from app.schemas.admin import AdminAuditLogItem, PaginatedResponse
from app.utils.admin_auth import get_current_admin, require_role

router = APIRouter(tags=["Admin Audit"])


@router.get("/audit-logs", response_model=PaginatedResponse[AdminAuditLogItem])
async def list_audit_logs(
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    action: Optional[str] = None,
    admin_id: Optional[str] = None,
    date_from: Optional[str] = None,
    date_to: Optional[str] = None,
    db: Session = Depends(get_db),
    admin: User = Depends(require_role(UserRole.admin)),
):
    """List admin audit logs with pagination and filters."""
    query = db.query(AdminAuditLog)

    if action:
        query = query.filter(AdminAuditLog.action.ilike(f"%{action}%"))

    if admin_id:
        query = query.filter(AdminAuditLog.admin_id == admin_id)

    if date_from:
        try:
            from_date = datetime.strptime(date_from, "%Y-%m-%d")
            query = query.filter(AdminAuditLog.created_at >= from_date)
        except ValueError:
            pass

    if date_to:
        try:
            to_date = datetime.strptime(date_to, "%Y-%m-%d")
            to_date = to_date.replace(hour=23, minute=59, second=59)
            query = query.filter(AdminAuditLog.created_at <= to_date)
        except ValueError:
            pass

    total = query.count()
    logs = (
        query.order_by(AdminAuditLog.created_at.desc())
        .offset((page - 1) * page_size)
        .limit(page_size)
        .all()
    )

    # Get admin details
    admin_ids = [log.admin_id for log in logs]
    admins = db.query(User).filter(User.id.in_(admin_ids)).all()
    admin_map = {str(a.id): a for a in admins}

    items = []
    for log in logs:
        admin_user = admin_map.get(str(log.admin_id))
        items.append(
            AdminAuditLogItem(
                id=str(log.id),
                admin_id=str(log.admin_id),
                admin_phone=admin_user.phone_number if admin_user else None,
                admin_name=admin_user.full_name if admin_user else None,
                action=log.action,
                target_type=log.target_type,
                target_id=log.target_id,
                details=log.details,
                ip_address=log.ip_address,
                created_at=log.created_at,
            )
        )

    return PaginatedResponse(
        items=items,
        total=total,
        page=page,
        page_size=page_size,
        total_pages=math.ceil(total / page_size) if total > 0 else 1,
    )

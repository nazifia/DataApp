from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session, joinedload

from app.database import get_db
from app.models.user import User
from app.models.transaction import Transaction
from app.schemas.admin import DashboardStats, AdminTransactionItem, AdminUserListItem
from app.services.admin_service import get_dashboard_stats
from app.utils.admin_auth import get_current_admin

router = APIRouter(tags=["Admin Dashboard"])


@router.get("/stats", response_model=DashboardStats)
async def dashboard_stats(
    db: Session = Depends(get_db),
    admin: User = Depends(get_current_admin),
):
    """Get aggregate stats for the admin dashboard."""
    return get_dashboard_stats(db)


@router.get("/recent-transactions", response_model=list[AdminTransactionItem])
async def recent_transactions(
    db: Session = Depends(get_db),
    admin: User = Depends(get_current_admin),
):
    """Get the 20 most recent transactions."""
    txns = (
        db.query(Transaction)
        .options(joinedload(Transaction.user))
        .order_by(Transaction.created_at.desc())
        .limit(20)
        .all()
    )

    return [
        AdminTransactionItem(
            id=str(txn.id),
            user_id=str(txn.user_id),
            user_phone=txn.user.phone_number if txn.user else None,
            user_name=txn.user.full_name if txn.user else None,
            type=txn.type.value if hasattr(txn.type, "value") else str(txn.type),
            amount=float(txn.amount),
            status=txn.status.value if hasattr(txn.status, "value") else str(txn.status),
            reference=txn.reference,
            network=txn.network,
            phone_number=txn.phone_number,
            plan_id=txn.plan_id,
            created_at=txn.created_at,
        )
        for txn in txns
    ]


@router.get("/recent-users", response_model=list[AdminUserListItem])
async def recent_users(
    db: Session = Depends(get_db),
    admin: User = Depends(get_current_admin),
):
    """Get the 10 most recently registered users."""
    users = db.query(User).order_by(User.created_at.desc()).limit(10).all()

    return [
        AdminUserListItem(
            id=str(user.id),
            phone_number=user.phone_number,
            full_name=user.full_name,
            is_active=user.is_active,
            role=user.role.value if hasattr(user.role, "value") else str(user.role),
            created_at=user.created_at,
        )
        for user in users
    ]

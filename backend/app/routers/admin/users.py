import math
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import or_
from sqlalchemy.orm import Session, joinedload

from app.database import get_db
from app.models.user import User
from app.models.wallet import Wallet
from app.models.transaction import Transaction, TransactionStatus
from app.schemas.admin import AdminUserListItem, AdminUserDetail, AdminTransactionItem, PaginatedResponse
from app.utils.admin_auth import get_current_admin, log_admin_action

router = APIRouter(tags=["Admin Users"])


@router.get("/users", response_model=PaginatedResponse[AdminUserListItem])
async def list_users(
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    search: Optional[str] = None,
    is_active: Optional[bool] = None,
    db: Session = Depends(get_db),
    admin: User = Depends(get_current_admin),
):
    """List users with pagination and filters."""
    query = db.query(User)

    if search:
        query = query.filter(
            or_(
                User.phone_number.ilike(f"%{search}%"),
                User.full_name.ilike(f"%{search}%"),
            )
        )

    if is_active is not None:
        query = query.filter(User.is_active == is_active)

    total = query.count()
    users = (
        query.order_by(User.created_at.desc())
        .offset((page - 1) * page_size)
        .limit(page_size)
        .all()
    )

    # Get wallet balances for each user
    user_ids = [user.id for user in users]
    wallets = db.query(Wallet).filter(Wallet.user_id.in_(user_ids)).all()
    wallet_map = {w.user_id: float(w.balance) for w in wallets}

    items = [
        AdminUserListItem(
            id=str(user.id),
            phone_number=user.phone_number,
            full_name=user.full_name,
            is_active=user.is_active,
            role=user.role.value if hasattr(user.role, "value") else str(user.role),
            created_at=user.created_at,
            wallet_balance=wallet_map.get(user.id, 0.0),
        )
        for user in users
    ]

    return PaginatedResponse(
        items=items,
        total=total,
        page=page,
        page_size=page_size,
        total_pages=math.ceil(total / page_size) if total > 0 else 1,
    )


@router.get("/users/{user_id}", response_model=AdminUserDetail)
async def get_user(
    user_id: str,
    db: Session = Depends(get_db),
    admin: User = Depends(get_current_admin),
):
    """Get detailed user information."""
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    wallet = db.query(Wallet).filter(Wallet.user_id == user.id).first()
    balance = float(wallet.balance) if wallet else 0.0

    txn_count = db.query(Transaction).filter(Transaction.user_id == user.id).count()
    total_spent = (
        db.query(Transaction)
        .filter(
            Transaction.user_id == user.id,
            Transaction.status == TransactionStatus.success,
        )
        .all()
    )
    total_spent_amount = sum(float(t.amount) for t in total_spent)

    return AdminUserDetail(
        id=str(user.id),
        phone_number=user.phone_number,
        full_name=user.full_name,
        device_id=user.device_id,
        is_active=user.is_active,
        role=user.role.value if hasattr(user.role, "value") else str(user.role),
        created_at=user.created_at,
        updated_at=user.updated_at,
        wallet_balance=balance,
        total_transactions=txn_count,
        total_spent=total_spent_amount,
    )


@router.put("/users/{user_id}/toggle-active")
async def toggle_user_active(
    user_id: str,
    request: dict,
    db: Session = Depends(get_db),
    admin: User = Depends(get_current_admin),
):
    """Toggle user active status."""
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    user.is_active = not user.is_active
    db.commit()

    log_admin_action(
        db,
        admin_id=admin.id,
        action="toggle_user_active",
        target_type="user",
        target_id=str(user.id),
        details=f"User {user.phone_number} {'activated' if user.is_active else 'deactivated'}",
    )

    return {"message": f"User {'activated' if user.is_active else 'deactivated'}", "is_active": user.is_active}


@router.get("/users/{user_id}/transactions", response_model=PaginatedResponse[AdminTransactionItem])
async def get_user_transactions(
    user_id: str,
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    db: Session = Depends(get_db),
    admin: User = Depends(get_current_admin),
):
    """Get transactions for a specific user."""
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    query = db.query(Transaction).filter(Transaction.user_id == user.id)
    total = query.count()
    txns = (
        query.order_by(Transaction.created_at.desc())
        .offset((page - 1) * page_size)
        .limit(page_size)
        .all()
    )

    items = [
        AdminTransactionItem(
            id=str(txn.id),
            user_id=str(txn.user_id),
            user_phone=user.phone_number,
            user_name=user.full_name,
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

    return PaginatedResponse(
        items=items,
        total=total,
        page=page,
        page_size=page_size,
        total_pages=math.ceil(total / page_size) if total > 0 else 1,
    )

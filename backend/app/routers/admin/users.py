import math
from typing import Optional

import bcrypt as bcrypt_lib
from fastapi import APIRouter, Depends, HTTPException, Query, Request
from sqlalchemy import or_
from sqlalchemy.orm import Session, joinedload

from app.database import get_db
from app.models.user import User, UserRole
from app.models.wallet import Wallet
from app.models.transaction import Transaction, TransactionStatus
from app.schemas.admin import (
    AdminUserListItem,
    AdminUserDetail,
    AdminTransactionItem,
    AdminCreateUserRequest,
    AdminCreateUserResponse,
    PaginatedResponse,
)
from app.utils.admin_auth import get_current_admin, log_admin_action, require_role, has_minimum_role

router = APIRouter(tags=["Admin Users"])


@router.get("", response_model=PaginatedResponse[AdminUserListItem])
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


@router.post("", response_model=AdminCreateUserResponse)
async def create_user(
    body: AdminCreateUserRequest,
    request: Request,
    db: Session = Depends(get_db),
    admin: User = Depends(get_current_admin),
):
    """Create a new user with role specification."""
    target_role = UserRole(body.role)

    # Permission checks
    # super_admin can assign any role
    if has_minimum_role(admin, UserRole.super_admin):
        pass  # Allowed
    # admin can only create user role
    elif has_minimum_role(admin, UserRole.admin):
        if target_role != UserRole.user:
            raise HTTPException(
                status_code=403,
                detail="Admins can only create users with the 'user' role",
            )
    # moderator/support are blocked
    else:
        raise HTTPException(
            status_code=403,
            detail="Access denied: insufficient permissions to create users",
        )

    # Check if phone number already exists
    existing = db.query(User).filter(User.phone_number == body.phone_number).first()
    if existing:
        raise HTTPException(status_code=400, detail="Phone number already registered")

    # Create user
    hashed_password = bcrypt_lib.hashpw(body.password.encode("utf-8"), bcrypt_lib.gensalt()).decode("utf-8")
    new_user = User(
        phone_number=body.phone_number,
        full_name=body.full_name,
        password_hash=hashed_password,
        is_active=body.is_active,
        role=target_role,
    )
    db.add(new_user)
    db.commit()
    db.refresh(new_user)

    # Audit log
    client_ip = request.client.host if request.client else None
    log_admin_action(
        db,
        admin_id=admin.id,
        action="create_user",
        target_type="user",
        target_id=str(new_user.id),
        details=f"Created user {body.phone_number} with role {target_role.value}",
        ip=client_ip,
    )

    return AdminCreateUserResponse(
        id=str(new_user.id),
        phone_number=new_user.phone_number,
        full_name=new_user.full_name,
        role=new_user.role.value,
        is_active=new_user.is_active,
        message=f"User created successfully with role {target_role.value}",
    )


@router.get("/{user_id}", response_model=AdminUserDetail)
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


@router.put("/{user_id}/role")
async def update_user_role(
    user_id: str,
    body: dict,
    request: Request,
    db: Session = Depends(get_db),
    admin: User = Depends(require_role(UserRole.super_admin)),
):
    """Update a user's role. Requires super_admin."""
    new_role_str = body.get("role")
    if not new_role_str:
        raise HTTPException(status_code=422, detail="'role' field is required")
    try:
        new_role = UserRole(new_role_str)
    except ValueError:
        raise HTTPException(status_code=422, detail=f"Invalid role '{new_role_str}'")

    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    old_role = user.role
    user.role = new_role
    db.commit()

    client_ip = request.client.host if request.client else None
    log_admin_action(
        db,
        admin_id=admin.id,
        action="update_user_role",
        target_type="user",
        target_id=str(user.id),
        details=f"Changed role of {user.phone_number} from {old_role.value} to {new_role.value}",
        ip=client_ip,
    )

    return {"message": f"Role updated to {new_role.value}", "role": new_role.value}


@router.put("/{user_id}/toggle-active")
async def toggle_user_active(
    user_id: str,
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


@router.get("/{user_id}/transactions", response_model=PaginatedResponse[AdminTransactionItem])
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

import math
from datetime import datetime
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import or_
from sqlalchemy.orm import Session, joinedload

from app.database import get_db
from app.models.user import User
from app.models.transaction import Transaction, TransactionType, TransactionStatus
from app.schemas.admin import AdminTransactionItem, PaginatedResponse
from app.utils.admin_auth import get_current_admin

router = APIRouter(tags=["Admin Transactions"])


@router.get("", response_model=PaginatedResponse[AdminTransactionItem])
async def list_transactions(
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    type: Optional[str] = None,
    status: Optional[str] = None,
    network: Optional[str] = None,
    date_from: Optional[str] = None,
    date_to: Optional[str] = None,
    search: Optional[str] = None,
    db: Session = Depends(get_db),
    admin: User = Depends(get_current_admin),
):
    """List transactions with pagination and filters."""
    query = db.query(Transaction).options(joinedload(Transaction.user))

    if type:
        query = query.filter(Transaction.type == type)

    if status:
        query = query.filter(Transaction.status == status)

    if network:
        query = query.filter(Transaction.network == network)

    if date_from:
        try:
            from_date = datetime.strptime(date_from, "%Y-%m-%d")
            query = query.filter(Transaction.created_at >= from_date)
        except ValueError:
            pass

    if date_to:
        try:
            to_date = datetime.strptime(date_to, "%Y-%m-%d")
            to_date = to_date.replace(hour=23, minute=59, second=59)
            query = query.filter(Transaction.created_at <= to_date)
        except ValueError:
            pass

    if search:
        query = query.filter(
            or_(
                Transaction.reference.ilike(f"%{search}%"),
                Transaction.phone_number.ilike(f"%{search}%"),
            )
        )

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

    return PaginatedResponse(
        items=items,
        total=total,
        page=page,
        page_size=page_size,
        total_pages=math.ceil(total / page_size) if total > 0 else 1,
    )


@router.get("/{txn_id}", response_model=AdminTransactionItem)
async def get_transaction(
    txn_id: str,
    db: Session = Depends(get_db),
    admin: User = Depends(get_current_admin),
):
    """Get a single transaction by ID."""
    txn = (
        db.query(Transaction)
        .options(joinedload(Transaction.user))
        .filter(Transaction.id == txn_id)
        .first()
    )
    if not txn:
        raise HTTPException(status_code=404, detail="Transaction not found")

    return AdminTransactionItem(
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

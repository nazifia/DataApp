import math
import uuid
from datetime import datetime
from typing import Optional
from decimal import Decimal

from fastapi import APIRouter, Depends, HTTPException, Query, Request
from sqlalchemy import or_
from sqlalchemy.orm import Session, joinedload

from app.database import get_db
from app.models.user import User, UserRole
from app.models.wallet import Wallet
from app.models.transaction import Transaction, TransactionType, TransactionStatus
from app.schemas.admin import AdminWalletItem, AdminWalletCreditRequest, AdminWalletDebitRequest, PaginatedResponse
from app.utils.admin_auth import get_current_admin, log_admin_action, require_role

router = APIRouter(tags=["Admin Wallets"])


@router.get("", response_model=PaginatedResponse[AdminWalletItem])
async def list_wallets(
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    search: Optional[str] = None,
    min_balance: Optional[float] = None,
    max_balance: Optional[float] = None,
    db: Session = Depends(get_db),
    admin: User = Depends(require_role(UserRole.moderator)),
):
    """List wallets with pagination and filters."""
    query = db.query(Wallet).options(joinedload(Wallet.user))

    if search:
        query = query.join(User).filter(
            or_(
                User.phone_number.ilike(f"%{search}%"),
                User.full_name.ilike(f"%{search}%"),
            )
        )

    if min_balance is not None:
        query = query.filter(Wallet.balance >= min_balance)

    if max_balance is not None:
        query = query.filter(Wallet.balance <= max_balance)

    total = query.count()
    wallets = (
        query.order_by(Wallet.updated_at.desc())
        .offset((page - 1) * page_size)
        .limit(page_size)
        .all()
    )

    items = [
        AdminWalletItem(
            id=str(wallet.id),
            user_id=str(wallet.user_id),
            user_phone=wallet.user.phone_number if wallet.user else "Unknown",
            user_name=wallet.user.full_name if wallet.user else None,
            balance=float(wallet.balance),
            updated_at=wallet.updated_at,
        )
        for wallet in wallets
    ]

    return PaginatedResponse(
        items=items,
        total=total,
        page=page,
        page_size=page_size,
        total_pages=math.ceil(total / page_size) if total > 0 else 1,
    )


@router.post("/{user_id}/credit")
async def credit_wallet(
    user_id: str,
    body: AdminWalletCreditRequest,
    request: Request,
    db: Session = Depends(get_db),
    admin: User = Depends(require_role(UserRole.admin)),
):
    """Credit a user's wallet."""
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    wallet = db.query(Wallet).filter(Wallet.user_id == user.id).first()
    if not wallet:
        raise HTTPException(status_code=404, detail="Wallet not found")

    wallet.balance = Decimal(str(wallet.balance)) + Decimal(str(body.amount))

    # Create wallet_fund transaction
    reference = f"ADM-CREDIT-{datetime.utcnow().strftime('%Y%m%d%H%M%S')}-{str(uuid.uuid4())[:8]}"
    txn = Transaction(
        user_id=user.id,
        type=TransactionType.wallet_fund,
        amount=Decimal(str(body.amount)),
        status=TransactionStatus.success,
        reference=reference,
    )
    db.add(txn)
    db.commit()

    client_ip = request.client.host if request.client else None
    log_admin_action(
        db,
        admin_id=admin.id,
        action="wallet_credit",
        target_type="wallet",
        target_id=str(user.id),
        details=f"Credited ₦{body.amount} to {user.phone_number}. Reason: {body.reason}",
        ip=client_ip,
    )

    return {"message": f"Wallet credited with ₦{body.amount}", "new_balance": float(wallet.balance)}


@router.post("/{user_id}/debit")
async def debit_wallet(
    user_id: str,
    body: AdminWalletDebitRequest,
    request: Request,
    db: Session = Depends(get_db),
    admin: User = Depends(require_role(UserRole.admin)),
):
    """Debit a user's wallet."""
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    wallet = db.query(Wallet).filter(Wallet.user_id == user.id).first()
    if not wallet:
        raise HTTPException(status_code=404, detail="Wallet not found")

    if Decimal(str(wallet.balance)) < Decimal(str(body.amount)):
        raise HTTPException(status_code=400, detail="Insufficient wallet balance")

    wallet.balance = Decimal(str(wallet.balance)) - Decimal(str(body.amount))

    # Create refund transaction (debit)
    reference = f"ADM-DEBIT-{datetime.utcnow().strftime('%Y%m%d%H%M%S')}-{str(uuid.uuid4())[:8]}"
    txn = Transaction(
        user_id=user.id,
        type=TransactionType.refund,
        amount=Decimal(str(body.amount)),
        status=TransactionStatus.success,
        reference=reference,
    )
    db.add(txn)
    db.commit()

    client_ip = request.client.host if request.client else None
    log_admin_action(
        db,
        admin_id=admin.id,
        action="wallet_debit",
        target_type="wallet",
        target_id=str(user.id),
        details=f"Debited ₦{body.amount} from {user.phone_number}. Reason: {body.reason}",
        ip=client_ip,
    )

    return {"message": f"Wallet debited ₦{body.amount}", "new_balance": float(wallet.balance)}

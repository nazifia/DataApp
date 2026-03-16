import math
import uuid
from datetime import datetime
from decimal import Decimal
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, Query, Request
from sqlalchemy import or_
from sqlalchemy.orm import Session, joinedload

from app.database import get_db
from app.models.user import User, UserRole
from app.models.wallet import Wallet
from app.models.transaction import Transaction, TransactionType, TransactionStatus
from app.schemas.admin import AdminTransactionItem, PaginatedResponse
from app.utils.admin_auth import get_current_admin, log_admin_action, require_role

router = APIRouter(tags=["Admin Transactions"])

# Transaction types that originated a wallet debit and can be reversed
_REVERSIBLE_TYPES = {TransactionType.airtime, TransactionType.data}


def _reversal_reference(original_ref: str) -> str:
    return f"REV-{original_ref}"


def _is_reversed(db: Session, original_ref: str) -> bool:
    """Return True if a reversal refund already exists for this transaction."""
    return (
        db.query(Transaction)
        .filter(Transaction.reference == _reversal_reference(original_ref))
        .first()
    ) is not None


def _build_item(txn: Transaction, reversed_refs: set) -> AdminTransactionItem:
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
        is_reversed=txn.reference in reversed_refs,
    )


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
            query = query.filter(
                Transaction.created_at >= datetime.strptime(date_from, "%Y-%m-%d")
            )
        except ValueError:
            pass
    if date_to:
        try:
            to_date = datetime.strptime(date_to, "%Y-%m-%d").replace(
                hour=23, minute=59, second=59
            )
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

    # Batch-check which transactions on this page have already been reversed
    candidate_refs = [t.reference for t in txns]
    reversal_refs = {
        ref[len("REV-"):]
        for (ref,) in db.query(Transaction.reference)
        .filter(Transaction.reference.in_([_reversal_reference(r) for r in candidate_refs]))
        .all()
    }

    items = [_build_item(txn, reversal_refs) for txn in txns]

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

    reversed_refs = {txn.reference} if _is_reversed(db, txn.reference) else set()
    return _build_item(txn, reversed_refs)


@router.post("/{txn_id}/reverse")
async def reverse_transaction(
    txn_id: str,
    request: Request,
    db: Session = Depends(get_db),
    admin: User = Depends(require_role(UserRole.admin)),
):
    """
    Reverse a failed airtime or data transaction by refunding the amount
    to the user's wallet.

    Rules:
    - Transaction must have status = failed.
    - Transaction type must be airtime or data.
    - Cannot reverse a transaction that has already been reversed.
    - Requires admin role or above.
    """
    txn = (
        db.query(Transaction)
        .options(joinedload(Transaction.user))
        .filter(Transaction.id == txn_id)
        .first()
    )
    if not txn:
        raise HTTPException(status_code=404, detail="Transaction not found")

    # Guard: only reversible types
    txn_type = txn.type if isinstance(txn.type, TransactionType) else TransactionType(txn.type)
    if txn_type not in _REVERSIBLE_TYPES:
        raise HTTPException(
            status_code=400,
            detail=f"Only {', '.join(t.value for t in _REVERSIBLE_TYPES)} transactions can be reversed.",
        )

    # Guard: only failed transactions
    txn_status = txn.status if isinstance(txn.status, TransactionStatus) else TransactionStatus(txn.status)
    if txn_status != TransactionStatus.failed:
        raise HTTPException(
            status_code=400,
            detail="Only failed transactions can be reversed.",
        )

    # Guard: prevent double-reversal
    if _is_reversed(db, txn.reference):
        raise HTTPException(
            status_code=409,
            detail="This transaction has already been reversed.",
        )

    # Fetch wallet
    wallet = db.query(Wallet).filter(Wallet.user_id == txn.user_id).first()
    if not wallet:
        raise HTTPException(status_code=404, detail="User wallet not found.")

    amount = Decimal(str(txn.amount))

    # Credit the wallet
    wallet.balance = Decimal(str(wallet.balance)) + amount

    # Create the reversal refund transaction
    refund_txn = Transaction(
        user_id=txn.user_id,
        type=TransactionType.refund,
        amount=amount,
        status=TransactionStatus.success,
        reference=_reversal_reference(txn.reference),
        network=txn.network,
        phone_number=txn.phone_number,
        plan_id=txn.plan_id,
    )
    db.add(refund_txn)
    db.commit()
    db.refresh(wallet)

    user_phone = txn.user.phone_number if txn.user else str(txn.user_id)
    client_ip = request.client.host if request.client else None
    log_admin_action(
        db,
        admin_id=admin.id,
        action="reverse_transaction",
        target_type="transaction",
        target_id=str(txn.id),
        details=(
            f"Reversed failed {txn_type.value} transaction {txn.reference} "
            f"for {user_phone}. Refunded ₦{float(amount):,.2f}. "
            f"Refund ref: {refund_txn.reference}"
        ),
        ip=client_ip,
    )

    return {
        "message": f"Transaction reversed. ₦{float(amount):,.2f} refunded to {user_phone}.",
        "refund_reference": refund_txn.reference,
        "new_wallet_balance": float(wallet.balance),
    }

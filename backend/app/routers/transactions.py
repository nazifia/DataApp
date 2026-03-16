import logging
from decimal import Decimal
from typing import List

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.transaction import Transaction, TransactionType, TransactionStatus
from app.models.user import User
from app.models.wallet import Wallet
from app.schemas.transaction import (
    TransactionItem,
    TransactionListResponse,
    TransactionReverseResponse,
)
from app.utils.auth import get_current_user

logger = logging.getLogger(__name__)

router = APIRouter(tags=["Transactions"])

_REVERSIBLE_TYPES = {TransactionType.airtime, TransactionType.data}


def _reversal_reference(original_ref: str) -> str:
    return f"REV-{original_ref}"


def _reversed_refs_for(db: Session, references: list[str]) -> set[str]:
    """Return the subset of `references` that already have a reversal refund."""
    reversal_refs = [_reversal_reference(r) for r in references]
    rows = (
        db.query(Transaction.reference)
        .filter(Transaction.reference.in_(reversal_refs))
        .all()
    )
    return {ref[len("REV-"):] for (ref,) in rows}


@router.get("/transactions", response_model=TransactionListResponse, status_code=status.HTTP_200_OK)
def list_transactions(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Return all transactions for the authenticated user, most recent first."""
    transactions = (
        db.query(Transaction)
        .filter(Transaction.user_id == current_user.id)
        .order_by(Transaction.created_at.desc())
        .all()
    )

    candidate_refs = [t.reference for t in transactions]
    reversed_refs = _reversed_refs_for(db, candidate_refs) if candidate_refs else set()

    items: List[TransactionItem] = []
    for txn in transactions:
        items.append(
            TransactionItem(
                id=txn.id,
                type=txn.type.value,
                amount=float(txn.amount),
                status=txn.status.value,
                reference=txn.reference,
                network=txn.network,
                phone_number=txn.phone_number,
                created_at=txn.created_at,
                is_reversed=txn.reference in reversed_refs,
            )
        )

    logger.info("Listed %d transactions for user %s", len(items), current_user.id)
    return TransactionListResponse(transactions=items)


@router.post(
    "/transactions/{txn_id}/reverse",
    response_model=TransactionReverseResponse,
    status_code=status.HTTP_200_OK,
)
def reverse_transaction(
    txn_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Reverse a failed airtime or data transaction by refunding the amount
    to the user's wallet. Users can only reverse their own transactions.
    """
    txn = (
        db.query(Transaction)
        .filter(Transaction.id == txn_id, Transaction.user_id == current_user.id)
        .first()
    )
    if not txn:
        raise HTTPException(status_code=404, detail="Transaction not found.")

    txn_type = txn.type if isinstance(txn.type, TransactionType) else TransactionType(txn.type)
    if txn_type not in _REVERSIBLE_TYPES:
        raise HTTPException(
            status_code=400,
            detail=f"Only {', '.join(t.value for t in _REVERSIBLE_TYPES)} transactions can be reversed.",
        )

    txn_status = txn.status if isinstance(txn.status, TransactionStatus) else TransactionStatus(txn.status)
    if txn_status != TransactionStatus.failed:
        raise HTTPException(status_code=400, detail="Only failed transactions can be reversed.")

    if _reversed_refs_for(db, [txn.reference]):
        raise HTTPException(status_code=409, detail="This transaction has already been reversed.")

    wallet = db.query(Wallet).filter(Wallet.user_id == current_user.id).first()
    if not wallet:
        raise HTTPException(status_code=404, detail="Wallet not found.")

    amount = Decimal(str(txn.amount))
    wallet.balance = Decimal(str(wallet.balance)) + amount

    refund_txn = Transaction(
        user_id=current_user.id,
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

    logger.info(
        "User %s reversed transaction %s (ref=%s), refunded ₦%.2f",
        current_user.id, txn_id, txn.reference, float(amount),
    )

    return TransactionReverseResponse(
        message=f"Transaction reversed. ₦{float(amount):,.2f} has been refunded to your wallet.",
        refund_reference=refund_txn.reference,
        new_wallet_balance=float(wallet.balance),
    )

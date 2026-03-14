import logging
from typing import List

from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.transaction import Transaction
from app.models.user import User
from app.schemas.transaction import TransactionItem, TransactionListResponse
from app.utils.auth import get_current_user

logger = logging.getLogger(__name__)

router = APIRouter(tags=["Transactions"])


@router.get("/transactions", response_model=TransactionListResponse, status_code=status.HTTP_200_OK)
def list_transactions(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Return all transactions for the authenticated user, most recent first.
    """
    transactions = (
        db.query(Transaction)
        .filter(Transaction.user_id == current_user.id)
        .order_by(Transaction.created_at.desc())
        .all()
    )

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
            )
        )

    logger.info("Listed %d transactions for user %s", len(items), current_user.id)
    return TransactionListResponse(transactions=items)

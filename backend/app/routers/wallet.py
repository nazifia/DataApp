import logging
import random
import time

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.transaction import Transaction, TransactionStatus, TransactionType
from app.models.user import User
from app.models.wallet import Wallet
from app.schemas.wallet import FundWalletRequest, FundWalletResponse, WalletBalanceResponse
from app.utils.auth import get_current_user

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/wallet", tags=["Wallet"])


def _get_wallet(user_id, db: Session) -> Wallet:
    """Retrieve the wallet for a user, raising 404 if not found."""
    wallet = db.query(Wallet).filter(Wallet.user_id == user_id).first()
    if not wallet:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Wallet not found. Please complete your profile setup first.",
        )
    return wallet


def _generate_reference() -> str:
    timestamp = int(time.time() * 1000)
    suffix = random.randint(1000, 9999)
    return f"ADP-{timestamp}-{suffix}"


@router.get("/balance", response_model=WalletBalanceResponse, status_code=status.HTTP_200_OK)
def get_balance(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Return the current wallet balance for the authenticated user."""
    wallet = _get_wallet(current_user.id, db)
    return WalletBalanceResponse(balance=float(wallet.balance))


@router.post("/fund", response_model=FundWalletResponse, status_code=status.HTTP_200_OK)
def fund_wallet(
    request: FundWalletRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Add funds to the authenticated user's wallet.

    In a production system this endpoint would be called by a payment webhook
    (e.g., Paystack/Flutterwave) after a successful card charge.
    For now, it directly credits the wallet.
    """
    wallet = _get_wallet(current_user.id, db)
    reference = _generate_reference()

    # Credit wallet
    wallet.balance = float(wallet.balance) + request.amount

    # Record transaction
    txn = Transaction(
        user_id=current_user.id,
        type=TransactionType.wallet_fund,
        amount=request.amount,
        status=TransactionStatus.success,
        reference=reference,
    )
    db.add(txn)
    db.commit()
    db.refresh(wallet)

    logger.info(
        "Wallet funded: user=%s, amount=%.2f, ref=%s, new_balance=%.2f",
        current_user.id, request.amount, reference, float(wallet.balance),
    )

    return FundWalletResponse(
        message=f"Wallet funded successfully with NGN {request.amount:,.2f}.",
        balance=float(wallet.balance),
    )

import logging
import random
import time

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.transaction import Transaction, TransactionStatus, TransactionType
from app.models.user import User
from app.models.wallet import Wallet
from app.schemas.transaction import AirtimePurchaseRequest, AirtimePurchaseResponse
from app.services import airtime_service
from app.utils.auth import get_current_user

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/airtime", tags=["Airtime"])


def _get_wallet(user_id, db: Session) -> Wallet:
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


@router.post("/purchase", response_model=AirtimePurchaseResponse, status_code=status.HTTP_200_OK)
async def purchase_airtime(
    request: AirtimePurchaseRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Purchase airtime for any Nigerian network.

    Flow:
      1. Check wallet has sufficient balance.
      2. Deduct amount from wallet.
      3. Call VTPass airtime API.
      4a. On success: mark transaction as success.
      4b. On failure: refund wallet and record a refund transaction.
    """
    wallet = _get_wallet(current_user.id, db)

    # Check balance
    current_balance = float(wallet.balance)
    if current_balance < request.amount:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Insufficient wallet balance. Available: NGN {current_balance:,.2f}",
        )

    reference = _generate_reference()

    # Deduct from wallet BEFORE calling VTPass
    wallet.balance = current_balance - request.amount

    # Record pending transaction
    txn = Transaction(
        user_id=current_user.id,
        type=TransactionType.airtime,
        amount=request.amount,
        status=TransactionStatus.pending,
        reference=reference,
        network=request.network,
        phone_number=request.phone_number,
    )
    db.add(txn)
    db.commit()

    # Call airtime service
    result = await airtime_service.purchase_airtime(
        network=request.network,
        phone=request.phone_number,
        amount=request.amount,
    )

    if result["success"]:
        txn.status = TransactionStatus.success
        txn.reference = result["reference"]  # Use the provider's reference if different
        db.commit()
        logger.info(
            "Airtime purchase success: user=%s, network=%s, phone=%s, amount=%.2f, ref=%s",
            current_user.id, request.network, request.phone_number, request.amount, txn.reference,
        )
        return AirtimePurchaseResponse(
            message="Airtime purchase successful.",
            reference=txn.reference,
            amount=request.amount,
            network=request.network,
            phone_number=request.phone_number,
        )
    else:
        # VTPass failed — refund the wallet
        txn.status = TransactionStatus.failed
        db.commit()

        refund_reference = _generate_reference()
        wallet.balance = float(wallet.balance) + request.amount
        refund_txn = Transaction(
            user_id=current_user.id,
            type=TransactionType.refund,
            amount=request.amount,
            status=TransactionStatus.success,
            reference=refund_reference,
            network=request.network,
            phone_number=request.phone_number,
        )
        db.add(refund_txn)
        db.commit()

        logger.error(
            "Airtime purchase failed — refunded: user=%s, network=%s, amount=%.2f, reason=%s",
            current_user.id, request.network, request.amount, result.get("message"),
        )
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail=f"Airtime purchase failed: {result.get('message', 'Unknown error')}. Your wallet has been refunded.",
        )

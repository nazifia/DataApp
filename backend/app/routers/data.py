import logging
import random
import time

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.transaction import Transaction, TransactionStatus, TransactionType
from app.models.user import User
from app.models.wallet import Wallet
from app.schemas.transaction import DataPlansResponse, DataPurchaseRequest, DataPurchaseResponse
from app.services import data_service
from app.utils.auth import get_current_user

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/data", tags=["Data"])

VALID_NETWORKS = {"mtn", "airtel", "glo", "etisalat"}


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


@router.get("/plans", response_model=DataPlansResponse, status_code=status.HTTP_200_OK)
async def get_data_plans(
    network: str = Query(..., description="Network code: mtn, airtel, glo, etisalat"),
    current_user: User = Depends(get_current_user),
):
    """
    Fetch available data plans for the specified network.
    """
    network = network.lower().strip()
    if network not in VALID_NETWORKS:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Invalid network. Must be one of: {', '.join(VALID_NETWORKS)}",
        )

    plans = await data_service.get_data_plans(network)
    return DataPlansResponse(plans=plans)


@router.post("/purchase", response_model=DataPurchaseResponse, status_code=status.HTTP_200_OK)
async def purchase_data(
    request: DataPurchaseRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Purchase a data bundle.

    Flow:
      1. Fetch plans to determine the cost of the requested plan_id.
      2. Check wallet has sufficient balance.
      3. Deduct amount from wallet.
      4. Call VTPass data API.
      5a. On success: mark transaction as success.
      5b. On failure: refund wallet and record a refund transaction.
    """
    wallet = _get_wallet(current_user.id, db)

    # Resolve plan price
    plans = await data_service.get_data_plans(request.network)
    plan = next((p for p in plans if p["id"] == request.plan_id), None)
    if plan is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Data plan '{request.plan_id}' not found for network '{request.network}'.",
        )

    plan_price = float(plan["price"])
    current_balance = float(wallet.balance)

    if current_balance < plan_price:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Insufficient wallet balance. Available: NGN {current_balance:,.2f}, Required: NGN {plan_price:,.2f}",
        )

    reference = _generate_reference()

    # Deduct from wallet BEFORE calling VTPass
    wallet.balance = current_balance - plan_price

    # Record pending transaction
    txn = Transaction(
        user_id=current_user.id,
        type=TransactionType.data,
        amount=plan_price,
        status=TransactionStatus.pending,
        reference=reference,
        network=request.network,
        phone_number=request.phone_number,
        plan_id=request.plan_id,
    )
    db.add(txn)
    db.commit()

    # Call data service
    result = await data_service.purchase_data(
        network=request.network,
        plan_id=request.plan_id,
        phone=request.phone_number,
    )

    if result["success"]:
        txn.status = TransactionStatus.success
        txn.reference = result["reference"]
        db.commit()
        logger.info(
            "Data purchase success: user=%s, network=%s, plan=%s, phone=%s, amount=%.2f, ref=%s",
            current_user.id, request.network, request.plan_id,
            request.phone_number, plan_price, txn.reference,
        )
        return DataPurchaseResponse(
            message="Data purchase successful.",
            reference=txn.reference,
            plan_id=request.plan_id,
            network=request.network,
            phone_number=request.phone_number,
        )
    else:
        # VTPass failed — refund the wallet
        txn.status = TransactionStatus.failed
        db.commit()

        refund_reference = _generate_reference()
        wallet.balance = float(wallet.balance) + plan_price
        refund_txn = Transaction(
            user_id=current_user.id,
            type=TransactionType.refund,
            amount=plan_price,
            status=TransactionStatus.success,
            reference=refund_reference,
            network=request.network,
            phone_number=request.phone_number,
            plan_id=request.plan_id,
        )
        db.add(refund_txn)
        db.commit()

        logger.error(
            "Data purchase failed — refunded: user=%s, network=%s, plan=%s, reason=%s",
            current_user.id, request.network, request.plan_id, result.get("message"),
        )
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail=f"Data purchase failed: {result.get('message', 'Unknown error')}. Your wallet has been refunded.",
        )

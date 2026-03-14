import logging

from fastapi import APIRouter, Depends, HTTPException, status
from passlib.context import CryptContext
from sqlalchemy.orm import Session

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

from app.database import get_db
from app.models.user import User
from app.models.wallet import Wallet
from app.schemas.user import (
    CreateProfileRequest,
    UpdateProfileRequest,
    UpdateProfileResponse,
    UserProfileResponse,
    UserResponse,
)
from app.utils.auth import get_current_user

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/user", tags=["User"])


@router.post("/profile", response_model=UserProfileResponse, status_code=status.HTTP_201_CREATED)
def create_profile(
    request: CreateProfileRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Complete the user's profile after OTP verification.

    Creates the wallet if it does not already exist.
    The phone_number in the request must match the authenticated user's phone.
    """
    # Verify the phone number matches the authenticated user
    if request.phone_number != current_user.phone_number:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Phone number does not match the authenticated user.",
        )

    # Check if profile is already complete (full_name already set)
    if current_user.full_name is not None:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Profile already exists. Use PUT /user/profile to update.",
        )

    # Update user profile fields
    current_user.full_name = request.full_name
    current_user.password_hash = pwd_context.hash(request.password)
    if request.device_id:
        current_user.device_id = request.device_id

    # Create wallet if not exists
    existing_wallet = db.query(Wallet).filter(Wallet.user_id == current_user.id).first()
    if not existing_wallet:
        wallet = Wallet(user_id=current_user.id, balance=0)
        db.add(wallet)
        logger.info("Wallet created for user %s", current_user.id)

    db.commit()
    db.refresh(current_user)
    logger.info("Profile created for user %s", current_user.id)

    return UserProfileResponse(user=UserResponse.model_validate(current_user))


@router.get("/profile", response_model=UserProfileResponse, status_code=status.HTTP_200_OK)
def get_profile(current_user: User = Depends(get_current_user)):
    """Return the authenticated user's profile."""
    return UserProfileResponse(user=UserResponse.model_validate(current_user))


@router.put("/profile", response_model=UpdateProfileResponse, status_code=status.HTTP_200_OK)
def update_profile(
    request: UpdateProfileRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Update the authenticated user's full name."""
    current_user.full_name = request.full_name
    db.commit()
    db.refresh(current_user)
    logger.info("Profile updated for user %s", current_user.id)

    return UpdateProfileResponse(
        message="Profile updated successfully.",
        user=UserResponse.model_validate(current_user),
    )

import logging
import os
import uuid

from fastapi import APIRouter, Depends, File, HTTPException, UploadFile, status
from passlib.context import CryptContext
from sqlalchemy.orm import Session

pwd_context = CryptContext(schemes=["pbkdf2_sha256"], deprecated="auto")

from app.database import get_db
from app.models.user import User
from app.models.wallet import Wallet
from app.schemas.user import (
    ChangePasswordRequest,
    ChangePasswordResponse,
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


@router.put("/password", response_model=ChangePasswordResponse, status_code=status.HTTP_200_OK)
def change_password(
    request: ChangePasswordRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Change the authenticated user's password."""
    # Verify the current password
    if not current_user.password_hash:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="No password set for this account.",
        )

    if not pwd_context.verify(request.current_password, current_user.password_hash):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Current password is incorrect.",
        )

    # Hash and save the new password
    current_user.password_hash = pwd_context.hash(request.new_password)
    db.commit()
    logger.info("Password changed for user %s", current_user.id)

    return ChangePasswordResponse(message="Password changed successfully.")


UPLOAD_DIR = "static/profile_pictures"
ALLOWED_EXTENSIONS = {".jpg", ".jpeg", ".png", ".webp"}
MAX_FILE_SIZE = 5 * 1024 * 1024  # 5 MB


@router.put("/profile/picture", response_model=UserProfileResponse, status_code=status.HTTP_200_OK)
async def upload_profile_picture(
    profile_picture: UploadFile = File(...),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Upload or replace the authenticated user's profile picture."""
    ext = os.path.splitext(profile_picture.filename or "")[1].lower()
    if ext not in ALLOWED_EXTENSIONS:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Unsupported file type. Allowed: {', '.join(ALLOWED_EXTENSIONS)}",
        )

    contents = await profile_picture.read()
    if len(contents) > MAX_FILE_SIZE:
        raise HTTPException(
            status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
            detail="File too large. Maximum size is 5 MB.",
        )

    os.makedirs(UPLOAD_DIR, exist_ok=True)

    # Delete old picture file if it exists
    if current_user.profile_picture_url:
        old_path = current_user.profile_picture_url.lstrip("/")
        if os.path.isfile(old_path):
            os.remove(old_path)

    filename = f"{current_user.id}_{uuid.uuid4().hex}{ext}"
    file_path = os.path.join(UPLOAD_DIR, filename)
    with open(file_path, "wb") as f:
        f.write(contents)

    current_user.profile_picture_url = f"/{file_path.replace(os.sep, '/')}"
    db.commit()
    db.refresh(current_user)
    logger.info("Profile picture updated for user %s", current_user.id)

    return UserProfileResponse(user=UserResponse.model_validate(current_user))

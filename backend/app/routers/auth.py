import logging
from datetime import timedelta

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.config import settings
from app.database import get_db
from app.models.user import User
from passlib.context import CryptContext

from app.schemas.auth import (
    LoginRequest,
    LoginResponse,
    RefreshTokenRequest,
    RefreshTokenResponse,
    SendOTPRequest,
    SendOTPResponse,
    VerifyOTPRequest,
    VerifyOTPResponse,
)
from app.services import otp_service, sms_service
from app.utils.auth import create_access_token, create_refresh_token, decode_token

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/auth", tags=["Authentication"])


@router.post("/send-otp", response_model=SendOTPResponse, status_code=status.HTTP_200_OK)
async def send_otp(request: SendOTPRequest):
    """
    Generate an OTP and send it via SMS to the given phone number.
    Phone number is normalized to +234XXXXXXXXX format.
    """
    phone = request.phone_number  # Already normalized by the schema validator

    otp = otp_service.generate_otp()
    otp_service.save_otp(phone, otp)

    sms_sent = await sms_service.send_otp_sms(phone, otp)
    if not sms_sent and not settings.dev_mode:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Failed to send OTP SMS. Please try again.",
        )

    logger.info("OTP sent to %s", phone)
    return SendOTPResponse(
        message="OTP sent successfully. Check your phone.",
        phone_number=phone,
    )


@router.post("/verify-otp", response_model=VerifyOTPResponse, status_code=status.HTTP_200_OK)
async def verify_otp(request: VerifyOTPRequest, db: Session = Depends(get_db)):
    """
    Verify the OTP for the given phone number.

    - If OTP is invalid or expired, returns 400.
    - If user already exists: returns tokens + is_new_user=false.
    - If user does not exist: creates user, returns tokens + is_new_user=true.
      The Flutter app should then call POST /user/profile to complete registration.
    """
    phone = request.phone_number

    is_valid = otp_service.verify_otp(phone, request.otp)
    if not is_valid:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid or expired OTP.",
        )

    # Check if user already exists
    user = db.query(User).filter(User.phone_number == phone).first()
    is_new_user = user is None

    if is_new_user:
        # Create the user record; profile (full_name, device_id) will be set later
        user = User(phone_number=phone)
        db.add(user)
        db.commit()
        db.refresh(user)
        logger.info("New user created for phone %s, id=%s", phone, user.id)
    else:
        logger.info("Existing user logged in: phone=%s, id=%s", phone, user.id)

    # Generate tokens
    user_id_str = str(user.id)
    access_token = create_access_token(
        data={"sub": user_id_str},
        expires_delta=timedelta(minutes=settings.access_token_expire_minutes),
    )
    refresh_token = create_refresh_token(
        data={"sub": user_id_str},
        expires_delta=timedelta(days=settings.refresh_token_expire_days),
    )

    return VerifyOTPResponse(
        message="OTP verified successfully.",
        access_token=access_token,
        refresh_token=refresh_token,
        is_new_user=is_new_user,
    )


@router.post("/login", response_model=LoginResponse, status_code=status.HTTP_200_OK)
async def login(request: LoginRequest, db: Session = Depends(get_db)):
    """
    Standard phone + password login.
    Returns access and refresh tokens on success.
    """
    phone = request.phone_number

    user = db.query(User).filter(User.phone_number == phone).first()
    if user is None or not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid phone number or password.",
        )

    if user.password_hash is None or not pwd_context.verify(request.password, user.password_hash):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid phone number or password.",
        )

    user_id_str = str(user.id)
    access_token = create_access_token(
        data={"sub": user_id_str},
        expires_delta=timedelta(minutes=settings.access_token_expire_minutes),
    )
    refresh_token = create_refresh_token(
        data={"sub": user_id_str},
        expires_delta=timedelta(days=settings.refresh_token_expire_days),
    )

    logger.info("User logged in: phone=%s, id=%s", phone, user.id)
    return LoginResponse(
        message="Login successful.",
        access_token=access_token,
        refresh_token=refresh_token,
    )


@router.post("/refresh-token", response_model=RefreshTokenResponse, status_code=status.HTTP_200_OK)
async def refresh_token(request: RefreshTokenRequest, db: Session = Depends(get_db)):
    """
    Exchange a valid refresh token for a new access token.

    The refresh token must be of type 'refresh'. The user must exist and be active.
    """
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Invalid or expired refresh token.",
        headers={"WWW-Authenticate": "Bearer"},
    )

    payload = decode_token(request.refresh_token)

    token_type = payload.get("type")
    if token_type != "refresh":
        raise credentials_exception

    user_id: str = payload.get("sub")
    if user_id is None:
        raise credentials_exception

    user = db.query(User).filter(User.id == user_id).first()
    if user is None or not user.is_active:
        raise credentials_exception

    new_access_token = create_access_token(
        data={"sub": str(user.id)},
        expires_delta=timedelta(minutes=settings.access_token_expire_minutes),
    )

    logger.info("Access token refreshed for user %s", user.id)
    return RefreshTokenResponse(access_token=new_access_token)

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.config import settings
from app.database import get_db
from app.models.user import User, UserRole
from app.schemas.admin import AdminSettingsResponse
from app.utils.admin_auth import get_current_admin, require_role

router = APIRouter(tags=["Admin Settings"])


@router.get("/settings", response_model=AdminSettingsResponse)
async def get_settings(
    db: Session = Depends(get_db),
    admin: User = Depends(require_role(UserRole.admin)),
):
    """Get system configuration settings."""
    db_type = "sqlite" if settings.database_url.startswith("sqlite") else "postgresql"
    vtpass_configured = bool(settings.vtpass_api_key and settings.vtpass_secret_key)

    return AdminSettingsResponse(
        dev_mode=settings.dev_mode,
        database_type=db_type,
        sms_provider="termii",
        vtpass_configured=vtpass_configured,
    )


@router.put("/settings/dev-mode")
async def toggle_dev_mode(
    db: Session = Depends(get_db),
    admin: User = Depends(require_role(UserRole.super_admin)),
):
    """Toggle development mode (note: requires restart to fully take effect)."""
    # In a real implementation, this would update a config file or database setting
    # For now, return current state
    return {
        "message": "Dev mode toggle requires application restart to take full effect",
        "current_dev_mode": settings.dev_mode,
    }

from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.user import User
from app.schemas.admin import DashboardStats
from app.services.admin_service import (
    get_revenue_over_time,
    get_network_distribution,
    get_top_users,
    get_transaction_type_breakdown,
)
from app.utils.admin_auth import get_current_admin

router = APIRouter(tags=["Admin Analytics"])


@router.get("/revenue")
async def revenue_over_time(
    period: str = Query("daily", pattern="^(daily|weekly|monthly)$"),
    days: int = Query(30, ge=1, le=365),
    db: Session = Depends(get_db),
    admin: User = Depends(get_current_admin),
):
    """Get revenue data over time for charts."""
    return get_revenue_over_time(db, period=period, days=days)


@router.get("/network-distribution")
async def network_distribution(
    db: Session = Depends(get_db),
    admin: User = Depends(get_current_admin),
):
    """Get transaction distribution by network."""
    return get_network_distribution(db)


@router.get("/top-users")
async def top_users(
    limit: int = Query(10, ge=1, le=50),
    db: Session = Depends(get_db),
    admin: User = Depends(get_current_admin),
):
    """Get top users by spend."""
    return get_top_users(db, limit=limit)


@router.get("/transaction-types")
async def transaction_types(
    db: Session = Depends(get_db),
    admin: User = Depends(get_current_admin),
):
    """Get transaction count by type."""
    return get_transaction_type_breakdown(db)

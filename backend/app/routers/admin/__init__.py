from fastapi import APIRouter

from app.routers.admin import dashboard, users, transactions, wallets, data_plans, analytics, export, audit, settings

# Combine all admin API sub-routers under /api/v1/admin prefix
router = APIRouter(prefix="/admin", tags=["Admin API"])

router.include_router(dashboard.router, prefix="/dashboard")
router.include_router(users.router, prefix="/users")
router.include_router(transactions.router, prefix="/transactions")
router.include_router(wallets.router, prefix="/wallets")
router.include_router(data_plans.router, prefix="/data-plans")
router.include_router(analytics.router, prefix="/analytics")
router.include_router(export.router, prefix="/export")
router.include_router(audit.router, prefix="/audit")
router.include_router(settings.router, prefix="/settings")

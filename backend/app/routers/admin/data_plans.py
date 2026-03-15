from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.user import User, UserRole
from app.schemas.admin import AdminDataPlanItem, AdminDataPlanCreateRequest
from app.services.data_service import MOCK_DATA_PLANS
from app.utils.admin_auth import get_current_admin, require_role

router = APIRouter(tags=["Admin Data Plans"])

# In-memory data plans storage (could be migrated to DB)
_data_plans_store: dict[str, list[dict]] = {}


def _init_plans():
    """Initialize plans from MOCK_DATA_PLANS if store is empty."""
    if not _data_plans_store:
        for network, plans in MOCK_DATA_PLANS.items():
            _data_plans_store[network] = [
                {
                    "id": plan["id"],
                    "network": network,
                    "plan_code": plan["id"],
                    "name": plan["name"],
                    "price": plan["price"],
                    "validity": plan["validity"],
                    "is_active": True,
                }
                for plan in plans
            ]


@router.get("/data-plans")
async def list_data_plans(
    db: Session = Depends(get_db),
    admin: User = Depends(require_role(UserRole.moderator)),
):
    """Get all data plans grouped by network."""
    _init_plans()
    return _data_plans_store


@router.post("/data-plans")
async def create_or_update_plan(
    body: AdminDataPlanCreateRequest,
    db: Session = Depends(get_db),
    admin: User = Depends(require_role(UserRole.admin)),
):
    """Create or update a data plan."""
    _init_plans()

    network = body.network.lower()
    if network not in _data_plans_store:
        _data_plans_store[network] = []

    # Check if plan with same code exists
    existing_idx = None
    for i, plan in enumerate(_data_plans_store[network]):
        if plan["plan_code"] == body.plan_code:
            existing_idx = i
            break

    plan_data = {
        "id": body.plan_code,
        "network": network,
        "plan_code": body.plan_code,
        "name": body.name,
        "price": body.price,
        "validity": body.validity,
        "is_active": body.is_active,
    }

    if existing_idx is not None:
        _data_plans_store[network][existing_idx] = plan_data
        return {"message": "Data plan updated", "plan": plan_data}
    else:
        _data_plans_store[network].append(plan_data)
        return {"message": "Data plan created", "plan": plan_data}


@router.delete("/data-plans/{plan_id}")
async def delete_plan(
    plan_id: str,
    db: Session = Depends(get_db),
    admin: User = Depends(require_role(UserRole.admin)),
):
    """Delete a data plan."""
    _init_plans()

    for network, plans in _data_plans_store.items():
        for i, plan in enumerate(plans):
            if plan["id"] == plan_id or plan["plan_code"] == plan_id:
                del _data_plans_store[network][i]
                return {"message": "Data plan deleted"}

    raise HTTPException(status_code=404, detail="Data plan not found")

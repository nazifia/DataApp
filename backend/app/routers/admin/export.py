import csv
import io
from datetime import datetime
from typing import Optional

from fastapi import APIRouter, Depends, Query
from fastapi.responses import StreamingResponse
from sqlalchemy.orm import Session, joinedload

from app.database import get_db
from app.models.user import User, UserRole
from app.models.transaction import Transaction, TransactionType, TransactionStatus
from app.utils.admin_auth import get_current_admin

router = APIRouter(tags=["Admin Export"])


@router.get("/users.csv")
async def export_users_csv(
    db: Session = Depends(get_db),
    admin: User = Depends(get_current_admin),
):
    """Export all users as CSV."""
    users = db.query(User).order_by(User.created_at.desc()).all()

    output = io.StringIO()
    writer = csv.writer(output)
    writer.writerow(["ID", "Phone", "Name", "Role", "Active", "Created At"])

    for user in users:
        writer.writerow([
            str(user.id),
            user.phone_number,
            user.full_name or "",
            user.role.value if hasattr(user.role, "value") else str(user.role),
            "Yes" if user.is_active else "No",
            user.created_at.isoformat() if user.created_at else "",
        ])

    output.seek(0)
    return StreamingResponse(
        iter([output.getvalue()]),
        media_type="text/csv",
        headers={"Content-Disposition": "attachment; filename=users.csv"},
    )


@router.get("/transactions.csv")
async def export_transactions_csv(
    type: Optional[str] = None,
    status: Optional[str] = None,
    date_from: Optional[str] = None,
    date_to: Optional[str] = None,
    db: Session = Depends(get_db),
    admin: User = Depends(get_current_admin),
):
    """Export transactions as CSV with optional filters."""
    query = db.query(Transaction).options(joinedload(Transaction.user))

    if type:
        query = query.filter(Transaction.type == type)
    if status:
        query = query.filter(Transaction.status == status)
    if date_from:
        try:
            from_date = datetime.strptime(date_from, "%Y-%m-%d")
            query = query.filter(Transaction.created_at >= from_date)
        except ValueError:
            pass
    if date_to:
        try:
            to_date = datetime.strptime(date_to, "%Y-%m-%d")
            to_date = to_date.replace(hour=23, minute=59, second=59)
            query = query.filter(Transaction.created_at <= to_date)
        except ValueError:
            pass

    txns = query.order_by(Transaction.created_at.desc()).all()

    output = io.StringIO()
    writer = csv.writer(output)
    writer.writerow([
        "Reference", "User Phone", "User Name", "Type", "Amount", "Status",
        "Network", "Phone Number", "Plan ID", "Created At"
    ])

    for txn in txns:
        writer.writerow([
            txn.reference,
            txn.user.phone_number if txn.user else "",
            txn.user.full_name if txn.user else "",
            txn.type.value if hasattr(txn.type, "value") else str(txn.type),
            float(txn.amount),
            txn.status.value if hasattr(txn.status, "value") else str(txn.status),
            txn.network or "",
            txn.phone_number or "",
            txn.plan_id or "",
            txn.created_at.isoformat() if txn.created_at else "",
        ])

    output.seek(0)
    return StreamingResponse(
        iter([output.getvalue()]),
        media_type="text/csv",
        headers={"Content-Disposition": "attachment; filename=transactions.csv"},
    )

from datetime import datetime, timedelta
from decimal import Decimal
from typing import List

from sqlalchemy import func, extract
from sqlalchemy.orm import Session

from app.models.user import User
from app.models.wallet import Wallet
from app.models.transaction import Transaction, TransactionType, TransactionStatus


def get_dashboard_stats(db: Session) -> dict:
    """Get aggregate stats for the admin dashboard."""
    total_users = db.query(func.count(User.id)).scalar() or 0
    active_users = db.query(func.count(User.id)).filter(User.is_active == True).scalar() or 0
    total_transactions = db.query(func.count(Transaction.id)).scalar() or 0
    successful_transactions = (
        db.query(func.count(Transaction.id))
        .filter(Transaction.status == TransactionStatus.success)
        .scalar()
        or 0
    )

    # Total revenue from successful airtime/data transactions
    total_revenue = (
        db.query(func.coalesce(func.sum(Transaction.amount), 0))
        .filter(
            Transaction.status == TransactionStatus.success,
            Transaction.type.in_([TransactionType.airtime, TransactionType.data]),
        )
        .scalar()
    )
    total_revenue = float(total_revenue) if total_revenue else 0.0

    # Total wallet balance across all users
    total_wallet_balance = db.query(func.coalesce(func.sum(Wallet.balance), 0)).scalar()
    total_wallet_balance = float(total_wallet_balance) if total_wallet_balance else 0.0

    # Today's stats
    today_start = datetime.utcnow().replace(hour=0, minute=0, second=0, microsecond=0)
    today_transactions = (
        db.query(func.count(Transaction.id))
        .filter(Transaction.created_at >= today_start)
        .scalar()
        or 0
    )
    today_revenue = (
        db.query(func.coalesce(func.sum(Transaction.amount), 0))
        .filter(
            Transaction.created_at >= today_start,
            Transaction.status == TransactionStatus.success,
            Transaction.type.in_([TransactionType.airtime, TransactionType.data]),
        )
        .scalar()
    )
    today_revenue = float(today_revenue) if today_revenue else 0.0

    return {
        "total_users": total_users,
        "active_users": active_users,
        "total_transactions": total_transactions,
        "successful_transactions": successful_transactions,
        "total_revenue": total_revenue,
        "total_wallet_balance": total_wallet_balance,
        "today_transactions": today_transactions,
        "today_revenue": today_revenue,
    }


def get_revenue_over_time(db: Session, period: str = "daily", days: int = 30) -> List[dict]:
    """Get revenue aggregated over time for charts."""
    start_date = datetime.utcnow() - timedelta(days=days)

    results = (
        db.query(
            func.date(Transaction.created_at).label("date"),
            func.count(Transaction.id).label("transactions"),
            func.coalesce(func.sum(Transaction.amount), 0).label("revenue"),
        )
        .filter(
            Transaction.created_at >= start_date,
            Transaction.status == TransactionStatus.success,
            Transaction.type.in_([TransactionType.airtime, TransactionType.data]),
        )
        .group_by(func.date(Transaction.created_at))
        .order_by(func.date(Transaction.created_at))
        .all()
    )

    return [
        {
            "date": str(r.date),
            "transactions": r.transactions,
            "revenue": float(r.revenue),
        }
        for r in results
    ]


def get_network_distribution(db: Session) -> List[dict]:
    """Get transaction count and revenue by network."""
    results = (
        db.query(
            Transaction.network,
            func.count(Transaction.id).label("count"),
            func.coalesce(func.sum(Transaction.amount), 0).label("revenue"),
        )
        .filter(
            Transaction.status == TransactionStatus.success,
            Transaction.network.isnot(None),
        )
        .group_by(Transaction.network)
        .order_by(func.sum(Transaction.amount).desc())
        .all()
    )

    return [
        {
            "network": r.network,
            "count": r.count,
            "revenue": float(r.revenue),
        }
        for r in results
    ]


def get_top_users(db: Session, limit: int = 10) -> List[dict]:
    """Get top users by total spend."""
    results = (
        db.query(
            User.id,
            User.phone_number,
            User.full_name,
            func.count(Transaction.id).label("transaction_count"),
            func.coalesce(func.sum(Transaction.amount), 0).label("total_spent"),
        )
        .join(Transaction, Transaction.user_id == User.id)
        .filter(Transaction.status == TransactionStatus.success)
        .group_by(User.id, User.phone_number, User.full_name)
        .order_by(func.sum(Transaction.amount).desc())
        .limit(limit)
        .all()
    )

    return [
        {
            "user_id": str(r.id),
            "phone_number": r.phone_number,
            "full_name": r.full_name,
            "transaction_count": r.transaction_count,
            "total_spent": float(r.total_spent),
        }
        for r in results
    ]


def get_transaction_type_breakdown(db: Session) -> List[dict]:
    """Get transaction count by type."""
    results = (
        db.query(
            Transaction.type,
            func.count(Transaction.id).label("count"),
        )
        .group_by(Transaction.type)
        .order_by(func.count(Transaction.id).desc())
        .all()
    )

    return [
        {
            "type": r.type.value if hasattr(r.type, "value") else str(r.type),
            "count": r.count,
        }
        for r in results
    ]

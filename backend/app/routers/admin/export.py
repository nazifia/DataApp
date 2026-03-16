import io
from datetime import datetime
from typing import Optional

from fastapi import APIRouter, Depends
from fastapi.responses import StreamingResponse
from fastapi import HTTPException
from reportlab.lib import colors
from reportlab.lib.pagesizes import A4, landscape
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import mm
from reportlab.platypus import SimpleDocTemplate, Table, TableStyle, Paragraph, Spacer, HRFlowable
from sqlalchemy.orm import Session, joinedload

from app.database import get_db
from app.models.user import User
from app.models.wallet import Wallet
from app.models.transaction import Transaction, TransactionStatus
from app.utils.admin_auth import get_current_admin

router = APIRouter(tags=["Admin Export"])

# ── Shared PDF helpers ────────────────────────────────────────────────────────

_HEADER_BG  = colors.HexColor("#1e40af")   # blue-800
_ALT_ROW_BG = colors.HexColor("#eff6ff")   # blue-50


def _doc(buffer, title: str, landscape_mode: bool = False) -> SimpleDocTemplate:
    pagesize = landscape(A4) if landscape_mode else A4
    return SimpleDocTemplate(
        buffer,
        pagesize=pagesize,
        rightMargin=15 * mm,
        leftMargin=15 * mm,
        topMargin=20 * mm,
        bottomMargin=15 * mm,
        title=title,
    )


def _header(title: str, subtitle: str):
    styles = getSampleStyleSheet()
    return [
        Paragraph(f"<b>ADP Nigeria &mdash; {title}</b>", styles["Title"]),
        Paragraph(subtitle, styles["Normal"]),
        Paragraph(
            f"<font size='8' color='grey'>Generated: "
            f"{datetime.utcnow().strftime('%Y-%m-%d %H:%M UTC')}</font>",
            styles["Normal"],
        ),
        Spacer(1, 6 * mm),
    ]


def _table_style() -> TableStyle:
    return TableStyle([
        # Header row
        ("BACKGROUND",    (0, 0), (-1, 0),  _HEADER_BG),
        ("TEXTCOLOR",     (0, 0), (-1, 0),  colors.white),
        ("FONTNAME",      (0, 0), (-1, 0),  "Helvetica-Bold"),
        ("FONTSIZE",      (0, 0), (-1, 0),  9),
        ("TOPPADDING",    (0, 0), (-1, 0),  8),
        ("BOTTOMPADDING", (0, 0), (-1, 0),  8),
        # Data rows
        ("FONTNAME",      (0, 1), (-1, -1), "Helvetica"),
        ("FONTSIZE",      (0, 1), (-1, -1), 8),
        ("TOPPADDING",    (0, 1), (-1, -1), 5),
        ("BOTTOMPADDING", (0, 1), (-1, -1), 5),
        ("ROWBACKGROUNDS",(0, 1), (-1, -1), [colors.white, _ALT_ROW_BG]),
        # Grid
        ("GRID",          (0, 0), (-1, -1), 0.4, colors.HexColor("#e5e7eb")),
        ("LINEBELOW",     (0, 0), (-1, 0),  1.5, _HEADER_BG),
        # Padding / alignment
        ("ALIGN",         (0, 0), (-1, -1), "LEFT"),
        ("VALIGN",        (0, 0), (-1, -1), "MIDDLE"),
        ("LEFTPADDING",   (0, 0), (-1, -1), 6),
        ("RIGHTPADDING",  (0, 0), (-1, -1), 6),
    ])


def _pdf_response(buffer: io.BytesIO, filename: str) -> StreamingResponse:
    buffer.seek(0)
    return StreamingResponse(
        buffer,
        media_type="application/pdf",
        headers={"Content-Disposition": f"attachment; filename={filename}"},
    )


# ── Users PDF ─────────────────────────────────────────────────────────────────

@router.get("/users.pdf")
async def export_users_pdf(
    db: Session = Depends(get_db),
    admin: User = Depends(get_current_admin),
):
    """Export all users as a formatted PDF."""
    users = db.query(User).order_by(User.created_at.desc()).all()

    rows = [["Phone", "Full Name", "Role", "Active", "Joined"]]
    for u in users:
        rows.append([
            u.phone_number or "",
            u.full_name or "—",
            u.role.value if hasattr(u.role, "value") else str(u.role),
            "Yes" if u.is_active else "No",
            u.created_at.strftime("%Y-%m-%d") if u.created_at else "—",
        ])

    col_widths = [45 * mm, 52 * mm, 30 * mm, 20 * mm, 28 * mm]
    table = Table(rows, colWidths=col_widths, repeatRows=1)
    table.setStyle(_table_style())

    buffer = io.BytesIO()
    story = _header(
        "Users Report",
        f"{len(users)} user(s) exported",
    ) + [table]
    _doc(buffer, "ADP Nigeria — Users Report").build(story)

    filename = f"users_{datetime.utcnow().strftime('%Y%m%d_%H%M')}.pdf"
    return _pdf_response(buffer, filename)


# ── Transactions PDF ──────────────────────────────────────────────────────────

@router.get("/transactions.pdf")
async def export_transactions_pdf(
    type: Optional[str] = None,
    status: Optional[str] = None,
    date_from: Optional[str] = None,
    date_to: Optional[str] = None,
    db: Session = Depends(get_db),
    admin: User = Depends(get_current_admin),
):
    """Export transactions as a formatted PDF with optional filters."""
    query = db.query(Transaction).options(joinedload(Transaction.user))

    if type:
        query = query.filter(Transaction.type == type)
    if status:
        query = query.filter(Transaction.status == status)
    if date_from:
        try:
            query = query.filter(
                Transaction.created_at >= datetime.strptime(date_from, "%Y-%m-%d")
            )
        except ValueError:
            pass
    if date_to:
        try:
            to_dt = datetime.strptime(date_to, "%Y-%m-%d").replace(
                hour=23, minute=59, second=59
            )
            query = query.filter(Transaction.created_at <= to_dt)
        except ValueError:
            pass

    txns = query.order_by(Transaction.created_at.desc()).all()

    rows = [["Reference", "User Phone", "Name", "Type", "Amount (NGN)", "Status", "Network", "Date"]]
    for txn in txns:
        rows.append([
            txn.reference or "—",
            txn.user.phone_number if txn.user else "—",
            txn.user.full_name if txn.user else "—",
            txn.type.value if hasattr(txn.type, "value") else str(txn.type),
            f"{float(txn.amount):,.2f}",
            txn.status.value if hasattr(txn.status, "value") else str(txn.status),
            (txn.network or "—").upper(),
            txn.created_at.strftime("%Y-%m-%d %H:%M") if txn.created_at else "—",
        ])

    col_widths = [38 * mm, 33 * mm, 30 * mm, 22 * mm, 28 * mm, 20 * mm, 20 * mm, 33 * mm]
    table = Table(rows, colWidths=col_widths, repeatRows=1)
    table.setStyle(_table_style())

    filter_parts = []
    if type:      filter_parts.append(f"Type: {type}")
    if status:    filter_parts.append(f"Status: {status}")
    if date_from: filter_parts.append(f"From: {date_from}")
    if date_to:   filter_parts.append(f"To: {date_to}")
    subtitle = f"{len(txns)} transaction(s) exported"
    if filter_parts:
        subtitle += f"  |  Filters: {', '.join(filter_parts)}"

    buffer = io.BytesIO()
    story = _header("Transactions Report", subtitle) + [table]
    _doc(buffer, "ADP Nigeria — Transactions Report", landscape_mode=True).build(story)

    filename = f"transactions_{datetime.utcnow().strftime('%Y%m%d_%H%M')}.pdf"
    return _pdf_response(buffer, filename)


# ── User Detail PDF ───────────────────────────────────────────────────────────

@router.get("/users/{user_id}.pdf")
async def export_user_detail_pdf(
    user_id: str,
    db: Session = Depends(get_db),
    admin: User = Depends(get_current_admin),
):
    """Export a single user's full profile and transaction history as PDF."""
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    wallet = db.query(Wallet).filter(Wallet.user_id == user.id).first()
    balance = float(wallet.balance) if wallet else 0.0

    txns = (
        db.query(Transaction)
        .filter(Transaction.user_id == user.id)
        .order_by(Transaction.created_at.desc())
        .all()
    )
    total_spent = sum(
        float(t.amount)
        for t in txns
        if hasattr(t.status, "value") and t.status == TransactionStatus.success
    )

    styles = getSampleStyleSheet()
    label_style = ParagraphStyle(
        "Label",
        parent=styles["Normal"],
        fontSize=8,
        textColor=colors.HexColor("#6b7280"),
        spaceAfter=1,
    )
    value_style = ParagraphStyle(
        "Value",
        parent=styles["Normal"],
        fontSize=10,
        fontName="Helvetica-Bold",
        textColor=colors.HexColor("#111827"),
        spaceAfter=6,
    )

    def _info_row(label: str, value: str):
        return [Paragraph(label, label_style), Paragraph(value or "—", value_style)]

    # ── Profile info grid (2-column key/value table) ──────────────────────────
    profile_data = [
        _info_row("Phone Number",       user.phone_number or "—"),
        _info_row("Full Name",          user.full_name or "—"),
        _info_row("Role",               user.role.value if hasattr(user.role, "value") else str(user.role)),
        _info_row("Status",             "Active" if user.is_active else "Inactive"),
        _info_row("Wallet Balance",     f"NGN {balance:,.2f}"),
        _info_row("Total Transactions", str(len(txns))),
        _info_row("Total Spent",        f"NGN {total_spent:,.2f}"),
        _info_row("Device ID",          user.device_id or "—"),
        _info_row("Joined",             user.created_at.strftime("%Y-%m-%d %H:%M") if user.created_at else "—"),
        _info_row("Last Updated",       user.updated_at.strftime("%Y-%m-%d %H:%M") if user.updated_at else "—"),
    ]

    profile_table = Table(profile_data, colWidths=[45 * mm, 130 * mm])
    profile_table.setStyle(TableStyle([
        ("BACKGROUND",    (0, 0), (0, -1), colors.HexColor("#f9fafb")),
        ("GRID",          (0, 0), (-1, -1), 0.4, colors.HexColor("#e5e7eb")),
        ("TOPPADDING",    (0, 0), (-1, -1), 4),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 4),
        ("LEFTPADDING",   (0, 0), (-1, -1), 8),
        ("RIGHTPADDING",  (0, 0), (-1, -1), 8),
        ("VALIGN",        (0, 0), (-1, -1), "TOP"),
    ]))

    # ── Transactions table ────────────────────────────────────────────────────
    txn_rows = [["Reference", "Type", "Amount (NGN)", "Status", "Network", "Recipient Phone", "Date"]]
    for txn in txns:
        txn_rows.append([
            txn.reference or "—",
            txn.type.value if hasattr(txn.type, "value") else str(txn.type),
            f"{float(txn.amount):,.2f}",
            txn.status.value if hasattr(txn.status, "value") else str(txn.status),
            (txn.network or "—").upper(),
            txn.phone_number or "—",
            txn.created_at.strftime("%Y-%m-%d %H:%M") if txn.created_at else "—",
        ])

    txn_col_widths = [42 * mm, 24 * mm, 28 * mm, 22 * mm, 22 * mm, 30 * mm, 32 * mm]
    txn_table = Table(txn_rows, colWidths=txn_col_widths, repeatRows=1)
    txn_table.setStyle(_table_style())

    section_style = ParagraphStyle(
        "Section",
        parent=styles["Heading2"],
        fontSize=11,
        textColor=_HEADER_BG,
        spaceBefore=10,
        spaceAfter=4,
    )

    display_name = user.full_name or user.phone_number
    story = (
        _header("User Detail Report", f"Profile for {display_name}")
        + [
            Paragraph("Profile Information", section_style),
            HRFlowable(width="100%", thickness=1, color=_HEADER_BG, spaceAfter=4),
            profile_table,
            Spacer(1, 8 * mm),
            Paragraph(f"Transaction History ({len(txns)} records)", section_style),
            HRFlowable(width="100%", thickness=1, color=_HEADER_BG, spaceAfter=4),
        ]
        + ([txn_table] if len(txns) > 0 else [Paragraph("No transactions found.", styles["Normal"])])
    )

    buffer = io.BytesIO()
    _doc(buffer, f"ADP Nigeria — User Report: {display_name}", landscape_mode=True).build(story)

    safe_name = (user.phone_number or user_id).replace("+", "").replace(" ", "")
    filename = f"user_{safe_name}_{datetime.utcnow().strftime('%Y%m%d_%H%M')}.pdf"
    return _pdf_response(buffer, filename)

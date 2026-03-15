import bcrypt as bcrypt_lib

from fastapi import APIRouter, Depends, Form, HTTPException, Request
from fastapi.responses import HTMLResponse, RedirectResponse
from fastapi.templating import Jinja2Templates
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.user import User, UserRole
from app.utils.admin_auth import create_admin_session_token, get_current_admin

router = APIRouter(tags=["Admin Pages"])
templates = Jinja2Templates(directory="templates")


@router.get("/admin/login", response_class=HTMLResponse)
async def login_page(request: Request):
    """Render admin login page."""
    return templates.TemplateResponse("admin/login.html", {"request": request})


@router.post("/admin/login")
async def login_submit(
    request: Request,
    phone: str = Form(...),
    password: str = Form(...),
    db: Session = Depends(get_db),
):
    """Process admin login form."""
    user = db.query(User).filter(User.phone_number == phone).first()

    if not user or not user.password_hash:
        return templates.TemplateResponse(
            "admin/login.html",
            {"request": request, "error": "Invalid credentials"},
            status_code=401,
        )

    if not bcrypt_lib.checkpw(password.encode('utf-8'), user.password_hash.encode('utf-8')):
        return templates.TemplateResponse(
            "admin/login.html",
            {"request": request, "error": "Invalid credentials"},
            status_code=401,
        )

    if user.role != UserRole.admin:
        return templates.TemplateResponse(
            "admin/login.html",
            {"request": request, "error": "Access denied: admin role required"},
            status_code=403,
        )

    if not user.is_active:
        return templates.TemplateResponse(
            "admin/login.html",
            {"request": request, "error": "Account is inactive"},
            status_code=403,
        )

    token = create_admin_session_token(str(user.id))
    response = RedirectResponse(url="/admin/dashboard", status_code=302)
    response.set_cookie(
        key="admin_session",
        value=token,
        httponly=True,
        max_age=8 * 60 * 60,  # 8 hours
        samesite="lax",
    )
    return response


@router.get("/admin/logout")
async def logout():
    """Clear admin session and redirect to login."""
    response = RedirectResponse(url="/admin/login", status_code=302)
    response.delete_cookie("admin_session")
    return response


@router.get("/admin/dashboard", response_class=HTMLResponse)
async def dashboard_page(request: Request, admin: User = Depends(get_current_admin)):
    return templates.TemplateResponse(
        "admin/dashboard.html",
        {"request": request, "admin_name": admin.full_name or admin.phone_number, "active_page": "dashboard"},
    )


@router.get("/admin/users", response_class=HTMLResponse)
async def users_page(request: Request, admin: User = Depends(get_current_admin)):
    return templates.TemplateResponse(
        "admin/users.html",
        {"request": request, "admin_name": admin.full_name or admin.phone_number, "active_page": "users"},
    )


@router.get("/admin/users/{user_id}", response_class=HTMLResponse)
async def user_detail_page(request: Request, user_id: str, admin: User = Depends(get_current_admin)):
    return templates.TemplateResponse(
        "admin/user_detail.html",
        {"request": request, "admin_name": admin.full_name or admin.phone_number, "active_page": "users"},
    )


@router.get("/admin/transactions", response_class=HTMLResponse)
async def transactions_page(request: Request, admin: User = Depends(get_current_admin)):
    return templates.TemplateResponse(
        "admin/transactions.html",
        {"request": request, "admin_name": admin.full_name or admin.phone_number, "active_page": "transactions"},
    )


@router.get("/admin/transactions/{txn_id}", response_class=HTMLResponse)
async def transaction_detail_page(request: Request, txn_id: str, admin: User = Depends(get_current_admin)):
    return templates.TemplateResponse(
        "admin/transaction_detail.html",
        {"request": request, "admin_name": admin.full_name or admin.phone_number, "active_page": "transactions"},
    )


@router.get("/admin/wallets", response_class=HTMLResponse)
async def wallets_page(request: Request, admin: User = Depends(get_current_admin)):
    return templates.TemplateResponse(
        "admin/wallets.html",
        {"request": request, "admin_name": admin.full_name or admin.phone_number, "active_page": "wallets"},
    )


@router.get("/admin/data-plans", response_class=HTMLResponse)
async def data_plans_page(request: Request, admin: User = Depends(get_current_admin)):
    return templates.TemplateResponse(
        "admin/data_plans.html",
        {"request": request, "admin_name": admin.full_name or admin.phone_number, "active_page": "data_plans"},
    )


@router.get("/admin/analytics", response_class=HTMLResponse)
async def analytics_page(request: Request, admin: User = Depends(get_current_admin)):
    return templates.TemplateResponse(
        "admin/analytics.html",
        {"request": request, "admin_name": admin.full_name or admin.phone_number, "active_page": "analytics"},
    )


@router.get("/admin/settings", response_class=HTMLResponse)
async def settings_page(request: Request, admin: User = Depends(get_current_admin)):
    return templates.TemplateResponse(
        "admin/settings.html",
        {"request": request, "admin_name": admin.full_name or admin.phone_number, "active_page": "settings"},
    )


@router.get("/admin/audit-log", response_class=HTMLResponse)
async def audit_log_page(request: Request, admin: User = Depends(get_current_admin)):
    return templates.TemplateResponse(
        "admin/audit_log.html",
        {"request": request, "admin_name": admin.full_name or admin.phone_number, "active_page": "audit_log"},
    )

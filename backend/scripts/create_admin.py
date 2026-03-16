#!/usr/bin/env python
"""CLI script to create the first admin user."""

import argparse
import sys
import os

# Add parent directory to path so we can import app modules
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

from alembic.config import Config
from alembic import command
from passlib.context import CryptContext

from app.database import SessionLocal
from app.models.user import User, UserRole
from app.models.wallet import Wallet
from app.utils.validators import normalize_phone_number

pwd_context = CryptContext(schemes=["pbkdf2_sha256"], deprecated="auto")

# Run any pending Alembic migrations before proceeding
def _run_migrations():
    alembic_cfg = Config(os.path.join(os.path.dirname(__file__), "..", "alembic.ini"))
    alembic_cfg.set_main_option("script_location", os.path.join(os.path.dirname(__file__), "..", "alembic"))
    command.upgrade(alembic_cfg, "head")

_run_migrations()


def hash_password(password: str) -> str:
    return pwd_context.hash(password)


def create_admin(phone: str, password: str, name: str = "Admin", role: str = "admin"):
    """Create an admin user or promote an existing user to the specified role."""
    normalized_phone = normalize_phone_number(phone)
    if normalized_phone is None:
        print(f"ERROR: Invalid phone number '{phone}'. Use format: 08XXXXXXXXX or +2348XXXXXXXXX")
        sys.exit(1)

    db = SessionLocal()
    try:
        # Validate role
        target_role = UserRole(role)

        # Check if user already exists (search both normalized and raw to handle legacy data)
        user = db.query(User).filter(User.phone_number == normalized_phone).first()
        if user is None:
            user = db.query(User).filter(User.phone_number == phone).first()

        if user:
            # Promote existing user to specified role; also fix phone format & rehash password
            user.phone_number = normalized_phone
            user.role = target_role
            if password:
                user.password_hash = hash_password(password)
            if name:
                user.full_name = name
            db.commit()
            db.refresh(user)
            # Ensure wallet exists
            if not db.query(Wallet).filter(Wallet.user_id == user.id).first():
                db.add(Wallet(user_id=user.id, balance=0))
                db.commit()
                print(f"  Wallet created.")
            print(f"SUCCESS: User {normalized_phone} promoted to {target_role.value} role.")
            print(f"  User ID: {user.id}")
            print(f"  Name: {user.full_name}")
            print(f"  Role: {user.role}")
            return user

        # Create new admin user
        hashed_password = hash_password(password)
        new_admin = User(
            phone_number=normalized_phone,
            full_name=name,
            password_hash=hashed_password,
            is_active=True,
            role=target_role,
        )
        db.add(new_admin)
        db.commit()
        db.refresh(new_admin)
        db.add(Wallet(user_id=new_admin.id, balance=0))
        db.commit()

        print(f"SUCCESS: Admin user created.")
        print(f"  Phone: {normalized_phone}")
        print(f"  Name: {name}")
        print(f"  User ID: {new_admin.id}")
        print(f"  Role: {new_admin.role}")
        return new_admin

    except ValueError as e:
        db.rollback()
        print(f"ERROR: Invalid role '{role}'. Must be one of: {', '.join([r.value for r in UserRole])}")
        sys.exit(1)
    except Exception as e:
        db.rollback()
        print(f"ERROR: Failed to create admin: {e}")
        sys.exit(1)
    finally:
        db.close()


def main():
    parser = argparse.ArgumentParser(description="Create or promote an admin user for TopUpNaija Admin Panel.")
    parser.add_argument("--phone", required=True, help="Phone number for the admin user (e.g., 08012345678)")
    parser.add_argument("--password", required=True, help="Password for the admin user")
    parser.add_argument("--name", default="Admin", help="Full name for the admin user (default: Admin)")
    parser.add_argument(
        "--role",
        default="admin",
        choices=["super_admin", "admin", "moderator", "support"],
        help="Role for the admin user (default: admin)",
    )

    args = parser.parse_args()
    create_admin(args.phone, args.password, args.name, args.role)


if __name__ == "__main__":
    main()

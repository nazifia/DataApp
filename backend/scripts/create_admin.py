#!/usr/bin/env python
"""CLI script to create the first admin user."""

import argparse
import sys
import os

# Add parent directory to path so we can import app modules
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

import bcrypt as bcrypt_lib

from app.database import SessionLocal, engine
from app.models.user import User, UserRole
from app.models import user as user_module, wallet as wallet_module, transaction as transaction_module, audit_log as audit_module

# Ensure all tables exist
user_module.Base.metadata.create_all(bind=engine)
wallet_module.Base.metadata.create_all(bind=engine)
transaction_module.Base.metadata.create_all(bind=engine)
audit_module.Base.metadata.create_all(bind=engine)


def hash_password(password: str) -> str:
    """Hash a password using bcrypt."""
    return bcrypt_lib.hashpw(password.encode('utf-8'), bcrypt_lib.gensalt()).decode('utf-8')


def create_admin(phone: str, password: str, name: str = "Admin", role: str = "admin"):
    """Create an admin user or promote an existing user to the specified role."""
    db = SessionLocal()
    try:
        # Validate role
        target_role = UserRole(role)

        # Check if user already exists
        user = db.query(User).filter(User.phone_number == phone).first()

        if user:
            # Promote existing user to specified role
            user.role = target_role
            if password:
                user.password_hash = hash_password(password)
            if name:
                user.full_name = name
            db.commit()
            db.refresh(user)
            print(f"SUCCESS: User {phone} promoted to {target_role.value} role.")
            print(f"  User ID: {user.id}")
            print(f"  Name: {user.full_name}")
            print(f"  Role: {user.role}")
            return user

        # Create new admin user
        hashed_password = hash_password(password)
        new_admin = User(
            phone_number=phone,
            full_name=name,
            password_hash=hashed_password,
            is_active=True,
            role=target_role,
        )
        db.add(new_admin)
        db.commit()
        db.refresh(new_admin)

        print(f"SUCCESS: Admin user created.")
        print(f"  Phone: {phone}")
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
    parser = argparse.ArgumentParser(description="Create or promote an admin user for ADP Admin Panel.")
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

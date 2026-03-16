"""expand user roles enum

Revision ID: 002_expand_user_roles
Revises: 001_add_password_hash
Create Date: 2026-03-15
"""
from alembic import op
import sqlalchemy as sa

revision = '002_expand_user_roles'
down_revision = '001_add_password_hash'
branch_labels = None
depends_on = None

NEW_ROLE_ENUM = sa.Enum('user', 'support', 'moderator', 'admin', 'super_admin', name='userrole')
OLD_ROLE_ENUM = sa.Enum('user', 'admin', name='userrole')


def upgrade() -> None:
    with op.batch_alter_table('users', schema=None) as batch_op:
        batch_op.alter_column(
            'role',
            existing_type=OLD_ROLE_ENUM,
            type_=NEW_ROLE_ENUM,
            existing_nullable=False,
        )


def downgrade() -> None:
    with op.batch_alter_table('users', schema=None) as batch_op:
        batch_op.alter_column(
            'role',
            existing_type=NEW_ROLE_ENUM,
            type_=OLD_ROLE_ENUM,
            existing_nullable=False,
        )

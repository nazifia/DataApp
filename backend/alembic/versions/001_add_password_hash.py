"""add password_hash to users

Revision ID: 001_add_password_hash
Revises:
Create Date: 2026-03-14
"""
from alembic import op
import sqlalchemy as sa

revision = '001_add_password_hash'
down_revision = None
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column('users', sa.Column('password_hash', sa.String(), nullable=True))


def downgrade() -> None:
    op.drop_column('users', 'password_hash')

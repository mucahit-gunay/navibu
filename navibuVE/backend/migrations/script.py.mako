"""fix_routes_schema

Revision ID: ${up_revision}
Revises: ${down_revision | comma,n}
Create Date: ${create_date}

"""
from alembic import op
import sqlalchemy as sa
${imports if imports else ""}

# revision identifiers, used by Alembic.
revision = ${repr(up_revision)}
down_revision = ${repr(down_revision)}
branch_labels = ${repr(branch_labels)}
depends_on = ${repr(depends_on)}


def upgrade():
    # Drop existing foreign key constraint
    op.drop_constraint('user_routes_ibfk_2', 'user_routes', type_='foreignkey')
    
    # Rename route_id to id in routes table
    op.alter_column('routes', 'route_id', new_column_name='id', existing_type=sa.Integer())
    
    # Add new foreign key constraint
    op.create_foreign_key(
        'user_routes_route_id_fkey',
        'user_routes', 'routes',
        ['route_id'], ['id']
    )


def downgrade():
    # Drop new foreign key constraint
    op.drop_constraint('user_routes_route_id_fkey', 'user_routes', type_='foreignkey')
    
    # Rename id back to route_id in routes table
    op.alter_column('routes', 'id', new_column_name='route_id', existing_type=sa.Integer())
    
    # Add back original foreign key constraint
    op.create_foreign_key(
        'user_routes_ibfk_2',
        'user_routes', 'routes',
        ['route_id'], ['route_id']
    ) 
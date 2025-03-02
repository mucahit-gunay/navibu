from extensions import db

user_routes = db.Table('user_routes',
    db.Column('user_id', db.Integer, db.ForeignKey('users.id', ondelete="CASCADE"), primary_key=True),
    db.Column('route_id', db.Integer, db.ForeignKey('routes.id', ondelete="CASCADE"), primary_key=True)
)
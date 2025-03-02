from ..extensions import db

user_routes = db.Table('user_routes',
    db.Column('user_id', db.Integer, db.ForeignKey('users.id'), primary_key=True),
    db.Column('route_id', db.Integer, db.ForeignKey('routes.id'), primary_key=True)
)

class Route(db.Model):
    __tablename__ = 'routes'
    id = db.Column(db.Integer, primary_key=True)
    route_short_name = db.Column(db.String(50), nullable=False)
    route_long_name = db.Column(db.String(200), nullable=False)
    
    users = db.relationship('User', secondary=user_routes, backref=db.backref('routes', lazy='dynamic'))

    def to_dict(self):
        return {
            'id': self.id,
            'route_short_name': self.route_short_name,
            'route_long_name': self.route_long_name
        }



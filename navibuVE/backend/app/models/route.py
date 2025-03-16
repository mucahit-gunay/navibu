from ..extensions import db

class Route(db.Model):
    __tablename__ = 'routes'
    
    id = db.Column(db.Integer, primary_key=True)
    route_short_name = db.Column(db.String(50), nullable=False, unique=True)
    route_long_name = db.Column(db.String(200), nullable=False)
    
    # Update the relationships with back_populates and overlaps
    users = db.relationship('User',
                          secondary='user_routes',
                          back_populates='routes',
                          overlaps="user_routes,routes")
    
    user_routes = db.relationship('UserRoute',
                                back_populates='route',
                                overlaps="users,routes")
    
    def to_dict(self):
        return {
            'id': self.id,
            'route_short_name': self.route_short_name,
            'route_long_name': self.route_long_name
        }



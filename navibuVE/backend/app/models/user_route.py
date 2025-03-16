from ..extensions import db

class UserRoute(db.Model):
    __tablename__ = 'user_routes'

    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    route_id = db.Column(db.Integer, db.ForeignKey('routes.id'), nullable=False)
    created_at = db.Column(db.DateTime, server_default=db.func.now())

    # Update relationships with back_populates and overlaps
    user = db.relationship('User', 
                         back_populates='user_routes',
                         overlaps="routes,users")
    
    route = db.relationship('Route', 
                          back_populates='user_routes',
                          overlaps="users,routes")

    def __repr__(self):
        return f'<UserRoute {self.user_id}-{self.route_id}>'

    def to_dict(self):
        return {
            'id': self.id,
            'user_id': self.user_id,
            'route_id': self.route_id,
            'is_favorite': self.is_favorite
        } 
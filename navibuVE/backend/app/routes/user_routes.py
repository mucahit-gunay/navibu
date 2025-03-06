from flask import Blueprint, request, jsonify
from ..models.user import User
from ..models.route import Route
from ..models.user_route import UserRoute
from ..extensions import db

user_routes_bp = Blueprint('user_routes', __name__)

@user_routes_bp.route('/add_favorite_route', methods=['POST'])
def add_favorite_route():
    data = request.json
    user = User.query.get(data['user_id'])
    route = Route.query.get(data['route_id'])

    if not user or not route:
        return jsonify({"error": "User or Route not found"}), 404

    # Create new UserRoute association
    user_route = UserRoute(user_id=user.id, route_id=route.id)
    db.session.add(user_route)
    db.session.commit()

    return jsonify({"message": "Route added to favorites"}), 200

@user_routes_bp.route('/get_favorite_routes/<int:user_id>', methods=['GET'])
def get_favorite_routes(user_id):
    user = User.query.get(user_id)
    if not user:
        return jsonify({"error": "User not found"}), 404

    favorite_routes = [{"id": ur.route.id, "name": ur.route.route_short_name} 
                      for ur in user.user_routes]
    
    return jsonify(favorite_routes), 200

@user_routes_bp.route('/user/<int:user_id>/routes', methods=['GET'])
def get_user_routes(user_id):
    """Get user's selected routes"""
    user = User.query.get_or_404(user_id)
    routes = [ur.route.to_dict() for ur in user.user_routes]
    return jsonify({
        'routes': routes,
        'has_selected_routes': len(routes) > 0
    })

@user_routes_bp.route('/user/<int:user_id>/routes', methods=['POST'])
def update_user_routes(user_id):
    """Update user's route selections"""
    user = User.query.get_or_404(user_id)
    data = request.json
    route_ids = data.get('route_ids', [])
    
    try:
        # Clear existing routes
        UserRoute.query.filter_by(user_id=user_id).delete()
        
        # Add new routes
        for route_id in route_ids:
            route = Route.query.get(route_id)
            if route:
                user_route = UserRoute(user_id=user_id, route_id=route_id)
                db.session.add(user_route)
        
        db.session.commit()
        return jsonify({'message': 'Routes updated successfully'}), 200
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 400

@user_routes_bp.route('/routes', methods=['GET'])
def get_all_routes():
    """Get all available routes"""
    routes = Route.query.all()
    return jsonify({
        'routes': [route.to_dict() for route in routes]
    })

@user_routes_bp.route('/user/check_route_selection/<int:user_id>', methods=['GET'])
def check_route_selection(user_id):
    """Check if user has selected any routes"""
    count = UserRoute.query.filter_by(user_id=user_id).count()
    return jsonify({
        'has_selected_routes': count > 0
    })

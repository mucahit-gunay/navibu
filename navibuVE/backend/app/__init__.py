from flask import Flask
from flask_cors import CORS
from .config import Config
from .extensions import db, mail
from .routes.auth import auth_bp
from .routes.user_routes import user_routes_bp

def create_app():
    app = Flask(__name__)
    CORS(app)  # Enable CORS for all routes
    
    # Configure app
    app.config.from_object(Config)
    
    # Initialize extensions
    db.init_app(app)
    mail.init_app(app)
    
    # Register blueprints
    app.register_blueprint(auth_bp, url_prefix="/auth")
    app.register_blueprint(user_routes_bp, url_prefix="/api")
    
    # Create database tables
    with app.app_context():
        db.create_all()
    
    return app 
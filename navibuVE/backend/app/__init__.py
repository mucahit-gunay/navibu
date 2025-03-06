from flask import Flask
from .config import Config
from .extensions import db, mail

def create_app():
    app = Flask(__name__)
    app.config.from_object(Config)

    # Initialize extensions
    db.init_app(app)
    mail.init_app(app)

    # Import and register blueprints
    from .routes.auth import auth_bp
    from .routes.user_routes import user_routes_bp

    # Register blueprints with prefixes
    app.register_blueprint(auth_bp, url_prefix="/auth")
    app.register_blueprint(user_routes_bp, url_prefix="/api")

    return app 
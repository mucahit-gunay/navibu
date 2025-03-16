import os
from datetime import timedelta
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

class Config:
    SECRET_KEY = os.environ.get('SECRET_KEY', 'your-secret-key-here')
    SQLALCHEMY_DATABASE_URI = "mysql+pymysql://root:Navibu161308_@localhost/NavibuDB"
    SQLALCHEMY_TRACK_MODIFICATIONS = False
    
    # Email Configuration
    MAIL_SERVER = 'smtp.gmail.com'
    MAIL_PORT = 587
    MAIL_USERNAME = os.environ.get('MAIL_USERNAME')
    MAIL_PASSWORD = os.environ.get('MAIL_PASSWORD')
    MAIL_USE_TLS = True
    MAIL_USE_SSL = False
    MAIL_DEFAULT_SENDER = os.environ.get('MAIL_USERNAME')
    MAIL_DEBUG = True  # Enable debug mode for email
    MAIL_SUPPRESS_SEND = False  # Don't suppress sending emails
    MAIL_MAX_EMAILS = None  # No limit on emails per connection
    MAIL_ASCII_ATTACHMENTS = False  # Allow UTF-8 attachments

    # Database Configuration
    MYSQL_HOST = 'localhost'
    MYSQL_USER = 'root'
    MYSQL_PASSWORD = 'Navibu161308_'
    MYSQL_DB = 'navibuDB'

    # JWT Settings
    JWT_SECRET_KEY = os.environ.get('JWT_SECRET_KEY', 'your-secret-key-here')
    JWT_ACCESS_TOKEN_EXPIRES = timedelta(hours=24)

    @staticmethod
    def init_app(app):
        pass
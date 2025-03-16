from flask_sqlalchemy import SQLAlchemy
from flask_mail import Mail
from flask_mysqldb import MySQL
from flask_jwt_extended import JWTManager

db = SQLAlchemy()
mail = Mail()
mysql = MySQL()
jwt = JWTManager()

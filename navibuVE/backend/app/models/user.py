import datetime
import random
import string
from ..extensions import db, mail
from flask_mail import Message

class User(db.Model):
    __tablename__ = 'users'
    
    id = db.Column(db.Integer, primary_key=True)
    email = db.Column(db.String(120), unique=True, nullable=False)
    password_hash = db.Column(db.String(255), nullable=False)
    is_verified = db.Column(db.Boolean, default=False)
    verification_code = db.Column(db.String(6), nullable=True)
    verification_expiry = db.Column(db.DateTime, nullable=True)

    def generate_verification_code(self):
        return ''.join(random.choices(string.digits, k=6))

    def send_verification_email(self):
        msg = Message(
            'Email Doğrulama',
            recipients=[self.email]
        )
        msg.body = f'Doğrulama kodunuz: {self.verification_code}'
        mail.send(msg)


from ..extensions import db
from werkzeug.security import generate_password_hash, check_password_hash
import random
import string
from datetime import datetime, timedelta
from flask_mail import Message
from ..extensions import mail

class User(db.Model):
    __tablename__ = 'users'
    
    id = db.Column(db.Integer, primary_key=True)
    email = db.Column(db.String(120), unique=True, nullable=False)
    password_hash = db.Column(db.String(256), nullable=False)
    name = db.Column(db.String(100), nullable=True)
    surname = db.Column(db.String(100), nullable=True)
    is_verified = db.Column(db.Boolean, default=False)
    verification_code = db.Column(db.String(6), nullable=True)
    verification_expiry = db.Column(db.DateTime, nullable=True)
    reset_code = db.Column(db.String(6))
    reset_code_timestamp = db.Column(db.DateTime)

    routes = db.relationship('Route', 
                           secondary='user_routes',
                           back_populates='users',
                           overlaps="user_routes,routes")
    
    user_routes = db.relationship('UserRoute', 
                                back_populates='user',
                                overlaps="routes,users")

    def generate_verification_code(self):
        return ''.join(random.choices(string.digits, k=6))

    def send_verification_email(self):
        msg = Message(
            'Navibu - Email Doğrulama',
            recipients=[self.email]
        )
        msg.body = f'''
        Merhaba,
        
        Navibu'ya hoş geldiniz! E-posta adresinizi doğrulamak için aşağıdaki kodu kullanın:
        
        Doğrulama Kodunuz: {self.verification_code}
        
        Bu kod 30 dakika içinde geçerliliğini yitirecektir.
        
        Eğer bu işlemi siz yapmadıysanız, lütfen bu e-postayı dikkate almayın.
        
        İyi günler,
        Navibu Ekibi
        '''
        mail.send(msg)

    def set_password(self, password):
        self.password_hash = generate_password_hash(password)

    def check_password(self, password):
        return check_password_hash(self.password_hash, password)

    def verify_password(self, password):
        return check_password_hash(self.password_hash, password)

    def verify_reset_code(self, code):
        if not self.reset_code or not self.reset_code_timestamp:
            return False
        
        # Check if code is expired (15 minutes)
        if datetime.utcnow() - self.reset_code_timestamp > timedelta(minutes=15):
            return False
            
        return self.reset_code == code

    def to_dict(self):
        return {
            'id': self.id,
            'email': self.email,
            'name': self.name or '',
            'surname': self.surname or ''
        }


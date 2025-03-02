import datetime
from flask import Blueprint, request, jsonify
from werkzeug.security import generate_password_hash, check_password_hash
from ..models.user import User
from ..extensions import db, mail
from flask_mail import Message

auth_bp = Blueprint("auth", __name__)

@auth_bp.route('/register', methods=['POST'])
def register():
    data = request.json
    email = data["email"]
    password = data["password"]  
    existing_user = User.query.filter_by(email=email).first()
    if existing_user:
        return jsonify({"error": "Bu e-posta zaten kayıtlı!"}), 400
    hashed_password = generate_password_hash(password)
    new_user = User(email=email, password_hash=hashed_password)
    new_user.verification_code = new_user.generate_verification_code()
    new_user.verification_expiry = datetime.datetime.utcnow() + datetime.timedelta(minutes=30)
    db.session.add(new_user)
    db.session.commit()
    new_user.send_verification_email()
    return jsonify({"message": "User registered"}), 201

@auth_bp.route("/verify", methods=["POST"])
def verify_user():
    """Kullanıcının doğrulama kodunu kontrol eder."""
    data = request.json
    email = data.get("email")
    code = data.get("code")

    user = User.query.filter_by(email=email).first()

    if not user:
        return jsonify({"message": "Kullanıcı bulunamadı"}), 404

    if user.is_verified:
        return jsonify({"message": "Kullanıcı zaten doğrulanmış"}), 400

    if user.verification_code == code and user.verification_expiry > datetime.datetime.utcnow():
        user.is_verified = True
        user.verification_code = None 
        user.verification_expiry = None
        db.session.commit()
        return jsonify({"message": "Hesap başarıyla doğrulandı!"}), 200
    else:
        return jsonify({"message": "Kod geçersiz veya süresi dolmuş"}), 400

@auth_bp.route('/login', methods=['POST'])
def login():
    data = request.json
    user = User.query.filter_by(email=data['email']).first()

    if not user or not check_password_hash(user.password_hash, data['password']):
        return jsonify({"error": "Invalid credentials"}), 401

    return jsonify({"message": "Login successful", "user_id": user.id}), 200

@auth_bp.route('/forgot-password', methods=['POST'])
def forgot_password():
    try:
        data = request.json
        email = data.get('email')
        
        if not email:
            return jsonify({'error': 'E-posta adresi gerekli'}), 400
            
        user = User.query.filter_by(email=email).first()
        if not user:
            return jsonify({'error': 'Bu e-posta adresi ile kayıtlı kullanıcı bulunamadı'}), 404
            
        # Generate new verification code
        user.verification_code = user.generate_verification_code()
        user.verification_expiry = datetime.datetime.utcnow() + datetime.timedelta(minutes=30)
        
        # Send reset code email
        msg = Message(
            'Şifre Sıfırlama',
            recipients=[user.email]
        )
        msg.body = f'''
        Merhaba,
        
        Şifre sıfırlama kodunuz: {user.verification_code}
        
        Bu kod 30 dakika içinde geçerliliğini yitirecektir.
        
        İyi günler,
        Navibu Ekibi
        '''
        
        mail.send(msg)
        db.session.commit()
        
        return jsonify({'message': 'Şifre sıfırlama kodu e-posta adresinize gönderildi'}), 200
        
    except Exception as e:
        print(f"Password reset error: {str(e)}")
        return jsonify({'error': 'Bir hata oluştu. Lütfen tekrar deneyin.'}), 500

@auth_bp.route('/reset-password', methods=['POST'])
def reset_password():
    try:
        data = request.json
        email = data.get('email')
        code = data.get('code')
        new_password = data.get('new_password')
        
        if not all([email, code, new_password]):
            return jsonify({'error': 'Tüm alanlar gerekli'}), 400
            
        user = User.query.filter_by(email=email).first()
        if not user:
            return jsonify({'error': 'Kullanıcı bulunamadı'}), 404
            
        if not user.verification_code or not user.verification_expiry:
            return jsonify({'error': 'Geçerli bir sıfırlama kodu bulunamadı'}), 400
            
        if user.verification_expiry < datetime.datetime.utcnow():
            return jsonify({'error': 'Sıfırlama kodunun süresi dolmuş'}), 400
            
        if user.verification_code != code:
            return jsonify({'error': 'Geçersiz kod'}), 400
            
        # Update password
        user.password_hash = generate_password_hash(new_password)
        user.verification_code = None
        user.verification_expiry = None
        db.session.commit()
        
        return jsonify({'message': 'Şifreniz başarıyla güncellendi'}), 200
        
    except Exception as e:
        print(f"Password reset error: {str(e)}")
        return jsonify({'error': 'Bir hata oluştu. Lütfen tekrar deneyin.'}), 500




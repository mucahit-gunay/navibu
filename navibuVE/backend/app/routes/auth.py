import datetime
from flask import Blueprint, request, jsonify, current_app
from werkzeug.security import generate_password_hash, check_password_hash
from ..models.user import User
from ..models.user_route import UserRoute
from ..extensions import db, mail
from flask_mail import Message

auth_bp = Blueprint("auth", __name__)

@auth_bp.route('/register', methods=['POST'])
def register():
    # Add debug logging
    current_app.logger.info('Register endpoint hit')
    current_app.logger.info(f'Request method: {request.method}')
    current_app.logger.info(f'Request data: {request.get_json()}')
    
    try:
        data = request.get_json()
        if not data:
            return jsonify({"error": "No JSON data provided"}), 400

        email = data.get("email")
        password = data.get("password")

        if not email or not password:
            return jsonify({"error": "Email ve şifre gereklidir"}), 400

        # Log the received data
        current_app.logger.info(f'Attempting to register user with email: {email}')

        existing_user = User.query.filter_by(email=email).first()
        if existing_user:
            return jsonify({"error": "Bu e-posta zaten kayıtlı!"}), 400

        hashed_password = generate_password_hash(password)
        new_user = User(email=email, password_hash=hashed_password)
        new_user.verification_code = new_user.generate_verification_code()
        new_user.verification_expiry = datetime.datetime.utcnow() + datetime.timedelta(minutes=30)
        
        db.session.add(new_user)
        db.session.commit()
        
        try:
            new_user.send_verification_email()
        except Exception as e:
            current_app.logger.error(f'Failed to send verification email: {str(e)}')
            return jsonify({
                "message": "User registered but verification email could not be sent",
                "user_id": new_user.id
            }), 201

        return jsonify({
            "message": "User registered successfully",
            "user_id": new_user.id
        }), 201

    except Exception as e:
        current_app.logger.error(f'Registration error: {str(e)}')
        db.session.rollback()
        return jsonify({"error": f"Registration failed: {str(e)}"}), 500

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
            
        # Generate new reset code
        user.reset_code = user.generate_verification_code()
        user.reset_code_timestamp = datetime.datetime.utcnow()
        
        # Send reset code email
        msg = Message(
            'Şifre Sıfırlama',
            recipients=[user.email]
        )
        msg.body = f'''
        Merhaba,
        
        Şifre sıfırlama kodunuz: {user.reset_code}
        
        Bu kod 15 dakika içinde geçerliliğini yitirecektir.
        
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
        data = request.get_json()
        email = data.get('email')
        code = data.get('code')
        new_password = data.get('new_password')

        if not all([email, code, new_password]):
            return jsonify({'error': 'Tüm alanlar gereklidir'}), 400

        user = User.query.filter_by(email=email).first()
        if not user:
            return jsonify({'error': 'Kullanıcı bulunamadı'}), 404

        if not user.verify_reset_code(code):
            return jsonify({'error': 'Geçersiz veya süresi dolmuş kod'}), 400

        # Set the new password
        if not user.set_password(new_password):
            return jsonify({'error': 'Geçersiz şifre'}), 400

        # Clear the reset code after successful password change
        user.reset_code = None
        user.reset_code_timestamp = None
        
        db.session.commit()
        return jsonify({'message': 'Şifre başarıyla güncellendi'}), 200

    except Exception as e:
        db.session.rollback()
        return jsonify({'error': f'Bir hata oluştu: {str(e)}'}), 500

@auth_bp.route('/check-routes', methods=['GET'])
def check_user_routes():
    current_app.logger.info('check-routes endpoint hit')
    user_id = request.args.get('user_id')
    current_app.logger.info(f'Received user_id: {user_id}')

    if not user_id:
        current_app.logger.warning('No user_id provided')
        return jsonify({'error': 'User ID required'}), 400

    try:
        # First check if user exists
        user = User.query.get(user_id)
        if not user:
            current_app.logger.warning(f'User with id {user_id} not found')
            return jsonify({'error': 'User not found'}), 404

        # Then check for routes
        user_routes = UserRoute.query.filter_by(user_id=int(user_id)).first()
        current_app.logger.info(f'Found routes for user {user_id}: {user_routes is not None}')
        
        return jsonify({
            'has_routes': user_routes is not None,
            'user_id': user_id
        }), 200

    except ValueError as e:
        current_app.logger.error(f'ValueError: {str(e)}')
        return jsonify({'error': 'Invalid user ID format'}), 400
    except Exception as e:
        current_app.logger.error(f'Unexpected error in check_user_routes: {str(e)}')
        current_app.logger.error(f'Error type: {type(e).__name__}')
        return jsonify({
            'error': 'An unexpected error occurred',
            'details': str(e)
        }), 500




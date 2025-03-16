import datetime
from flask import Blueprint, request, jsonify, current_app
from werkzeug.security import generate_password_hash, check_password_hash
from ..models.user import User
from ..models.route import Route
from ..models.user_route import UserRoute
from ..extensions import db, mail
from flask_mail import Message
from flask_jwt_extended import create_access_token, jwt_required, get_jwt_identity
from datetime import timedelta
import logging

auth_bp = Blueprint("auth", __name__)
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

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

        # Create new user
        hashed_password = generate_password_hash(password)
        new_user = User(email=email, password_hash=hashed_password)
        new_user.verification_code = new_user.generate_verification_code()
        new_user.verification_expiry = datetime.datetime.utcnow() + datetime.timedelta(minutes=30)
        
        # Log verification code (for debugging)
        current_app.logger.info(f'Generated verification code: {new_user.verification_code}')
        
        # First save the user
        db.session.add(new_user)
        db.session.commit()
        
        # Then try to send email
        try:
            # Log email configuration
            current_app.logger.info(f'Mail settings: SERVER={current_app.config["MAIL_SERVER"]}, PORT={current_app.config["MAIL_PORT"]}, USERNAME={current_app.config["MAIL_USERNAME"]}')
            
            # Create message
            msg = Message(
                'Navibu - Email Doğrulama',
                recipients=[new_user.email]
            )
            msg.body = f'''
            Merhaba,
            
            Navibu'ya hoş geldiniz! E-posta adresinizi doğrulamak için aşağıdaki kodu kullanın:
            
            Doğrulama Kodunuz: {new_user.verification_code}
            
            Bu kod 30 dakika içinde geçerliliğini yitirecektir.
            
            Eğer bu işlemi siz yapmadıysanız, lütfen bu e-postayı dikkate almayın.
            
            İyi günler,
            Navibu Ekibi
            '''
            
            # Send email
            mail.send(msg)
            current_app.logger.info(f'Verification email sent successfully to {email}')
            
            return jsonify({
                "message": "Kayıt başarılı! Lütfen e-posta adresinizi doğrulayın.",
                "user_id": new_user.id
            }), 201
            
        except Exception as e:
            current_app.logger.error(f'Failed to send verification email: {str(e)}')
            # Don't rollback the user creation, but inform the user about email issue
            return jsonify({
                "message": "Kayıt başarılı fakat doğrulama e-postası gönderilemedi. Lütfen daha sonra tekrar deneyin.",
                "error": str(e),
                "user_id": new_user.id
            }), 201

    except Exception as e:
        current_app.logger.error(f'Registration error: {str(e)}')
        db.session.rollback()
        return jsonify({"error": f"Kayıt başarısız: {str(e)}"}), 500

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
    try:
        data = request.get_json()
        email = data.get('email')
        password = data.get('password')

        if not email or not password:
            return jsonify({"error": "Missing email or password"}), 400

        user = User.query.filter_by(email=email).first()

        if user and user.check_password(password):
            access_token = create_access_token(
                identity=user.id,
                expires_delta=timedelta(hours=24)
            )
            return jsonify({
                "token": access_token,
                "user": user.to_dict()
            }), 200
        
        return jsonify({"error": "Invalid credentials"}), 401

    except Exception as e:
        logger.error(f"Login error: {str(e)}")
        return jsonify({"error": "An error occurred during login"}), 500

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
            
        # Generate new reset code and save it
        reset_code = user.generate_verification_code()
        user.reset_code = reset_code
        user.reset_code_timestamp = datetime.datetime.utcnow()
        
        try:
            # Send reset code email
            msg = Message(
                'Şifre Sıfırlama',
                recipients=[user.email]
            )
            msg.body = f'''
            Merhaba,
            
            Şifre sıfırlama kodunuz: {reset_code}
            
            Bu kod 15 dakika içinde geçerliliğini yitirecektir.
            
            İyi günler,
            Navibu Ekibi
            '''
            
            # First commit the changes to database
            db.session.commit()
            
            # Then send the email
            mail.send(msg)
            
            return jsonify({'message': 'Şifre sıfırlama kodu e-posta adresinize gönderildi'}), 200
            
        except Exception as e:
            db.session.rollback()
            current_app.logger.error(f"Email sending error: {str(e)}")
            return jsonify({'error': 'E-posta gönderilirken bir hata oluştu. Lütfen tekrar deneyin.'}), 500
            
    except Exception as e:
        db.session.rollback()
        current_app.logger.error(f"Password reset error: {str(e)}")
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

        # Set the new password using the set_password method
        user.set_password(new_password)

        # Clear the reset code after successful password change
        user.reset_code = None
        user.reset_code_timestamp = None
        
        db.session.commit()
        return jsonify({'message': 'Şifre başarıyla güncellendi'}), 200

    except Exception as e:
        db.session.rollback()
        current_app.logger.error(f"Password reset error: {str(e)}")
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

@auth_bp.route('/home', methods=['GET'])
@jwt_required()
def get_home_data():
    try:
        current_user_id = get_jwt_identity()
        user = User.query.get(current_user_id)
        
        if not user:
            return jsonify({"error": "User not found"}), 404

        user_routes = UserRoute.query.filter_by(user_id=current_user_id).all()
        routes_data = []
        
        for user_route in user_routes:
            route = Route.query.get(user_route.route_id)
            if route:
                route_data = route.to_dict()
                route_data['favorite'] = user_route.is_favorite
                routes_data.append(route_data)

        return jsonify({
            "user": user.to_dict(),
            "routes": routes_data
        }), 200

    except Exception as e:
        logger.error(f"Error fetching home data: {str(e)}")
        return jsonify({"error": "An error occurred fetching home data"}), 500

@auth_bp.route('/logout', methods=['POST'])
@jwt_required()
def logout():
    try:
        return jsonify({"message": "Successfully logged out"}), 200
    except Exception as e:
        logger.error(f"Logout error: {str(e)}")
        return jsonify({"error": "An error occurred during logout"}), 500

@auth_bp.route('/resend-verification', methods=['POST'])
def resend_verification():
    try:
        data = request.json
        email = data.get('email')
        
        if not email:
            return jsonify({'error': 'E-posta adresi gerekli'}), 400
            
        user = User.query.filter_by(email=email).first()
        if not user:
            return jsonify({'error': 'Bu e-posta adresi ile kayıtlı kullanıcı bulunamadı'}), 404
            
        if user.is_verified:
            return jsonify({'error': 'Bu hesap zaten doğrulanmış'}), 400

        # Generate new verification code
        user.verification_code = user.generate_verification_code()
        user.verification_expiry = datetime.datetime.utcnow() + datetime.timedelta(minutes=30)
        
        try:
            # Save the new verification code
            db.session.commit()
            
            # Send the verification email
            msg = Message(
                'Navibu - Yeni Email Doğrulama Kodu',
                recipients=[user.email]
            )
            msg.body = f'''
            Merhaba,
            
            Yeni doğrulama kodunuz aşağıdadır:
            
            Doğrulama Kodunuz: {user.verification_code}
            
            Bu kod 30 dakika içinde geçerliliğini yitirecektir.
            
            Eğer bu işlemi siz yapmadıysanız, lütfen bu e-postayı dikkate almayın.
            
            İyi günler,
            Navibu Ekibi
            '''
            
            mail.send(msg)
            current_app.logger.info(f'New verification code sent to {email}')
            
            return jsonify({
                'message': 'Yeni doğrulama kodu e-posta adresinize gönderildi'
            }), 200
            
        except Exception as e:
            current_app.logger.error(f'Failed to send verification email: {str(e)}')
            db.session.rollback()
            return jsonify({
                'error': 'Doğrulama kodu gönderilemedi. Lütfen daha sonra tekrar deneyin.'
            }), 500

    except Exception as e:
        current_app.logger.error(f'Resend verification error: {str(e)}')
        return jsonify({'error': f'Bir hata oluştu: {str(e)}'}), 500




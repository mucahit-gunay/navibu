import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService extends ChangeNotifier {
  // Platform-specific base URL
  static String get baseUrl {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:5000';  // Android emulator localhost
    }
    return 'http://127.0.0.1:5000';   // iOS simulator localhost
  }
  static const String authPrefix = '/auth';
  
  // Store JWT token
  static Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwt_token', token);
  }

  // Get stored JWT token
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  // Add JWT token to headers
  static Future<Map<String, String>> _getHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Generic GET request
  Future<Map<String, dynamic>> get(String endpoint) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: await _getHeaders(),
      );

      final data = json.decode(response.body);
      return {
        'success': response.statusCode == 200,
        'data': data,
        'message': data['message'] ?? data['error'],
      };
    } on SocketException {
      return {
        'success': false,
        'message': 'Sunucuya bağlanılamadı. Lütfen internet bağlantınızı kontrol edin.',
      };
    } on FormatException {
      return {
        'success': false,
        'message': 'Sunucudan geçersiz yanıt alındı.',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Bir hata oluştu: $e',
      };
    }
  }

  // Generic POST request
  Future<Map<String, dynamic>> post(String endpoint, {Map<String, dynamic>? data}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: await _getHeaders(),
        body: data != null ? json.encode(data) : null,
      );

      final responseData = json.decode(response.body);
      return {
        'success': response.statusCode == 200,
        'data': responseData,
        'message': responseData['message'] ?? responseData['error'],
      };
    } on SocketException {
      return {
        'success': false,
        'message': 'Sunucuya bağlanılamadı. Lütfen internet bağlantınızı kontrol edin.',
      };
    } on FormatException {
      return {
        'success': false,
        'message': 'Sunucudan geçersiz yanıt alındı.',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Bir hata oluştu: $e',
      };
    }
  }

  int? _currentUserId;
  
  int? get currentUserId => _currentUserId;

  // Login
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await post('/auth/login', data: {
        'email': email,
        'password': password,
      });
      
      if (response['success'] == true && response['data'] != null) {
        final data = response['data'] as Map<String, dynamic>;
        // Store the token
        await _saveToken(data['token']);
        // Store the user ID from the nested data.user object
        _currentUserId = data['user']['id'];
      }
      
      return response;
    } catch (e) {
      print('Login error in AuthService: $e');
      return {
        'success': false,
        'message': 'Bir hata oluştu. Lütfen tekrar deneyin.'
      };
    }
  }

  // Register
  Future<Map<String, dynamic>> register(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$authPrefix/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return data;
      } else {
        final data = json.decode(response.body);
        throw Exception(data['error'] ?? 'Kayıt başarısız');
      }
    } on SocketException {
      throw Exception('Sunucuya bağlanılamadı. Lütfen internet bağlantınızı kontrol edin.');
    } on FormatException {
      throw Exception('Sunucudan geçersiz yanıt alındı.');
    } catch (e) {
      throw Exception('Kayıt olurken bir hata oluştu: $e');
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$authPrefix/logout'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        // Clear the stored token
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('jwt_token');
      } else {
        throw Exception('Failed to logout: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to logout: $e');
    }
  }

  // Check if user is authenticated
  Future<bool> isAuthenticated() async {
    final token = await getToken();
    return token != null;
  }

  // Get user profile
  Future<Map<String, dynamic>> getHomeData() async {
    try {
      final token = await getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Oturum süresi dolmuş. Lütfen tekrar giriş yapın.',
          'requireLogin': true
        };
      }

      final response = await http.get(
        Uri.parse('$baseUrl$authPrefix/home'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
      );

      if (response.statusCode == 422 || response.statusCode == 401) {
        // Token is invalid or expired
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('jwt_token'); // Clear the invalid token
        return {
          'success': false,
          'message': 'Oturum süresi dolmuş. Lütfen tekrar giriş yapın.',
          'requireLogin': true
        };
      }

      final data = json.decode(response.body);
      return {
        'success': response.statusCode == 200,
        'data': data,
        'message': data['message'] ?? data['error']
      };
    } on SocketException {
      return {
        'success': false,
        'message': 'Sunucuya bağlanılamadı. Lütfen internet bağlantınızı kontrol edin.'
      };
    } on FormatException {
      return {
        'success': false,
        'message': 'Sunucudan geçersiz yanıt alındı.'
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Bir hata oluştu: $e'
      };
    }
  }

  // Update user profile
  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl$authPrefix/profile'),
        headers: await _getHeaders(),
        body: json.encode(data),
      );

      return json.decode(response.body);
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  // Change password
  Future<Map<String, dynamic>> changePassword(String currentPassword, String newPassword) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$authPrefix/change-password'),
        headers: await _getHeaders(),
        body: json.encode({
          'current_password': currentPassword,
          'new_password': newPassword,
        }),
      );

      return json.decode(response.body);
    } catch (e) {
      throw Exception('Failed to change password: $e');
    }
  }

  // Reset password request
  Future<Map<String, dynamic>> requestPasswordReset(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$authPrefix/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email}),
      );

      final data = json.decode(response.body);
      if (response.statusCode == 200) {
        return data;
      } else {
        throw Exception(data['error'] ?? 'Şifre sıfırlama kodu gönderilemedi');
      }
    } on SocketException {
      throw Exception('Sunucuya bağlanılamadı. Lütfen internet bağlantınızı kontrol edin.');
    } on FormatException {
      throw Exception('Sunucudan geçersiz yanıt alındı.');
    } catch (e) {
      throw Exception('Şifre sıfırlama kodu gönderilirken bir hata oluştu: $e');
    }
  }

  // Resend verification code
  Future<Map<String, dynamic>> resendVerificationCode(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$authPrefix/resend-verification'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email}),
      );

      final data = json.decode(response.body);
      if (response.statusCode == 200) {
        return data;
      } else {
        throw Exception(data['error'] ?? 'Doğrulama kodu gönderilemedi');
      }
    } on SocketException {
      throw Exception('Sunucuya bağlanılamadı. Lütfen internet bağlantınızı kontrol edin.');
    } on FormatException {
      throw Exception('Sunucudan geçersiz yanıt alındı.');
    } catch (e) {
      throw Exception('Doğrulama kodu gönderilirken bir hata oluştu: $e');
    }
  }

  // Add this method to check user routes
  Future<Map<String, dynamic>> checkUserRoutes(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl$authPrefix/check-routes?user_id=$userId'),
        headers: await _getHeaders(),
      );

      return json.decode(response.body);
    } catch (e) {
      throw Exception('Failed to check user routes: $e');
    }
  }
}
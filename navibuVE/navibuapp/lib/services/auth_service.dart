import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String baseUrl = 'http://127.0.0.1:5000';
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

  // Login
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$authPrefix/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );

      final data = json.decode(response.body);
      if (response.statusCode == 200 && data['token'] != null) {
        await _saveToken(data['token']);
      }
      return data;
    } catch (e) {
      throw Exception('Failed to login: $e');
    }
  }

  // Register
  Future<Map<String, dynamic>> register(String email, String password, String username) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$authPrefix/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
          'username': username,
        }),
      );

      return json.decode(response.body);
    } catch (e) {
      throw Exception('Failed to register: $e');
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
      final response = await http.get(
        Uri.parse('$baseUrl$authPrefix/home'),
        headers: await _getHeaders(),  // This will include the JWT token
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to get home data: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to get home data: $e');
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
        Uri.parse('$baseUrl$authPrefix/reset-password-request'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email}),
      );

      return json.decode(response.body);
    } catch (e) {
      throw Exception('Failed to request password reset: $e');
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
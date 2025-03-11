import 'dart:convert';
import 'api_middleware.dart';

class BaseApiService {
  Future<Map<String, dynamic>> get(String endpoint) async {
    final response = await ApiMiddleware.authenticatedRequest('GET', endpoint);
    return json.decode(response.body);
  }

  Future<Map<String, dynamic>> post(String endpoint, Map<String, dynamic> body) async {
    final response = await ApiMiddleware.authenticatedRequest(
      'POST', 
      endpoint, 
      body: body  // Don't encode the body here
    );
    return json.decode(response.body);
  }

  Future<Map<String, dynamic>> put(String endpoint, Map<String, dynamic> body) async {
    final response = await ApiMiddleware.authenticatedRequest(
      'PUT', 
      endpoint, 
      body: body  // Don't encode the body here
    );
    return json.decode(response.body);
  }

  Future<Map<String, dynamic>> delete(String endpoint) async {
    final response = await ApiMiddleware.authenticatedRequest('DELETE', endpoint);
    return json.decode(response.body);
  }
} 
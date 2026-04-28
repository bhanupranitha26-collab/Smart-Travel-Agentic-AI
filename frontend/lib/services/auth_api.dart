import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:http/http.dart' as http;

class AuthApi {
  static const String _nativeBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://smart-travel-ai.vercel.app', // Smart fallback for production
  );

  static String get baseUrl {
    if (kIsWeb) return 'https://travelapp-51ko.onrender.com';
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) return 'https://travelapp-51ko.onrender.com';
    return 'https://travelapp-51ko.onrender.com';
  }

  static bool demoMode = false;

  static bool _isNetworkLikeError(String errorText) {
    final text = errorText.toLowerCase();
    return text.contains('connection timed out') ||
        text.contains('xmlhttprequest error') ||
        text.contains('clientexception') ||
        text.contains('timeout') ||
        text.contains('socketexception') ||
        text.contains('failed to fetch');
  }

  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        if (response.body == "Invalid credentials") {
           return {'success': false, 'message': 'Invalid credentials'};
        }
        try {
          var data = jsonDecode(response.body);
          if (data["message"] == "Login successful") {
            return {
              'success': true,
              'data': {
                'access_token': 'dummy_token',
                'user_name': email.split('@').first,
                'user_email': email,
                'user_id': data['userId']?.toString() ?? '',
              }
            };
          }
        } catch (_) {}
      }
      
      return {'success': false, 'message': response.body};
    } catch (e) {
      if (demoMode && _isNetworkLikeError(e.toString())) {
        return {
          'success': true,
          'data': {
            'access_token': 'demo_token_123',
            'token_type': 'bearer',
            'user_name': email.split('@').first,
            'user_email': email,
            'user_id': '69c8cee244c75f054847a135',
          }
        };
      }
      return {'success': false, 'message': 'Connecting to server...'};
    }
  }

  static Future<Map<String, dynamic>> signup(String name, String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/signup'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'name': name, 'email': email, 'password': password}),
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        if (response.body == "User already exists") {
           return {'success': false, 'message': 'User already exists'};
        }
        try {
          var data = jsonDecode(response.body);
          if (data["message"] == "User registered") {
            return {
              'success': true,
              'data': {
                'access_token': 'dummy_token',
                'user_name': name,
                'user_email': email,
                'user_id': data['userId']?.toString() ?? '',
              }
            };
          }
        } catch (_) {}
      }
      
      return {'success': false, 'message': response.body};
    } catch (e) {
      if (demoMode && _isNetworkLikeError(e.toString())) {
        return {
          'success': true,
          'data': {
            'access_token': 'demo_token_123',
            'token_type': 'bearer',
            'user_name': name,
            'user_email': email,
            'user_id': '69c8cee244c75f054847a135',
          }
        };
      }
      return {'success': false, 'message': 'Connecting to server...'};
    }
  }
}

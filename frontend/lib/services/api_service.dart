import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/expense.dart';

class ApiService {
  static const String _nativeBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://travelapp-51ko.onrender.com', // Smart fallback for production
  );

  static String get baseUrl => kIsWeb ? 'https://travelapp-51ko.onrender.com' : _nativeBaseUrl;
  
  static String getImageUrl(String? path) {
    if (path == null) return '';
    if (path.startsWith('http') || path.startsWith('blob:') || path.startsWith('data:')) return path;
    return kIsWeb ? '/$path' : '$_nativeBaseUrl/$path';
  }

  static const Duration _requestTimeout = Duration(seconds: 12);

  static bool demoMode = false;

  static final List<Map<String, dynamic>> _demoExpenses = [
    {'id': 1, 'amount': 1450.0, 'category': 'Hotel'},
    {'id': 2, 'amount': 820.0, 'category': 'Food'},
    {'id': 3, 'amount': 560.0, 'category': 'Transport'},
    {'id': 4, 'amount': 1990.0, 'category': 'Activities'},
  ];

  static final List<Map<String, dynamic>> _demoMemories = [
    {
      'id': 1,
      'description': 'Sunrise walk near Charminar before breakfast.',
      'media_type': 'image',
      'media_path': '',
      'timestamp': '2026-03-23T08:00:00',
    },
    {
      'id': 2,
      'description': 'Tried local biryani and saved the best cafe for later.',
      'media_type': 'image',
      'media_path': '',
      'timestamp': '2026-03-23T13:15:00',
    },
  ];

  static final List<Map<String, dynamic>> _demoPreferences = [
    {'key': 'preferred_budget_style', 'value': 'Balanced comfort'},
    {'key': 'preferred_food_choice', 'value': 'Local cuisine first'},
    {'key': 'activity_pattern', 'value': 'Sightseeing in the morning'},
    {'key': 'transport_pattern', 'value': 'Short rides with walkable stops'},
  ];

  Map<String, dynamic> _success(Map<String, dynamic> decoded) {
    return decoded;
  }

  Map<String, dynamic> _error(Object error) {
    return {'status': 'error', 'message': error.toString()};
  }

  dynamic _decodeResponse(http.Response response) {
    dynamic body;
    try {
      body = jsonDecode(response.body);
    } catch (_) {
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {'status': 'success', 'message': response.body};
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      if (body is Map && body['message'] != null) {
        throw Exception(body['message']);
      }
      throw Exception('HTTP ${response.statusCode}');
    }

    if (body is List) {
      return {'status': 'success', 'data': body};
    }

    return body;
  }

  Future<Map<String, dynamic>> _get(String endpoint) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl$endpoint'))
          .timeout(_requestTimeout);
      final decoded = _decodeResponse(response);
      if (decoded is Map<String, dynamic>) {
        return _success(decoded);
      }
      return _error('Invalid API response');
    } catch (e) {
      if (demoMode && _shouldUseDemoFallback(e)) {
        return _demoGetResponse(endpoint);
      }
      return _error(_friendlyError(e));
    }
  }

  Future<Map<String, dynamic>> _post(
    String endpoint,
    Map<String, dynamic> payload,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl$endpoint'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(_requestTimeout);
      final decoded = _decodeResponse(response);
      if (decoded is Map<String, dynamic>) {
        return _success(decoded);
      }
      return _error('Invalid API response');
    } catch (e) {
      if (demoMode && _shouldUseDemoFallback(e)) {
        return _demoPostResponse(endpoint, payload);
      }
      return _error(_friendlyError(e));
    }
  }

  Future<Map<String, dynamic>> _delete(String endpoint) async {
    try {
      final response = await http
          .delete(Uri.parse('$baseUrl$endpoint'))
          .timeout(_requestTimeout);
      final decoded = _decodeResponse(response);
      if (decoded is Map<String, dynamic>) {
        return _success(decoded);
      }
      return _error('Invalid API response');
    } catch (e) {
      if (demoMode && _shouldUseDemoFallback(e)) {
        return {'status': 'success', 'message': 'Demo delete successful'};
      }
      return _error(_friendlyError(e));
    }
  }

  Future<Map<String, dynamic>> runAllAgents({
    String location = 'Hyderabad',
    String? time,
    double? latitude,
    double? longitude,
  }) async {
    return _post('/agents/run-all', {
      'location': location,
      'time': time ?? DateTime.now().toIso8601String(),
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
    });
  }

  Future<Map<String, dynamic>> addExpense(
    double amount,
    String category,
    String description, {
    String? tripId,
    double? budget,
  }) async {
    final userId = await _getUserId();
    return _post('/agents/add-expense', {
      'amount': amount,
      'category': category,
      'date': DateTime.now().toIso8601String(),
      'description': description,
      if (tripId != null) 'trip_id': tripId,
      if (budget != null) 'budget': budget,
      if (userId != null) 'userId': userId,
      if (userId != null) 'user_id': userId, // Add snake_case for Python backend
    });
  }

  Future<Map<String, dynamic>> getExpenses({String? tripId}) async {
    final endpoint = tripId == null
        ? '/agents/get-expenses'
        : '/agents/get-expenses?trip_id=$tripId';
    return _get(endpoint);
  }

  Future<Map<String, dynamic>> getExpensesByUser() async {
    final userId = await _getUserId();
    if (userId == null) return _error('Not logged in');
    return _get('/expense/$userId');
  }

  List<Expense> parseExpenses(Map<String, dynamic> response) {
    final root = response['data'] ?? response;

    if (root is Map && root['expenses'] is List) {
      final records = root['expenses'] as List;
      return records
          .whereType<Map<String, dynamic>>()
          .map(Expense.fromJson)
          .toList();
    }

    return [];
  }

  Future<Map<String, dynamic>> planTrip({required String destination, required String tripId}) async {
    final userId = await _getUserId();
    return _post('/add-past-trip', {
      'place': destination,
      'date': DateTime.now().toIso8601String(),
      'trip_id': tripId,
      if (userId != null) 'userId': userId,
    });
  }

  Future<Map<String, dynamic>> endTrip({required String tripId}) async {
    return _post('/agents/end-trip', {
      'trip_id': tripId,
    });
  }

  Future<Map<String, dynamic>> deleteTrip({required String tripId}) async {
    return _delete('/delete-trip/$tripId');
  }

  Future<Map<String, dynamic>> getMemories({String? tripId}) async {
    final endpoint = tripId == null
        ? '/agents/get-memories'
        : '/agents/get-memories?trip_id=$tripId';
    return _get(endpoint);
  }

  Future<Map<String, dynamic>> getMemoriesByUser() async {
    final userId = await _getUserId();
    if (userId == null) return _error('Not logged in');
    return _get('/memories/$userId');
  }

  Future<Map<String, dynamic>> getTripsByUser() async {
    final userId = await _getUserId();
    if (userId == null) return _error('Not logged in');
    return _get('/past-trip/$userId');
  }

  Future<Map<String, dynamic>> _successData(dynamic data) async {
    return {'status': 'success', 'data': data};
  }

  Future<String?> _getUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('user_id');
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>> getPreferences() async {
    return _get('/agents/get-preferences');
  }

  Future<Map<String, dynamic>> uploadMemory({
    required String description,
    String? filePath,
    String? mediaType,
    String? tripId,
    List<int>? fileBytes,
    String? fileName,
  }) async {
    final userId = await _getUserId();
    
    final uri = Uri.parse('$baseUrl/agents/upload-memory');
    final request = http.MultipartRequest('POST', uri);
    request.fields['description'] = description;
    request.fields['note'] = description;
    request.fields['media_type'] = mediaType ?? 'image';
    if (tripId != null) request.fields['trip_id'] = tripId;
    if (userId != null) request.fields['user_id'] = userId;
    
    if (fileBytes != null) {
      request.files.add(http.MultipartFile.fromBytes('file', fileBytes, filename: fileName ?? (mediaType == 'video' ? 'upload.mp4' : 'upload.jpg')));
    } else if (filePath != null && !kIsWeb && !filePath.startsWith('http')) {
      try {
        request.files.add(await http.MultipartFile.fromPath('file', filePath));
      } catch (e) {
        debugPrint("Skipping file fromPath error: $e");
      }
    }

    try {
      final streamedResponse = await request.send().timeout(_requestTimeout);
      final response = await http.Response.fromStream(streamedResponse);
      final decoded = _decodeResponse(response);
      return decoded is Map<String, dynamic> ? _success(decoded) : _error('Invalid API response');
    } catch (e) {
      if (demoMode && _shouldUseDemoFallback(e)) {
        return _demoUploadMemoryResponse(description: description, mediaType: mediaType, tripId: tripId);
      }
      return _error(_friendlyError(e));
    }
  }

  String buildMediaUrl(String mediaPath) {
    if (mediaPath.startsWith('http://') || mediaPath.startsWith('https://')) {
      return mediaPath;
    }
    if (baseUrl.isEmpty) {
      return mediaPath;
    }
    return '$baseUrl$mediaPath';
  }

  String _friendlyError(Object error) {
    final text = error.toString();
    if (_isNetworkLikeError(error)) {
      if (demoMode) {
        return 'Backend unavailable, using demo data.';
      }
      return 'Connecting to server...';
    }
    return text;
  }

  bool _shouldUseDemoFallback(Object error) {
    return _isNetworkLikeError(error);
  }

  bool _isNetworkLikeError(Object error) {
    final text = error.toString().toLowerCase();
    return error is TimeoutException ||
        error is http.ClientException ||
        text.contains('connection timed out') ||
        text.contains('future not completed') ||
        text.contains('xmlhttprequest error') ||
        text.contains('failed to fetch') ||
        text.contains('clientexception');
  }

  Map<String, dynamic> _demoGetResponse(String endpoint) {
    if (endpoint.startsWith('/agents/get-expenses')) {
      return {
        'status': 'success',
        'message': 'Demo expenses loaded',
        'data': {
          'expenses': List<Map<String, dynamic>>.from(_demoExpenses),
        },
      };
    }

    if (endpoint.startsWith('/agents/get-memories')) {
      return {
        'status': 'success',
        'message': 'Demo memories loaded',
        'data': {
          'memories': List<Map<String, dynamic>>.from(_demoMemories),
        },
      };
    }

    if (endpoint == '/agents/get-preferences') {
      return {
        'status': 'success',
        'message': 'Demo preferences loaded',
        'data': {
          'preferences': List<Map<String, dynamic>>.from(_demoPreferences),
        },
      };
    }

    return {
      'status': 'success',
      'message': 'Demo data loaded',
      'data': <String, dynamic>{},
    };
  }

  Map<String, dynamic> _demoPostResponse(
    String endpoint,
    Map<String, dynamic> payload,
  ) {
    if (endpoint == '/agents/run-all') {
      return _demoRunAllResponse(
        location: payload['location']?.toString() ?? 'Hyderabad',
      );
    }

    if (endpoint == '/agents/plan-trip') {
      return _demoPlanTripResponse(
        destination: payload['destination']?.toString() ?? 'Goa',
      );
    }

    if (endpoint == '/agents/add-expense') {
      final nextId = _demoExpenses.isEmpty
          ? 1
          : (_demoExpenses.last['id'] as int) + 1;
      _demoExpenses.add({
        'id': nextId,
        'amount': (payload['amount'] as num?)?.toDouble() ?? 0.0,
        'category': payload['category']?.toString() ?? 'General',
      });
      return {
        'status': 'success',
        'message': 'Expense added in demo mode',
        'data': {'id': nextId},
      };
    }

    return {
      'status': 'success',
      'message': 'Demo action completed',
      'data': <String, dynamic>{},
    };
  }

  Map<String, dynamic> _demoRunAllResponse({required String location}) {
    final total = _demoExpenses.fold<double>(
      0,
      (sum, item) => sum + ((item['amount'] as num?)?.toDouble() ?? 0.0),
    );

    return {
      'status': 'success',
      'message': 'Demo dashboard loaded',
      'data': {
        'rule_based': {
          'expenses': {
            'total': 'Rs ${total.toStringAsFixed(0)}',
            'categories': {
              for (final item in _demoExpenses)
                item['category'].toString():
                    (item['amount'] as num?)?.toDouble() ?? 0.0,
            },
          },
          'context':
              'You are currently exploring $location. Weather and crowd patterns look favorable for short city hops.',
        },
        'ai_insights': {
          'expense':
              'Food and activities are your largest spends today. Group nearby stops to reduce transport cost.',
        },
        'final_decision_engine': {
          'final_decision':
              'Continue with one premium experience this evening, then keep the rest of the plan budget-friendly.',
        },
        'personalization':
            'This plan leans toward local food, compact travel, and one highlight activity based on your recent behavior.',
      },
      'expense_analysis': {
        'total': total.toStringAsFixed(0),
        'categories': {
          for (final item in _demoExpenses)
            item['category'].toString():
                (item['amount'] as num?)?.toDouble() ?? 0.0,
        },
        'suggestion':
            'You are on track for a comfortable day trip. Cap transport spend and focus on nearby attractions.',
      },
      'reminders': [
        'Carry a power bank before the evening outing.',
        'Pre-book your top attraction to skip the queue.',
        'Set aside a small food budget for late-night snacks.',
      ],
      'travel_plan': {
        'activities': [
          'Breakfast at a popular local cafe',
          'Visit a nearby landmark during low-crowd hours',
          'Take an evening photo stop and dinner walk',
        ],
      },
      'context': {
        'message':
            'Demo mode is active. Live backend data will appear automatically when the server responds.',
      },
      'memories': List<Map<String, dynamic>>.from(_demoMemories),
    };
  }

  Map<String, dynamic> _demoPlanTripResponse({required String destination}) {
    final place = destination.trim().isEmpty ? 'Goa' : destination.trim();
    return {
      'status': 'success',
      'message': 'Demo travel plan generated',
      'data': {
        'summary': '$place Getaway',
        'generated_itinerary': [
          'Day 1: Arrive in $place, check in, and explore a signature local market.',
          'Day 2: Start early with sightseeing, keep lunch local, and reserve sunset for a scenic stop.',
          'Day 3: Add a relaxed brunch, souvenir stop, and a short wrap-up walk before departure.',
        ],
        'places': [
          '$place Central Market',
          '$place Heritage Walk',
          '$place Sunset Point',
          '$place Food Street',
        ],
      },
    };
  }

  Map<String, dynamic> _demoUploadMemoryResponse({
    required String description,
    String? mediaType,
    String? tripId,
  }) {
    final nextId = _demoMemories.isEmpty
        ? 1
        : (_demoMemories.last['id'] as int) + 1;
    _demoMemories.insert(0, {
      'id': nextId,
      'description': description,
      'media_type': mediaType ?? 'image',
      'media_path': '',
      'trip_id': tripId,
      'timestamp': DateTime.now().toIso8601String(),
    });

    return {
      'status': 'success',
      'message': 'Memory saved in demo mode',
      'data': {'id': nextId},
    };
  }
}

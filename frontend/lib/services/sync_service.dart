import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'api_service.dart';

class SyncService {
  static String get _baseUrl => ApiService.baseUrl;
  static const String _syncQueueKey = 'travel_offline_sync_queue';
  
  static final SyncService instance = SyncService._();
  SyncService._();

  // Expose a stream for the Cloud Icon in the UI
  final ValueNotifier<bool> isSynced = ValueNotifier(true);

  Future<void> uploadLocalData(List<Map<String, dynamic>> localData) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Read offline queue
    final queueRaw = prefs.getString(_syncQueueKey);
    List<Map<String, dynamic>> offlineQueue = [];
    if (queueRaw != null && queueRaw.isNotEmpty) {
      final decoded = jsonDecode(queueRaw) as List<dynamic>;
      offlineQueue = decoded.cast<Map<String, dynamic>>();
    }

    // Merge new data with offline queue
    final mergedData = [...offlineQueue, ...localData];
    
    print('[AGENT] Syncing... (Sending ${mergedData.length} trips to backend)');
    final url = Uri.parse('$_baseUrl/sync-trips');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(mergedData),
      );

      if (response.statusCode == 200) {
        print('[AGENT] Sync complete. Server response: ${response.body}');
        // Clear queue on success
        await prefs.setString(_syncQueueKey, '');
        isSynced.value = true;
      } else {
        print('[AGENT] Sync failed with status code: ${response.statusCode}');
        // Save back to queue
        await prefs.setString(_syncQueueKey, jsonEncode(mergedData));
        isSynced.value = false;
      }
    } catch (e) {
      print('[AGENT] An error occurred during sync: $e');
      // Save back to queue offline
      await prefs.setString(_syncQueueKey, jsonEncode(mergedData));
      isSynced.value = false;
    }
  }

  /// Optional method to just retry sync from the background
  Future<void> retryOfflineQueue() async {
    final prefs = await SharedPreferences.getInstance();
    final queueRaw = prefs.getString(_syncQueueKey);
    if (queueRaw != null && queueRaw.isNotEmpty) {
      final decoded = jsonDecode(queueRaw) as List<dynamic>;
      final items = decoded.cast<Map<String, dynamic>>();
      if (items.isNotEmpty) {
        await uploadLocalData([]); // Pass empty list to just upload the queue
      }
    }
  }
}

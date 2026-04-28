import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'travel_data_service.dart';

class SmsExpenseSyncResult {
  final int scannedMessages;
  final int matchedMessages;
  final int importedExpenses;
  final bool permissionGranted;
  final String? error;

  const SmsExpenseSyncResult({
    required this.scannedMessages,
    required this.matchedMessages,
    required this.importedExpenses,
    required this.permissionGranted,
    this.error,
  });
}

class SmsExpenseService {
  SmsExpenseService({TravelDataService? travelData})
    : _travelData = travelData ?? TravelDataService.instance;

  static const MethodChannel _permissionChannel = MethodChannel(
    'smart_travel_app/sms_permissions',
  );
  static const String _processedIdsKey = 'processed_sms_ids';

  final TravelDataService _travelData;

  Future<SmsExpenseSyncResult> syncExpensesFromSms({
    bool requestPermission = true,
    int maxMessages = 80,
  }) async {
    if (!await _isAndroid()) {
      return const SmsExpenseSyncResult(
        scannedMessages: 0,
        matchedMessages: 0,
        importedExpenses: 0,
        permissionGranted: false,
        error: 'SMS expense detection is available on Android only.',
      );
    }

    final permissionGranted = requestPermission
        ? await _requestReadSmsPermission()
        : await _hasReadSmsPermission();

    if (!permissionGranted) {
      return const SmsExpenseSyncResult(
        scannedMessages: 0,
        matchedMessages: 0,
        importedExpenses: 0,
        permissionGranted: false,
        error: 'SMS permission not granted.',
      );
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final processedIds = prefs.getStringList(_processedIdsKey)?.toSet() ?? {};
      final messages = await _readInboxMessages(maxMessages);

      int matchedMessages = 0;
      int importedExpenses = 0;
      final updatedProcessedIds = <String>{...processedIds};

      for (final message in messages) {
        final smsId = message['id']?.toString();
        final body = message['body']?.toString() ?? '';
        if (smsId == null || updatedProcessedIds.contains(smsId)) {
          continue;
        }

        final parsed = _parseExpenseFromSms(body);
        if (parsed == null) {
          continue;
        }

        matchedMessages += 1;

        await _travelData.addExpense(
          amount: parsed.amount,
          category: parsed.category,
          note: parsed.description,
          date: DateTime.now().toIso8601String(),
        );
        importedExpenses += 1;
        updatedProcessedIds.add(smsId);
      }

      await prefs.setStringList(
        _processedIdsKey,
        updatedProcessedIds.toList()..sort(),
      );

      return SmsExpenseSyncResult(
        scannedMessages: messages.length,
        matchedMessages: matchedMessages,
        importedExpenses: importedExpenses,
        permissionGranted: true,
      );
    } catch (e) {
      return SmsExpenseSyncResult(
        scannedMessages: 0,
        matchedMessages: 0,
        importedExpenses: 0,
        permissionGranted: true,
        error: e.toString(),
      );
    }
  }

  Future<List<Map<String, dynamic>>> _readInboxMessages(int maxMessages) async {
    final rawMessages = await _permissionChannel.invokeMethod<List<dynamic>>(
      'queryInboxSms',
      {'count': maxMessages},
    );

    if (rawMessages == null) {
      return const [];
    }

    return rawMessages
        .whereType<Map>()
        .map(
          (message) => message.map(
            (key, value) => MapEntry(key.toString(), value),
          ),
        )
        .toList();
  }

  _ParsedExpense? _parseExpenseFromSms(String body) {
    final text = body.trim();
    if (text.isEmpty) return null;

    final lower = text.toLowerCase();
    final hasSignalWord =
        lower.contains('debited') ||
        lower.contains('credited') ||
        lower.contains('spent') ||
        lower.contains('rs') ||
        lower.contains('inr');

    if (!hasSignalWord) {
      return null;
    }

    final amountMatch = RegExp(
      r'(?:rs\.?|inr)\s*([0-9,]+(?:\.\d{1,2})?)|([0-9,]+(?:\.\d{1,2})?)\s*(?:rs\.?|inr)',
      caseSensitive: false,
    ).firstMatch(text);

    final rawAmount = amountMatch?.group(1) ?? amountMatch?.group(2);
    if (rawAmount == null) {
      return null;
    }

    final amount = double.tryParse(rawAmount.replaceAll(',', ''));
    if (amount == null || amount <= 0) {
      return null;
    }

    final merchantMatch = RegExp(
      r'(?:at|to|on)\s+([A-Za-z0-9&._ -]{2,40})',
      caseSensitive: false,
    ).firstMatch(text);
    final merchant = merchantMatch?.group(1)?.trim().replaceAll(RegExp(r'\s+'), ' ');
    final category = _inferCategory(text, merchant);
    final description = merchant == null || merchant.isEmpty
        ? 'Imported from SMS: $text'
        : 'Imported from SMS at $merchant';

    return _ParsedExpense(
      amount: amount,
      category: category,
      description: description,
    );
  }

  String _inferCategory(String body, String? merchant) {
    final text = '${body.toLowerCase()} ${merchant?.toLowerCase() ?? ''}';

    if (_containsAny(text, ['swiggy', 'zomato', 'restaurant', 'cafe', 'food'])) {
      return 'food';
    }
    if (_containsAny(text, ['uber', 'ola', 'metro', 'irctc', 'flight', 'travel'])) {
      return 'travel';
    }
    if (_containsAny(text, ['amazon', 'flipkart', 'myntra', 'shopping'])) {
      return 'shopping';
    }
    if (_containsAny(text, ['electricity', 'water bill', 'gas bill', 'recharge'])) {
      return 'bills';
    }
    if (_containsAny(text, ['credited', 'salary', 'refund'])) {
      return 'income';
    }

    return 'general';
  }

  bool _containsAny(String text, List<String> values) {
    for (final value in values) {
      if (text.contains(value)) {
        return true;
      }
    }
    return false;
  }

  Future<bool> _isAndroid() async {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android;
  }

  Future<bool> _hasReadSmsPermission() async {
    final granted = await _permissionChannel.invokeMethod<bool>(
      'hasReadSmsPermission',
    );
    return granted ?? false;
  }

  Future<bool> _requestReadSmsPermission() async {
    final granted = await _permissionChannel.invokeMethod<bool>(
      'requestReadSmsPermission',
    );
    return granted ?? false;
  }
}

class _ParsedExpense {
  final double amount;
  final String category;
  final String description;

  const _ParsedExpense({
    required this.amount,
    required this.category,
    required this.description,
  });
}

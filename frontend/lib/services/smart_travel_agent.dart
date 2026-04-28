import 'package:flutter/foundation.dart';

import 'travel_data_service.dart';

class TripAgent {
  final SmartTravelAgent brain;
  TripAgent(this.brain);

  void onPlaceVisited(String placeName) {
    // AGENTIC LOGIC: Trip -> Reminder
    brain.reminders.triggerSuggestion(
      "Visit Verified \u2705: $placeName",
    );
  }
}

class ExpenseAgent {
  final SmartTravelAgent brain;
  ExpenseAgent(this.brain);

  void detectOverspending(double currentExpenses, double tripBudget) {
    if (currentExpenses > tripBudget) {
      // AGENTIC LOGIC: Expense -> Reminder
      brain.reminders.triggerSuggestion(
        'Smart Alert: Expense tracking indicates you have exceeded your trip budget!',
      );
    }
  }
}

class AlbumAgent {
  final SmartTravelAgent brain;
  AlbumAgent(this.brain);

  Map<String, dynamic> organizeMedia(String mediaPath, dynamic trip, String mediaType) {
    // AGENTIC LOGIC: Auto-tagging based on Trip context
    return {
      'mediaPath': mediaPath,
      'mediaType': mediaType,
      'description': 'Logged a memory at ${trip.destination}.',
      'title': 'Memories in ${trip.destination}',
    };
  }
}

class ReminderAgent {
  final SmartTravelAgent brain;
  ReminderAgent(this.brain);

  final ValueNotifier<String?> activeSuggestion = ValueNotifier(null);

  void triggerSuggestion(String message) {
    activeSuggestion.value = message;
    Future.delayed(const Duration(seconds: 4), () {
      if (activeSuggestion.value == message) {
        activeSuggestion.value = null;
      }
    });
  }

  void clearSuggestion() {
    activeSuggestion.value = null;
  }
}

class SummaryAgent {
  final SmartTravelAgent brain;
  SummaryAgent(this.brain);

  Map<String, dynamic> generateTripReport(dynamic trip, double expenses, int visited, int memories) {
    return {
      'title': trip == null ? 'Overall Trip Report' : 'Trip Report: ${trip.destination}',
      'expenses': expenses,
      'is_estimated': false,
      'visited_places': visited,
      'memories_logged': memories,
    };
  }
}

class SmartTravelAgent {
  SmartTravelAgent._() {
    trip = TripAgent(this);
    expenses = ExpenseAgent(this);
    albums = AlbumAgent(this);
    reminders = ReminderAgent(this);
    summary = SummaryAgent(this);
  }

  static final SmartTravelAgent instance = SmartTravelAgent._();

  late final TripAgent trip;
  late final ExpenseAgent expenses;
  late final AlbumAgent albums;
  late final ReminderAgent reminders;
  late final SummaryAgent summary;

  TravelDataService get dataService => TravelDataService.instance;
}

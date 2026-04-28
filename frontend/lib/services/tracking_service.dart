import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import 'smart_travel_agent.dart';
import 'travel_data_service.dart';

class TrackingAgent {
  static final TrackingAgent instance = TrackingAgent._();
  TrackingAgent._();

  Timer? _simulationTimer;
  final ValueNotifier<bool> isSimulating = ValueNotifier(false);
  int _currentTargetIndex = 0;

  void toggleSimulation() {
    if (isSimulating.value) {
      stopSimulation();
    } else {
      startSimulation();
    }
  }

  void startSimulation() {
    isSimulating.value = true;
    _currentTargetIndex = 0;
    
    _simulationTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      _simulateMovementTick();
    });
    
    SmartTravelAgent.instance.reminders.triggerSuggestion("Passive Tracking Agent Simulation Started...");
  }

  void stopSimulation() {
    isSimulating.value = false;
    _simulationTimer?.cancel();
    SmartTravelAgent.instance.reminders.triggerSuggestion("Tracking Simulation Stopped.");
  }

  Future<void> _simulateMovementTick() async {
    final travelData = TravelDataService.instance;
    final stops = travelData.itineraryStops;
    
    if (stops.isEmpty) return;

    // Refresh live location
    await travelData.refreshTripLocation();
    final currentLoc = travelData.currentLocation;
    
    if (currentLoc == null) return;

    for (final stop in stops) {
      if (travelData.visitedPlaceIds.contains(stop.place)) continue;

      final distance = Geolocator.distanceBetween(
        currentLoc.latitude, currentLoc.longitude,
        stop.latitude, stop.longitude,
      );

      // If within 200 meters of the stop, mark as visited automatically
      if (distance <= 200) {
        int index = stops.indexOf(stop);
        if (index != -1) {
          await travelData.markVisitedByOrder(index);
        }
        break;
      }
    }
  }
}

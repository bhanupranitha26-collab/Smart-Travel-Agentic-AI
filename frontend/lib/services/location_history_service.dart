import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

import '../models/location_history_entry.dart';
import 'location_service.dart';

class JourneySnapshot {
  final List<LocationHistoryEntry> history;
  final List<String> visitedPlaces;

  const JourneySnapshot({
    required this.history,
    required this.visitedPlaces,
  });
}

class LocationHistoryService {
  static Database? _database;
  static final List<_NamedPlace> _mockPlaces = [
    _NamedPlace(
      name: 'Cafe Coffee Day',
      latitude: 17.3862,
      longitude: 78.4891,
    ),
    _NamedPlace(
      name: 'Inorbit Mall',
      latitude: 17.3905,
      longitude: 78.5007,
    ),
    _NamedPlace(
      name: 'Metro Station',
      latitude: 17.3881,
      longitude: 78.4920,
    ),
    _NamedPlace(
      name: 'Airport Shuttle Stop',
      latitude: 17.3918,
      longitude: 78.4968,
    ),
  ];

  Future<Database> get database async {
    if (_database != null) return _database!;

    final dbPath = await getDatabasesPath();
    final fullPath = path.join(dbPath, 'journey_history.db');

    _database = await openDatabase(
      fullPath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE location_history (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            latitude REAL NOT NULL,
            longitude REAL NOT NULL,
            timestamp TEXT NOT NULL,
            place_name TEXT NOT NULL
          )
        ''');
      },
    );

    return _database!;
  }

  Future<LocationHistoryEntry> saveLocation(LocationPoint point) async {
    return saveRawLocation(
      latitude: point.latitude,
      longitude: point.longitude,
      placeName: resolvePlaceName(point.latitude, point.longitude),
    );
  }

  Future<LocationHistoryEntry> saveRawLocation({
    required double latitude,
    required double longitude,
    required String placeName,
  }) async {
    final db = await database;
    final entry = LocationHistoryEntry(
      latitude: latitude,
      longitude: longitude,
      timestamp: DateTime.now(),
      placeName: placeName,
    );

    final id = await db.insert('location_history', entry.toMap());
    return LocationHistoryEntry(
      id: id,
      latitude: entry.latitude,
      longitude: entry.longitude,
      timestamp: entry.timestamp,
      placeName: entry.placeName,
    );
  }

  Future<JourneySnapshot> getTodayJourney() async {
    final db = await database;
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);

    final rows = await db.query(
      'location_history',
      where: 'timestamp >= ?',
      whereArgs: [startOfDay.toIso8601String()],
      orderBy: 'timestamp ASC',
    );

    final history = rows.map(LocationHistoryEntry.fromMap).toList();
    final visitedPlaces = <String>[];

    for (final entry in history) {
      if (!visitedPlaces.contains(entry.placeName)) {
        visitedPlaces.add(entry.placeName);
      }
    }

    return JourneySnapshot(
      history: history,
      visitedPlaces: visitedPlaces,
    );
  }

  String resolvePlaceName(double latitude, double longitude) {
    _NamedPlace? nearestPlace;
    double nearestDistance = double.infinity;

    for (final place in _mockPlaces) {
      final distance = _distanceSquared(
        latitude,
        longitude,
        place.latitude,
        place.longitude,
      );
      if (distance < nearestDistance) {
        nearestDistance = distance;
        nearestPlace = place;
      }
    }

    if (nearestPlace != null && nearestDistance < 0.00012) {
      return nearestPlace.name;
    }

    return 'Lat ${latitude.toStringAsFixed(4)}, Lon ${longitude.toStringAsFixed(4)}';
  }

  double _distanceSquared(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    final latDiff = lat1 - lat2;
    final lonDiff = lon1 - lon2;
    return (latDiff * latDiff) + (lonDiff * lonDiff);
  }
}

class _NamedPlace {
  final String name;
  final double latitude;
  final double longitude;

  const _NamedPlace({
    required this.name,
    required this.latitude,
    required this.longitude,
  });
}

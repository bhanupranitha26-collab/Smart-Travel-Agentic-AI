class LocationHistoryEntry {
  final int? id;
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final String placeName;

  const LocationHistoryEntry({
    this.id,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    required this.placeName,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp.toIso8601String(),
      'place_name': placeName,
    };
  }

  factory LocationHistoryEntry.fromMap(Map<String, dynamic> map) {
    return LocationHistoryEntry(
      id: map['id'] as int?,
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      timestamp: DateTime.parse(map['timestamp'] as String),
      placeName: (map['place_name'] ?? 'Unknown place').toString(),
    );
  }
}

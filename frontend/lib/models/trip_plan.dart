class PlannerStop {
  final String id;
  final int dayIndex;
  final String place;
  final String time;
  final String notes;
  final String status;
  final String category;
  final double latitude;
  final double longitude;
  final double distanceKm;

  const PlannerStop({
    required this.id,
    required this.dayIndex,
    required this.place,
    required this.time,
    required this.notes,
    required this.status,
    required this.category,
    required this.latitude,
    required this.longitude,
    required this.distanceKm,
  });

  factory PlannerStop.fromJson(Map<String, dynamic> json) {
    return PlannerStop(
      id: json['id']?.toString() ?? '',
      dayIndex: (json['dayIndex'] as num?)?.toInt() ?? 0,
      place: json['place']?.toString() ?? 'Trip stop',
      time: json['time']?.toString() ?? '',
      notes: json['notes']?.toString() ?? '',
      status: json['status']?.toString() ?? 'PLANNED',
      category: json['category']?.toString() ?? 'attraction',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      distanceKm: (json['distanceKm'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'dayIndex': dayIndex,
      'place': place,
      'time': time,
      'notes': notes,
      'status': status,
      'category': category,
      'latitude': latitude,
      'longitude': longitude,
      'distanceKm': distanceKm,
    };
  }

  PlannerStop copyWith({
    String? place,
    String? time,
    String? notes,
    String? status,
    String? category,
    double? latitude,
    double? longitude,
    double? distanceKm,
    int? dayIndex,
  }) {
    return PlannerStop(
      id: id,
      dayIndex: dayIndex ?? this.dayIndex,
      place: place ?? this.place,
      time: time ?? this.time,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      category: category ?? this.category,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      distanceKm: distanceKm ?? this.distanceKm,
    );
  }
}

class TravelEvent {
  final String id;
  final String name;
  final String date;
  final String category;
  final double latitude;
  final double longitude;
  final double distanceKm;

  const TravelEvent({
    required this.id,
    required this.name,
    required this.date,
    required this.category,
    required this.latitude,
    required this.longitude,
    required this.distanceKm,
  });

  factory TravelEvent.fromJson(Map<String, dynamic> json) {
    return TravelEvent(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Local Event',
      date: json['date']?.toString() ?? '',
      category: json['category']?.toString() ?? 'Local',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      distanceKm: (json['distanceKm'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'date': date,
      'category': category,
      'latitude': latitude,
      'longitude': longitude,
      'distanceKm': distanceKm,
    };
  }
}

class TravelTrip {
  final String id;
  final String destination;
  final String cityLabel;
  final String startDate;
  final String endDate;
  final int tripDays;
  final String status;
  final String shareCode;
  final List<String> friends;

  const TravelTrip({
    required this.id,
    required this.destination,
    required this.cityLabel,
    required this.startDate,
    required this.endDate,
    required this.tripDays,
    this.status = 'upcoming',
    this.shareCode = '',
    this.friends = const [],
  });

  factory TravelTrip.fromJson(Map<String, dynamic> json) {
    return TravelTrip(
      id: json['id']?.toString() ?? '',
      destination: json['destination']?.toString() ?? '',
      cityLabel: json['cityLabel']?.toString() ?? '',
      startDate: json['startDate']?.toString() ?? '',
      endDate: json['endDate']?.toString() ?? '',
      tripDays: (json['tripDays'] as num?)?.toInt() ?? 3,
      status: json['status']?.toString() ?? 'upcoming',
      shareCode: json['shareCode']?.toString() ?? '',
      friends: (json['friends'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'destination': destination,
      'cityLabel': cityLabel,
      'startDate': startDate,
      'endDate': endDate,
      'tripDays': tripDays,
      'status': status,
      'shareCode': shareCode,
      'friends': friends,
    };
  }

  TravelTrip copyWith({
    String? status,
    String? shareCode,
    List<String>? friends,
  }) {
    return TravelTrip(
      id: id,
      destination: destination,
      cityLabel: cityLabel,
      startDate: startDate,
      endDate: endDate,
      tripDays: tripDays,
      status: status ?? this.status,
      shareCode: shareCode ?? this.shareCode,
      friends: friends ?? this.friends,
    );
  }
}

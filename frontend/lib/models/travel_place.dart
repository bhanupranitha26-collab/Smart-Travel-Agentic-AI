class TravelPlace {
  final String id;
  final String name;
  final String category;
  final String subcategory;
  final String address;
  final double latitude;
  final double longitude;
  final double distanceKm;

  const TravelPlace({
    required this.id,
    required this.name,
    required this.category,
    required this.subcategory,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.distanceKm,
  });

  factory TravelPlace.fromJson(Map<String, dynamic> json) {
    return TravelPlace(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Untitled Place',
      category: json['category']?.toString() ?? 'attraction',
      subcategory: json['subcategory']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      distanceKm: (json['distanceKm'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'subcategory': subcategory,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'distanceKm': distanceKm,
    };
  }
}

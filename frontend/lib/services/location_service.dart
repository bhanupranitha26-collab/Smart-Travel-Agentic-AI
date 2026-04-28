import 'package:geolocator/geolocator.dart';

class LocationPoint {
  final double latitude;
  final double longitude;

  const LocationPoint({required this.latitude, required this.longitude});
}

class LocationService {
  static Future<LocationPoint?> getCurrentLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      return LocationPoint(
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } catch (_) {
      return null;
    }
  }
}

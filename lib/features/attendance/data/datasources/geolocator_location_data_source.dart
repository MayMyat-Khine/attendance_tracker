import 'package:geolocator/geolocator.dart';

import 'package:attendance_tracker/core/error/app_exception.dart';
import 'package:attendance_tracker/features/attendance/domain/entities/geo_location.dart';

final class GeolocatorLocationDataSource {
  Future<GeoLocation> currentLocation() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      throw const LocationServiceException();
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw const LocationPermissionException();
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      return GeoLocation(
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } on PermissionDeniedException {
      throw const LocationPermissionException();
    } on LocationServiceDisabledException {
      throw const LocationServiceException();
    }
  }
}

import 'package:attendance_tracker/core/error/result.dart';
import 'package:attendance_tracker/features/attendance/domain/entities/geo_location.dart';

abstract class LocationRepository {
  Future<Result<GeoLocation>> currentLocation();
}

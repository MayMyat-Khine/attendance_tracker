import 'package:attendance_tracker/core/error/result.dart';
import 'package:attendance_tracker/features/attendance/domain/entities/geo_location.dart';
import 'package:attendance_tracker/features/attendance/domain/repositories/location_repository.dart';

final class GetCurrentLocation {
  const GetCurrentLocation(this._repository);

  final LocationRepository _repository;

  Future<Result<GeoLocation>> call() => _repository.currentLocation();
}

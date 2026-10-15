import 'package:attendance_tracker/core/error/map_to_failure.dart';
import 'package:attendance_tracker/core/error/result.dart';
import 'package:attendance_tracker/features/attendance/data/datasources/geolocator_location_data_source.dart';
import 'package:attendance_tracker/features/attendance/domain/entities/geo_location.dart';
import 'package:attendance_tracker/features/attendance/domain/repositories/location_repository.dart';

final class LocationRepositoryImpl implements LocationRepository {
  const LocationRepositoryImpl(this._remote);

  final GeolocatorLocationDataSource _remote;

  @override
  Future<Result<GeoLocation>> currentLocation() async {
    try {
      final location = await _remote.currentLocation();
      return Success(location);
    } catch (error) {
      return ResultFailure(mapToFailure(error));
    }
  }
}

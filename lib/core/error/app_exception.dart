final class LocationPermissionException implements Exception {
  const LocationPermissionException();
}

final class LocationServiceException implements Exception {
  const LocationServiceException();
}

final class AttendanceConflictException implements Exception {
  const AttendanceConflictException(this.message);

  final String message;
}

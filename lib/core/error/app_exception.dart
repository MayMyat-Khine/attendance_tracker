import 'package:attendance_tracker/core/error/failure.dart';

final class LocationPermissionException implements Exception {
  const LocationPermissionException();
}

final class LocationServiceException implements Exception {
  const LocationServiceException();
}

final class LocationTimeoutException implements Exception {
  const LocationTimeoutException();
}

final class AttendanceConflictException implements Exception {
  const AttendanceConflictException(this.message);

  final String message;
}

final class AccessDeniedException implements Exception {
  const AccessDeniedException();
}

final class OperationFailureException implements Exception {
  const OperationFailureException(this.failure);
  final Failure failure;
}

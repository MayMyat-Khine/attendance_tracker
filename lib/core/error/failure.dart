sealed class Failure {
  const Failure(this.message);

  final String message;
}

final class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'No internet connection.']);
}

final class FirebaseFailure extends Failure {
  const FirebaseFailure(super.message);
}

final class PermissionFailure extends Failure {
  const PermissionFailure(super.message);
}

final class LocationFailure extends Failure {
  const LocationFailure([
    super.message =
        'Could not get your location. Move to an open area and try again.',
  ]);
}

final class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

final class UnexpectedFailure extends Failure {
  const UnexpectedFailure([super.message = 'Something went wrong.']);
}

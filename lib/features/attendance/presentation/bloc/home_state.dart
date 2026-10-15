import 'package:attendance_tracker/core/error/failure.dart';
import 'package:attendance_tracker/features/attendance/domain/entities/geo_location.dart';
import 'package:attendance_tracker/features/attendance/domain/entities/user_history.dart';

sealed class HomeState {
  const HomeState();
}

final class HomeLoading extends HomeState {
  const HomeLoading();
}

final class HomeSignedOut extends HomeState {
  const HomeSignedOut();
}

final class HomeLoadFailure extends HomeState {
  const HomeLoadFailure(this.failure);

  final Failure failure;
}

final class HomeReady extends HomeState {
  const HomeReady({
    required this.name,
    required this.email,
    this.photoUrl,
    required this.history,
    required this.location,
    this.failure,
    this.isSubmitting = false,
  });

  final String name;
  final String email;
  final String? photoUrl;
  final UserHistory history;
  final GeoLocation? location;
  final Failure? failure;
  final bool isSubmitting;
}

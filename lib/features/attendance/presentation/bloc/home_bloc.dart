import 'dart:async';

import 'package:bloc/bloc.dart';

import 'package:attendance_tracker/core/error/failure.dart';
import 'package:attendance_tracker/core/error/result.dart';
import 'package:attendance_tracker/core/error/unit.dart';
import 'package:attendance_tracker/core/network/network_info.dart';
import 'package:attendance_tracker/features/attendance/domain/entities/geo_location.dart';
import 'package:attendance_tracker/features/attendance/domain/usecases/check_in.dart';
import 'package:attendance_tracker/features/attendance/domain/usecases/check_out.dart';
import 'package:attendance_tracker/features/attendance/domain/usecases/get_current_location.dart';
import 'package:attendance_tracker/features/attendance/domain/usecases/get_user_history.dart';
import 'package:attendance_tracker/features/attendance/domain/usecases/sync_pending_logs.dart';
import 'package:attendance_tracker/features/attendance/presentation/bloc/home_event.dart';
import 'package:attendance_tracker/features/attendance/presentation/bloc/home_state.dart';
import 'package:attendance_tracker/features/auth/domain/entities/app_user.dart';
import 'package:attendance_tracker/features/auth/domain/usecases/get_signed_in_user.dart';

final class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc({
    required this._getSignedInUser,
    required this._getUserHistory,
    required this._getCurrentLocation,
    required this._checkIn,
    required this._checkOut,
    required this._syncPendingLogs,
    required NetworkInfo networkInfo,
  }) : super(const HomeLoading()) {
    on<HomeStarted>(_onStarted);
    on<HomeResumed>(_onResumed);
    on<HomeRefreshed>(_onRefreshed);
    on<CheckInRequested>(_onCheckIn);
    on<CheckOutRequested>(_onCheckOut);
    add(const HomeStarted());
    _connectivity = networkInfo.onConnectivityChanged.listen((online) {
      if (online) {
        add(const HomeResumed());
      }
    });
  }

  final GetSignedInUser _getSignedInUser;
  final GetUserHistory _getUserHistory;
  final GetCurrentLocation _getCurrentLocation;
  final CheckIn _checkIn;
  final CheckOut _checkOut;
  final SyncPendingLogs _syncPendingLogs;
  late final StreamSubscription<bool> _connectivity;

  Future<void> _onStarted(HomeStarted event, Emitter<HomeState> emit) async {
    await _load(emit, keepVisible: false, readLocation: true);
  }

  Future<void> _onResumed(HomeResumed event, Emitter<HomeState> emit) async {
    if (state is HomeLoading || _isSubmitting) {
      return;
    }
    await _load(emit, keepVisible: true);
  }

  Future<void> _onRefreshed(
    HomeRefreshed event,
    Emitter<HomeState> emit,
  ) async {
    final current = state;
    if (current is HomeLoading || _isSubmitting) {
      if (current is HomeReady) {
        emit(
          HomeReady(
            name: current.name,
            email: current.email,
            history: current.history,
            location: current.location,
            failure: current.failure,
            isSubmitting: current.isSubmitting,
          ),
        );
      }
      return;
    }
    await _load(emit, keepVisible: true);
  }

  Future<void> _onCheckIn(
    CheckInRequested event,
    Emitter<HomeState> emit,
  ) async {
    final current = state;
    if (current is! HomeReady || current.isSubmitting) {
      return;
    }
    emit(
      HomeReady(
        name: current.name,
        email: current.email,
        history: current.history,
        location: current.location,
        isSubmitting: true,
      ),
    );
    final locationResult = await _getCurrentLocation();
    switch (locationResult) {
      case ResultFailure(:final failure):
        emit(
          HomeReady(
            name: current.name,
            email: current.email,
            history: current.history,
            location: current.location,
            failure: failure,
          ),
        );
      case Success(:final value):
        final result = await _checkIn(
          CheckInParams(email: current.email, location: value),
        );
        final submissionFailure = switch (result) {
          ResultFailure(:final failure) => failure,
          Success() => null,
        };
        await _load(
          emit,
          keepVisible: true,
          location: value,
          failure: submissionFailure,
        );
    }
  }

  Future<void> _onCheckOut(
    CheckOutRequested event,
    Emitter<HomeState> emit,
  ) async {
    final current = state;
    if (current is! HomeReady || current.isSubmitting) {
      return;
    }
    emit(
      HomeReady(
        name: current.name,
        email: current.email,
        history: current.history,
        location: current.location,
        isSubmitting: true,
      ),
    );
    final located = await _getCurrentLocation();
    if (located case ResultFailure(:final failure)) {
      _emitFailure(emit, failure, keepVisible: true);
      return;
    }
    final location = (located as Success<GeoLocation>).value;
    final result = await _checkOut(email: current.email, location: location);
    final submissionFailure = switch (result) {
      ResultFailure(:final failure) => failure,
      Success() => null,
    };
    await _load(
      emit,
      keepVisible: true,
      location: location,
      failure: submissionFailure,
    );
  }

  Future<void> _load(
    Emitter<HomeState> emit, {
    required bool keepVisible,
    bool readLocation = false,
    GeoLocation? location,
    Failure? failure,
  }) async {
    final sync = await _syncPendingLogs();
    final userResult = await _getSignedInUser();
    switch (userResult) {
      case ResultFailure(:final failure):
        _emitFailure(emit, failure, keepVisible: keepVisible);
      case Success(:final value) when value == null:
        emit(const HomeSignedOut());
      case Success(:final value):
        final user = value;
        if (user == null) {
          emit(const HomeSignedOut());
          return;
        }
        final located = await _resolveLocation(
          readLocation: readLocation,
          location: location,
        );
        final historyResult = await _getUserHistory(email: user.email);
        switch (historyResult) {
          case ResultFailure(:final failure):
            _emitFailure(
              emit,
              failure,
              keepVisible: keepVisible,
              location: located.location,
            );
          case Success(:final value):
            emit(
              HomeReady(
                name: _displayName(user),
                email: user.email,
                history: value,
                location: located.location ?? _locationFrom(state),
                failure: failure ?? located.failure ?? _syncFailure(sync),
              ),
            );
        }
    }
  }

  Future<({GeoLocation? location, Failure? failure})> _resolveLocation({
    required bool readLocation,
    required GeoLocation? location,
  }) async {
    if (location != null || !readLocation) {
      return (location: location ?? _locationFrom(state), failure: null);
    }
    final result = await _getCurrentLocation();
    return switch (result) {
      Success(:final value) => (location: value, failure: null),
      ResultFailure(:final failure) => (
        location: _locationFrom(state),
        failure: failure,
      ),
    };
  }

  void _emitFailure(
    Emitter<HomeState> emit,
    Failure failure, {
    required bool keepVisible,
    GeoLocation? location,
  }) {
    final current = state;
    if (keepVisible && current is HomeReady) {
      emit(
        HomeReady(
          name: current.name,
          email: current.email,
          history: current.history,
          location: location ?? current.location,
          failure: failure,
        ),
      );
      return;
    }
    emit(HomeLoadFailure(failure));
  }

  Failure? _syncFailure(Result<Unit> result) {
    return switch (result) {
      ResultFailure(:final failure) when failure is! NetworkFailure => failure,
      _ => null,
    };
  }

  GeoLocation? _locationFrom(HomeState current) {
    return switch (current) {
      HomeReady(:final location) => location,
      _ => null,
    };
  }

  String _displayName(AppUser user) {
    final name = user.name?.trim();
    if (name == null || name.isEmpty) {
      return user.email;
    }
    return name;
  }

  bool get _isSubmitting => switch (state) {
    HomeReady(:final isSubmitting) => isSubmitting,
    _ => false,
  };

  @override
  Future<void> close() {
    _connectivity.cancel();
    return super.close();
  }
}

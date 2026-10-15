import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:attendance_tracker/core/error/failure.dart';
import 'package:attendance_tracker/core/error/result.dart';
import 'package:attendance_tracker/features/auth/domain/entities/app_user.dart';
import 'package:attendance_tracker/features/auth/domain/usecases/get_signed_in_user.dart';
import 'package:attendance_tracker/features/auth/domain/usecases/sign_out.dart';

sealed class SessionEvent {
  const SessionEvent();
}

final class SessionStarted extends SessionEvent {
  const SessionStarted();
}

sealed class SessionState {
  const SessionState();
}

final class SessionLoading extends SessionState {
  const SessionLoading();
}

final class SessionReady extends SessionState {
  const SessionReady(this.user, {this.failure});
  final AppUser? user;
  final Failure? failure;
}

final class SessionBloc extends Bloc<SessionEvent, SessionState> {
  SessionBloc(GetSignedInUser getUser, SignOut signOut, {bool logout = false})
    : super(const SessionLoading()) {
    on<SessionStarted>((event, emit) async {
      if (logout) {
        final result = await signOut();
        if (result case ResultFailure(:final failure)) {
          emit(SessionReady(null, failure: failure));
          return;
        }
        emit(const SessionReady(null));
        return;
      }
      final result = await getUser();
      switch (result) {
        case Success(:final value):
          emit(SessionReady(value));
        case ResultFailure(:final failure):
          emit(SessionReady(null, failure: failure));
      }
    });
    add(const SessionStarted());
  }
}

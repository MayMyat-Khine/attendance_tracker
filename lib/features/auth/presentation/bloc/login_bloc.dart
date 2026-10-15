import 'package:bloc/bloc.dart';

import 'package:attendance_tracker/core/error/result.dart';
import 'package:attendance_tracker/features/auth/domain/usecases/send_password_reset.dart';
import 'package:attendance_tracker/features/auth/domain/usecases/sign_in.dart';
import 'package:attendance_tracker/features/auth/domain/usecases/sign_out.dart';
import 'package:attendance_tracker/features/auth/presentation/bloc/login_event.dart';
import 'package:attendance_tracker/features/auth/presentation/bloc/login_state.dart';

final class LoginBloc extends Bloc<LoginEvent, LoginState> {
  LoginBloc({
    required this._signIn,
    required this._sendPasswordReset,
    required this._signOut,
  }) : super(const LoginCheckingSession()) {
    on<LoginStarted>(_onStarted);
    on<LoginSubmitted>(_onSubmitted);
    on<ForgotPasswordRequested>(_onForgotPassword);
    add(const LoginStarted());
  }

  final SignIn _signIn;
  final SendPasswordReset _sendPasswordReset;
  final SignOut _signOut;

  Future<void> _onStarted(
    LoginStarted event,
    Emitter<LoginState> emit,
  ) async {
    await _signOut();
    emit(const LoginReady());
  }

  Future<void> _onSubmitted(
    LoginSubmitted event,
    Emitter<LoginState> emit,
  ) async {
    if (state is LoginCheckingSession || _isSubmitting) {
      return;
    }

    emit(const LoginReady(isSubmitting: true));
    final result = await _signIn(
      SignInParams(email: event.email, password: event.password),
    );
    switch (result) {
      case Success(:final value):
        emit(LoginSucceeded(value));
      case ResultFailure(:final failure):
        emit(LoginReady(failure: failure));
    }
  }

  Future<void> _onForgotPassword(
    ForgotPasswordRequested event,
    Emitter<LoginState> emit,
  ) async {
    if (state is LoginCheckingSession || _isSubmitting) {
      return;
    }

    emit(const LoginReady(isSubmitting: true));
    final result = await _sendPasswordReset(event.email);
    switch (result) {
      case Success():
        emit(const LoginReady(passwordResetSent: true));
      case ResultFailure(:final failure):
        emit(LoginReady(failure: failure));
    }
  }

  bool get _isSubmitting => switch (state) {
    LoginReady(:final isSubmitting) => isSubmitting,
    _ => false,
  };
}

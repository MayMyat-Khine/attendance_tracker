import 'package:attendance_tracker/features/auth/domain/entities/profile_image.dart';
import 'package:attendance_tracker/features/auth/domain/usecases/pick_profile_image.dart';
import 'package:bloc/bloc.dart';

import 'package:attendance_tracker/core/error/result.dart';
import 'package:attendance_tracker/features/auth/domain/usecases/register_account.dart';
import 'package:attendance_tracker/features/auth/presentation/bloc/register_event.dart';
import 'package:attendance_tracker/features/auth/presentation/bloc/register_state.dart';

final class RegisterBloc extends Bloc<RegisterEvent, RegisterState> {
  RegisterBloc({
    required this._registerAccount,
    required this._pickProfileImage,
  }) : super(const RegisterCheckingSession()) {
    on<ProfileImageRequested>(_onPickImage);
    on<RegisterStarted>(_onStarted);
    on<RegisterSubmitted>(_onSubmitted);
    add(const RegisterStarted());
  }

  final RegisterAccount _registerAccount;
  final PickProfileImage _pickProfileImage;
  ProfileImage? _image;

  Future<void> _onPickImage(
    ProfileImageRequested event,
    Emitter<RegisterState> emit,
  ) async {
    if (_isSubmitting) return;
    emit(RegisterReady(profileImage: _image, isSubmitting: true));
    final result = await _pickProfileImage();
    switch (result) {
      case Success(:final value):
        _image = value ?? _image;
        emit(RegisterReady(profileImage: _image));
      case ResultFailure(:final failure):
        emit(RegisterReady(profileImage: _image, failure: failure));
    }
  }

  Future<void> _onStarted(
    RegisterStarted event,
    Emitter<RegisterState> emit,
  ) async {
    emit(const RegisterReady());
  }

  Future<void> _onSubmitted(
    RegisterSubmitted event,
    Emitter<RegisterState> emit,
  ) async {
    if (state is RegisterCheckingSession || _isSubmitting) {
      return;
    }

    emit(RegisterReady(isSubmitting: true, profileImage: _image));
    final result = await _registerAccount(
      RegisterAccountParams(
        email: event.email,
        password: event.password,
        name: event.name,
        position: event.position,
        department: event.department,
        profileImage: _image,
      ),
    );
    switch (result) {
      case Success(:final value):
        emit(RegisterSucceeded(value));
      case ResultFailure(:final failure):
        emit(RegisterReady(failure: failure, profileImage: _image));
    }
  }

  bool get _isSubmitting => switch (state) {
    RegisterReady(:final isSubmitting) => isSubmitting,
    _ => false,
  };
}

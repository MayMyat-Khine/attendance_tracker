import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:attendance_tracker/core/error/failure.dart';
import 'package:attendance_tracker/core/error/result.dart';
import 'package:attendance_tracker/features/auth/domain/entities/app_user.dart';
import 'package:attendance_tracker/features/admin_dashboard/domain/entities/admin_data.dart';
import 'package:attendance_tracker/features/admin_dashboard/domain/usecases/search_users.dart';

sealed class UsersEvent {
  const UsersEvent();
}

final class UsersSearchChanged extends UsersEvent {
  const UsersSearchChanged(this.search, this.byEmail);
  final String search;
  final bool byEmail;
}

final class UsersRefreshed extends UsersEvent {
  const UsersRefreshed();
}

final class UsersNextPageRequested extends UsersEvent {
  const UsersNextPageRequested();
}

sealed class UsersState {
  const UsersState();
}

final class UsersReady extends UsersState {
  const UsersReady({
    this.users = const [],
    this.next,
    this.loading = false,
    this.failure,
  });
  final List<AppUser> users;
  final PageCursor? next;
  final bool loading;
  final Failure? failure;
}

final class UsersBloc extends Bloc<UsersEvent, UsersState> {
  UsersBloc(this._searchUsers) : super(const UsersReady(loading: true)) {
    on<UsersSearchChanged>((event, emit) async {
      _search = event.search;
      _byEmail = event.byEmail;
      final generation = ++_generation;
      emit(const UsersReady(loading: true));
      await Future<void>.delayed(const Duration(milliseconds: 300));
      if (generation != _generation) return;
      await _load(emit, generation: generation);
    });
    on<UsersRefreshed>((event, emit) async {
      final generation = ++_generation;
      emit(const UsersReady(loading: true));
      await _load(emit, generation: generation);
    });
    on<UsersNextPageRequested>((event, emit) async {
      final current = switch (state) {
        UsersReady ready => ready,
      };
      if (current.loading || current.next == null) return;
      emit(UsersReady(users: current.users, next: current.next, loading: true));
      await _load(emit, generation: _generation, previous: current);
    });
    add(const UsersRefreshed());
  }
  final SearchUsers _searchUsers;
  String _search = '';
  bool _byEmail = false;
  int _generation = 0;
  Future<void> _load(
    Emitter<UsersState> emit, {
    required int generation,
    UsersReady? previous,
  }) async {
    final result = await _searchUsers(
      search: _search,
      byEmail: _byEmail,
      after: previous?.next,
    );
    if (generation != _generation || isClosed) return;
    switch (result) {
      case Success(:final value):
        emit(
          UsersReady(
            users: [...?previous?.users, ...value.users],
            next: value.next,
          ),
        );
      case ResultFailure(:final failure):
        emit(
          UsersReady(
            users: previous?.users ?? const [],
            next: previous?.next,
            failure: failure,
          ),
        );
    }
  }
}

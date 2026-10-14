---
name: bloc-state-management
description: >-
  Implements attendance_tracker screen state with BLoC and flutter_bloc. Use when
  adding events, states, blocs, BlocProvider, form submission, loading, or
  connecting a page to a use case.
---

# BLoC

Use `Bloc` (events and states) for feature state. Do not use Cubit, `setState` for loaded data, Provider, or Riverpod.

## Shape

One bloc per screen flow: `LoginBloc`, `RegisterBloc`, `HomeBloc`, `HistoryBloc`, `DashboardBloc`, `UsersBloc`, `UserHistoryBloc`.

- Events and states are `sealed` classes in the feature `presentation/bloc/` folder.
- The bloc depends on use cases, never on Firebase, repositories, or data sources.
- States hold entities and `Failure`, never models or exceptions.
- Emit a loading state before the call, then success or failure. Ignore overlapping taps while loading.

```dart
sealed class HomeEvent {
  const HomeEvent();
}

final class HomeStarted extends HomeEvent {
  const HomeStarted();
}

final class CheckInRequested extends HomeEvent {
  const CheckInRequested();
}

sealed class HomeState {
  const HomeState();
}

final class HomeLoading extends HomeState {
  const HomeLoading();
}

final class HomeReady extends HomeState {
  const HomeReady({required this.status, required this.location});

  final AttendanceStatus status;
  final Location? location;
}

final class HomeSubmitFailure extends HomeState {
  const HomeSubmitFailure({required this.status, required this.failure});

  final AttendanceStatus status;
  final Failure failure;
}
```

Keep the last ready data on a submit failure so the button and location stay visible.

## Wiring

- Provide the bloc at the route that owns the screen. Create use cases in `app.dart` and pass them in.
- The page sends events. It does not call use cases.
- Use `BlocBuilder` for rendering and `BlocListener` for one-off effects (navigation, snackbar).
- After login, the listener reads the role and navigates. The bloc does not import pages.

```dart
final current = state;
if (current is! HomeReady) return;

final result = await _checkIn(params);
switch (result) {
  case Success(:final value):
    emit(HomeReady(
      status: AttendanceStatus.checkedIn,
      location: value.location,
    ));
  case ResultFailure(:final failure):
    emit(HomeSubmitFailure(status: current.status, failure: failure));
}
```

## Forms and lists

- Validate empty fields in the use case as `ValidationFailure`. The bloc can skip the call when the field is empty and emit that failure immediately.
- Search: the page emits `UsersSearchChanged`. The bloc waits briefly, drops stale queries, then calls `SearchUsers`.
- Pagination: `UsersNextPageRequested` appends the next page. `UsersRefreshed` replaces page one.
- Do not add `equatable`. Emit new state instances. Add `==` and `hashCode` on a single state only if rebuilds become a measured problem.

## Decisions worth stating in the reply

Say why a second bloc was split from an existing one, or why a state kept previous data.

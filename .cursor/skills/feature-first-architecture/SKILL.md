---
name: feature-first-architecture
description: >-
  Places attendance_tracker code in feature-first Clean Architecture with pure
  domain, data implementations, and presentation. Use when creating features,
  folders, entities, repositories, use cases, models, shared widgets, dependency
  injection, or deciding whether to add a package.
---

# Feature-first Clean Architecture

Organize by feature, then by layer. A feature owns its UI, use cases, and data. Shared code goes in `core` only when two features need it.

## Layout

```
lib/
  main.dart
  app.dart
  core/
    error/          # Failure, Result, mapToFailure
    network/        # NetworkInfo
    theme/
    router/
    widgets/        # widgets used by two or more features
  features/
    auth/
    attendance/
    admin_dashboard/
    admin_users/
```

Each feature:

```
feature/
  domain/
    entities/
    repositories/     # abstract classes
    usecases/
  data/
    models/
    datasources/
    repositories/     # implementations
  presentation/
    bloc/
    pages/
    widgets/
```

## Dependency rule

| Layer | May import | Must not import |
| --- | --- | --- |
| domain | pure Dart, `core/error` | Flutter, Firebase, plugins, data, presentation |
| data | domain, core, Firebase, plugins | presentation, widgets |
| presentation | domain use cases, core, Flutter, flutter_bloc | data sources, Firebase, models |
| core | Flutter only in theme, router, and widgets | features |

- Entities are immutable: `final` fields, `const` constructors.
- Data models map with `toEntity()` and `fromEntity()`. Do not pass models into blocs or pages.
- Repositories are abstract in domain. `SomethingRepositoryImpl` lives in data.
- Use cases are one class per action, named as a verb: `CheckIn`, `CheckOut`, `SyncPendingLogs`, `GetUserHistory`, `SearchUsers`.
- Inject dependencies through constructors. Build them in `app.dart`. Do not add a service locator.

```dart
class CheckIn {
  const CheckIn(this._repository, this._networkInfo);

  final AttendanceRepository _repository;
  final NetworkInfo _networkInfo;

  Future<Result<AttendanceLog>> call(CheckInParams params) {
    // business rule lives here
  }
}
```

## What belongs where

- Business rules (open session, role, ownership): use case. Repository repeats the write constraint so online and offline paths cannot diverge.
- Firebase, location, image picker, and the local queue: data sources only.
- Screen flow and rendering: presentation.
- `NetworkInfo` is an abstract type in `core/network`. The plugin implementation stays in data.

## Coding rules

- Files: `snake_case`. Types: `UpperCamelCase`. Members and constants: `lowerCamelCase`. Private members start with `_`.
- File name matches the primary type: `check_in.dart` defines `CheckIn`.
- Prefer required named parameters. Avoid `!` except a local invariant checked on the lines above.
- No `dynamic`. No `print`. No business logic in widgets.
- Keep a widget in the feature until a second feature needs it, then move it to `core/widgets`.

## Packages

Add a dependency only from this list, and only when the feature needs it:

- `flutter_bloc`, `bloc`
- `firebase_core`, `firebase_auth`, `cloud_firestore`, `firebase_storage`
- `geolocator`, `image_picker`, `connectivity_plus`, `path_provider`

Do not add `dartz`, `freezed`, `json_serializable`, `equatable`, `get_it`, `injectable`, `riverpod`, `provider`, `go_router`, `mockito`, `mocktail`, `hive`, or `isar`. Use sealed classes, hand-written `fromJson`/`toJson`, constructor injection, and fakes.

## Decisions worth stating in the reply

State why a type sits in domain versus data, and why a new package was required. Skip the explanation for a straight mapping of these folders.

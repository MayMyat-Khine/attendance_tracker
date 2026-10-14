---
name: attendance-tracker
description: >-
  Guides feature work in the attendance_tracker Flutter app: feature-first Clean
  Architecture, Failure/Result errors, BLoC, admin and user roles, light and dark
  theme, check-in/out, offline sync, and unit tests. Use when adding or changing
  any screen, feature, repository, bloc, test, navigation, or Dart file in this project.
---

# Attendance Tracker

Follow these rules for every change in this app. Before writing code, read the linked skill that matches the task.

## Required reading

- New folders, layers, packages, or shared types: [feature-first-architecture](../feature-first-architecture/SKILL.md)
- Exceptions, Firebase, network, or permission errors: [failure-result-errors](../failure-result-errors/SKILL.md)
- Events, states, or screen state: [bloc-state-management](../bloc-state-management/SKILL.md)
- Routes, themes, login, registration, admin or user screens: [attendance-screens-navigation](../attendance-screens-navigation/SKILL.md)
- Check-in, check-out, location, offline sync, history refresh: [attendance-check-in](../attendance-check-in/SKILL.md)
- Tests for use cases or error mapping: [attendance-unit-tests](../attendance-unit-tests/SKILL.md)

## Product rules

- Admin can see all users and all check-in/out logs.
- User can check-in/out and view only their own history.
- Login authenticates and redirects by role.
- Registration is for users only: name, email, password, profile image.
- Check-in and check-out store a UTC timestamp and location.
- A user cannot check in again until they check out.
- Offline check-in/out is allowed and syncs when the device is online.
- History and the admin user list support pull-to-refresh.
- The app supports light mode and dark mode.

## Always

- Feature-first Clean Architecture. Domain stays pure Dart.
- Return `Result<T>` with a `Failure`. Map Network, Firebase, and Permission errors in one mapper.
- Use BLoC for feature state. Widgets call blocs. Blocs call use cases.
- Enforce role and ownership in use cases and repositories, not only in the UI.
- Null safety. Dart file, type, and member names. No `dynamic`.
- Add a package only when a skill lists it or the user asks.
- Unit-test business rules with hand-written fakes.
- In the reply, explain important implementation decisions in a few sentences. Do not narrate them with long comments in the source.

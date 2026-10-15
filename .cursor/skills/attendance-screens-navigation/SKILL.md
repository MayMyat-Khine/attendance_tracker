---
name: attendance-screens-navigation
description: >-
  Builds attendance_tracker screens, role-based navigation, and light and dark
  themes. Use when adding login, registration, admin dashboard, users list,
  user history, home, history, routes, redirects, or ThemeData.
---

# Screens and navigation

Use `Navigator` and named routes in `lib/core/router/app_router.dart`. Do not add `go_router`.

## Roles

```dart
enum UserRole { admin, user }
```

Store `role` on the user profile. Admin accounts are created outside registration.

| Role | Can do |
| --- | --- |
| Admin | See all users and every check-in/out log |
| User | Check-in/out and view only their own history |

Redirect after login:

- `UserRole.admin` → Dashboard
- `UserRole.user` → Home

Unknown or missing role → stay on Login and show `FirebaseFailure`.

## Screens

Common:

- Login → email, password. Authenticate, then redirect by role.
- Registration (users only) → name, email, password, profile image. No admin signup on this screen.

Admin:

- Dashboard → total users, today's check-in count, today's check-out count.
- Users list → all registered users, search, pagination, pull-to-refresh.
- User history → logs filtered by user and date.

User:

- Home → one check-in or check-out button, plus the current location.
- History → that user's past check-ins and check-outs, pull-to-refresh.

## Route guard

- No signed-in user: only Login and Registration.
- Signed-in user opening Login: redirect by role.
- Admin routes check `UserRole.admin` before building the page.
- User routes are the default for `UserRole.user`.
- Hide navigation controls the role cannot use. Repositories still scope the query. A hidden button is not the security check.

## Theme

Support light and dark mode with Material 3:

```dart
MaterialApp(
  theme: AppTheme.light,
  darkTheme: AppTheme.dark,
  themeMode: ThemeMode.system,
)
```

- Build both themes in `lib/core/theme/app_theme.dart` from the same seed color.
- Read colors from `Theme.of(context).colorScheme` and text styles from `textTheme`.
- Do not hardcode `Colors.black` / `Colors.white` for surfaces.
- Do not add a settings screen or a theme package for the system switch.

## Screen behavior

- Registration needs a network. It is not an offline feature.
- Upload the profile image to Storage and save the download URL on the user document.
- Users list page size is 20. Store `nameLower` and `emailLower` on the profile for prefix search. Search and pagination share one query.
- "Today" on the dashboard is the device's local calendar day. Persist timestamps in UTC and convert the day to a UTC range at the query boundary.
- Admin user history filters by user id and an inclusive local date range. The user History screen has no user picker; it always uses the signed-in id.
- Pull-to-refresh on History, admin User history, and Users list. It dispatches the same reload event as the first load and resets pagination to page one.

## Decisions worth stating in the reply

Mention role redirects, how "today" is bounded, and any field added for search (`nameLower`).

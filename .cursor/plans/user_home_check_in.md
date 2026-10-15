# User home check-in

The date-range question was cancelled. This plan treats **Absent** as every day of the **current local month through today** that has no `records` entry. Say so if that range should change before implementation.

A copy of this plan will be written to `.cursor/plans/user_home_check_in.md` before the code, then the placeholder in `lib/features/attendance/presentation/pages/home_page.dart` will be replaced. No tests.

## Firestore document

Collection `history`. One document per user, found with `where('email', isEqualTo: signedInEmail)`. Create it on the first check-in.

- `email` (string)
- `records` (array of maps)
  - `date` (string, local `yyyy-MM-dd`)
  - `checkin` (string, local `HH:mm`, empty until check-in)
  - `checkout` (string, local `HH:mm`, empty until check-out)
  - `location` (GeoPoint). The console shows this as `0° N, 0° E`. Written only when the day's record is created. Check-out does not change it.

Same local date means the same `date` string. At most one record per date. The write is a transaction so a second device cannot open two sessions.

- No record for today: check in. Store location.
- Record for today with an empty `checkout`: check out. Do not write location.
- Both times already set: `ValidationFailure` and no write.
- Check-out with no open check-in: `ValidationFailure('Check in before checking out.')`.
- Missing location permission or location services off: `PermissionFailure` and no write.

## Home screen

`HomePage` gets a `HomeBloc` from `lib/core/router/app_router.dart`. The bloc loads the signed-in profile (name and email) and that user's history.

- **Profile card:** name, today's date, today's check-in time, today's check-out time, and one icon button. The icon is Check in when today has no open session, and Check out when check-in exists and check-out is empty. After both times are set, the icon does not write again.
- **History list under the card:** scrollable, newest date first, pull-to-refresh. Each row is the date plus check-in and check-out times. A day in the current month with no record shows **Absent** for both times. A day that has a check-in and no check-out shows the check-in time and a blank check-out, not Absent.
- Current location is a one-shot read when the screen opens and again on check-in. GPS is not streamed.

## Offline

Check-in and check-out work offline. Login stays online-only.

- Add `geolocator`, `connectivity_plus`, and `path_provider`.
- `NetworkInfo` stays abstract in `lib/core/network`. The plugin implementation stays in data.
- Offline success appends the operation to a local JSON queue (`pendingSync: true`) and returns `Success`. The open-session rule includes queued operations, so two offline check-ins cannot both succeed.
- The list merges the queue with the last cached history page.
- `SyncPendingLogs` runs when connectivity returns and when the app resumes. It applies queued operations onto the same `history` document in time order, then deletes uploaded items. A failed upload stays in the queue.

## Layers

Under `lib/features/attendance/`:

- Domain: `AttendanceRecord`, repository, `CheckIn`, `CheckOut`, `GetUserHistory`, `GetCurrentLocation`, `SyncPendingLogs`. Rules live in the use cases. Domain stays pure Dart.
- Data: Firestore history source, Geolocator source, JSON queue, repository implementation that maps errors with `mapToFailure`.
- Presentation: `HomeBloc` only. The page sends events and does not call Firebase.

Re-wire `GetSignedInUser` in `lib/app_dependencies.dart` so Home can read the signed-in email. Restart still signs out and opens Login.

## Permissions

- Android `android/app/src/main/AndroidManifest.xml`: `ACCESS_COARSE_LOCATION` and `ACCESS_FINE_LOCATION`.
- iOS `ios/Runner/Info.plist`: `NSLocationWhenInUseUsageDescription` explaining that location is used for check-in.

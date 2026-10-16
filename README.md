# Attendance Tracker

Flutter attendance app for Android and iOS. Employees check in and out with their GPS location, including while offline. Admins see every user and every attendance record. Built with Firebase Authentication and Firestore, Cloudinary for profile photos, BLoC, and feature-first Clean Architecture.

## Quick start

```bash
flutter pub get
flutter run --flavor staging -t lib/main_staging.dart --dart-define-from-file=config/staging.json -d <device>
```

Run `flutter devices` to find the device ID. The rest of this file covers setup, other flavors, and builds.

## Contents

- [Quick start](#quick-start)
- [Features](#features)
- [How the app works](#how-the-app-works)
- [Architecture](#architecture)
- [Requirements](#requirements)
- [Flavors](#flavors)
- [Configuration and keys](#configuration-and-keys)
- [One-time setup](#one-time-setup)
- [Running the app](#running-the-app)
- [Building APKs and releases](#building-apks-and-releases)
- [Data model and security rules](#data-model-and-security-rules)
- [Migrating existing data](#migrating-existing-data)
- [Testing](#testing)
- [Troubleshooting](#troubleshooting)

## Features

**Employees (`role: user`)**

- Register with name, email, password, position, department, and an optional profile photo (JPEG/PNG under 5 MB, uploaded to Cloudinary). Registration always creates a `user`; admins cannot be created from the app.
- The Home card shows today's date, check-in and check-out times in 12-hour format such as `9:05 AM` (`-` when empty), the current GPS coordinates, and a status: **Pending** for unsynced records, or **Absent** when the day has neither a check-in nor a check-out.
- One check-in and one check-out per day. Each action takes a fresh GPS reading. An open session must be checked out before the next check-in.
- Work offline. Actions are saved locally, shown right away with a Pending label, and synced to Firestore when the connection returns.
- See the five most recent days on Home, and the current month on History.

**Admins (`role: admin`)**

- The Dashboard shows the total user count and today's check-in and check-out counts.
- The Users page has name or email prefix search, 20 users per page with **Load more**, and pull-to-refresh, which reloads the first page.
- View all attendance or one user's history, filtered by date range, 30 records per page.

**Everyone**

- Light and dark themes with a toggle in the app bar. The theme starts from the device setting and lasts for the current session.
- Signed-in sessions are restored on startup. Signing out clears the navigation stack.

## How the app works

### Login and roles

1. The email and password are checked with **Firebase Authentication**.
2. On success, the app reads the profile document `users/{uid}` (or `staging_users/{uid}` on staging) from **Firestore**.
3. The profile's `role` field decides the route: `admin` goes to the Admin Dashboard, `user` goes to the employee Home.
4. If the profile document is missing, the user is signed out with "Account profile is missing". If `role` is missing or invalid, sign-in fails with "This account has no role".

There are no hardcoded admin credentials. See [Create an admin account](#create-an-admin-account).

### Check-in, check-out, and offline sync

1. Pressing **Check in** or **Check out** reads the GPS location, then writes the action to a local queue file (`attendance_v2_<flavor>.json`).
2. Home and History immediately show the cached server records merged with the queued actions, so the user sees the action even when offline.
3. If the device is online, the queue is uploaded right away. Each action runs in a Firestore transaction that updates the daily record and the user's open-session lock together.
4. Sync also runs when the connection returns, when the app returns to the foreground, and on pull-to-refresh, but only while the app is open. There is no background sync.
5. Uploads are idempotent: each action carries an operation ID, so a retry never creates a duplicate.
6. If the server permanently rejects a queued action (for example, the day already exists from another device), that action is dropped and its error is shown once. The server copy wins, and later actions still sync. Network errors leave the queue untouched for the next attempt.

The recorded time is the device time at the moment the button was pressed, not the sync time. Firestore rules reject timestamps more than five minutes in the future.

### Error handling

Every repository returns `Result<T>`, which is either `Success` or `ResultFailure`. A single function, `lib/core/error/map_to_failure.dart`, turns exceptions into typed failures:

| Failure | Typical causes |
| --- | --- |
| `NetworkFailure` | No connection, timeouts, Firebase `unavailable`, HTTP or TLS errors |
| `FirebaseFailure` | Wrong credentials, email already in use, missing index, and similar Firebase errors |
| `PermissionFailure` | Location or photo permission denied, location services off, Firestore `permission-denied`, expired session, disabled account |
| `LocationFailure` | No GPS fix within 20 seconds |
| `ValidationFailure` | Invalid input, or attendance rule conflicts |
| `UnexpectedFailure` | Anything else, including Cloudinary upload errors |

Blocs keep the `Failure` in their state, and screens only display `failure.message`. If startup itself fails (missing config, flavor mismatch, or Firebase setup error), the app shows a "could not start" screen instead of crashing. Staging and local also show the technical reason.

## Architecture

```
lib/
  core/          config, error (Failure/Result), network, router, theme
  features/
    auth/              login, register, session, profile photo
    attendance/        home, history, check-in/out, offline queue, location
    admin_dashboard/   dashboard, users, all and per-user history
      domain/          entities, repository contracts, use cases (no Flutter/Firebase imports)
      data/            Firebase, Cloudinary, geolocator, disk implementations
      presentation/    blocs, pages, widgets
  app_dependencies.dart   wires every dependency once
  bootstrap.dart          per-flavor startup, Firebase init, emulator hookup
  main_<flavor>.dart      entrypoints
```

Pages send events to blocs, blocs call use cases, and use cases call repository contracts. Admin repositories re-check the `admin` role on the server before each query, and Firestore rules enforce access no matter what the UI does.

## Requirements

| Tool | Version | Needed for |
| --- | --- | --- |
| Flutter | 3.44+ (Dart `^3.12.1`) | Everything |
| Xcode + CocoaPods/SPM | Current | iOS (iOS 15.0+) |
| Android SDK + JDK 17+ | Current | Android |
| Node.js | 18+ | Firebase CLI (`npx firebase-tools`), migration tools |
| Java | **21+** | Firebase emulators (local flavor only) |
| A Cloudinary account | — | Profile photo upload |
| Firebase CLI login | — | Deploying rules and indexes |

On macOS, Java 21 can be installed with `brew install openjdk@21`. Then export it before starting the emulators:

```bash
export JAVA_HOME=/opt/homebrew/opt/openjdk@21/libexec/openjdk.jdk/Contents/Home
export PATH="$JAVA_HOME/bin:$PATH"
```

Android and iOS builds need several GB of free disk space. The first Android build downloads about 5 GB of Gradle caches.

## Flavors

| Flavor | Entrypoint | Config file | Backend | Collections |
| --- | --- | --- | --- | --- |
| `local` | `lib/main_local.dart` | `config/local.json` | Firebase emulators, project `demo-attendance-tracker` | `users`, `attendance`, `attendance_sessions` |
| `staging` | `lib/main_staging.dart` | `config/staging.json` | Live project `attendancetracker-b7a9b` | `staging_users`, `staging_attendance`, `staging_attendance_sessions` |
| `production` | `lib/main_production.dart` | `config/production.json` | Live project `attendancetracker-b7a9b` | `users`, `attendance`, `attendance_sessions` |

- Always pass all three together: `--flavor`, `-t`, and `--dart-define-from-file`. If the flavor and the entrypoint don't match, startup stops before Firebase is touched.
- Staging and production share one Firebase project, so they share Firebase Authentication accounts. Their data is kept apart by the `staging_` prefix, and roles are set separately in `users` and `staging_users`.
- Android app names are "Attendance Local", "Attendance Staging", and "Attendance Tracker". All flavors use the same application and bundle ID, so installing one flavor replaces another on the same device.
- Cloudinary photos go to `<flavor>/profiles`, and the offline queue file is separate for each flavor.

## Configuration and keys

All environment values come from `config/<flavor>.json` through `--dart-define-from-file`. The Dart code has no built-in project IDs or keys. If a staging or production value is missing, the app stops at startup with `Missing Firebase config for <flavor>: ...` instead of silently connecting to another project. Local uses fixed demo values for the emulators.

| Key | Used by | Notes |
| --- | --- | --- |
| `FIREBASE_PROJECT_ID`, `FIREBASE_SENDER_ID`, `FIREBASE_STORAGE_BUCKET` | Staging and production | Firebase Console > Project settings |
| `FIREBASE_ANDROID_API_KEY`, `FIREBASE_ANDROID_APP_ID` | Android | From the Android app registration |
| `FIREBASE_IOS_API_KEY`, `FIREBASE_IOS_APP_ID`, `IOS_BUNDLE_ID` | iOS | From the iOS app registration |
| `CLOUDINARY_CLOUD_NAME`, `CLOUDINARY_UPLOAD_PRESET` | Profile photo upload | Public values; no API key or secret |
| `EMULATOR_HOST` | Local, optional | Overrides the emulator host (defaults: `10.0.2.2` on Android, `127.0.0.1` on iOS) |

Firebase is initialized only from these Dart values. The native `google-services.json` and `GoogleService-Info.plist` files are not used to configure Firebase at startup.

### What may and may not go in config files

Everything in `config/*.json` is compiled into the app and can be extracted from an APK or IPA, so treat these values as public.

- **Allowed:** Firebase client keys and IDs (identifiers, not secrets), and the Cloudinary cloud name and upload preset name.
- **Never:** API secrets, service account keys, admin tokens, or any other server credential, whether in `config/*.json`, `--dart-define`, `.env` files, or app assets. Anything that needs a secret belongs on a server, such as a Cloud Function. Personal overrides can go in gitignored `config/*.local.json` files.

Protection for the live project comes from Firestore rules, plus two steps recommended before release:

- Restrict the API keys in Google Cloud Console > APIs & Services > Credentials (Android: package name and SHA-1; iOS: bundle ID).
- Enable Firebase App Check (Play Integrity and DeviceCheck or App Attest). This is not added yet.

## One-time setup

### 1. Install dependencies

```bash
flutter pub get
```

### 2. Firebase project (staging and production)

1. In Firebase Console, enable **Authentication > Email/Password**.
2. Create the **Firestore** database.
3. Deploy the security rules and indexes from this repo:

```bash
npx --yes firebase-tools login
npx --yes firebase-tools deploy --only firestore:rules,firestore:indexes --project attendancetracker-b7a9b
```

Rules changed in `firestore.rules` take effect only after this deploy. Compare against Firebase Console > Firestore > Rules if unsure. Wait for the indexes to finish building before using admin history filters.

### 3. Cloudinary upload preset

Photos are uploaded with an unsigned preset, so no Cloudinary secret ships in the app. In Cloudinary Console > Settings > Upload > Upload presets:

1. Add a preset named `attendance_profiles_unsigned` (or change `CLOUDINARY_UPLOAD_PRESET` in the config files to match yours).
2. Set **Signing mode** to **Unsigned**.
3. Leave the folder empty (the app sends `<flavor>/profiles`), allow only `jpg, jpeg, png`, and set a maximum size such as 5 MB.
4. Optionally add an incoming transformation such as `c_limit,w_512,h_512` to keep avatars small.

Until the preset exists, registering with a photo fails with "Could not upload the profile image". Older builds bundled a Cloudinary API secret, so rotate it in Settings > API Keys if that hasn't been done.

### 4. Create an admin account

Admins can only be created outside the app:

1. Register a normal account in the app, or create a user in Firebase Console > Authentication.
2. In Firestore, open `users/{uid}` (production) or `staging_users/{uid}` (staging). The document ID must equal the Auth UID.
3. Set `role` to `admin`. For a Console-created Auth user, create the whole document with `id`, `email`, `emailLower`, `name`, `nameLower`, `photoUrl`, `position`, `department`, and `role`.
4. Sign out and sign in again.

For the local flavor, do the same in the Emulator UI at http://127.0.0.1:4000, under Authentication and Firestore.

## Running the app

List devices with `flutter devices`, then pass the device ID with `-d <id>`.

### Staging

```bash
flutter run --flavor staging -t lib/main_staging.dart --dart-define-from-file=config/staging.json -d <device>
```

### Production (live data)

```bash
flutter run --flavor production -t lib/main_production.dart --dart-define-from-file=config/production.json -d <device>
```

### Local (Firebase emulators)

Terminal 1, with Java 21 on the `PATH`:

```bash
npx --yes firebase-tools emulators:start --only auth,firestore --project demo-attendance-tracker
```

The Emulator UI is at http://127.0.0.1:4000. Emulator data is temporary unless exported. Add `--import ./emulator-data --export-on-exit` to keep it between runs.

Terminal 2:

```bash
# iOS simulator or Android Emulator
flutter run --flavor local -t lib/main_local.dart --dart-define-from-file=config/local.json -d <device>
```

To use a physical Android phone over USB, forward the emulator ports to the Mac first:

```bash
adb reverse tcp:9099 tcp:9099 && adb reverse tcp:8080 tcp:8080
flutter run --flavor local -t lib/main_local.dart --dart-define-from-file=config/local.json --dart-define=EMULATOR_HOST=127.0.0.1 -d <device>
```

### Device notes

- Location services must be on. On emulators and simulators, set a simulated GPS position.
- After code changes during `flutter run`, press `r` (hot reload) or `R` (hot restart).

## Building APKs and releases

### Android APK for each flavor

Pick a mode: `--debug` for development, `--profile` for performance checks, or `--release` for the final build.

```bash
# Staging
flutter build apk --release --flavor staging -t lib/main_staging.dart --dart-define-from-file=config/staging.json

# Production
flutter build apk --release --flavor production -t lib/main_production.dart --dart-define-from-file=config/production.json

# Local (needs the emulators running and reachable from the phone)
flutter build apk --debug --flavor local -t lib/main_local.dart --dart-define-from-file=config/local.json
```

The APK is saved as `build/app/outputs/flutter-apk/app-<flavor>-<mode>.apk`, for example `app-staging-release.apk`. Install it on a connected phone with:

```bash
adb install -r build/app/outputs/flutter-apk/app-staging-release.apk
```

All flavors share one application ID, so installing one flavor replaces another on the same phone.

### Store builds (production)

```bash
flutter build appbundle --release --flavor production -t lib/main_production.dart --dart-define-from-file=config/production.json
flutter build ios --release --flavor production -t lib/main_production.dart --dart-define-from-file=config/production.json
```

Before publishing to a store:

- **Android signing:** release builds still use the debug key (`android/app/build.gradle.kts`). Add a release keystore.
- **App IDs:** `com.example.attendance_tracker` (Android) and `com.example.attendanceTracker` (iOS) are not accepted by the stores. Change them and register the new IDs in Firebase, then update `config/production.json`.
- **iOS:** set your signing team in Xcode.
- **Security:** restrict the API keys, enable App Check, and deploy the latest rules.

## Data model and security rules

| Path | Contents |
| --- | --- |
| `users/{uid}` | `id`, `email`, `emailLower`, `name`, `nameLower`, `position`, `department`, `photoUrl`, `role` |
| `attendance/{uid}_{yyyy-MM-dd}` | `userId`, `email`, `date`, display times `checkin` and `checkout`, UTC `checkInAt` and `checkOutAt`, `location` and `checkOutLocation` GeoPoints, operation IDs |
| `attendance_sessions/{uid}` | `openDate` while checked in, empty after check-out |

Staging uses the same layout with the `staging_` prefix. Profile photos live in Cloudinary (`<flavor>/profiles`). Firebase Storage rules remain in `storage.rules`, but the app no longer uploads to Storage.

What `firestore.rules` enforces:

- Only admins (profile `role == 'admin'`) can list users and read everyone's attendance.
- A user can read only their own profile, attendance, and session.
- Users cannot change their `role`. New profiles must have `role: 'user'`, and updates cannot touch `role`, `email`, or `id`.
- Only employees can write attendance, in a single transaction that updates the day and the session lock together. One check-in per day, no edits after check-in, no repeated check-out, and no timestamps in the future.
- Nobody can delete profiles or attendance, and every path not listed is denied.

## Migrating existing data

The old `history` array schema is left untouched, and client access to it is denied once the new rules are deployed. To migrate an existing dataset, use the admin tools. They are dry runs unless `--apply` is passed, and they need Google Application Default Credentials with Firestore and Auth access:

```bash
npm install --prefix tools
node tools/normalize_profiles.mjs --project=attendancetracker-b7a9b
node tools/migrate_history.mjs --project=attendancetracker-b7a9b --offset-minutes=390
# Review the reported counts, then:
node tools/normalize_profiles.mjs --project=attendancetracker-b7a9b --apply
node tools/migrate_history.mjs --project=attendancetracker-b7a9b --offset-minutes=390 --apply
```

- Use the original records' timezone offset (Myanmar is +390 minutes), and add `--staging` for staging profiles.
- Imports never overwrite an existing daily record.
- Missing historical check-out coordinates stay `null`.
- Sync each old installation's local queue with the previous app version before upgrading.

## Testing

Tests are run manually when needed:

```bash
flutter analyze lib
flutter test --concurrency=1
```

## Troubleshooting

| Symptom | Cause and fix |
| --- | --- |
| "Account profile is missing" | The Auth account has no `users/{uid}` document (or `staging_users/{uid}` on staging). Create it as described in [Create an admin account](#create-an-admin-account). |
| "Email or password is incorrect" on local | The user doesn't exist in the Auth emulator, whose data resets each run. Create it in the Emulator UI. |
| "You do not have access to this data" | The rules aren't deployed, or the profile's `role` is wrong. |
| "Database setup is incomplete…" | The Firestore indexes are missing. Deploy `firestore:indexes` and wait for them to build. |
| "Could not get your location…" | No GPS fix within 20 seconds. Move outdoors, or set a simulated location. |
| "Profile photo upload is not configured" or "Could not upload the profile image" | The Cloudinary keys are missing from the config file, or the unsigned preset doesn't exist. |
| "Missing Firebase config for <flavor>" at startup | `--dart-define-from-file=config/<flavor>.json` wasn't passed. |
| "Build flavor and Dart entrypoint must use the same environment" | `--flavor` and `-t lib/main_<flavor>.dart` don't match. |
| "Gradle build failed to produce an .apk file" | `--flavor` was left out, so Gradle built every flavor and Flutter couldn't pick one. Always pass `--flavor <flavor> -t lib/main_<flavor>.dart --dart-define-from-file=config/<flavor>.json`. |
| Emulators say Java is too old | Install Java 21 and export `JAVA_HOME` as shown in [Requirements](#requirements). |
| Gradle or Xcode fails with "No space left on device" | Free disk space: delete `build/`, `~/Library/Developer/Xcode/DerivedData`, and if needed `~/.gradle/caches` (it is downloaded again). |
| Physical Android phone can't reach the local emulators | Run the `adb reverse` commands and pass `EMULATOR_HOST=127.0.0.1`. |

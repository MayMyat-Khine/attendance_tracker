# Attendance Tracker

Flutter mobile and web attendance app with Firebase email/password authentication, externally assigned admin roles, BLoC, feature-first Clean Architecture, and offline attendance.

## Implemented behavior

- User registration collects name, email, password, profile image, position, and department. Photos are validated as JPEG/PNG under 5 MB and uploaded to Firebase Storage. Registration always creates `role: user`; it cannot create admins.
- Signed-in sessions restore on startup. Route guards send admins to Dashboard and employees to Home. Signing out clears the navigation stack.
- Home shows the current location, today's check-in/out, recent history, and the appropriate attendance action. Both actions require a fresh location reading.
- One check-in/check-out pair per local calendar day. An open session must be checked out before another day can start; overnight checkout closes the original day's record.
- Offline actions are saved to an atomic JSON queue. History merges cached records with pending actions. Connectivity recovery, app resume, and refresh retry synchronization in timestamp order. Only the signed-in employee's queue can sync.
- Admin Dashboard shows all registered users (including admins), and today's check-in and check-out event counts. Each event count uses its own UTC timestamp bounded by local midnight and the following local midnight.
- Admin Users supports case-insensitive name/email prefix search, 20-user cursor pages, refresh, and links to a user's history. All attendance and per-user history support inclusive local date ranges, 30-record cursor pages, and refresh. Date filters select the session's check-in date.
- Light and dark themes follow the device setting. Errors use the centralized `Failure`/`Result` mapper.

## Architecture

`lib/features/<feature>/{domain,data,presentation}` owns each feature. Domain entities, repository contracts, and use cases contain no Flutter/Firebase imports. Firebase, image picking, location, and disk access stay in data. Pages dispatch BLoC events; blocs call use cases. Dependencies are assembled once in `app_dependencies.dart`.

`lib/core` contains errors, network contracts, environment configuration, theme, and routing. Admin queries revalidate the role from the server, employee repositories check ownership/role, and Firebase rules enforce access independently of the UI.

## Build environments

Requires Flutter with Dart 3.12 or newer, Android SDK/JDK, and Xcode on macOS for iOS.

| Flavor | Entrypoint | Firebase/data |
| --- | --- | --- |
| Local | `lib/main_local.dart` | Demo project `demo-attendance-tracker`, Auth/Firestore/Storage emulators |
| Staging | `lib/main_staging.dart` | Provided Firebase project; `staging_` collection and Storage prefixes |
| Production | `lib/main_production.dart` | `attendancetracker-b7a9b`; standard collection paths |

Staging and Production currently share Firebase Authentication because only one Firebase project was supplied. Use separate test accounts for staging, or create a matching `staging_users/{uid}` profile for an existing Auth account. Roles are set separately in `users` and `staging_users`. Data and photo paths are separated; this is not isolation between Firebase projects. To use a separate staging project later, replace `config/staging.json` and deploy the rules/indexes there.

Both native platforms have matching flavors/schemes. They currently use the existing application/bundle IDs and replace one another when installed. Firebase settings are supplied through Dart options, without Android automatic google-services initialization.

```powershell
flutter pub get
flutter run --flavor staging -t lib/main_staging.dart --dart-define-from-file=config/staging.json
flutter run --flavor production -t lib/main_production.dart --dart-define-from-file=config/production.json
flutter build apk --release --flavor production -t lib/main_production.dart --dart-define-from-file=config/production.json
```

The Android template still uses debug signing for release builds; configure your release keystore before distributing through a store. On macOS, use the equivalent `flutter build ios --flavor production -t lib/main_production.dart --dart-define-from-file=config/production.json` and configure your signing team.

`lib/main.dart` also detects the selected native flavor. Entrypoint/flavor mismatches fail before Firebase initialization. All Firebase identifiers/API keys can be overridden through `--dart-define-from-file`; developer overrides may be saved as ignored `config/*.local.json` files.

### Local emulator

Install Node.js and Java 21 or newer for Firebase CLI/emulators. In one terminal:

```powershell
npx --yes firebase-tools emulators:start --only auth,firestore,storage --project demo-attendance-tracker
```

In another:

```powershell
flutter run --flavor local -t lib/main_local.dart --dart-define-from-file=config/local.json
```

Android Emulator uses `10.0.2.2` for the host. For an iOS simulator, override with `--dart-define=EMULATOR_HOST=127.0.0.1`. A physical phone needs the computer's LAN IP plus emulator host/firewall configuration. Location must be enabled, and an emulator needs a simulated GPS position.

This checkout's downloaded emulator runtimes were moved to `.local-tools/firebase-emulators` to avoid filling C:. To reuse them in PowerShell, set `$env:FIREBASE_EMULATORS_PATH = (Resolve-Path '.local-tools/firebase-emulators').Path` before starting the emulators. This directory is ignored by Git.

The Android build disables Kotlin incremental compilation because the project and Pub cache are on different Windows drives. If temporary disk space is limited, point `TEMP`, `TMP`, and Java's `java.io.tmpdir` at a directory with enough space.

## Firebase setup and admin provisioning

For an existing dataset, first synchronize attendance from old app installations, then run the reviewed migration steps below, deploy rules/indexes, and distribute the new app. The new rules deliberately deny writes from the legacy array-based client.

1. Enable Authentication > Email/Password in the supplied Firebase project.
2. Create the Firestore database and initialize Firebase Storage for the configured bucket. Firebase may require enabling billing to provision Storage.
3. Sign into the CLI with a Google account that can manage this project, then deploy:

```powershell
npx --yes firebase-tools login
npx --yes firebase-tools deploy --only firestore:rules,firestore:indexes,storage --project attendancetracker-b7a9b
```

Wait for indexes to finish building before filtering history by user/date.

To provision an admin, register a normal account, then use Firebase Console > Firestore > `users/{authUid}` (or `staging_users/{authUid}`) and set `role` to `admin`. Sign out and sign in again to refresh the cached role. There is no admin registration route, and client rules reject role changes. For a console-created Auth account, also create its profile with `id`, `email`, `emailLower`, `name`, `nameLower`, `photoUrl`, `position`, `department`, and `role`.

## Firestore and Storage schema

- `users/{uid}`: profile, immutable client role/email/id, lowercase search fields, and photo URL.
- `attendance/{uid}_{yyyy-MM-dd}`: employee UID/email, local session date and display times, UTC `checkInAt`/`checkOutAt`, check-in `location` and `checkOutLocation` GeoPoints, and idempotent operation IDs.
- `attendance_sessions/{uid}`: current `openDate`, empty after checkout.
- Storage `profiles/{uid}/avatar`: validated profile image. Staging uses `staging_` equivalents for every path.

Daily records and session locks are updated in one transaction. Rules require this paired update and prevent a second check-in, edits to an existing check-in, repeated checkout, role escalation, and cross-user reads/writes. Admins may read all profiles/attendance, but cannot edit employee attendance through the app. Unmatched paths are denied.

Offline event time comes from the device clock so the original action time survives synchronization. Rules reject timestamps more than five minutes in the future. Device clock/GPS spoof detection is outside the requirements.

A rejected upload stays in the local queue and displays a failure. It is not silently overwritten or discarded. If two offline devices create competing actions, the first valid server transaction wins; review the rejected local action before resolving it. Unsent data remains local if the app is uninstalled.

## Existing data

The former `history` array schema remains untouched and is denied to client access after the new rules are deployed. Before switching an existing Firebase dataset to this version, normalize old profiles and import old history with the supplied admin tools. They are dry runs unless `--apply` is specified and require Google Application Default Credentials with Firestore/Auth access:

```powershell
npm install --prefix tools
# Configure Application Default Credentials on your machine, then:
node tools/normalize_profiles.mjs --project=attendancetracker-b7a9b
node tools/migrate_history.mjs --project=attendancetracker-b7a9b --offset-minutes=390
# Review the reported counts before applying:
node tools/normalize_profiles.mjs --project=attendancetracker-b7a9b --apply
node tools/migrate_history.mjs --project=attendancetracker-b7a9b --offset-minutes=390 --apply
```

Use the timezone offset of the original records; Myanmar is +390 minutes. Imports never overwrite an existing daily record or delete a legacy history document. Missing historical checkout coordinates stay null rather than being fabricated. Invalid/unmatched records and conflicting open sessions require manual review. Use `--staging` with profile normalization for existing staging profiles.

The old local queue file is also left untouched. Before upgrading an existing installation, synchronize its old queue with the previous app version. New queues are versioned and separated by environment and UID; legacy operations without a UID are not uploaded under another account.

## Verification status

Source analysis uses `flutter analyze lib`. Firebase Emulator startup validates the Firestore/Storage rules. Android debug APK builds validate the native/Dart flavor wiring. Tests were enabled for the explicit web testing request. Run `flutter test --concurrency=1` for the unit/widget suite; browser tests are described below. The existing repository rule continues to require an explicit testing request for future work.

Live Firebase deployment requires an authenticated CLI account. Device attendance/auth/photo/sync flows and iOS compilation still require a connected phone/emulator and a macOS/Xcode environment, respectively. The optional push-notification feature is not included.


## Run and test in a browser

Web uses browser localStorage for the versioned attendance cache/queue, Web Locks to serialize changes across tabs, and Firestore IndexedDB persistence for cached profiles. Startup waits for Firebase Auth to restore its saved session before applying route guards. For local web builds, `web/firebase_emulator.js` connects Auth before FlutterFire restores cached credentials; its Firebase JS SDK version must stay aligned with the locked `firebase_core_web` dependency. Location requires HTTPS or localhost and browser permission.

Start the Firebase emulators as above, then build and serve the local web app:

```powershell
flutter build web -t lib/main_local.dart --dart-define=EMULATOR_HOST=127.0.0.1
python -m http.server 5173 --bind 127.0.0.1 --directory build/web
```

Open http://127.0.0.1:5173. This uses the local demo Firebase project; real project credentials are not needed. For web development with hot restart, use `flutter run -d chrome -t lib/main_local.dart --web-port=5173 --dart-define=EMULATOR_HOST=127.0.0.1` instead of the static server.

Live staging/production web builds require registering a Web app in the intended Firebase project and adding `FIREBASE_WEB_APP_ID`, `FIREBASE_WEB_API_KEY`, and `FIREBASE_AUTH_DOMAIN` to the relevant config JSON. The app intentionally does not substitute a mobile app ID for missing web configuration. For local web runs, do not use `config/local.json` unchanged because its `10.0.2.2` host is for Android Emulator; pass `EMULATOR_HOST=127.0.0.1`.

Run browser integration tests with the local emulators/server running and Chrome installed:

```powershell
npm ci --prefix tools
npx --prefix tools playwright test --config tools/playwright.config.mjs
```

Browser fixtures are created only in `demo-attendance-tracker` on localhost. Tests cover registration/photo upload, location, offline check-in/out, one pair per day, reconnect synchronization, reload/session restoration, user/admin access rules, admin pagination/search/history, dark mode, and competing check-ins from two tabs. Failure traces/screenshots go to ignored `.local-tools/playwright-results`.

After browser tests, the local admin demo account is `admin.web@example.test` with password `WebDemo123!`. This account exists only in the running local Auth emulator. The emulator data is temporary unless explicitly exported.


## Run against the real Firebase project

`config/production.json` now includes the registered **Attendance Tracker Web** app for `attendancetracker-b7a9b` (`1:114999346116:web:9698b17d4ef11c1e26da91`).

```powershell
flutter build web -t lib/main_production.dart --dart-define-from-file=config/production.json --output=build/web-production
python -m http.server 5174 --bind 127.0.0.1 --directory build/web-production
```

Open http://127.0.0.1:5174 for the real project. The emulator demo remains on port 5173. Production does not connect to the local emulator services and uses a separate attendance queue. Existing Firebase Authentication accounts and their `users/{uid}` roles are used.

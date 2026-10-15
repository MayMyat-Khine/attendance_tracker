# Web verification — 2026-10-15

Running locally at http://127.0.0.1:5173 with the demo Firebase Auth/Firestore/Storage emulators. The live Firebase project was not used.

- `flutter build web -t lib/main_local.dart --dart-define=EMULATOR_HOST=127.0.0.1`: passed.
- `flutter analyze`: passed with no issues.
- `flutter test --concurrency=1`: 34 passed.
- `npx --prefix tools playwright test --config tools/playwright.config.mjs`: 2 passed.

The browser suite exercised real local Firebase registration and photo upload, fresh geolocation, an offline daily check-in/out pair, reconnect synchronization, UTC timestamps and both coordinates in Firestore, saved-session restoration on page reload, cross-user read denial and role-escalation denial, admin pagination/name search/per-user history, and dark mode. The second browser test exercised two tabs queuing check-ins concurrently: exactly one operation was queued and one server record created.

The refresh test found an Auth emulator initialization ordering issue. Local web startup now connects Auth before FlutterFire restores its persisted user; it also awaits the initial auth state before routing. Browser attendance persistence uses localStorage plus Web Locks; native persistence retains the existing atomic file implementation. Firestore web persistence supports multiple tabs.

The local admin fixture is `admin.web@example.test` / `WebDemo123!`. All fixtures exist only in the running demo emulators. Headless browser contexts are isolated from the user's normal browser.

Services were left running for manual use. Local data disappears when the emulators stop unless exported. Live web builds still require the Firebase project's Web app configuration as documented in README.


## Real Firebase connection verification

Registered **Attendance Tracker Web** in `attendancetracker-b7a9b`, added its official Web SDK configuration to `config/production.json`, and built `build/web-production` from `lib/main_production.dart`. It is served separately at http://127.0.0.1:5174.

The supplied tester account successfully signed in through real Firebase Authentication. Its Firestore profile and Home/history data loaded successfully. Requests went to `identitytoolkit.googleapis.com` and `firestore.googleapis.com`, with no emulator requests or JavaScript runtime errors observed. No attendance action was submitted during this live verification. Browser location permission is required for check-in/out.


## Real tester attendance verification

At the user's explicit request, submitted one daily check-in/check-out pair through the production web UI for `tester@gmail.com`. Browser geolocation timed out; this verification used the disclosed test coordinates **16.8661, 96.1951**.

- Firestore record: `attendance/ttdd1a0Z5aS12eKbYynP0MVjdcs2_2026-10-15`.
- Check-in (Asia/Rangoon): **2026-10-15 14:05:07**; persisted UTC: `2026-10-15T07:35:07.682Z`.
- Check-out (Asia/Rangoon): **2026-10-15 14:05:17**; persisted UTC: `2026-10-15T07:35:17.241Z`.
- Both location GeoPoints matched the test coordinates.
- Read back the saved document directly from real Firestore using the tester's authenticated session.
- The daily session lock was closed (`openDate` empty).
- History displayed the saved date/times and both coordinates; it remained visible after a full page reload.
- No JavaScript runtime errors occurred.

The test record remains in real Firebase. Screenshot: `.local-tools/real-firebase-attendance-history.png`; raw verification result: `.local-tools/real-firebase-attendance-result.json`.

## Real Firebase admin verification (2026-10-15)

- User authorized promoting tester@gmail.com; its existing users document now has role admin. Attendance was preserved.
- Dashboard: Registered users 4, check-ins today 1, check-outs today 1.
- Added missing nameLower/emailLower search fields to 4 existing profiles.
- Users list: 2 valid profiles displayed; 2 legacy profiles lack a valid role (one also has empty identity fields). Dashboard counts all 4 documents.
- Case-insensitive name/email prefix search and empty results passed. End-of-list correctly hides Load more. A real second page cannot be tested with fewer than 21 profiles; no artificial production profiles were created. Multi-page behavior previously passed against emulators.
- All attendance logs displayed the tester daily pair, timestamps, and locations correctly.
- User-specific history initially failed because the composite index was absent. Created only the production attendance index (userId ascending, checkInAt descending, document ID descending); waiting for Firebase to finish building before final verification.
- Screenshots: .local-tools/real-admin-dashboard.png and .local-tools/real-admin-users.png.
- Final retest passed after index build: MMK user-specific history shows 2026-10-15 check-in 14:05:07.682 and checkout 14:05:17.241, both locations 16.86610, 96.19510. Screenshot: .local-tools/real-admin-user-history.png.
- Reload observation: Admin authentication persists, but reloading the user-history route loses its in-memory user argument and opens All attendance. The automated assertion expecting dashboard was incorrect; the observed page remained authorized and displayed the real record. Preserving a per-user filter across a hard reload remains a limitation.

## Legacy roles and history reload fix (2026-10-15)

- Added role=user to the two legacy profiles that had no role, using update-time preconditions and updating only that field. Existing tester admin and attendance data were preserved. All four profiles now appear in the live users list; one legacy profile still has empty name/email as in the original data.
- Per-user history navigation now encodes userId and display name in the route query. The router parses the URI path for guards and restores the user filter from the query after a full reload. Existing argument-based calls remain supported; all-attendance routes remain unfiltered.
- Targeted source analysis and production Flutter web build passed. Browser live retest confirmed tester history retains its user ID, title, record, and URL after reload.
- Evidence: .local-tools/real-admin-roles-fixed.png and .local-tools/real-admin-user-history-reload-fixed.png.
- Additional real browser retest passed for May: empty per-user history remains empty after reload, title/URL preserved, and no tester record appears. No runtime errors. Screenshot: .local-tools/real-admin-empty-history-reload-fixed.png.

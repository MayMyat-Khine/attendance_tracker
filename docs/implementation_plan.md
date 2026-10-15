# Requirements implementation plan

Agreed on 2026-10-15: complete every mandatory requirement in the supplied coding-test document; admins are assigned in Firebase; one check-in/check-out pair per local day. The older `.cursor/plans` documents are historical and do not override these decisions.

| Requirement | Implementation |
| --- | --- |
| Feature-first Clean Architecture | Existing feature layers retained; admin domain/data/presentation added |
| Failure/Result errors | Central mapper extended for photo permission, storage, setup, and access failures |
| Local/Staging/Production | Android flavors, iOS schemes/configurations, environment entrypoints and JSON configs |
| BLoC | Dashboard, users, admin history, session guard, registration, home/history flows |
| Light/Dark | Existing system-controlled Material themes retained |
| Auth and roles | Email/password, users-only signup, Firebase-assigned admin, guarded routes/repositories |
| Profile image | Gallery picker, image validation/preview, temporary Cloudinary upload, secure URL stored as photoUrl |
| Admin Dashboard | Registered-user total and separate local-day check-in/out counts |
| Users list | Name/email prefix search, cursor pagination, refresh, profile links |
| Admin history | All/per-user logs, inclusive date ranges, pagination, refresh, coordinates |
| User attendance/history | One daily session, fresh location on the home card, 12-hour times or Absent, shared bordered history cards |
| Offline-first | Durable atomic queue, cached profile/history, pending rows, reconnect/resume sync |
| Security | Owner/admin read rules, immutable roles, daily record/session transaction rules, restricted Storage |

Staging has separate collections/photo paths in the provided project and shares its Auth accounts. A separate Firebase project can be configured later without changing feature code.

Remaining environment-dependent completion: authenticated live Firebase provisioning/deployment and any necessary legacy migration; real-device interaction checks; iOS compilation on macOS. No live settings or legacy records are claimed to have been changed without deployment evidence.

Web follow-up: browser storage/Web Locks and Firestore multi-tab persistence, local Auth initialization before session restoration, web entry files, updated unit/widget tests, and Playwright emulator integration tests were added at the user's explicit request.

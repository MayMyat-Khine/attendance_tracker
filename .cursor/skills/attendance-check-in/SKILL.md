---
name: attendance-check-in
description: >-
  Implements attendance_tracker check-in and check-out, location capture, the
  open-session rule, offline queue, and sync. Use when storing logs, reading
  history, handling offline mode, or refreshing attendance data.
---

# Check-in and check-out

An attendance log is an immutable record: `id`, `userId`, `type` (`checkIn` or `checkOut`), `timestamp` (UTC), `latitude`, `longitude`, and `pendingSync`.

## Session rule

A user has at most one open session (a check-in with no later check-out).

- Check-in while a session is open → `ValidationFailure('Check out before checking in again.')`
- Check-out with no open session → `ValidationFailure('Check in before checking out.')`
- Decide this in `CheckIn` and `CheckOut`, using local pending logs plus the latest remote log.
- The repository must reject a conflicting write so a second device or a retry cannot create two open sessions.

The home button is Check in when there is no open session, and Check out when there is. Show the current location from a one-shot `GetCurrentLocation` call when the screen opens and again when the user submits. Do not stream GPS.

If location permission is missing, return `PermissionFailure` and do not write a log.

## Offline mode

Only check-in and check-out work offline. Login, registration, and admin lists require a network.

- `NetworkInfo.isConnected` is the gate.
- Offline success writes the log to a local queue (JSON file via `path_provider`) with `pendingSync: true` and returns `Success`.
- Online success writes to Firestore. Then run sync.
- `SyncPendingLogs` runs when connectivity returns and when the app resumes: upload the queue in timestamp order, then delete uploaded items.
- A failed upload leaves the item in the queue and returns the mapped `Failure` without dropping it.
- The open-session check includes queued logs so two offline check-ins cannot both succeed.

## History

- User history queries are scoped by the signed-in `userId` inside the repository method.
- Admin history accepts a user id plus a local date range and can read every log.
- Pull-to-refresh reloads from remote when online, and shows the local queue merged with the last cached page when offline.
- Sort by timestamp descending. Pending rows stay visible.

## Decisions worth stating in the reply

Explain that the session rule lives in the use case and is repeated at the write, that offline success is a queued `Success`, and that location is one-shot rather than a stream.

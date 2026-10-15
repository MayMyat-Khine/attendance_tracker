# Home card and shared history cards

Display-only. Stored check-in and check-out stay `HH:mm`.

## Home profile card

- Today's local date sits above the check-in time.
- Check-in and check-out display as 12-hour times (`9:05 AM`, `1:30 PM`). An empty time shows Absent.
- The live latitude and longitude that used to sit under the History title are inside this card. Missing GPS keeps the unavailable message.
- The square button uses a location pin for check-in, a logout icon for check-out, and a check icon when the day is finished.

## History lists

Home shows the 5 newest saved records. History shows the full saved list. Both use the same card: theme surface, outline border, and 12-point corners. Each card shows the date and both times in 12-hour form, or Absent when a time is empty. Days that were never saved are not added.

`displayAttendanceTime` in `lib/features/attendance/domain/attendance_time.dart` converts a stored `HH:mm` string for both surfaces.

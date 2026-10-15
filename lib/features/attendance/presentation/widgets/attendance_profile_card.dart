import 'package:flutter/material.dart';

import 'package:attendance_tracker/core/error/failure.dart';
import 'package:attendance_tracker/features/attendance/domain/attendance_time.dart';
import 'package:attendance_tracker/features/attendance/domain/entities/attendance_action.dart';
import 'package:attendance_tracker/features/attendance/domain/entities/attendance_day.dart';

class AttendanceProfileCard extends StatelessWidget {
  const AttendanceProfileCard({
    required this.date,
    required this.locationLabel,
    this.coordinates,
    required this.day,
    required this.action,
    required this.isSubmitting,
    required this.onCheckIn,
    required this.onCheckOut,
    this.failure,
    super.key,
  });

  final String date;
  final String locationLabel;
  final String? coordinates;
  final AttendanceDay? day;
  final AttendanceAction action;
  final bool isSubmitting;
  final VoidCallback onCheckIn;
  final VoidCallback onCheckOut;
  final Failure? failure;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final message = failure?.message;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              displayAttendanceDate(date),
                              style: textTheme.titleMedium,
                            ),
                          ),
                          if (_absent)
                            Text('Absent', style: textTheme.labelLarge),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text('Check in', style: textTheme.labelLarge),
                      const SizedBox(height: 4),
                      Text(
                        _timeLabel(day, isCheckIn: true),
                        style: textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      Text('Check out', style: textTheme.labelLarge),
                      const SizedBox(height: 4),
                      Text(
                        _timeLabel(day, isCheckIn: false),
                        style: textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      coordinates == null
                          ? Text(locationLabel, style: textTheme.bodyMedium)
                          : Row(
                              children: [
                                Text('Location', style: textTheme.bodyMedium),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    coordinates!,
                                    style: textTheme.bodyMedium,
                                    maxLines: 1,
                                    softWrap: false,
                                  ),
                                ),
                              ],
                            ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                _SquareAction(
                  action: action,
                  isSubmitting: isSubmitting,
                  onCheckIn: onCheckIn,
                  onCheckOut: onCheckOut,
                ),
              ],
            ),
          ),
        ),
        if (message != null) ...[
          const SizedBox(height: 8),
          Text(
            message,
            style: textTheme.bodyMedium?.copyWith(color: colorScheme.error),
          ),
        ],
      ],
    );
  }

  bool get _absent =>
      day == null ||
      isAbsentStatus(checkIn: day!.checkIn, checkOut: day!.checkOut);

  String _timeLabel(AttendanceDay? day, {required bool isCheckIn}) {
    if (day == null) {
      return '-';
    }
    return displayAttendanceTime(isCheckIn ? day.checkIn : day.checkOut);
  }
}

class _SquareAction extends StatelessWidget {
  const _SquareAction({
    required this.action,
    required this.isSubmitting,
    required this.onCheckIn,
    required this.onCheckOut,
  });

  final AttendanceAction action;
  final bool isSubmitting;
  final VoidCallback onCheckIn;
  final VoidCallback onCheckOut;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final enabled = !isSubmitting && action != AttendanceAction.completed;
    final onPressed = switch (action) {
      AttendanceAction.checkIn => onCheckIn,
      AttendanceAction.checkOut => onCheckOut,
      AttendanceAction.completed => null,
    };
    final icon = switch (action) {
      AttendanceAction.checkIn => Icons.location_on,
      AttendanceAction.checkOut => Icons.logout,
      AttendanceAction.completed => Icons.check,
    };
    final tooltip = switch (action) {
      AttendanceAction.checkIn => 'Check in',
      AttendanceAction.checkOut => 'Check out',
      AttendanceAction.completed => 'Checked out',
    };

    return SizedBox(
      width: 72,
      height: 72,
      child: Material(
        color: enabled
            ? colorScheme.primary
            : colorScheme.surfaceContainerHighest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          onTap: enabled ? onPressed : null,
          customBorder: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: isSubmitting
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colorScheme.onPrimary,
                    ),
                  )
                : Icon(
                    icon,
                    color: enabled
                        ? colorScheme.onPrimary
                        : colorScheme.onSurfaceVariant,
                    semanticLabel: tooltip,
                  ),
          ),
        ),
      ),
    );
  }
}

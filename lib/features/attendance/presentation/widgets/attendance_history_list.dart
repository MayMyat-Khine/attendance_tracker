import 'package:flutter/material.dart';

import 'package:attendance_tracker/features/attendance/domain/attendance_time.dart';
import 'package:attendance_tracker/features/attendance/domain/entities/attendance_day.dart';

class AttendanceHistoryList extends StatelessWidget {
  const AttendanceHistoryList({required this.days, super.key});

  final List<AttendanceDay> days;

  @override
  Widget build(BuildContext context) {
    if (days.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 48),
          Center(child: Text('No history yet')),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      itemCount: days.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        return _HistoryCard(day: days[index]);
      },
    );
  }
}

class _TimeColumn extends StatelessWidget {
  const _TimeColumn({required this.label, required this.time});

  final String label;
  final String time;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: textTheme.labelLarge),
        const SizedBox(height: 4),
        Text(time, style: textTheme.titleMedium),
      ],
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.day});

  final AttendanceDay day;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final checkIn = displayAttendanceTime(day.checkIn);
    final checkOut = displayAttendanceTime(day.checkOut);
    final absent = isAbsentStatus(
      checkIn: day.checkIn,
      checkOut: day.checkOut,
    );

    return Card(
      margin: EdgeInsets.zero,
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outline),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    displayAttendanceDate(day.date),
                    style: textTheme.titleMedium,
                  ),
                ),
                if (absent) Text('Absent', style: textTheme.labelLarge),
                if (absent && day.pendingSync) const SizedBox(width: 8),
                if (day.pendingSync)
                  Text('Pending', style: textTheme.labelMedium),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _TimeColumn(label: 'Check in', time: checkIn)),
                const SizedBox(width: 12),
                Expanded(
                  child: _TimeColumn(label: 'Check out', time: checkOut),
                ),
              ],
            ),
            if (day.location != null) ...[
              const SizedBox(height: 12),
              Text(displayLocation(day.location!), style: textTheme.bodyMedium),
            ],
            if (day.checkOutAt != null &&
                day.checkOutAt!.toLocal().toString().split(' ').first !=
                    day.date)
              Text(
                'Checked out on ${displayLocalDate(day.checkOutAt!)}',
                style: textTheme.bodyMedium,
              ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import 'package:attendance_tracker/features/attendance/domain/entities/attendance_day.dart';

class AttendanceHistoryList extends StatelessWidget {
  const AttendanceHistoryList({required this.days, super.key});

  final List<AttendanceDay> days;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

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
      itemCount: days.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final day = days[index];
        final checkIn = day.isAbsent ? 'Absent' : day.checkIn;
        final checkOut = day.isAbsent
            ? 'Absent'
            : (day.checkOut.isEmpty ? '—' : day.checkOut);
        return ListTile(
          title: Text(day.date),
          subtitle: Text('Check in $checkIn · Check out $checkOut'),
          trailing: day.pendingSync
              ? Text('Pending', style: textTheme.labelMedium)
              : null,
        );
      },
    );
  }
}

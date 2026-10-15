import 'package:flutter/material.dart';
import 'package:attendance_tracker/core/router/app_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:attendance_tracker/features/admin_dashboard/presentation/bloc/user_history_bloc.dart';
import 'package:attendance_tracker/features/attendance/domain/attendance_time.dart';

class UserHistoryPage extends StatelessWidget {
  const UserHistoryPage({super.key, this.userName});
  final String? userName;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(userName == null ? 'All attendance' : '$userName · History'),
    ),
    body: BlocBuilder<UserHistoryBloc, UserHistoryState>(
      builder: (context, state) {
        final ready = state as UserHistoryReady;
        return Column(
          children: [
            if (userName == null)
              TextButton.icon(
                onPressed: () => Navigator.pushNamed(context, AppRouter.users),
                icon: const Icon(Icons.person_search),
                label: const Text('Filter by user'),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: OutlinedButton.icon(
                icon: const Icon(Icons.date_range),
                label: Text(
                  '${displayLocalDate(ready.from)} — ${displayLocalDate(ready.to)}',
                ),
                onPressed: () async {
                  final range = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                    initialDateRange: DateTimeRange(
                      start: ready.from,
                      end: ready.to,
                    ),
                  );
                  if (range != null && context.mounted) {
                    context.read<UserHistoryBloc>().add(
                      UserHistoryRangeChanged(range.start, range.end),
                    );
                  }
                },
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  final bloc = context.read<UserHistoryBloc>();
                  final done = bloc.stream.firstWhere(
                    (s) => s is UserHistoryReady && !s.loading,
                  );
                  bloc.add(const UserHistoryRefreshed());
                  await done;
                },
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    if (ready.loading) const LinearProgressIndicator(),
                    if (ready.failure case final failure?)
                      ListTile(
                        title: Text(failure.message),
                        trailing: IconButton(
                          icon: const Icon(Icons.refresh),
                          onPressed: () => context.read<UserHistoryBloc>().add(
                            const UserHistoryRefreshed(),
                          ),
                        ),
                      ),
                    if (!ready.loading &&
                        ready.logs.isEmpty &&
                        ready.failure == null)
                      const ListTile(
                        title: Text('No attendance in this date range'),
                      ),
                    for (final log in ready.logs)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                log.email,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              Text(displayAttendanceDate(log.record.date)),
                              const SizedBox(height: 8),
                              Text(
                                'Check in: ${log.record.checkIn.isEmpty ? 'Absent' : displayAttendanceTime(log.record.checkIn)}',
                              ),
                              if (log.record.latitude != null &&
                                  log.record.longitude != null)
                                Text(
                                  displayLocation(
                                    '${log.record.latitude!.toStringAsFixed(5)}, ${log.record.longitude!.toStringAsFixed(5)}',
                                  ),
                                ),
                              Text(
                                'Check out: ${log.record.checkOut.isEmpty ? 'Absent' : displayAttendanceTime(log.record.checkOut)}',
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (ready.next != null)
                      OutlinedButton(
                        onPressed: ready.loading
                            ? null
                            : () => context.read<UserHistoryBloc>().add(
                                const UserHistoryNextPageRequested(),
                              ),
                        child: const Text('Load more'),
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    ),
  );
}

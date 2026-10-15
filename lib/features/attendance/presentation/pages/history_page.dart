import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:attendance_tracker/core/router/app_router.dart';
import 'package:attendance_tracker/features/attendance/presentation/bloc/history_bloc.dart';
import 'package:attendance_tracker/features/attendance/presentation/bloc/history_event.dart';
import 'package:attendance_tracker/features/attendance/presentation/bloc/history_state.dart';
import 'package:attendance_tracker/features/attendance/presentation/widgets/attendance_history_list.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: BlocConsumer<HistoryBloc, HistoryState>(
        listener: (context, state) {
          if (state is HistorySignedOut) {
            Navigator.pushReplacementNamed(context, AppRouter.login);
          }
        },
        builder: (context, state) {
          return switch (state) {
            HistoryLoading() || HistorySignedOut() => const Center(
              child: CircularProgressIndicator(),
            ),
            HistoryFailure(:final failure) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(failure.message),
                    TextButton(
                      onPressed: () => context.read<HistoryBloc>().add(
                        const HistoryStarted(),
                      ),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
            HistoryReady(:final days, :final failure) => Column(
              children: [
                if (failure != null)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(failure.message),
                        TextButton(
                          onPressed: () => context.read<HistoryBloc>().add(
                            const HistoryStarted(),
                          ),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      final bloc = context.read<HistoryBloc>();
                      final next = bloc.stream.first;
                      bloc.add(const HistoryRefreshed());
                      await next;
                    },
                    child: AttendanceHistoryList(days: days),
                  ),
                ),
              ],
            ),
          };
        },
      ),
    );
  }
}

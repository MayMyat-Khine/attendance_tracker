import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:attendance_tracker/core/router/app_router.dart';
import 'package:attendance_tracker/features/attendance/domain/attendance_time.dart';
import 'package:attendance_tracker/features/attendance/presentation/bloc/home_bloc.dart';
import 'package:attendance_tracker/features/attendance/presentation/bloc/home_event.dart';
import 'package:attendance_tracker/features/attendance/presentation/bloc/home_state.dart';
import 'package:attendance_tracker/features/attendance/presentation/widgets/attendance_history_list.dart';
import 'package:attendance_tracker/features/attendance/presentation/widgets/attendance_profile_card.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      context.read<HomeBloc>().add(const HomeResumed());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
            onPressed: () => Navigator.pushNamedAndRemoveUntil(
              context,
              AppRouter.logout,
              (_) => false,
            ),
          ),
        ],
      ),
      body: BlocConsumer<HomeBloc, HomeState>(
        listener: (context, state) {
          if (state is HomeSignedOut) {
            Navigator.pushReplacementNamed(context, AppRouter.login);
          }
        },
        builder: (context, state) {
          return switch (state) {
            HomeLoading() ||
            HomeSignedOut() => const Center(child: CircularProgressIndicator()),
            HomeLoadFailure(:final failure) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(failure.message),
                    TextButton(
                      onPressed: () =>
                          context.read<HomeBloc>().add(const HomeStarted()),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
            HomeReady() => _HomeBody(state: state),
          };
        },
      ),
    );
  }
}

class _HomeBody extends StatelessWidget {
  const _HomeBody({required this.state});

  final HomeReady state;

  @override
  Widget build(BuildContext context) {
    final today = state.history.days.isEmpty ? null : state.history.days.first;
    final location = state.location;

    return Column(
      children: [
        ListTile(
          leading: CircleAvatar(
            backgroundImage: state.photoUrl?.isNotEmpty == true
                ? NetworkImage(state.photoUrl!)
                : null,
            child: state.photoUrl?.isNotEmpty == true
                ? null
                : const Icon(Icons.person),
          ),
          title: Text(state.name),
          subtitle: Text(state.email),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: AttendanceProfileCard(
            date: today?.date ?? formatAttendanceDate(DateTime.now()),
            locationLabel: location == null
                ? 'Check in Location unavailable. Enable GPS and location permission.'
                : displayLocation(
                    '${location.latitude.toStringAsFixed(5)}, ${location.longitude.toStringAsFixed(5)}',
                  ),
            day: today,
            action: state.history.action,
            isSubmitting: state.isSubmitting,
            failure: state.failure,
            onCheckIn: () {
              context.read<HomeBloc>().add(const CheckInRequested());
            },
            onCheckOut: () {
              context.read<HomeBloc>().add(const CheckOutRequested());
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
          child: Row(
            children: [
              Text('History', style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, AppRouter.history);
                },
                child: const Text('See more'),
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              final bloc = context.read<HomeBloc>();
              final next = bloc.stream.first;
              bloc.add(const HomeRefreshed());
              await next;
            },
            child: AttendanceHistoryList(
              days: state.history.savedDays.take(5).toList(),
            ),
          ),
        ),
      ],
    );
  }
}

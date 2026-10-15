import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:attendance_tracker/core/router/app_router.dart';
import 'package:attendance_tracker/features/admin_dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:attendance_tracker/features/attendance/domain/attendance_time.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Admin dashboard'),
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
    body: BlocBuilder<DashboardBloc, DashboardState>(
      builder: (context, state) {
        if (state is DashboardLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        final ready = state as DashboardReady;
        return RefreshIndicator(
          onRefresh: () async {
            final bloc = context.read<DashboardBloc>();
            final done = bloc.stream.first;
            bloc.add(const DashboardRefreshed());
            await done;
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                'Today · ${displayLocalDate(DateTime.now())}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              if (ready.failure case final failure?) ...[
                Text(
                  failure.message,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                TextButton(
                  onPressed: () => context.read<DashboardBloc>().add(
                    const DashboardRefreshed(),
                  ),
                  child: const Text('Retry'),
                ),
              ],
              if (ready.summary case final summary?) ...[
                _CountCard(
                  'Registered users',
                  summary.totalUsers,
                  Icons.people_outline,
                ),
                _CountCard('Check-ins today', summary.checkIns, Icons.login),
                _CountCard('Check-outs today', summary.checkOuts, Icons.logout),
              ],
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => Navigator.pushNamed(context, AppRouter.users),
                icon: const Icon(Icons.people),
                label: const Text('Users'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () =>
                    Navigator.pushNamed(context, AppRouter.adminHistory),
                icon: const Icon(Icons.history),
                label: const Text('All attendance logs'),
              ),
            ],
          ),
        );
      },
    ),
  );
}

class _CountCard extends StatelessWidget {
  const _CountCard(this.label, this.count, this.icon);
  final String label;
  final int count;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      leading: Icon(icon),
      title: Text(label),
      trailing: Text(
        '$count',
        style: Theme.of(context).textTheme.headlineMedium,
      ),
    ),
  );
}

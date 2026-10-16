import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:attendance_tracker/core/router/app_router.dart';
import 'package:attendance_tracker/core/theme/app_theme_scope.dart';
import 'package:attendance_tracker/features/admin_dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:attendance_tracker/features/attendance/domain/attendance_time.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Admin dashboard'),
      actions: [
        const ThemeModeButton(),
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
        final ready = switch (state) {
          DashboardLoading() => null,
          DashboardReady ready => ready,
        };
        if (ready == null) {
          return const Center(child: CircularProgressIndicator());
        }
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
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () => context.read<DashboardBloc>().add(
                      const DashboardRefreshed(),
                    ),
                    child: const Text('Retry'),
                  ),
                ),
              ],
              if (ready.summary case final summary?) ...[
                _CountCard(
                  label: 'Registered users',
                  count: summary.totalUsers,
                  icon: Icons.people_outline,
                ),
                _CountCard(
                  label: 'Check-ins today',
                  count: summary.checkIns,
                  icon: Icons.login,
                ),
                _CountCard(
                  label: 'Check-outs today',
                  count: summary.checkOuts,
                  icon: Icons.logout,
                ),
              ],
              const SizedBox(height: 8),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => Navigator.pushNamed(context, AppRouter.users),
                icon: const Icon(Icons.people),
                label: const Text('Users'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
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
  const _CountCard({
    required this.label,
    required this.count,
    required this.icon,
  });

  final String label;
  final int count;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outline),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: SizedBox(
                width: 44,
                height: 44,
                child: Icon(icon, color: colorScheme.onPrimaryContainer),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(child: Text(label, style: textTheme.titleMedium)),
            Text('$count', style: textTheme.headlineSmall),
          ],
        ),
      ),
    );
  }
}

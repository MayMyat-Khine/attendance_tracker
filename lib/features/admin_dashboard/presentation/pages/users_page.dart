import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:attendance_tracker/core/router/app_router.dart';
import 'package:attendance_tracker/features/admin_dashboard/presentation/bloc/users_bloc.dart';

class UsersPage extends StatefulWidget {
  const UsersPage({super.key});
  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  final _search = TextEditingController();
  bool _byEmail = false;
  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _changed() =>
      context.read<UsersBloc>().add(UsersSearchChanged(_search.text, _byEmail));
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Users')),
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: false, label: Text('Name')),
                  ButtonSegment(value: true, label: Text('Email')),
                ],
                selected: {_byEmail},
                onSelectionChanged: (value) {
                  setState(() => _byEmail = value.first);
                  _changed();
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _search,
                onChanged: (_) => _changed(),
                decoration: InputDecoration(
                  labelText: _byEmail
                      ? 'Email starts withâ€¦'
                      : 'Name starts withâ€¦',
                  prefixIcon: const Icon(Icons.search),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: BlocBuilder<UsersBloc, UsersState>(
            builder: (context, state) {
              final ready = state as UsersReady;
              return RefreshIndicator(
                onRefresh: () async {
                  final bloc = context.read<UsersBloc>();
                  final done = bloc.stream.firstWhere(
                    (s) => s is UsersReady && !s.loading,
                  );
                  bloc.add(const UsersRefreshed());
                  await done;
                },
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    if (ready.loading) const LinearProgressIndicator(),
                    if (ready.failure case final failure?)
                      ListTile(
                        title: Text(failure.message),
                        trailing: IconButton(
                          icon: const Icon(Icons.refresh),
                          onPressed: () => context.read<UsersBloc>().add(
                            const UsersRefreshed(),
                          ),
                        ),
                      ),
                    if (!ready.loading &&
                        ready.users.isEmpty &&
                        ready.failure == null)
                      const ListTile(title: Text('No users found')),
                    for (final user in ready.users)
                      ListTile(
                        leading: CircleAvatar(
                          backgroundImage: user.photoUrl?.isNotEmpty == true
                              ? NetworkImage(user.photoUrl!)
                              : null,
                          child: user.photoUrl?.isNotEmpty == true
                              ? null
                              : const Icon(Icons.person),
                        ),
                        title: Text(
                          user.name?.isNotEmpty == true
                              ? user.name!
                              : user.email,
                        ),
                        subtitle: Text('${user.email} Â· ${user.role.name}'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.pushNamed(
                          context,
                          AppRouter.adminHistory,
                          arguments: user,
                        ),
                      ),
                    if (ready.next != null)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: OutlinedButton(
                          onPressed: ready.loading
                              ? null
                              : () => context.read<UsersBloc>().add(
                                  const UsersNextPageRequested(),
                                ),
                          child: const Text('Load more'),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    ),
  );
}

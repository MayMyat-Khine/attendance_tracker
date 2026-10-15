import 'package:attendance_tracker/features/auth/domain/entities/app_user.dart';
import 'package:attendance_tracker/features/auth/presentation/bloc/session_bloc.dart';
import 'package:attendance_tracker/features/admin_dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:attendance_tracker/features/admin_dashboard/presentation/bloc/users_bloc.dart';
import 'package:attendance_tracker/features/admin_dashboard/presentation/bloc/user_history_bloc.dart';
import 'package:attendance_tracker/features/admin_dashboard/presentation/pages/users_page.dart';
import 'package:attendance_tracker/features/admin_dashboard/presentation/pages/user_history_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:attendance_tracker/app_dependencies.dart';
import 'package:attendance_tracker/features/admin_dashboard/presentation/pages/dashboard_page.dart';
import 'package:attendance_tracker/features/attendance/presentation/bloc/history_bloc.dart';
import 'package:attendance_tracker/features/attendance/presentation/bloc/home_bloc.dart';
import 'package:attendance_tracker/features/attendance/presentation/pages/history_page.dart';
import 'package:attendance_tracker/features/attendance/presentation/pages/home_page.dart';
import 'package:attendance_tracker/features/auth/domain/entities/user_role.dart';
import 'package:attendance_tracker/features/auth/presentation/bloc/login_bloc.dart';
import 'package:attendance_tracker/features/auth/presentation/bloc/register_bloc.dart';
import 'package:attendance_tracker/features/auth/presentation/pages/login_page.dart';
import 'package:attendance_tracker/features/auth/presentation/pages/register_page.dart';

abstract final class AppRouter {
  static const login = '/';
  static const register = '/register';
  static const home = '/home';
  static const history = '/history';
  static const dashboard = '/dashboard';
  static const users = '/admin/users';
  static const adminHistory = '/admin/history';
  static const logout = '/logout';

  static String locationFor(UserRole role) {
    return switch (role) {
      UserRole.admin => dashboard,
      UserRole.user => home,
    };
  }

  static Route<void> onGenerateRoute(
    RouteSettings settings,
    AppDependencies dependencies,
  ) {
    return MaterialPageRoute<void>(
      settings: settings,
      builder: (_) {
        return BlocProvider(
          create: (_) => SessionBloc(
            dependencies.getSignedInUser,
            dependencies.signOut,
            logout: settings.name == logout,
          ),
          child: BlocBuilder<SessionBloc, SessionState>(
            builder: (context, state) {
              if (state is SessionLoading) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              final ready = state as SessionReady;
              if (ready.failure case final failure?) {
                return Scaffold(
                  body: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(failure.message),
                        TextButton(
                          onPressed: () => context.read<SessionBloc>().add(
                            const SessionStarted(),
                          ),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                );
              }
              final user = ready.user;
              if (user == null) {
                return settings.name == register
                    ? _register(dependencies)
                    : _login(dependencies);
              }
              if (user.role == UserRole.admin) {
                return switch (settings.name) {
                  users => BlocProvider(
                    create: (_) => UsersBloc(dependencies.searchUsers),
                    child: const UsersPage(),
                  ),
                  adminHistory => _adminHistory(
                    dependencies,
                    settings.arguments is AppUser
                        ? settings.arguments as AppUser
                        : null,
                  ),
                  _ => BlocProvider(
                    create: (_) =>
                        DashboardBloc(dependencies.getDashboardSummary),
                    child: const DashboardPage(),
                  ),
                };
              }
              return settings.name == history
                  ? _history(dependencies)
                  : _home(dependencies);
            },
          ),
        );
      },
    );
  }

  static Widget _adminHistory(AppDependencies dependencies, AppUser? user) =>
      BlocProvider(
        create: (_) =>
            UserHistoryBloc(dependencies.getAdminHistory, userId: user?.id),
        child: UserHistoryPage(
          userName: user?.name?.isNotEmpty == true ? user?.name : user?.email,
        ),
      );

  static Widget _login(AppDependencies dependencies) {
    return BlocProvider(
      create: (_) => LoginBloc(
        signIn: dependencies.signIn,
        sendPasswordReset: dependencies.sendPasswordReset,
        signOut: dependencies.signOut,
      ),
      child: const LoginPage(),
    );
  }

  static Widget _home(AppDependencies dependencies) {
    return BlocProvider(
      create: (_) => HomeBloc(
        getSignedInUser: dependencies.getSignedInUser,
        getUserHistory: dependencies.getUserHistory,
        getCurrentLocation: dependencies.getCurrentLocation,
        checkIn: dependencies.checkIn,
        checkOut: dependencies.checkOut,
        syncPendingLogs: dependencies.syncPendingLogs,
        networkInfo: dependencies.networkInfo,
      ),
      child: const HomePage(),
    );
  }

  static Widget _history(AppDependencies dependencies) {
    return BlocProvider(
      create: (_) => HistoryBloc(
        getSignedInUser: dependencies.getSignedInUser,
        getUserHistory: dependencies.getUserHistory,
        syncPendingLogs: dependencies.syncPendingLogs,
      ),
      child: const HistoryPage(),
    );
  }

  static Widget _register(AppDependencies dependencies) {
    return BlocProvider(
      create: (_) => RegisterBloc(
        registerAccount: dependencies.registerAccount,
        pickProfileImage: dependencies.pickProfileImage,
      ),
      child: const RegisterPage(),
    );
  }
}

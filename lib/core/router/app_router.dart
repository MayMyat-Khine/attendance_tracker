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
        return switch (settings.name) {
          register => _register(dependencies),
          home => _home(dependencies),
          history => _history(dependencies),
          dashboard => const DashboardPage(),
          _ => _login(dependencies),
        };
      },
    );
  }

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
      create: (_) =>
          RegisterBloc(registerAccount: dependencies.registerAccount),
      child: const RegisterPage(),
    );
  }
}

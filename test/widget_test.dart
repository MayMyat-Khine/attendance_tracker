import 'package:attendance_tracker/app.dart';
import 'package:attendance_tracker/features/auth/domain/entities/app_user.dart';
import 'package:attendance_tracker/features/auth/domain/entities/user_role.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'support/fake_auth_repository.dart';
import 'support/test_dependencies.dart';

void main() {
  testWidgets('shows one login and users-only registration', (tester) async {
    await tester.pumpWidget(
      App(dependencies: testDependencies(FakeAuthRepository())),
    );
    await tester.pumpAndSettle();
    expect(find.widgetWithText(FilledButton, 'Login'), findsOneWidget);
    expect(find.text('Register'), findsOneWidget);
    expect(find.text('Admin'), findsNothing);
    await tester.tap(find.text('Register'));
    await tester.pumpAndSettle();
    expect(find.text('Choose profile image'), findsOneWidget);
    expect(find.text('Name'), findsOneWidget);
  });
  testWidgets('restores an admin to the dashboard', (tester) async {
    final auth = FakeAuthRepository()
      ..current = const AppUser(
        id: 'admin',
        email: 'admin@example.com',
        role: UserRole.admin,
      );
    await tester.pumpWidget(App(dependencies: testDependencies(auth)));
    await tester.pumpAndSettle();
    expect(find.text('Admin dashboard'), findsOneWidget);
    expect(find.text('Registered users'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
  });
  testWidgets('restores an employee to Home and signs out', (tester) async {
    final auth = FakeAuthRepository()
      ..current = const AppUser(
        id: 'user-1',
        email: 'user@example.com',
        role: UserRole.user,
        name: 'Ada',
      );
    await tester.pumpWidget(App(dependencies: testDependencies(auth)));
    await tester.pumpAndSettle();
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Ada'), findsOneWidget);
    await tester.tap(find.byTooltip('Sign out'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(FilledButton, 'Login'), findsOneWidget);
    expect(auth.current, isNull);
  });
}

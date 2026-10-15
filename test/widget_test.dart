import 'package:attendance_tracker/app.dart';
import 'package:attendance_tracker/app_dependencies.dart';
import 'package:attendance_tracker/features/auth/domain/usecases/get_signed_in_user.dart';
import 'package:attendance_tracker/features/auth/domain/usecases/register_account.dart';
import 'package:attendance_tracker/features/auth/domain/usecases/send_password_reset.dart';
import 'package:attendance_tracker/features/auth/domain/usecases/sign_in.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_auth_repository.dart';

void main() {
  testWidgets('shows user and admin entry points', (tester) async {
    final repository = FakeAuthRepository();

    await tester.pumpWidget(
      App(
        dependencies: AppDependencies(
          signIn: SignIn(repository),
          registerAccount: RegisterAccount(repository),
          sendPasswordReset: SendPasswordReset(repository),
          getSignedInUser: GetSignedInUser(repository),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('User'), findsOneWidget);
    expect(find.text('Admin'), findsOneWidget);
  });
}

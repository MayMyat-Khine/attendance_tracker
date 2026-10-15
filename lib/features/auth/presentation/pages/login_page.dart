import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:attendance_tracker/core/router/app_router.dart';
import 'package:attendance_tracker/features/auth/presentation/bloc/login_bloc.dart';
import 'package:attendance_tracker/features/auth/presentation/bloc/login_event.dart';
import 'package:attendance_tracker/features/auth/presentation/bloc/login_state.dart';
import 'package:attendance_tracker/features/auth/presentation/widgets/auth_fields.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: BlocConsumer<LoginBloc, LoginState>(
        listener: (context, state) {
          switch (state) {
            case LoginSucceeded(:final user):
              Navigator.pushReplacementNamed(
                context,
                AppRouter.locationFor(user.role),
              );
            case LoginReady(:final passwordResetSent) when passwordResetSent:
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Password reset email sent.')),
              );
            case LoginCheckingSession():
            case LoginReady():
              break;
          }
        },
        builder: (context, state) {
          return switch (state) {
            LoginCheckingSession() || LoginSucceeded() => const Center(
              child: CircularProgressIndicator(),
            ),
            LoginReady(:final failure, :final isSubmitting) => SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  const _LoginLogo(),
                  const SizedBox(height: 32),
                  AuthFields(
                    emailController: _emailController,
                    passwordController: _passwordController,
                    submitLabel: 'Login',
                    isSubmitting: isSubmitting,
                    failure: failure,
                    onSubmit: () {
                      context.read<LoginBloc>().add(
                        LoginSubmitted(
                          email: _emailController.text,
                          password: _passwordController.text,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: isSubmitting
                        ? null
                        : () {
                            Navigator.pushReplacementNamed(
                              context,
                              AppRouter.register,
                            );
                          },
                    child: const Text('Register'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: isSubmitting
                        ? null
                        : () {
                            context.read<LoginBloc>().add(
                              ForgotPasswordRequested(
                                email: _emailController.text,
                              ),
                            );
                          },
                    child: const Text('Forgot password'),
                  ),
                ],
              ),
            ),
          };
        },
      ),
    );
  }
}

class _LoginLogo extends StatelessWidget {
  const _LoginLogo();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colorScheme.primary,
          shape: BoxShape.circle,
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Icon(Icons.schedule, size: 48, color: colorScheme.onPrimary),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:attendance_tracker/core/error/failure.dart';
import 'package:attendance_tracker/core/router/app_router.dart';
import 'package:attendance_tracker/features/auth/domain/entities/department.dart';
import 'package:attendance_tracker/features/auth/presentation/bloc/register_bloc.dart';
import 'package:attendance_tracker/features/auth/presentation/bloc/register_event.dart';
import 'package:attendance_tracker/features/auth/presentation/bloc/register_state.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _positionController = TextEditingController();
  String? _department = Department.values.contains('IT') ? 'IT' : null;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _positionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: BlocConsumer<RegisterBloc, RegisterState>(
        listener: (context, state) {
          if (state case RegisterSucceeded(:final user)) {
            Navigator.pushReplacementNamed(
              context,
              AppRouter.locationFor(user.role),
            );
          }
        },
        builder: (context, state) {
          return switch (state) {
            RegisterCheckingSession() || RegisterSucceeded() => const Center(
              child: CircularProgressIndicator(),
            ),
            RegisterReady(:final failure, :final isSubmitting) => SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  if (state.profileImage case final image?)
                    Center(
                      child: CircleAvatar(
                        radius: 44,
                        backgroundImage: MemoryImage(image.bytes),
                      ),
                    ),
                  TextButton.icon(
                    onPressed: isSubmitting
                        ? null
                        : () => context.read<RegisterBloc>().add(
                            const ProfileImageRequested(),
                          ),
                    icon: const Icon(Icons.add_photo_alternate_outlined),
                    label: Text(
                      state.profileImage == null
                          ? 'Choose profile image'
                          : 'Change profile image',
                    ),
                  ),
                  _UserRegisterFields(
                    emailController: _emailController,
                    passwordController: _passwordController,
                    nameController: _nameController,
                    positionController: _positionController,
                    department: _department,
                    isSubmitting: isSubmitting,
                    failure: failure,
                    onDepartmentChanged: (value) {
                      setState(() => _department = value);
                    },
                    onSubmit: _submit,
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: isSubmitting
                        ? null
                        : () {
                            Navigator.pushReplacementNamed(
                              context,
                              AppRouter.login,
                            );
                          },
                    child: const Text('Already have an account? Sign in'),
                  ),
                ],
              ),
            ),
          };
        },
      ),
    );
  }

  void _submit() {
    context.read<RegisterBloc>().add(
      RegisterSubmitted(
        email: _emailController.text,
        password: _passwordController.text,
        name: _nameController.text,
        position: _positionController.text,
        department: _department,
      ),
    );
  }
}

class _UserRegisterFields extends StatelessWidget {
  const _UserRegisterFields({
    required this.emailController,
    required this.passwordController,
    required this.nameController,
    required this.positionController,
    required this.department,
    required this.isSubmitting,
    required this.onDepartmentChanged,
    required this.onSubmit,
    this.failure,
  });

  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController nameController;
  final TextEditingController positionController;
  final String? department;
  final bool isSubmitting;
  final ValueChanged<String?> onDepartmentChanged;
  final VoidCallback onSubmit;
  final Failure? failure;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final message = failure?.message;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: nameController,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Name'),
          enabled: !isSubmitting,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          decoration: const InputDecoration(labelText: 'Email'),
          enabled: !isSubmitting,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: passwordController,
          obscureText: true,
          autofillHints: const [AutofillHints.password],
          decoration: const InputDecoration(labelText: 'Password'),
          enabled: !isSubmitting,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: positionController,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Position'),
          enabled: !isSubmitting,
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: department,
          decoration: const InputDecoration(labelText: 'Department'),
          items: [
            for (final value in Department.values)
              DropdownMenuItem(value: value, child: Text(value)),
          ],
          onChanged: isSubmitting ? null : onDepartmentChanged,
        ),
        if (message != null) ...[
          const SizedBox(height: 16),
          Text(
            message,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: colorScheme.error),
          ),
        ],
        const SizedBox(height: 24),
        FilledButton(
          onPressed: isSubmitting ? null : onSubmit,
          child: isSubmitting
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Register'),
        ),
      ],
    );
  }
}

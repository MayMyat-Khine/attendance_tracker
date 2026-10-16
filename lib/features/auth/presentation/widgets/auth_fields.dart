import 'package:flutter/material.dart';

import 'package:attendance_tracker/core/error/failure.dart';
import 'package:attendance_tracker/features/auth/presentation/widgets/password_field.dart';

class AuthFields extends StatelessWidget {
  const AuthFields({
    required this.emailController,
    required this.passwordController,
    required this.submitLabel,
    required this.onSubmit,
    required this.isSubmitting,
    this.failure,
    super.key,
  });

  final TextEditingController emailController;
  final TextEditingController passwordController;
  final String submitLabel;
  final VoidCallback onSubmit;
  final bool isSubmitting;
  final Failure? failure;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final message = failure?.message;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          decoration: const InputDecoration(labelText: 'Email'),
          enabled: !isSubmitting,
        ),
        const SizedBox(height: 16),
        PasswordField(controller: passwordController, enabled: !isSubmitting),
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
              : Text(submitLabel),
        ),
      ],
    );
  }
}

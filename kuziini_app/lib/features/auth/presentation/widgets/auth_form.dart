import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/widgets/kuziini_text_field.dart';

class AuthForm extends StatefulWidget {
  const AuthForm({
    super.key,
    required this.onSubmit,
    this.isSignUp = false,
    this.isLoading = false,
    this.initialEmail,
  });

  final void Function({
    required String email,
    required String password,
    String? fullName,
  }) onSubmit;
  final bool isSignUp;
  final bool isLoading;
  final String? initialEmail;

  @override
  State<AuthForm> createState() => _AuthFormState();
}

class _AuthFormState extends State<AuthForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController(text: widget.initialEmail ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    widget.onSubmit(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      fullName: widget.isSignUp ? _nameController.text.trim().nullIfEmpty : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.isSignUp) ...[
            KuziiniTextField(
              controller: _nameController,
              label: 'Full Name',
              hint: 'Enter your full name',
              prefixIcon: PhosphorIcons.user(PhosphorIconsStyle.regular),
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              enabled: !widget.isLoading,
              validator: (value) {
                if (widget.isSignUp && (value == null || value.trim().isEmpty)) {
                  return 'Please enter your name';
                }
                return null;
              },
            ),
            AppSpacing.vGapLg,
          ],
          KuziiniTextField(
            controller: _emailController,
            label: 'Email',
            hint: 'Enter your email',
            prefixIcon: PhosphorIcons.envelope(PhosphorIconsStyle.regular),
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            enabled: !widget.isLoading && widget.initialEmail == null,
            validator: (value) {
              if (value == null || !value.trim().isValidEmail) {
                return 'Please enter a valid email';
              }
              return null;
            },
          ),
          AppSpacing.vGapLg,
          KuziiniTextField(
            controller: _passwordController,
            label: 'Password',
            hint: widget.isSignUp ? 'Create a password' : 'Enter your password',
            prefixIcon: PhosphorIcons.lock(PhosphorIconsStyle.regular),
            obscureText: _obscurePassword,
            suffixIcon: _obscurePassword
                ? PhosphorIcons.eye(PhosphorIconsStyle.regular)
                : PhosphorIcons.eyeSlash(PhosphorIconsStyle.regular),
            onSuffixTap: () {
              setState(() => _obscurePassword = !_obscurePassword);
            },
            textInputAction: TextInputAction.done,
            enabled: !widget.isLoading,
            onSubmitted: (_) => _submit(),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a password';
              }
              if (widget.isSignUp && value.length < 8) {
                return 'Password must be at least 8 characters';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }
}

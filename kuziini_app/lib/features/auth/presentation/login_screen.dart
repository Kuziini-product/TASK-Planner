import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/extensions.dart';
import '../../../core/widgets/kuziini_button.dart';
import '../../../core/widgets/kuziini_text_field.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isSignUp = false;
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final notifier = ref.read(authStateProvider.notifier);

    try {
      if (_isSignUp) {
        await notifier.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          fullName: _nameController.text.trim().nullIfEmpty,
        );
      } else {
        await notifier.signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      }
    } catch (e) {
      if (mounted) {
        context.showSnackBar(
          e.toString().replaceAll('Exception: ', ''),
          isError: true,
        );
      }
    }
  }

  Future<void> _forgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.isValidEmail) {
      context.showSnackBar('Please enter a valid email address', isError: true);
      return;
    }

    try {
      await ref.read(authStateProvider.notifier).resetPassword(email);
      if (mounted) {
        context.showSnackBar('Password reset email sent. Check your inbox.');
      }
    } catch (e) {
      if (mounted) {
        context.showSnackBar('Failed to send reset email', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final isLoading = authState.isLoading;
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo and branding
                  Column(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: primaryColor,
                          borderRadius: AppSpacing.borderRadiusLg,
                        ),
                        child: const Center(
                          child: Text(
                            'K',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      )
                          .animate()
                          .fadeIn(duration: 600.ms)
                          .scale(
                            begin: const Offset(0.5, 0.5),
                            duration: 600.ms,
                            curve: Curves.elasticOut,
                          ),
                      AppSpacing.vGapLg,
                      Text(
                        'Kuziini',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: primaryColor,
                        ),
                      ).animate().fadeIn(duration: 500.ms, delay: 200.ms),
                      AppSpacing.vGapXs,
                      Text(
                        'Task Management, Simplified',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ).animate().fadeIn(duration: 500.ms, delay: 300.ms),
                    ],
                  ),

                  AppSpacing.vGapXxxl,

                  // Form fields
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_isSignUp) ...[
                        KuziiniTextField(
                          controller: _nameController,
                          label: 'Full Name',
                          hint: 'Enter your full name',
                          prefixIcon: PhosphorIcons.user(PhosphorIconsStyle.regular),
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.next,
                          validator: (value) {
                            if (_isSignUp && (value == null || value.trim().isEmpty)) {
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
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your email';
                          }
                          if (!value.trim().isValidEmail) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                      ),

                      AppSpacing.vGapLg,

                      KuziiniTextField(
                        controller: _passwordController,
                        label: 'Password',
                        hint: 'Enter your password',
                        prefixIcon: PhosphorIcons.lock(PhosphorIconsStyle.regular),
                        obscureText: _obscurePassword,
                        suffixIcon: _obscurePassword
                            ? PhosphorIcons.eye(PhosphorIconsStyle.regular)
                            : PhosphorIcons.eyeSlash(PhosphorIconsStyle.regular),
                        onSuffixTap: () {
                          setState(() => _obscurePassword = !_obscurePassword);
                        },
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _submit(),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }
                          if (_isSignUp && value.length < 8) {
                            return 'Password must be at least 8 characters';
                          }
                          return null;
                        },
                      ),

                      if (!_isSignUp) ...[
                        AppSpacing.vGapSm,
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: isLoading ? null : _forgotPassword,
                            child: const Text('Forgot password?'),
                          ),
                        ),
                      ],
                    ],
                  )
                      .animate()
                      .fadeIn(duration: 500.ms, delay: 400.ms)
                      .moveY(begin: 20, duration: 500.ms, delay: 400.ms),

                  AppSpacing.vGapXl,

                  // Submit button
                  KuziiniButton(
                    label: _isSignUp ? 'Create Account' : 'Sign In',
                    onPressed: _submit,
                    isLoading: isLoading,
                  ).animate().fadeIn(duration: 500.ms, delay: 500.ms),

                  AppSpacing.vGapLg,

                  // Toggle sign in/up
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _isSignUp
                            ? 'Already have an account?'
                            : 'Don\'t have an account?',
                        style: theme.textTheme.bodyMedium,
                      ),
                      TextButton(
                        onPressed: isLoading
                            ? null
                            : () => setState(() => _isSignUp = !_isSignUp),
                        child: Text(_isSignUp ? 'Sign In' : 'Sign Up'),
                      ),
                    ],
                  ).animate().fadeIn(duration: 500.ms, delay: 600.ms),

                  // Error display
                  if (authState.hasError) ...[
                    AppSpacing.vGapLg,
                    Container(
                      padding: AppSpacing.paddingMd,
                      decoration: BoxDecoration(
                        color: AppColors.errorLight,
                        borderRadius: AppSpacing.borderRadiusSm,
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline,
                              color: AppColors.error, size: 20),
                          AppSpacing.hGapSm,
                          Expanded(
                            child: Text(
                              authState.error.toString(),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.errorDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

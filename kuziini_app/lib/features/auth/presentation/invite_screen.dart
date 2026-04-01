import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/router/app_router.dart';
import '../../../core/utils/extensions.dart';
import '../../../core/widgets/kuziini_button.dart';
import '../../../core/widgets/kuziini_text_field.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../data/auth_repository.dart';
import '../providers/auth_provider.dart';

class InviteScreen extends ConsumerStatefulWidget {
  const InviteScreen({super.key, required this.token});

  final String token;

  @override
  ConsumerState<InviteScreen> createState() => _InviteScreenState();
}

class _InviteScreenState extends ConsumerState<InviteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _isValidating = true;
  bool _isValidToken = false;
  String? _invitedEmail;

  @override
  void initState() {
    super.initState();
    _validateToken();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _validateToken() async {
    final repo = ref.read(authRepositoryProvider);
    final invitation = await repo.getInvitationByToken(widget.token);

    if (mounted) {
      setState(() {
        _isValidating = false;
        _isValidToken = invitation != null && invitation['status'] == 'pending';
        _invitedEmail = invitation?['email'] as String?;
        if (_invitedEmail != null) {
          _emailController.text = _invitedEmail!;
        }
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(authRepositoryProvider);

      // Accept the invitation
      await repo.acceptInvitation(widget.token);

      // Create account
      await ref.read(authStateProvider.notifier).signUp(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            fullName: _nameController.text.trim(),
          );

      if (mounted) {
        context.go(AppRoutes.today);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        context.showSnackBar(
          'Failed to create account: ${e.toString()}',
          isError: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isValidating) {
      return const Scaffold(
        body: LoadingIndicator(
          message: 'Validating invitation...',
          fullScreen: false,
        ),
      );
    }

    if (!_isValidToken) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: AppSpacing.paddingXl,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  PhosphorIcons.linkBreak(PhosphorIconsStyle.light),
                  size: 64,
                  color: AppColors.error,
                ),
                AppSpacing.vGapXl,
                Text(
                  'Invalid Invitation',
                  style: theme.textTheme.titleLarge,
                ),
                AppSpacing.vGapSm,
                Text(
                  'This invitation link is invalid or has already been used.',
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                AppSpacing.vGapXl,
                KuziiniButton(
                  label: 'Go to Login',
                  onPressed: () => context.go(AppRoutes.login),
                  isFullWidth: false,
                  height: 44,
                ),
              ],
            ),
          ),
        ),
      );
    }

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
                  Icon(
                    PhosphorIcons.envelopeOpen(PhosphorIconsStyle.light),
                    size: 56,
                    color: AppColors.primary,
                  ).animate().fadeIn(duration: 500.ms).scale(
                        begin: const Offset(0.5, 0.5),
                        duration: 500.ms,
                        curve: Curves.elasticOut,
                      ),
                  AppSpacing.vGapLg,
                  Text(
                    'You\'re Invited!',
                    style: theme.textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ).animate().fadeIn(duration: 500.ms, delay: 100.ms),
                  AppSpacing.vGapSm,
                  Text(
                    'Create your account to join Kuziini',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ).animate().fadeIn(duration: 500.ms, delay: 200.ms),

                  AppSpacing.vGapXxl,

                  KuziiniTextField(
                    controller: _nameController,
                    label: 'Full Name',
                    hint: 'Enter your full name',
                    prefixIcon: PhosphorIcons.user(PhosphorIconsStyle.regular),
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your name';
                      }
                      return null;
                    },
                  ),

                  AppSpacing.vGapLg,

                  KuziiniTextField(
                    controller: _emailController,
                    label: 'Email',
                    hint: 'Your email',
                    prefixIcon: PhosphorIcons.envelope(PhosphorIconsStyle.regular),
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    readOnly: _invitedEmail != null,
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
                    hint: 'Create a password',
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
                      if (value == null || value.length < 8) {
                        return 'Password must be at least 8 characters';
                      }
                      return null;
                    },
                  ),

                  AppSpacing.vGapXl,

                  KuziiniButton(
                    label: 'Create Account',
                    onPressed: _submit,
                    isLoading: _isLoading,
                  ),

                  AppSpacing.vGapLg,

                  TextButton(
                    onPressed: () => context.go(AppRoutes.login),
                    child: const Text('Already have an account? Sign In'),
                  ),
                ].animate(interval: 50.ms).fadeIn(duration: 400.ms, delay: 300.ms),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

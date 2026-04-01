import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/extensions.dart';
import '../../../core/widgets/kuziini_button.dart';
import '../providers/auth_provider.dart';

class PendingApprovalScreen extends ConsumerStatefulWidget {
  const PendingApprovalScreen({super.key});

  @override
  ConsumerState<PendingApprovalScreen> createState() =>
      _PendingApprovalScreenState();
}

class _PendingApprovalScreenState extends ConsumerState<PendingApprovalScreen> {
  bool _isChecking = false;

  Future<void> _checkStatus() async {
    setState(() => _isChecking = true);
    try {
      await ref.read(authStateProvider.notifier).checkApprovalStatus();
    } catch (e) {
      if (mounted) {
        context.showSnackBar('Failed to check status', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isChecking = false);
      }
    }
  }

  Future<void> _signOut() async {
    await ref.read(authStateProvider.notifier).signOut();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profile = ref.watch(currentUserProfileProvider);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: AppSpacing.paddingXl,
                  decoration: BoxDecoration(
                    color: AppColors.warningLight.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    PhosphorIcons.hourglass(PhosphorIconsStyle.light),
                    size: 64,
                    color: AppColors.warning,
                  ),
                )
                    .animate(
                      onPlay: (controller) => controller.repeat(reverse: true),
                    )
                    .fadeIn(duration: 600.ms)
                    .scale(
                      begin: const Offset(0.9, 0.9),
                      end: const Offset(1.05, 1.05),
                      duration: 2000.ms,
                    ),

                AppSpacing.vGapXxl,

                Text(
                  'Account Pending Approval',
                  style: theme.textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ).animate().fadeIn(duration: 500.ms, delay: 200.ms),

                AppSpacing.vGapMd,

                Text(
                  'Your account has been created successfully. An administrator will review and approve your access shortly.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(duration: 500.ms, delay: 300.ms),

                if (profile.valueOrNull != null) ...[
                  AppSpacing.vGapLg,
                  Container(
                    padding: AppSpacing.paddingMd,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: AppSpacing.borderRadiusSm,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          PhosphorIcons.envelope(PhosphorIconsStyle.regular),
                          size: 16,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        AppSpacing.hGapSm,
                        Text(
                          profile.valueOrNull!.email,
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],

                AppSpacing.vGapXxl,

                KuziiniButton(
                  label: 'Check Status',
                  onPressed: _checkStatus,
                  isLoading: _isChecking,
                  icon: PhosphorIcons.arrowClockwise(PhosphorIconsStyle.bold),
                ).animate().fadeIn(duration: 500.ms, delay: 400.ms),

                AppSpacing.vGapLg,

                KuziiniButton(
                  label: 'Sign Out',
                  onPressed: _signOut,
                  variant: KuziiniButtonVariant.text,
                ).animate().fadeIn(duration: 500.ms, delay: 500.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

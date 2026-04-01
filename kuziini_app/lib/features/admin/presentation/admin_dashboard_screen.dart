import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/router/app_router.dart';
import '../../../core/widgets/kuziini_app_bar.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../providers/admin_provider.dart';
import 'widgets/admin_stat_card.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final statsAsync = ref.watch(adminStatsProvider);

    return Scaffold(
      appBar: const KuziiniAppBar(
        showBackButton: true,
        title: 'Admin Dashboard',
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(adminStatsProvider);
          ref.invalidate(pendingUsersProvider);
        },
        child: ListView(
          padding: AppSpacing.paddingLg,
          children: [
            // Stats
            statsAsync.when(
              data: (stats) => Column(
                children: [
                  Row(
                    children: [
                      AdminStatCard(
                        label: 'Total Users',
                        value: '${stats['totalUsers'] ?? 0}',
                        icon: PhosphorIcons.users(PhosphorIconsStyle.fill),
                        color: AppColors.info,
                        animationDelay: Duration.zero,
                      ),
                      AppSpacing.hGapMd,
                      AdminStatCard(
                        label: 'Pending',
                        value: '${stats['pendingUsers'] ?? 0}',
                        icon: PhosphorIcons.hourglass(PhosphorIconsStyle.fill),
                        color: AppColors.warning,
                        onTap: () => context.push(AppRoutes.userApproval),
                        animationDelay: 100.ms,
                      ),
                    ],
                  ),
                  AppSpacing.vGapMd,
                  Row(
                    children: [
                      AdminStatCard(
                        label: 'Total Tasks',
                        value: '${stats['totalTasks'] ?? 0}',
                        icon:
                            PhosphorIcons.listChecks(PhosphorIconsStyle.fill),
                        color: AppColors.primary,
                        animationDelay: 200.ms,
                      ),
                      AppSpacing.hGapMd,
                      AdminStatCard(
                        label: 'Completed',
                        value: '${stats['completedTasks'] ?? 0}',
                        icon: PhosphorIcons.checkCircle(
                            PhosphorIconsStyle.fill),
                        color: AppColors.success,
                        animationDelay: 300.ms,
                      ),
                    ],
                  ),
                ],
              ),
              loading: () => const SizedBox(
                height: 200,
                child: LoadingIndicator(size: 24),
              ),
              error: (_, __) =>
                  const Center(child: Text('Failed to load stats')),
            ),

            AppSpacing.vGapXxl,

            // Quick actions
            Text(
              'QUICK ACTIONS',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ).animate().fadeIn(duration: 300.ms, delay: 400.ms),

            AppSpacing.vGapMd,

            _QuickActionTile(
              icon: PhosphorIcons.userCheck(PhosphorIconsStyle.regular),
              label: 'User Approvals',
              subtitle: 'Review pending user registrations',
              color: AppColors.warning,
              onTap: () => context.push(AppRoutes.userApproval),
            ).animate().fadeIn(duration: 300.ms, delay: 450.ms),

            _QuickActionTile(
              icon:
                  PhosphorIcons.envelopeSimple(PhosphorIconsStyle.regular),
              label: 'Send Invitations',
              subtitle: 'Invite new team members',
              color: AppColors.info,
              onTap: () => context.push(AppRoutes.invitations),
            ).animate().fadeIn(duration: 300.ms, delay: 500.ms),

            _QuickActionTile(
              icon: PhosphorIcons.usersThree(PhosphorIconsStyle.regular),
              label: 'Manage Users',
              subtitle: 'View and manage team members',
              color: AppColors.primary,
              onTap: () => context.push(AppRoutes.userApproval),
            ).animate().fadeIn(duration: 300.ms, delay: 550.ms),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: AppSpacing.borderRadiusMd,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        margin: const EdgeInsets.symmetric(vertical: 3),
        decoration: BoxDecoration(
          borderRadius: AppSpacing.borderRadiusMd,
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.15),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: AppSpacing.borderRadiusSm,
              ),
              child: Icon(icon, size: 22, color: color),
            ),
            AppSpacing.hGapLg,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: theme.textTheme.titleSmall),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              PhosphorIcons.caretRight(PhosphorIconsStyle.regular),
              size: 18,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

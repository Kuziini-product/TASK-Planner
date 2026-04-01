import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../auth/domain/auth_state.dart';

class UserListTile extends StatelessWidget {
  const UserListTile({
    super.key,
    required this.user,
    this.onApprove,
    this.onReject,
    this.onRoleChange,
    this.showActions = true,
    this.isPending = false,
  });

  final UserProfile user;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  final ValueChanged<String>? onRoleChange;
  final bool showActions;
  final bool isPending;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      margin: const EdgeInsets.symmetric(vertical: 3),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: AppSpacing.borderRadiusMd,
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                backgroundImage: user.avatarUrl != null
                    ? NetworkImage(user.avatarUrl!)
                    : null,
                child: user.avatarUrl == null
                    ? Text(
                        user.initials,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      )
                    : null,
              ),

              AppSpacing.hGapMd,

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            user.displayName,
                            style: theme.textTheme.titleSmall,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        AppSpacing.hGapSm,
                        _RoleBadge(role: user.role),
                      ],
                    ),
                    AppSpacing.vGapXs,
                    Text(
                      user.email,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (user.createdAt != null)
                      Text(
                        'Joined ${AppDateUtils.formatTimeAgo(user.createdAt!)}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),

              // Status indicator
              if (!isPending)
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color:
                        user.isApproved ? AppColors.success : AppColors.warning,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),

          // Action buttons for pending users
          if (isPending && showActions) ...[
            AppSpacing.vGapMd,
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onReject,
                    icon: Icon(
                      PhosphorIcons.x(PhosphorIconsStyle.bold),
                      size: 16,
                    ),
                    label: const Text('Reject'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                      minimumSize: const Size(0, 36),
                    ),
                  ),
                ),
                AppSpacing.hGapMd,
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onApprove,
                    icon: Icon(
                      PhosphorIcons.check(PhosphorIconsStyle.bold),
                      size: 16,
                    ),
                    label: const Text('Approve'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 36),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.role});

  final String role;

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (role) {
      case 'admin':
        color = AppColors.priorityUrgent;
      case 'member':
        color = AppColors.primary;
      case 'viewer':
        color = AppColors.secondary;
      default:
        color = AppColors.priorityNone;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: AppSpacing.borderRadiusFull,
      ),
      child: Text(
        role.toUpperCase(),
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

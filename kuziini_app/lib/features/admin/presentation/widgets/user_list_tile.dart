import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/widgets/birthday_banner.dart';
import '../../../auth/domain/auth_state.dart';

class UserListTile extends StatelessWidget {
  const UserListTile({
    super.key,
    required this.user,
    this.onApprove,
    this.onReject,
    this.onDelete,
    this.onBirthDateChanged,
    this.onRoleChange,
    this.onManageAccess,
    this.onTap,
    this.showActions = true,
    this.isPending = false,
  });

  final UserProfile user;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  final VoidCallback? onDelete;
  final ValueChanged<DateTime>? onBirthDateChanged;
  final ValueChanged<String>? onRoleChange;
  final VoidCallback? onManageAccess;
  final VoidCallback? onTap;
  final bool showActions;
  final bool isPending;

  void _showRolePicker(BuildContext context) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4,
                decoration: BoxDecoration(color: theme.dividerColor, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),
              Text('Schimbă rolul', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              Text(user.displayName, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
              const SizedBox(height: 16),
              ...['user', 'manager', 'admin'].map((role) {
                final isSelected = user.role == role;
                final color = role == 'admin' ? AppColors.priorityUrgent
                    : role == 'manager' ? theme.colorScheme.primary
                    : AppColors.secondary;
                return ListTile(
                  leading: Icon(
                    isSelected ? PhosphorIcons.checkCircle(PhosphorIconsStyle.fill) : PhosphorIcons.circle(PhosphorIconsStyle.regular),
                    color: isSelected ? color : theme.colorScheme.onSurfaceVariant,
                  ),
                  title: Text(role.toUpperCase(), style: TextStyle(
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? color : null,
                  )),
                  onTap: () {
                    Navigator.pop(ctx);
                    if (!isSelected) onRoleChange?.call(role);
                  },
                );
              }),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
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
              // Avatar — rainbow border for birthday week
              _BirthdayAvatar(user: user, primaryColor: primaryColor),

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
                        GestureDetector(
                          onTap: onRoleChange != null ? () => _showRolePicker(context) : null,
                          child: _RoleBadge(role: user.role),
                        ),
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
                    Row(
                      children: [
                        if (user.birthDate != null)
                          GestureDetector(
                            onTap: onBirthDateChanged != null ? () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: user.birthDate!,
                                firstDate: DateTime(1940),
                                lastDate: DateTime.now(),
                              );
                              if (date != null) onBirthDateChanged!(date);
                            } : null,
                            child: Row(
                              children: [
                                Icon(PhosphorIcons.cake(PhosphorIconsStyle.regular), size: 11, color: user.isBirthdayToday ? AppColors.error : theme.colorScheme.onSurfaceVariant),
                                const SizedBox(width: 3),
                                Text(
                                  '${user.birthDate!.day}/${user.birthDate!.month}',
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: user.isBirthdayToday ? AppColors.error : theme.colorScheme.onSurfaceVariant),
                                ),
                                const SizedBox(width: 8),
                              ],
                            ),
                          )
                        else if (onBirthDateChanged != null)
                          GestureDetector(
                            onTap: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: DateTime(1990, 1, 1),
                                firstDate: DateTime(1940),
                                lastDate: DateTime.now(),
                              );
                              if (date != null) onBirthDateChanged!(date);
                            },
                            child: Row(
                              children: [
                                Icon(PhosphorIcons.cake(PhosphorIconsStyle.regular), size: 11, color: primaryColor),
                                const SizedBox(width: 3),
                                Text('Set birthday', style: TextStyle(fontSize: 10, color: primaryColor, fontWeight: FontWeight.w500)),
                                const SizedBox(width: 8),
                              ],
                            ),
                          ),
                        if (user.createdAt != null)
                          Text(
                            'Joined ${AppDateUtils.formatTimeAgo(user.createdAt!)}',
                            style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // Status indicator
              if (!isPending)
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: user.isApproved ? AppColors.success : AppColors.warning,
                    shape: BoxShape.circle,
                  ),
                ),
              // Manage access button (managers only)
              if (onManageAccess != null)
                IconButton(
                  onPressed: onManageAccess,
                  icon: Icon(PhosphorIcons.usersThree(PhosphorIconsStyle.regular), size: 18, color: Theme.of(context).colorScheme.primary),
                  tooltip: 'Manage access',
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  padding: EdgeInsets.zero,
                ),
              // Report button
              if (onTap != null)
                IconButton(
                  onPressed: onTap,
                  icon: Icon(PhosphorIcons.chartBar(PhosphorIconsStyle.regular), size: 18, color: primaryColor),
                  tooltip: 'Raport',
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  padding: EdgeInsets.zero,
                ),
              // Delete button
              if (onDelete != null)
                IconButton(
                  onPressed: onDelete,
                  icon: Icon(PhosphorIcons.trash(PhosphorIconsStyle.regular), size: 18, color: AppColors.error),
                  tooltip: 'Delete user',
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  padding: EdgeInsets.zero,
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
      case 'manager':
        color = Theme.of(context).colorScheme.primary;
      case 'user':
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

/// Avatar with animated rainbow border during the user's birthday week
class _BirthdayAvatar extends StatelessWidget {
  const _BirthdayAvatar({required this.user, required this.primaryColor});
  final UserProfile user;
  final Color primaryColor;

  @override
  Widget build(BuildContext context) {
    final avatar = CircleAvatar(
      radius: 20,
      backgroundColor: primaryColor.withValues(alpha: 0.1),
      backgroundImage:
          user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
      child: user.avatarUrl == null
          ? Text(
              user.initials,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: primaryColor,
              ),
            )
          : null,
    );

    if (user.isBirthdayThisWeek) {
      return SizedBox(
        width: 46,
        height: 46,
        child: BirthdayBorderWrapper(
          borderRadius: 23,
          strokeWidth: 2.5,
          child: Padding(
            padding: const EdgeInsets.all(2),
            child: avatar,
          ),
        ),
      );
    }

    return avatar;
  }
}

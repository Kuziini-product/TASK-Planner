import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/kuziini_card.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../tasks/providers/tasks_provider.dart';
import '../data/notification_repository.dart';
import '../providers/notifications_provider.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final notificationsAsync = ref.watch(notificationsProvider);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Image.asset('assets/images/kuziini_logo.png', height: 32, color: theme.colorScheme.onSurface),
        actions: [
          TextButton(
            onPressed: () {
              ref.read(notificationsProvider.notifier).markAllAsRead();
            },
            child: const Text('Mark all read'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(notificationsProvider.notifier).refresh(),
        color: primaryColor,
        child: notificationsAsync.when(
          data: (notifications) {
            if (notifications.isEmpty) {
              return EmptyState.notifications();
            }

            // Group by date
            final grouped = <String, List<NotificationModel>>{};
            for (final n in notifications) {
              final key = n.createdAt != null
                  ? AppDateUtils.getRelativeDateLabel(n.createdAt!)
                  : 'Unknown';
              grouped.putIfAbsent(key, () => []).add(n);
            }

            return ListView.builder(
              padding: AppSpacing.paddingLg,
              itemCount: grouped.length,
              itemBuilder: (context, groupIndex) {
                final entry = grouped.entries.elementAt(groupIndex);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (groupIndex > 0) AppSpacing.vGapLg,
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        entry.key,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    ...entry.value.asMap().entries.map((e) {
                      final notification = e.value;
                      return _NotificationTile(
                        notification: notification,
                        onTap: () {
                          ref
                              .read(notificationsProvider.notifier)
                              .markAsRead(notification.id);

                          final taskId =
                              notification.data?['task_id'] as String?;
                          if (taskId != null) {
                            context.push('/task/$taskId');
                          }
                        },
                        onDismiss: () {
                          ref
                              .read(notificationsProvider.notifier)
                              .deleteNotification(notification.id);
                        },
                        animationIndex: e.key,
                      );
                    }),
                  ],
                );
              },
            );
          },
          loading: () =>
              const LoadingIndicator(message: 'Loading notifications...'),
          error: (error, _) => ErrorView(
            message: error.toString(),
            onRetry: () =>
                ref.read(notificationsProvider.notifier).refresh(),
          ),
        ),
      ),
    );
  }
}

class _NotificationTile extends ConsumerWidget {
  const _NotificationTile({
    required this.notification,
    required this.onTap,
    required this.onDismiss,
    this.animationIndex = 0,
  });

  final NotificationModel notification;
  final VoidCallback onTap;
  final VoidCallback onDismiss;
  final int animationIndex;

  IconData get _icon {
    switch (notification.type) {
      case 'task_assigned':
        return PhosphorIcons.userPlus(PhosphorIconsStyle.fill);
      case 'task_completed':
        return PhosphorIcons.checkCircle(PhosphorIconsStyle.fill);
      case 'task_comment':
        return PhosphorIcons.chatCircle(PhosphorIconsStyle.fill);
      case 'task_due':
        return PhosphorIcons.clock(PhosphorIconsStyle.fill);
      case 'approval':
        return PhosphorIcons.shieldCheck(PhosphorIconsStyle.fill);
      case 'edit_request':
        return PhosphorIcons.pencilSimple(PhosphorIconsStyle.fill);
      case 'edit_approved':
        return PhosphorIcons.checkCircle(PhosphorIconsStyle.fill);
      default:
        return PhosphorIcons.bell(PhosphorIconsStyle.fill);
    }
  }

  Color _iconColor(BuildContext context) {
    switch (notification.type) {
      case 'task_assigned':
        return AppColors.info;
      case 'task_completed':
        return AppColors.success;
      case 'task_comment':
        return AppColors.secondary;
      case 'task_due':
        return AppColors.warning;
      case 'edit_request':
        return AppColors.warning;
      case 'edit_approved':
        return AppColors.success;
      case 'approval':
        return Theme.of(context).colorScheme.primary;
      default:
        return Theme.of(context).colorScheme.primaryContainer;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    final iconColor = _iconColor(context);

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismiss(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.1),
          borderRadius: AppSpacing.borderRadiusMd,
        ),
        child: Icon(
          PhosphorIcons.trash(PhosphorIconsStyle.bold),
          color: AppColors.error,
        ),
      ),
      child: KuziiniCard(
        onTap: onTap,
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.symmetric(vertical: 3),
        color: notification.isRead
            ? null
            : theme.colorScheme.primary.withValues(alpha: 0.04),
        borderColor: notification.isRead
            ? null
            : theme.colorScheme.primary.withValues(alpha: 0.15),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(_icon, size: 18, color: iconColor),
            ),
            AppSpacing.hGapMd,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight:
                          notification.isRead ? FontWeight.w500 : FontWeight.w600,
                    ),
                  ),
                  AppSpacing.vGapXs,
                  Text(
                    notification.body,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  AppSpacing.vGapXs,
                  if (notification.createdAt != null)
                    Text(
                      AppDateUtils.formatTimeAgo(notification.createdAt!),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  // Approve button for edit requests
                  if (notification.type == 'edit_request' && !notification.isRead)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: SizedBox(
                        height: 32,
                        child: FilledButton.icon(
                          onPressed: () async {
                            final taskId = notification.data?['task_id'] as String?;
                            final requesterId = notification.data?['requester_id'] as String?;
                            final requesterName = notification.data?['requester_name'] as String?;
                            if (taskId == null || requesterId == null) return;

                            try {
                              final taskRepo = ref.read(taskRepositoryProvider);
                              await taskRepo.grantEditPermission(taskId, requesterId);

                              final notifRepo = NotificationRepository();
                              await notifRepo.createNotification(
                                userId: requesterId,
                                title: 'Edit Approved',
                                body: 'Your request to edit the task has been approved. You can now edit it once.',
                                type: 'edit_approved',
                                data: {'task_id': taskId},
                              );

                              ref.read(notificationsProvider.notifier).markAsRead(notification.id);
                            } catch (_) {}
                          },
                          icon: Icon(PhosphorIcons.check(PhosphorIconsStyle.bold), size: 14),
                          label: const Text('Approve Edit', style: TextStyle(fontSize: 12)),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            backgroundColor: AppColors.success,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (!notification.isRead)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(
          duration: 300.ms,
          delay: Duration(milliseconds: 30 * animationIndex),
        )
        .moveY(
          begin: 10,
          duration: 300.ms,
          delay: Duration(milliseconds: 30 * animationIndex),
        );
  }
}

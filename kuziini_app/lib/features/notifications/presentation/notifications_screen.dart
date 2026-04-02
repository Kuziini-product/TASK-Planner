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

    // Daily stats
    final statsAsync = ref.watch(taskStatsProvider);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Image.asset('assets/images/kuziini_logo.png', height: 32, color: theme.colorScheme.onSurface),
        actions: [
          TextButton(
            onPressed: () => ref.read(notificationsProvider.notifier).markAllAsRead(),
            child: const Text('Mark all read'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(notificationsProvider.notifier).refresh(),
        color: primaryColor,
        child: notificationsAsync.when(
          data: (notifications) {
            // Group notifications by category
            final newTasks = notifications.where((n) => n.type == 'task_assigned' || n.type == 'task_created').toList();
            final overdue = notifications.where((n) => n.type == 'task_due' || n.type == 'task_overdue').toList();
            final comments = notifications.where((n) => n.type == 'task_comment').toList();
            final attachments = notifications.where((n) => n.type == 'task_attachment').toList();
            final editRequests = notifications.where((n) => n.type == 'edit_request' || n.type == 'edit_approved').toList();
            final other = notifications.where((n) =>
              n.type != 'task_assigned' && n.type != 'task_created' &&
              n.type != 'task_due' && n.type != 'task_overdue' &&
              n.type != 'task_comment' && n.type != 'task_attachment' &&
              n.type != 'edit_request' && n.type != 'edit_approved'
            ).toList();

            // Resolved today count
            final resolvedToday = statsAsync.valueOrNull?['done'] ?? 0;

            return ListView(
              padding: AppSpacing.paddingLg,
              children: [
                // Resolved today card
                Container(
                  padding: const EdgeInsets.all(14),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.success.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(PhosphorIcons.checkCircle(PhosphorIconsStyle.fill), color: AppColors.success, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Tasks Resolved', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.success)),
                            Text('$resolvedToday completed', style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: AppColors.success, borderRadius: BorderRadius.circular(12)),
                        child: Text('$resolvedToday', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                ),

                // Category cards
                if (newTasks.isNotEmpty)
                  _NotificationCategory(
                    icon: PhosphorIcons.plusCircle(PhosphorIconsStyle.fill),
                    title: 'New Tasks',
                    color: AppColors.info,
                    notifications: newTasks,
                    onTapNotification: (n) => _handleTap(context, ref, n),
                    onDismiss: (n) => ref.read(notificationsProvider.notifier).deleteNotification(n.id),
                  ),

                if (overdue.isNotEmpty)
                  _NotificationCategory(
                    icon: PhosphorIcons.warning(PhosphorIconsStyle.fill),
                    title: 'Overdue Alerts',
                    color: AppColors.error,
                    notifications: overdue,
                    onTapNotification: (n) => _handleTap(context, ref, n),
                    onDismiss: (n) => ref.read(notificationsProvider.notifier).deleteNotification(n.id),
                  ),

                if (comments.isNotEmpty)
                  _NotificationCategory(
                    icon: PhosphorIcons.chatCircle(PhosphorIconsStyle.fill),
                    title: 'Comments',
                    color: AppColors.secondary,
                    notifications: comments,
                    onTapNotification: (n) => _handleTap(context, ref, n),
                    onDismiss: (n) => ref.read(notificationsProvider.notifier).deleteNotification(n.id),
                  ),

                if (attachments.isNotEmpty)
                  _NotificationCategory(
                    icon: PhosphorIcons.paperclip(PhosphorIconsStyle.fill),
                    title: 'Attachments',
                    color: AppColors.warning,
                    notifications: attachments,
                    onTapNotification: (n) => _handleTap(context, ref, n),
                    onDismiss: (n) => ref.read(notificationsProvider.notifier).deleteNotification(n.id),
                  ),

                if (editRequests.isNotEmpty)
                  _NotificationCategory(
                    icon: PhosphorIcons.pencilSimple(PhosphorIconsStyle.fill),
                    title: 'Edit Requests',
                    color: Colors.orange,
                    notifications: editRequests,
                    onTapNotification: (n) => _handleTap(context, ref, n),
                    onDismiss: (n) => ref.read(notificationsProvider.notifier).deleteNotification(n.id),
                  ),

                if (other.isNotEmpty)
                  _NotificationCategory(
                    icon: PhosphorIcons.bell(PhosphorIconsStyle.fill),
                    title: 'Other',
                    color: theme.colorScheme.primary,
                    notifications: other,
                    onTapNotification: (n) => _handleTap(context, ref, n),
                    onDismiss: (n) => ref.read(notificationsProvider.notifier).deleteNotification(n.id),
                  ),

                if (notifications.isEmpty)
                  EmptyState.notifications(),
              ],
            );
          },
          loading: () => const LoadingIndicator(message: 'Loading notifications...'),
          error: (error, _) => ErrorView(
            message: error.toString(),
            onRetry: () => ref.read(notificationsProvider.notifier).refresh(),
          ),
        ),
      ),
    );
  }

  void _handleTap(BuildContext context, WidgetRef ref, NotificationModel notification) {
    ref.read(notificationsProvider.notifier).markAsRead(notification.id);
    final taskId = notification.data?['task_id'] as String?;
    if (taskId != null) context.push('/task/$taskId');
  }
}

// ── Notification Category Card (expandable) ──

class _NotificationCategory extends StatefulWidget {
  const _NotificationCategory({
    required this.icon,
    required this.title,
    required this.color,
    required this.notifications,
    required this.onTapNotification,
    required this.onDismiss,
  });

  final IconData icon;
  final String title;
  final Color color;
  final List<NotificationModel> notifications;
  final ValueChanged<NotificationModel> onTapNotification;
  final ValueChanged<NotificationModel> onDismiss;

  @override
  State<_NotificationCategory> createState() => _NotificationCategoryState();
}

class _NotificationCategoryState extends State<_NotificationCategory> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unread = widget.notifications.where((n) => !n.isRead).length;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: widget.color.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: widget.color.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          // Header - clickable to expand
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Icon(widget.icon, size: 20, color: widget.color),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(widget.title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  ),
                  if (unread > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: widget.color, borderRadius: BorderRadius.circular(10)),
                      child: Text('$unread', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                    ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('${widget.notifications.length}', style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant)),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    _expanded ? PhosphorIcons.caretUp(PhosphorIconsStyle.bold) : PhosphorIcons.caretDown(PhosphorIconsStyle.bold),
                    size: 14, color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
          // Expanded content
          if (_expanded)
            ...widget.notifications.asMap().entries.map((e) {
              final n = e.value;
              return InkWell(
                onTap: () => widget.onTapNotification(n),
                child: Dismissible(
                  key: Key(n.id),
                  direction: DismissDirection.endToStart,
                  onDismissed: (_) => widget.onDismiss(n),
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 16),
                    color: AppColors.error.withValues(alpha: 0.1),
                    child: Icon(PhosphorIcons.trash(PhosphorIconsStyle.bold), color: AppColors.error),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border(top: BorderSide(color: widget.color.withValues(alpha: 0.08))),
                      color: n.isRead ? null : widget.color.withValues(alpha: 0.03),
                    ),
                    child: Row(
                      children: [
                        if (!n.isRead)
                          Container(width: 6, height: 6, margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(shape: BoxShape.circle, color: widget.color)),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(n.title, style: TextStyle(fontSize: 13, fontWeight: n.isRead ? FontWeight.w400 : FontWeight.w600)),
                              Text(n.body, style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant), maxLines: 2, overflow: TextOverflow.ellipsis),
                              if (n.createdAt != null)
                                Text(AppDateUtils.formatTimeAgo(n.createdAt!), style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurfaceVariant)),
                            ],
                          ),
                        ),
                        Icon(PhosphorIcons.caretRight(PhosphorIconsStyle.regular), size: 14, color: theme.colorScheme.onSurfaceVariant),
                      ],
                    ),
                  ),
                ),
              );
            }),
        ],
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

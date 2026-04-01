import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/widgets/kuziini_card.dart';
import '../../data/models/task_model.dart';
import 'priority_badge.dart';
import 'status_chip.dart';

class TaskCard extends StatelessWidget {
  const TaskCard({
    super.key,
    required this.task,
    this.onStatusChanged,
    this.onTap,
    this.showDate = false,
    this.animationIndex = 0,
  });

  final TaskModel task;
  final ValueChanged<TaskStatus>? onStatusChanged;
  final VoidCallback? onTap;
  final bool showDate;
  final int animationIndex;

  Color get _accentColor {
    switch (task.priority) {
      case TaskPriority.urgent:
        return AppColors.priorityUrgent;
      case TaskPriority.high:
        return AppColors.priorityHigh;
      case TaskPriority.medium:
        return AppColors.priorityMedium;
      case TaskPriority.low:
        return AppColors.priorityLow;
      case TaskPriority.none:
        return Colors.transparent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return KuziiniCard(
      onTap: onTap ?? () => context.push('/task/${task.id}'),
      leftAccentColor: task.priority != TaskPriority.none ? _accentColor : null,
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: status icon, title, priority
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () {
                  if (onStatusChanged != null) {
                    onStatusChanged!(
                      task.isCompleted ? TaskStatus.todo : TaskStatus.done,
                    );
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.only(top: 2, right: 10),
                  child: StatusChip(status: task.status, compact: true),
                ),
              ),
              Expanded(
                child: Text(
                  task.title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    decoration:
                        task.isCompleted ? TextDecoration.lineThrough : null,
                    color: task.isCompleted
                        ? theme.colorScheme.onSurfaceVariant
                        : null,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (task.priority != TaskPriority.none)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: PriorityBadge(priority: task.priority),
                ),
            ],
          ),

          // Description preview
          if (task.description != null && task.description!.isNotEmpty) ...[
            AppSpacing.vGapXs,
            Padding(
              padding: const EdgeInsets.only(left: 30),
              child: Text(
                task.description!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],

          // Bottom row: metadata
          AppSpacing.vGapSm,
          Padding(
            padding: const EdgeInsets.only(left: 30),
            child: Row(
              children: [
                // Time
                if (task.startTime != null) ...[
                  Icon(
                    PhosphorIcons.clock(PhosphorIconsStyle.regular),
                    size: 13,
                    color: task.isOverdue
                        ? AppColors.error
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    task.endTime != null
                        ? '${AppDateUtils.formatTime(task.startTime!)} - ${AppDateUtils.formatTime(task.endTime!)}'
                        : AppDateUtils.formatTime(task.startTime!),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: task.isOverdue
                          ? AppColors.error
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  AppSpacing.hGapMd,
                ],

                // Due date
                if (showDate && task.dueDate != null) ...[
                  Icon(
                    PhosphorIcons.calendar(PhosphorIconsStyle.regular),
                    size: 13,
                    color: task.isOverdue
                        ? AppColors.error
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    AppDateUtils.getRelativeDateLabel(task.dueDate!),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: task.isOverdue
                          ? AppColors.error
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  AppSpacing.hGapMd,
                ],

                // Checklist
                if (task.hasChecklist) ...[
                  Icon(
                    PhosphorIcons.checkSquare(PhosphorIconsStyle.regular),
                    size: 13,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    '${task.checklistCompleted}/${task.checklistTotal}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  AppSpacing.hGapMd,
                ],

                // Comments
                if (task.hasComments) ...[
                  Icon(
                    PhosphorIcons.chatCircle(PhosphorIconsStyle.regular),
                    size: 13,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    '${task.commentCount}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  AppSpacing.hGapMd,
                ],

                // Attachments
                if (task.hasAttachments) ...[
                  Icon(
                    PhosphorIcons.paperclip(PhosphorIconsStyle.regular),
                    size: 13,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    '${task.attachmentCount}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],

                const Spacer(),

                // Assignee avatar
                if (task.isAssigned)
                  CircleAvatar(
                    radius: 10,
                    backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                    child: Text(
                      (task.assigneeName ?? 'U')[0].toUpperCase(),
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),

                // Overdue indicator
                if (task.isOverdue)
                  Container(
                    margin: const EdgeInsets.only(left: 6),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.errorLight,
                      borderRadius: AppSpacing.borderRadiusFull,
                    ),
                    child: Text(
                      'OVERDUE',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: AppColors.error,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(
          duration: 300.ms,
          delay: Duration(milliseconds: 50 * animationIndex),
        )
        .moveX(
          begin: 20,
          duration: 300.ms,
          delay: Duration(milliseconds: 50 * animationIndex),
        );
  }
}

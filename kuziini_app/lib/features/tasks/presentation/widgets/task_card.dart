import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/widgets/kuziini_card.dart';
import '../../data/models/task_model.dart';
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
          // Top row: status icon, title, time/date on right
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
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
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
              // Time and date on the right
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (task.startTime != null)
                    Text(
                      task.endTime != null
                          ? '${AppDateUtils.formatTime(task.startTime!)} - ${AppDateUtils.formatTime(task.endTime!)}'
                          : AppDateUtils.formatTime(task.startTime!),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: task.isOverdue
                            ? AppColors.error
                            : theme.colorScheme.primary,
                      ),
                    ),
                  if (task.dueDate != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        AppDateUtils.getRelativeDateLabel(task.dueDate!),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: task.isOverdue
                              ? AppColors.error
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                ],
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

          // Location preview
          if (task.hasLocation) ...[
            AppSpacing.vGapXs,
            Padding(
              padding: const EdgeInsets.only(left: 30),
              child: Row(
                children: [
                  Icon(
                    PhosphorIcons.mapPin(PhosphorIconsStyle.regular),
                    size: 12,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      task.locationDisplay,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Bottom row: metadata (checklist, comments, attachments, assignee)
          if (task.hasChecklist || task.hasComments || task.hasAttachments || task.isAssigned) ...[
            AppSpacing.vGapSm,
            Padding(
              padding: const EdgeInsets.only(left: 30),
              child: Row(
                children: [
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
                ],
              ),
            ),
          ],
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

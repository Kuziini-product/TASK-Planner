import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/widgets/kuziini_card.dart';
import '../../data/models/task_model.dart';
import '../../providers/tasks_provider.dart';
import 'status_chip.dart';

class TaskCard extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
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
              // Time/date on the right
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (task.isMultiDay) ...[
                    // Multi-day: show date range
                    Text(
                      '${task.dueDate!.day}/${task.dueDate!.month} → ${task.endDate!.day}/${task.endDate!.month}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    Text(
                      '${task.endDate!.difference(task.dueDate!).inDays + 1} days',
                      style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ] else ...[
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

          // Bottom row: metadata
          AppSpacing.vGapSm,
          Padding(
            padding: const EdgeInsets.only(left: 30),
            child: Row(
              children: [
                // Relocate button
                GestureDetector(
                  onTap: () => _showRelocate(context, ref),
                  child: Icon(PhosphorIcons.calendarPlus(PhosphorIconsStyle.regular), size: 14, color: theme.colorScheme.onSurfaceVariant),
                ),
                AppSpacing.hGapMd,
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

  void _showRelocate(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    DateTime? newDate = task.dueDate;
    DateTime? newEndDate = task.endDate;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 40, height: 4, decoration: BoxDecoration(color: theme.dividerColor, borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 12),
                Text('Relocate Task', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                ListTile(
                  leading: Icon(PhosphorIcons.calendar(PhosphorIconsStyle.regular)),
                  title: Text(newDate != null ? '${newDate!.day}/${newDate!.month}/${newDate!.year}' : 'Select date'),
                  onTap: () async {
                    final d = await showDatePicker(context: ctx, initialDate: newDate ?? DateTime.now(), firstDate: DateTime.now().subtract(const Duration(days: 365)), lastDate: DateTime.now().add(const Duration(days: 365 * 2)));
                    if (d != null) setSheetState(() => newDate = d);
                  },
                  dense: true,
                ),
                ListTile(
                  leading: Icon(PhosphorIcons.calendarDots(PhosphorIconsStyle.regular)),
                  title: Text(newEndDate != null ? 'End: ${newEndDate!.day}/${newEndDate!.month}/${newEndDate!.year}' : 'Add end date'),
                  trailing: newEndDate != null ? IconButton(icon: const Icon(Icons.close, size: 16), onPressed: () => setSheetState(() => newEndDate = null)) : null,
                  onTap: () async {
                    final d = await showDatePicker(context: ctx, initialDate: newEndDate ?? newDate ?? DateTime.now(), firstDate: newDate ?? DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365 * 2)));
                    if (d != null) setSheetState(() => newEndDate = d);
                  },
                  dense: true,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      try {
                        final repo = ref.read(taskRepositoryProvider);
                        final dateStr = newDate != null ? '${newDate!.year}-${newDate!.month.toString().padLeft(2, '0')}-${newDate!.day.toString().padLeft(2, '0')}' : null;
                        final endDateStr = newEndDate != null ? '${newEndDate!.year}-${newEndDate!.month.toString().padLeft(2, '0')}-${newEndDate!.day.toString().padLeft(2, '0')}' : null;
                        await repo.updateTask(task.id, {'due_date': dateStr, 'end_date': endDateStr});
                        ref.invalidate(dailyTasksProvider);
                      } catch (_) {}
                    },
                    child: const Text('Relocate'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../data/models/task_model.dart';
import 'time_slot.dart';
import 'task_card.dart';

class TaskTimeline extends StatelessWidget {
  const TaskTimeline({
    super.key,
    required this.tasks,
    this.onStatusChanged,
  });

  final List<TaskModel> tasks;
  final void Function(String taskId, TaskStatus status)? onStatusChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final currentHour = now.hour;

    // Separate scheduled and unscheduled tasks
    final scheduledTasks =
        tasks.where((t) => t.startTime != null).toList();
    final unscheduledTasks =
        tasks.where((t) => t.startTime == null).toList();

    // Group scheduled tasks by hour
    final tasksByHour = <int, List<TaskModel>>{};
    for (final task in scheduledTasks) {
      final hour = task.startTime!.hour;
      tasksByHour.putIfAbsent(hour, () => []).add(task);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Unscheduled tasks section
        if (unscheduledTasks.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: AppSpacing.borderRadiusFull,
                  ),
                  child: Text(
                    'Unscheduled',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                AppSpacing.hGapSm,
                Text(
                  '${unscheduledTasks.length} task${unscheduledTasks.length == 1 ? '' : 's'}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: AppSpacing.paddingHorizontalLg,
            child: Column(
              children: unscheduledTasks
                  .asMap()
                  .entries
                  .map(
                    (entry) => TaskCard(
                      task: entry.value,
                      animationIndex: entry.key,
                      onStatusChanged: onStatusChanged != null
                          ? (status) =>
                              onStatusChanged!(entry.value.id, status)
                          : null,
                    ),
                  )
                  .toList(),
            ),
          ),
          AppSpacing.vGapLg,
          const Divider(),
          AppSpacing.vGapSm,
        ],

        // Timeline
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            children: List.generate(
              AppConstants.timelineEndHour - AppConstants.timelineStartHour + 1,
              (index) {
                final hour = AppConstants.timelineStartHour + index;
                final hourTasks = tasksByHour[hour] ?? [];

                return TimeSlot(
                  hour: hour,
                  tasks: hourTasks,
                  isCurrentHour: hour == currentHour,
                  onStatusChanged: onStatusChanged,
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

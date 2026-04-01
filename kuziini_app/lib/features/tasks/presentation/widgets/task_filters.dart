import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../data/models/task_model.dart';
import '../../providers/tasks_provider.dart';

class TaskFilters extends ConsumerWidget {
  const TaskFilters({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentFilter = ref.watch(taskFilterProvider);
    final priorityFilter = ref.watch(taskPriorityFilterProvider);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: AppSpacing.paddingHorizontalLg,
      child: Row(
        children: [
          // Task type filters
          _FilterChip(
            label: 'All',
            isSelected: currentFilter == TaskFilterType.all,
            onTap: () =>
                ref.read(taskFilterProvider.notifier).state = TaskFilterType.all,
          ),
          AppSpacing.hGapSm,
          _FilterChip(
            label: 'My Tasks',
            isSelected: currentFilter == TaskFilterType.myTasks,
            onTap: () => ref.read(taskFilterProvider.notifier).state =
                TaskFilterType.myTasks,
          ),
          AppSpacing.hGapSm,
          _FilterChip(
            label: 'Assigned to Me',
            isSelected: currentFilter == TaskFilterType.assignedToMe,
            onTap: () => ref.read(taskFilterProvider.notifier).state =
                TaskFilterType.assignedToMe,
          ),
          AppSpacing.hGapSm,
          _FilterChip(
            label: 'Overdue',
            isSelected: currentFilter == TaskFilterType.overdue,
            color: AppColors.error,
            onTap: () => ref.read(taskFilterProvider.notifier).state =
                TaskFilterType.overdue,
          ),
          AppSpacing.hGapSm,
          _FilterChip(
            label: 'Done',
            isSelected: currentFilter == TaskFilterType.done,
            color: AppColors.success,
            onTap: () => ref.read(taskFilterProvider.notifier).state =
                currentFilter == TaskFilterType.done ? TaskFilterType.all : TaskFilterType.done,
          ),
          AppSpacing.hGapSm,
          _FilterChip(
            label: 'In Progress',
            isSelected: currentFilter == TaskFilterType.inProgress,
            color: AppColors.warning,
            onTap: () => ref.read(taskFilterProvider.notifier).state =
                currentFilter == TaskFilterType.inProgress ? TaskFilterType.all : TaskFilterType.inProgress,
          ),

          AppSpacing.hGapLg,

          // Divider
          Container(
            width: 1,
            height: 20,
            color: Theme.of(context).dividerColor,
          ),

          AppSpacing.hGapLg,

          // Priority filters
          _FilterChip(
            label: 'Urgent',
            isSelected: priorityFilter == TaskPriority.urgent,
            color: AppColors.priorityUrgent,
            onTap: () => ref.read(taskPriorityFilterProvider.notifier).state =
                priorityFilter == TaskPriority.urgent
                    ? null
                    : TaskPriority.urgent,
          ),
          AppSpacing.hGapSm,
          _FilterChip(
            label: 'High',
            isSelected: priorityFilter == TaskPriority.high,
            color: AppColors.priorityHigh,
            onTap: () => ref.read(taskPriorityFilterProvider.notifier).state =
                priorityFilter == TaskPriority.high ? null : TaskPriority.high,
          ),
          AppSpacing.hGapSm,
          _FilterChip(
            label: 'Medium',
            isSelected: priorityFilter == TaskPriority.medium,
            color: AppColors.priorityMedium,
            onTap: () => ref.read(taskPriorityFilterProvider.notifier).state =
                priorityFilter == TaskPriority.medium
                    ? null
                    : TaskPriority.medium,
          ),
          AppSpacing.hGapSm,
          _FilterChip(
            label: 'Low',
            isSelected: priorityFilter == TaskPriority.low,
            color: AppColors.priorityLow,
            onTap: () => ref.read(taskPriorityFilterProvider.notifier).state =
                priorityFilter == TaskPriority.low ? null : TaskPriority.low,
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.color,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chipColor = color ?? theme.colorScheme.primary;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? chipColor.withValues(alpha: 0.12)
              : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: AppSpacing.borderRadiusFull,
          border: Border.all(
            color: isSelected
                ? chipColor.withValues(alpha: 0.5)
                : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: isSelected ? chipColor : theme.colorScheme.onSurfaceVariant,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

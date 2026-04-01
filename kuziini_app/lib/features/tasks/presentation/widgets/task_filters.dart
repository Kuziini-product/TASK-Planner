import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

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

    // Check if a "more" filter is active
    final isMoreActive = currentFilter == TaskFilterType.assignedToMe ||
        currentFilter == TaskFilterType.overdue ||
        currentFilter == TaskFilterType.done ||
        currentFilter == TaskFilterType.inProgress ||
        priorityFilter != null;

    String moreLabel = 'More';
    if (isMoreActive) {
      if (priorityFilter != null) {
        moreLabel = priorityFilter.label;
      } else {
        switch (currentFilter) {
          case TaskFilterType.assignedToMe:
            moreLabel = 'Assigned to Me';
          case TaskFilterType.overdue:
            moreLabel = 'Overdue';
          case TaskFilterType.done:
            moreLabel = 'Done';
          case TaskFilterType.inProgress:
            moreLabel = 'In Progress';
          default:
            break;
        }
      }
    }

    return Padding(
      padding: AppSpacing.paddingHorizontalLg,
      child: Row(
        children: [
          _FilterChip(
            label: 'All',
            isSelected: currentFilter == TaskFilterType.all && priorityFilter == null,
            onTap: () {
              ref.read(taskFilterProvider.notifier).state = TaskFilterType.all;
              ref.read(taskPriorityFilterProvider.notifier).state = null;
            },
          ),
          AppSpacing.hGapSm,
          _FilterChip(
            label: 'My Tasks',
            isSelected: currentFilter == TaskFilterType.myTasks && priorityFilter == null,
            onTap: () {
              ref.read(taskFilterProvider.notifier).state = TaskFilterType.myTasks;
              ref.read(taskPriorityFilterProvider.notifier).state = null;
            },
          ),
          AppSpacing.hGapSm,
          _MoreFilterChip(
            label: moreLabel,
            isActive: isMoreActive,
            currentFilter: currentFilter,
            priorityFilter: priorityFilter,
          ),
        ],
      ),
    );
  }
}

class _MoreFilterChip extends ConsumerWidget {
  const _MoreFilterChip({
    required this.label,
    required this.isActive,
    required this.currentFilter,
    this.priorityFilter,
  });

  final String label;
  final bool isActive;
  final TaskFilterType currentFilter;
  final TaskPriority? priorityFilter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (ctx) => _MoreFiltersSheet(
            currentFilter: currentFilter,
            priorityFilter: priorityFilter,
            onFilterChanged: (filter) {
              ref.read(taskFilterProvider.notifier).state = filter;
              ref.read(taskPriorityFilterProvider.notifier).state = null;
              Navigator.pop(ctx);
            },
            onPriorityChanged: (priority) {
              ref.read(taskPriorityFilterProvider.notifier).state = priority;
              ref.read(taskFilterProvider.notifier).state = TaskFilterType.all;
              Navigator.pop(ctx);
            },
            onClear: () {
              ref.read(taskFilterProvider.notifier).state = TaskFilterType.all;
              ref.read(taskPriorityFilterProvider.notifier).state = null;
              Navigator.pop(ctx);
            },
          ),
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isActive
              ? primaryColor.withValues(alpha: 0.12)
              : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: AppSpacing.borderRadiusFull,
          border: Border.all(
            color: isActive ? primaryColor.withValues(alpha: 0.5) : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: isActive ? primaryColor : theme.colorScheme.onSurfaceVariant,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              PhosphorIcons.caretDown(PhosphorIconsStyle.bold),
              size: 12,
              color: isActive ? primaryColor : theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

class _MoreFiltersSheet extends StatelessWidget {
  const _MoreFiltersSheet({
    required this.currentFilter,
    this.priorityFilter,
    required this.onFilterChanged,
    required this.onPriorityChanged,
    required this.onClear,
  });

  final TaskFilterType currentFilter;
  final TaskPriority? priorityFilter;
  final ValueChanged<TaskFilterType> onFilterChanged;
  final ValueChanged<TaskPriority> onPriorityChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text('Filter Tasks', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),

            // Status filters
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('STATUS', style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  )),
                  const SizedBox(height: 8),
                  _FilterOption(
                    label: 'Assigned to Me',
                    isSelected: currentFilter == TaskFilterType.assignedToMe,
                    onTap: () => onFilterChanged(TaskFilterType.assignedToMe),
                  ),
                  _FilterOption(
                    label: 'In Progress',
                    color: AppColors.warning,
                    isSelected: currentFilter == TaskFilterType.inProgress,
                    onTap: () => onFilterChanged(TaskFilterType.inProgress),
                  ),
                  _FilterOption(
                    label: 'Done',
                    color: AppColors.success,
                    isSelected: currentFilter == TaskFilterType.done,
                    onTap: () => onFilterChanged(TaskFilterType.done),
                  ),
                  _FilterOption(
                    label: 'Overdue',
                    color: AppColors.error,
                    isSelected: currentFilter == TaskFilterType.overdue,
                    onTap: () => onFilterChanged(TaskFilterType.overdue),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),

            // Priority filters
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('PRIORITY', style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  )),
                  const SizedBox(height: 8),
                  _FilterOption(
                    label: 'Urgent',
                    color: AppColors.priorityUrgent,
                    isSelected: priorityFilter == TaskPriority.urgent,
                    onTap: () => onPriorityChanged(TaskPriority.urgent),
                  ),
                  _FilterOption(
                    label: 'High',
                    color: AppColors.priorityHigh,
                    isSelected: priorityFilter == TaskPriority.high,
                    onTap: () => onPriorityChanged(TaskPriority.high),
                  ),
                  _FilterOption(
                    label: 'Medium',
                    color: AppColors.priorityMedium,
                    isSelected: priorityFilter == TaskPriority.medium,
                    onTap: () => onPriorityChanged(TaskPriority.medium),
                  ),
                  _FilterOption(
                    label: 'Low',
                    color: AppColors.priorityLow,
                    isSelected: priorityFilter == TaskPriority.low,
                    onTap: () => onPriorityChanged(TaskPriority.low),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Clear button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: onClear,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.onSurfaceVariant,
                    side: BorderSide(color: theme.dividerColor),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Clear Filters'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterOption extends StatelessWidget {
  const _FilterOption({
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
    final effectiveColor = color ?? theme.colorScheme.primary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(
          children: [
            Container(
              width: 10, height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: effectiveColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? effectiveColor : null,
                ),
              ),
            ),
            if (isSelected)
              Icon(PhosphorIcons.check(PhosphorIconsStyle.bold), size: 18, color: effectiveColor),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chipColor = theme.colorScheme.primary;

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

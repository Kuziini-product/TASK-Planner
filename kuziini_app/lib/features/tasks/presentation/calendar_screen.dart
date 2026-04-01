import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../data/models/task_model.dart';
import '../providers/tasks_provider.dart';
import 'widgets/priority_badge.dart';
import 'widgets/task_card.dart';

final _calendarMonthProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, 1);
});

final _calendarSelectedDayProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});

class CalendarScreen extends ConsumerWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final month = ref.watch(_calendarMonthProvider);
    final selectedDay = ref.watch(_calendarSelectedDayProvider);

    final firstDay = DateTime(month.year, month.month, 1);
    final lastDay = DateTime(month.year, month.month + 1, 0);
    final range = (from: firstDay, to: lastDay);
    final tasksAsync = ref.watch(calendarTasksProvider(range));

    return Scaffold(
      appBar: AppBar(
        title: Text('Calendar', style: theme.textTheme.titleLarge),
        actions: [
          TextButton(
            onPressed: () {
              final now = DateTime.now();
              ref.read(_calendarMonthProvider.notifier).state =
                  DateTime(now.year, now.month, 1);
              ref.read(_calendarSelectedDayProvider.notifier).state =
                  DateTime(now.year, now.month, now.day);
            },
            child: const Text('Today'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Month navigation
          Padding(
            padding: AppSpacing.paddingHorizontalLg,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () {
                    ref.read(_calendarMonthProvider.notifier).state =
                        DateTime(month.year, month.month - 1, 1);
                  },
                  icon: Icon(PhosphorIcons.caretLeft(PhosphorIconsStyle.bold)),
                ),
                Text(
                  AppDateUtils.formatMonthYear(month),
                  style: theme.textTheme.titleMedium,
                ),
                IconButton(
                  onPressed: () {
                    ref.read(_calendarMonthProvider.notifier).state =
                        DateTime(month.year, month.month + 1, 1);
                  },
                  icon: Icon(PhosphorIcons.caretRight(PhosphorIconsStyle.bold)),
                ),
              ],
            ),
          ),

          // Day labels
          Padding(
            padding: AppSpacing.paddingHorizontalLg,
            child: Row(
              children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
                  .map((day) => Expanded(
                        child: Center(
                          child: Text(
                            day,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ),

          AppSpacing.vGapSm,

          // Calendar grid
          tasksAsync.when(
            data: (tasks) {
              final tasksByDay = <int, List<TaskModel>>{};
              for (final task in tasks) {
                if (task.dueDate != null) {
                  final day = task.dueDate!.day;
                  tasksByDay.putIfAbsent(day, () => []).add(task);
                }
              }

              return _CalendarGrid(
                month: month,
                selectedDay: selectedDay,
                tasksByDay: tasksByDay,
                onDaySelected: (day) {
                  ref.read(_calendarSelectedDayProvider.notifier).state = day;
                },
              );
            },
            loading: () => const SizedBox(
              height: 280,
              child: LoadingIndicator(size: 24),
            ),
            error: (_, __) => const SizedBox(
              height: 280,
              child: Center(child: Text('Failed to load tasks')),
            ),
          ),

          const Divider(),

          // Selected day tasks
          Expanded(
            child: tasksAsync.when(
              data: (allTasks) {
                final dayTasks = allTasks
                    .where((t) =>
                        t.dueDate != null &&
                        AppDateUtils.isSameDay(t.dueDate!, selectedDay))
                    .toList();

                if (dayTasks.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          AppDateUtils.getRelativeDateLabel(selectedDay),
                          style: theme.textTheme.titleSmall,
                        ),
                        AppSpacing.vGapSm,
                        Text(
                          'No tasks scheduled',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                      child: Text(
                        '${AppDateUtils.getRelativeDateLabel(selectedDay)} - ${dayTasks.length} task${dayTasks.length == 1 ? '' : 's'}',
                        style: theme.textTheme.titleSmall,
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: AppSpacing.paddingHorizontalLg,
                        itemCount: dayTasks.length,
                        itemBuilder: (context, index) {
                          return TaskCard(
                            task: dayTasks[index],
                            animationIndex: index,
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
              loading: () => const LoadingIndicator(size: 24),
              error: (_, __) =>
                  const Center(child: Text('Failed to load tasks')),
            ),
          ),
        ],
      ),
    );
  }
}

class _CalendarGrid extends StatelessWidget {
  const _CalendarGrid({
    required this.month,
    required this.selectedDay,
    required this.tasksByDay,
    required this.onDaySelected,
  });

  final DateTime month;
  final DateTime selectedDay;
  final Map<int, List<TaskModel>> tasksByDay;
  final ValueChanged<DateTime> onDaySelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final firstDay = DateTime(month.year, month.month, 1);
    final lastDay = DateTime(month.year, month.month + 1, 0);
    final startWeekday = firstDay.weekday; // 1 = Monday
    final daysInMonth = lastDay.day;

    final cells = <Widget>[];

    // Empty cells for days before the first
    for (int i = 1; i < startWeekday; i++) {
      cells.add(const SizedBox());
    }

    // Day cells
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(month.year, month.month, day);
      final isSelected = AppDateUtils.isSameDay(date, selectedDay);
      final isToday = AppDateUtils.isToday(date);
      final tasks = tasksByDay[day] ?? [];
      final hasTasks = tasks.isNotEmpty;

      cells.add(
        GestureDetector(
          onTap: () => onDaySelected(date),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary
                  : isToday
                      ? AppColors.primary.withValues(alpha: 0.08)
                      : null,
              borderRadius: BorderRadius.circular(8),
              border: isToday && !isSelected
                  ? Border.all(color: AppColors.primary.withValues(alpha: 0.3))
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$day',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isSelected
                        ? Colors.white
                        : theme.colorScheme.onSurface,
                    fontWeight:
                        isSelected || isToday ? FontWeight.w700 : null,
                  ),
                ),
                if (hasTasks)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: tasks
                        .take(3)
                        .map((t) => Container(
                              width: 4,
                              height: 4,
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 1),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isSelected
                                    ? Colors.white.withValues(alpha: 0.8)
                                    : _priorityColor(t.priority),
                              ),
                            ))
                        .toList(),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: AppSpacing.paddingHorizontalLg,
      child: GridView.count(
        crossAxisCount: 7,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 1.1,
        children: cells,
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Color _priorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.urgent:
        return AppColors.priorityUrgent;
      case TaskPriority.high:
        return AppColors.priorityHigh;
      case TaskPriority.medium:
        return AppColors.priorityMedium;
      case TaskPriority.low:
        return AppColors.priorityLow;
      case TaskPriority.none:
        return AppColors.primaryLight;
    }
  }
}

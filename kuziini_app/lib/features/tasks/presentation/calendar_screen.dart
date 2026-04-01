import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/widgets/alerts_button.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../data/models/task_model.dart';
import '../providers/tasks_provider.dart';
import 'widgets/task_card.dart';

// ── Providers ──

enum CalendarView { day, week, month, year }

final _calendarViewProvider = StateProvider<CalendarView>((ref) => CalendarView.month);

final _calendarMonthProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, 1);
});

final _calendarSelectedDayProvider = StateProvider<DateTime?>((ref) => null);

// ── Main Screen ──

class CalendarScreen extends ConsumerWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final view = ref.watch(_calendarViewProvider);
    final month = ref.watch(_calendarMonthProvider);
    final selectedDay = ref.watch(_calendarSelectedDayProvider);

    // If a day is selected, show the day detail view
    if (selectedDay != null) {
      return _DayDetailView(day: selectedDay);
    }

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        leading: const AlertsButton(),
        title: Image.asset('assets/images/kuziini_logo.png', height: 32, color: theme.colorScheme.onSurface),
        actions: [
          TextButton(
            onPressed: () {
              final now = DateTime.now();
              ref.read(_calendarMonthProvider.notifier).state = DateTime(now.year, now.month, 1);
            },
            child: const Text('Today'),
          ),
        ],
      ),
      body: Column(
        children: [
          // View selector: Day | Week | Month | Year
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: CalendarView.values.map((v) {
                final isSelected = view == v;
                final label = v.name[0].toUpperCase() + v.name.substring(1);
                return Expanded(
                  child: GestureDetector(
                    onTap: () => ref.read(_calendarViewProvider.notifier).state = v,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? primaryColor : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected ? primaryColor : theme.dividerColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected ? Colors.white : theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // Content based on view
          Expanded(
            child: switch (view) {
              CalendarView.day => _DayView(month: month),
              CalendarView.week => _WeekView(month: month),
              CalendarView.month => _MonthView(month: month),
              CalendarView.year => _YearView(month: month),
            },
          ),
        ],
      ),
    );
  }
}

// ── Day View ──

class _DayView extends ConsumerWidget {
  const _DayView({required this.month});
  final DateTime month;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return Column(
      children: [
        // Day navigation
        Padding(
          padding: AppSpacing.paddingHorizontalLg,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () {
                  final prev = today.subtract(const Duration(days: 1));
                  ref.read(_calendarMonthProvider.notifier).state = DateTime(prev.year, prev.month, 1);
                },
                icon: Icon(PhosphorIcons.caretLeft(PhosphorIconsStyle.bold)),
              ),
              Text(AppDateUtils.formatFull(today), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
              IconButton(
                onPressed: () {
                  final next = today.add(const Duration(days: 1));
                  ref.read(_calendarMonthProvider.notifier).state = DateTime(next.year, next.month, 1);
                },
                icon: Icon(PhosphorIcons.caretRight(PhosphorIconsStyle.bold)),
              ),
            ],
          ),
        ),
        const Divider(),
        // Show today's tasks
        Expanded(child: _TaskListForDay(day: today)),
      ],
    );
  }
}

// ── Week View ──

class _WeekView extends ConsumerWidget {
  const _WeekView({required this.month});
  final DateTime month;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final days = List.generate(7, (i) => weekStart.add(Duration(days: i)));

    final firstDay = days.first;
    final lastDay = days.last;
    final range = (from: firstDay, to: lastDay);
    final tasksAsync = ref.watch(calendarTasksProvider(range));

    return Column(
      children: [
        // Week header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            '${AppDateUtils.formatDate(firstDay)} – ${AppDateUtils.formatDate(lastDay)}',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        // Day headers
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: days.map((day) {
              final isToday = AppDateUtils.isToday(day);
              return Expanded(
                child: GestureDetector(
                  onTap: () => ref.read(_calendarSelectedDayProvider.notifier).state = day,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isToday ? primaryColor : null,
                      borderRadius: BorderRadius.circular(10),
                      border: isToday ? null : Border.all(color: theme.dividerColor.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][day.weekday - 1],
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: isToday ? Colors.white70 : theme.colorScheme.onSurfaceVariant),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${day.day}',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: isToday ? Colors.white : null),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        // Timeline grid with task bars
        Expanded(
          child: tasksAsync.when(
            data: (tasks) {
              // Group tasks by day of week
              final tasksByDay = <int, List<TaskModel>>{};
              for (final task in tasks) {
                if (task.dueDate != null) {
                  for (int i = 0; i < 7; i++) {
                    if (AppDateUtils.isSameDay(task.dueDate!, days[i])) {
                      tasksByDay.putIfAbsent(i, () => []).add(task);
                      break;
                    }
                  }
                }
              }

              // Find max task rows across all days
              int maxRows = 0;
              for (final dayTasks in tasksByDay.values) {
                final scheduled = dayTasks.where((t) => t.startTime != null).length;
                final unscheduled = dayTasks.where((t) => t.startTime == null).length;
                final rows = scheduled + unscheduled;
                if (rows > maxRows) maxRows = rows;
              }
              if (maxRows == 0) {
                return Center(child: Text('No tasks this week', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)));
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: List.generate(7, (dayIdx) {
                      final dayTasks = tasksByDay[dayIdx] ?? [];
                      final scheduled = dayTasks.where((t) => t.startTime != null).toList()
                        ..sort((a, b) => a.startTime!.compareTo(b.startTime!));
                      final unscheduled = dayTasks.where((t) => t.startTime == null).toList();
                      final allTasks = [...scheduled, ...unscheduled];

                      return Expanded(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(
                            border: Border(
                              left: BorderSide(color: theme.dividerColor.withValues(alpha: 0.15)),
                            ),
                          ),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final colWidth = constraints.maxWidth;
                              return Column(
                                children: allTasks.map((task) {
                                  return GestureDetector(
                                    onTap: () => context.push('/task/${task.id}'),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 2),
                                      child: _WeekTaskBar(task: task, colWidth: colWidth),
                                    ),
                                  );
                                }).toList(),
                              );
                            },
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              );
            },
            loading: () => const LoadingIndicator(size: 24),
            error: (_, __) => const Center(child: Text('Failed to load tasks')),
          ),
        ),
      ],
    );
  }
}

class _WeekTaskBar extends StatelessWidget {
  const _WeekTaskBar({required this.task, required this.colWidth});

  final TaskModel task;
  final double colWidth;

  @override
  Widget build(BuildContext context) {
    final color = _taskColor(context, task.priority);

    if (task.startTime == null) {
      // Unscheduled: small centered bar
      return Align(
        alignment: Alignment.centerLeft,
        child: Container(
          width: colWidth * 0.4,
          height: 5,
          margin: const EdgeInsets.only(left: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(2.5),
          ),
        ),
      );
    }

    // Scheduled: position proportional to time
    final startMin = _minutesSinceStart(task.startTime!);
    final endMin = task.endTime != null ? _minutesSinceStart(task.endTime!) : startMin + 60;

    final leftFraction = (startMin / _totalMinutes).clamp(0.0, 1.0);
    final widthFraction = ((endMin - startMin) / _totalMinutes).clamp(0.05, 1.0 - leftFraction);

    final left = leftFraction * colWidth;
    final width = widthFraction * colWidth;

    return SizedBox(
      height: 7,
      child: Stack(
        children: [
          Positioned(
            left: left.clamp(0, colWidth - 4),
            child: Container(
              width: width.clamp(4, colWidth),
              height: 5,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _minutesSinceStart(DateTime time) {
    final local = time.toLocal();
    final mins = (local.hour - _dayStartHour) * 60 + local.minute;
    return mins.clamp(0, _totalMinutes).toDouble();
  }

  Color _taskColor(BuildContext context, TaskPriority priority) {
    switch (priority) {
      case TaskPriority.urgent: return AppColors.priorityUrgent;
      case TaskPriority.high: return AppColors.priorityHigh;
      case TaskPriority.medium: return AppColors.priorityMedium;
      case TaskPriority.low: return AppColors.priorityLow;
      case TaskPriority.none: return Theme.of(context).colorScheme.primary;
    }
  }
}

// ── Month View (original) ──

class _MonthView extends ConsumerWidget {
  const _MonthView({required this.month});
  final DateTime month;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final currentMonth = ref.watch(_calendarMonthProvider);

    final firstDay = DateTime(currentMonth.year, currentMonth.month, 1);
    final lastDay = DateTime(currentMonth.year, currentMonth.month + 1, 0);
    final range = (from: firstDay, to: lastDay);
    final tasksAsync = ref.watch(calendarTasksProvider(range));

    return Column(
      children: [
        // Month navigation
        Padding(
          padding: AppSpacing.paddingHorizontalLg,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () => ref.read(_calendarMonthProvider.notifier).state = DateTime(currentMonth.year, currentMonth.month - 1, 1),
                icon: Icon(PhosphorIcons.caretLeft(PhosphorIconsStyle.bold)),
              ),
              Text(AppDateUtils.formatMonthYear(currentMonth), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
              IconButton(
                onPressed: () => ref.read(_calendarMonthProvider.notifier).state = DateTime(currentMonth.year, currentMonth.month + 1, 1),
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
                        child: Text(day, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600)),
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
                tasksByDay.putIfAbsent(task.dueDate!.day, () => []).add(task);
              }
            }
            return _CalendarGrid(
              month: currentMonth,
              tasksByDay: tasksByDay,
              onDaySelected: (day) => ref.read(_calendarSelectedDayProvider.notifier).state = day,
            );
          },
          loading: () => const SizedBox(height: 280, child: LoadingIndicator(size: 24)),
          error: (_, __) => const SizedBox(height: 280, child: Center(child: Text('Failed to load tasks'))),
        ),
      ],
    );
  }
}

// ── Year View ──

class _YearView extends ConsumerWidget {
  const _YearView({required this.month});
  final DateTime month;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final currentMonth = ref.watch(_calendarMonthProvider);
    final year = currentMonth.year;
    final now = DateTime.now();

    return Column(
      children: [
        // Year navigation
        Padding(
          padding: AppSpacing.paddingHorizontalLg,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () => ref.read(_calendarMonthProvider.notifier).state = DateTime(year - 1, currentMonth.month, 1),
                icon: Icon(PhosphorIcons.caretLeft(PhosphorIconsStyle.bold)),
              ),
              Text('$year', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
              IconButton(
                onPressed: () => ref.read(_calendarMonthProvider.notifier).state = DateTime(year + 1, currentMonth.month, 1),
                icon: Icon(PhosphorIcons.caretRight(PhosphorIconsStyle.bold)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // 12 month grid (3x4)
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.3,
            ),
            itemCount: 12,
            itemBuilder: (context, index) {
              final m = index + 1;
              final isCurrentMonth = year == now.year && m == now.month;
              final monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

              return GestureDetector(
                onTap: () {
                  ref.read(_calendarMonthProvider.notifier).state = DateTime(year, m, 1);
                  ref.read(_calendarViewProvider.notifier).state = CalendarView.month;
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isCurrentMonth ? primaryColor.withValues(alpha: 0.1) : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: isCurrentMonth ? Border.all(color: primaryColor.withValues(alpha: 0.4)) : null,
                  ),
                  child: Center(
                    child: Text(
                      monthNames[index],
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: isCurrentMonth ? FontWeight.w700 : FontWeight.w500,
                        color: isCurrentMonth ? primaryColor : theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ── Day Detail View (when tapping a day) ──

class _DayDetailView extends ConsumerWidget {
  const _DayDetailView({required this.day});
  final DateTime day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => ref.read(_calendarSelectedDayProvider.notifier).state = null,
          icon: Icon(PhosphorIcons.arrowLeft(PhosphorIconsStyle.bold)),
        ),
        centerTitle: true,
        title: Text(
          AppDateUtils.formatFull(day),
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      body: _TaskListForDay(day: day),
    );
  }
}

// ── Task List for a Day ──

class _TaskListForDay extends ConsumerWidget {
  const _TaskListForDay({required this.day});
  final DateTime day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final range = (from: DateTime(day.year, day.month, 1), to: DateTime(day.year, day.month + 1, 0));
    final tasksAsync = ref.watch(calendarTasksProvider(range));

    return tasksAsync.when(
      data: (allTasks) {
        final dayTasks = allTasks
            .where((t) => t.dueDate != null && AppDateUtils.isSameDay(t.dueDate!, day))
            .toList();

        if (dayTasks.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(PhosphorIcons.calendarBlank(PhosphorIconsStyle.regular), size: 48, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3)),
                const SizedBox(height: 12),
                Text('No tasks scheduled', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: dayTasks.length,
          itemBuilder: (context, index) => TaskCard(task: dayTasks[index], animationIndex: index),
        );
      },
      loading: () => const LoadingIndicator(size: 24),
      error: (_, __) => const Center(child: Text('Failed to load tasks')),
    );
  }
}

// ── Calendar Grid (Month) with timeline bars ──
// Each day cell shows task bars proportional to duration on a 8:00–19:00 axis.

const _dayStartHour = 8;
const _dayEndHour = 19;
const _totalMinutes = (_dayEndHour - _dayStartHour) * 60; // 660 min

class _CalendarGrid extends StatelessWidget {
  const _CalendarGrid({
    required this.month,
    required this.tasksByDay,
    required this.onDaySelected,
  });

  final DateTime month;
  final Map<int, List<TaskModel>> tasksByDay;
  final ValueChanged<DateTime> onDaySelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final firstDay = DateTime(month.year, month.month, 1);
    final lastDay = DateTime(month.year, month.month + 1, 0);
    final startWeekday = firstDay.weekday;
    final daysInMonth = lastDay.day;

    final cells = <Widget>[];
    for (int i = 1; i < startWeekday; i++) {
      cells.add(const SizedBox());
    }

    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(month.year, month.month, day);
      final isToday = AppDateUtils.isToday(date);
      final tasks = tasksByDay[day] ?? [];

      cells.add(
        GestureDetector(
          onTap: () => onDaySelected(date),
          child: Container(
            margin: const EdgeInsets.all(1),
            decoration: BoxDecoration(
              color: isToday ? primaryColor.withValues(alpha: 0.08) : null,
              borderRadius: BorderRadius.circular(6),
              border: isToday ? Border.all(color: primaryColor.withValues(alpha: 0.4), width: 1.5) : null,
            ),
            child: Column(
              children: [
                // Day number
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    '$day',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: isToday ? FontWeight.w800 : FontWeight.w500,
                      color: isToday ? primaryColor : theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                // Task timeline bars
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 1),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final cellWidth = constraints.maxWidth;
                        final cellHeight = constraints.maxHeight;
                        if (tasks.isEmpty || cellWidth <= 0) return const SizedBox();

                        final sorted = tasks.where((t) => t.startTime != null).toList()
                          ..sort((a, b) => a.startTime!.compareTo(b.startTime!));
                        final noTime = tasks.where((t) => t.startTime == null).toList();

                        final bars = <Widget>[];
                        int row = 0;

                        for (final task in sorted.take(5)) {
                          final startMin = _minutesSinceStart(task.startTime!);
                          final endMin = task.endTime != null
                              ? _minutesSinceStart(task.endTime!)
                              : startMin + 60;

                          final leftPx = (startMin / _totalMinutes * cellWidth).clamp(0.0, cellWidth - 2);
                          final widthPx = ((endMin - startMin) / _totalMinutes * cellWidth).clamp(2.0, cellWidth - leftPx);
                          final topPx = (row * 4.0).clamp(0.0, cellHeight - 3);

                          bars.add(
                            Positioned(
                              left: leftPx,
                              top: topPx,
                              child: Container(
                                width: widthPx,
                                height: 3,
                                decoration: BoxDecoration(
                                  color: _priorityColor(context, task.priority),
                                  borderRadius: BorderRadius.circular(1.5),
                                ),
                              ),
                            ),
                          );
                          row++;
                        }

                        for (int i = 0; i < noTime.length && i < 3; i++) {
                          bars.add(
                            Positioned(
                              left: 1 + i * 5.0,
                              bottom: 1,
                              child: Container(
                                width: 3, height: 3,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _priorityColor(context, noTime[i].priority),
                                ),
                              ),
                            ),
                          );
                        }

                        return Stack(clipBehavior: Clip.hardEdge, children: bars);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Expanded(
      child: Padding(
        padding: AppSpacing.paddingHorizontalLg,
        child: GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 0.8,
          children: cells,
        ),
      ),
    );
  }

  /// Minutes from 8:00 start
  double _minutesSinceStart(DateTime time) {
    final local = time.toLocal();
    final mins = (local.hour - _dayStartHour) * 60 + local.minute;
    return mins.clamp(0, _totalMinutes).toDouble();
  }

  Color _priorityColor(BuildContext context, TaskPriority priority) {
    switch (priority) {
      case TaskPriority.urgent: return AppColors.priorityUrgent;
      case TaskPriority.high: return AppColors.priorityHigh;
      case TaskPriority.medium: return AppColors.priorityMedium;
      case TaskPriority.low: return AppColors.priorityLow;
      case TaskPriority.none: return Theme.of(context).colorScheme.primary;
    }
  }
}

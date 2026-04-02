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

// Navigation reference date (used by Day and Week views)
final _calendarRefDateProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});

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
              ref.read(_calendarRefDateProvider.notifier).state = DateTime(now.year, now.month, now.day);
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
    final day = ref.watch(_calendarRefDateProvider);

    return Column(
      children: [
        Padding(
          padding: AppSpacing.paddingHorizontalLg,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () => ref.read(_calendarRefDateProvider.notifier).state = day.subtract(const Duration(days: 1)),
                icon: Icon(PhosphorIcons.caretLeft(PhosphorIconsStyle.bold)),
              ),
              Text(AppDateUtils.formatFull(day), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
              IconButton(
                onPressed: () => ref.read(_calendarRefDateProvider.notifier).state = day.add(const Duration(days: 1)),
                icon: Icon(PhosphorIcons.caretRight(PhosphorIconsStyle.bold)),
              ),
            ],
          ),
        ),
        const Divider(),
        Expanded(child: _TaskListForDay(day: day)),
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
    final refDate = ref.watch(_calendarRefDateProvider);
    // Calculate week start (Monday) from ref date
    final weekStart = refDate.subtract(Duration(days: refDate.weekday - 1));
    final days = List.generate(7, (i) => weekStart.add(Duration(days: i)));

    final firstDay = days.first;
    final lastDay = days.last;
    final range = (from: firstDay, to: lastDay);
    final tasksAsync = ref.watch(calendarTasksProvider(range));

    return Column(
      children: [
        // Week navigation with arrows
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () => ref.read(_calendarRefDateProvider.notifier).state = refDate.subtract(const Duration(days: 7)),
                icon: Icon(PhosphorIcons.caretLeft(PhosphorIconsStyle.bold)),
              ),
              Text(
                '${AppDateUtils.formatDate(firstDay)} – ${AppDateUtils.formatDate(lastDay)}',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              IconButton(
                onPressed: () => ref.read(_calendarRefDateProvider.notifier).state = refDate.add(const Duration(days: 7)),
                icon: Icon(PhosphorIcons.caretRight(PhosphorIconsStyle.bold)),
              ),
            ],
          ),
        ),
        // Day selector row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: days.map((day) {
              final isToday = AppDateUtils.isToday(day);
              return Expanded(
                child: GestureDetector(
                  onTap: () => ref.read(_calendarSelectedDayProvider.notifier).state = day,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: isToday ? theme.colorScheme.primary : null,
                      borderRadius: BorderRadius.circular(8),
                      border: isToday ? null : Border.all(color: theme.dividerColor.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      children: [
                        Text(['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][day.weekday - 1],
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: isToday ? Colors.white70 : theme.colorScheme.onSurfaceVariant)),
                        Text('${day.day}', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: isToday ? Colors.white : null)),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),
        // Logo + task list
        Expanded(
          child: tasksAsync.when(
            data: (tasks) {
              // Collect all tasks for this week, sorted by priority then time
              final weekTasks = <TaskModel>[];
              final seen = <String>{};
              for (final task in tasks) {
                if (task.dueDate == null) continue;
                for (final day in days) {
                  if (task.coversDate(day) && !seen.contains(task.id)) {
                    weekTasks.add(task);
                    seen.add(task.id);
                  }
                }
              }
              // Sort: urgent first, then by date/time
              weekTasks.sort((a, b) {
                final pa = a.priority.index;
                final pb = b.priority.index;
                if (pa != pb) return pa.compareTo(pb);
                final da = a.startTime ?? a.dueDate ?? DateTime(2099);
                final db = b.startTime ?? b.dueDate ?? DateTime(2099);
                return da.compareTo(db);
              });

              final taskWidgets = weekTasks.map((task) {
                final color = _priorityColorStatic(context, task.priority);
                final dayLabel = task.dueDate != null
                    ? ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][task.dueDate!.weekday - 1]
                    : '';
                final timeStr = task.startTime != null
                    ? AppDateUtils.formatTime(task.startTime!)
                    : '';

                return GestureDetector(
                  onTap: () => context.push('/task/${task.id}'),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: color,
                            boxShadow: [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 4)],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                task.title,
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (dayLabel.isNotEmpty || timeStr.isNotEmpty)
                                Text(
                                  [dayLabel, timeStr].where((s) => s.isNotEmpty).join(' \u00B7 '),
                                  style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
                                ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            task.priority.label,
                            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: color),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList();

              return Stack(
                children: [
                  // Background logo watermark - centered, fills the space
                  Positioned.fill(
                    child: Center(
                      child: Image.asset(
                        'assets/images/kuziini_logo_portrait.png',
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.contain,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.04),
                      ),
                    ),
                  ),
                  // Task list on top
                  ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    children: [
                      if (weekTasks.isEmpty)
                        Center(child: Padding(
                          padding: const EdgeInsets.only(top: 80),
                          child: Text('No tasks this week', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
                        )),
                      ...taskWidgets,
                    ],
                  ),
                ],
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

Color _priorityColorStatic(BuildContext context, TaskPriority priority) {
  switch (priority) {
    case TaskPriority.urgent: return AppColors.priorityUrgent;
    case TaskPriority.high: return AppColors.priorityHigh;
    case TaskPriority.medium: return AppColors.priorityMedium;
    case TaskPriority.low: return AppColors.priorityLow;
    case TaskPriority.none: return Theme.of(context).colorScheme.primary;
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
        Expanded(
          child: tasksAsync.when(
            data: (tasks) {
              final tasksByDay = <int, List<TaskModel>>{};
              for (final task in tasks) {
                if (task.dueDate != null) {
                  // For multi-day tasks, add to all days in range
                  if (task.endDate != null) {
                    final start = task.dueDate!;
                    final end = task.endDate!;
                    for (var d = start; !d.isAfter(end); d = d.add(const Duration(days: 1))) {
                      if (d.month == currentMonth.month && d.year == currentMonth.year) {
                        tasksByDay.putIfAbsent(d.day, () => []).add(task);
                      }
                    }
                  } else {
                    tasksByDay.putIfAbsent(task.dueDate!.day, () => []).add(task);
                  }
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
        leading: TextButton.icon(
          onPressed: () => ref.read(_calendarSelectedDayProvider.notifier).state = null,
          icon: Icon(PhosphorIcons.arrowLeft(PhosphorIconsStyle.bold), size: 18),
          label: const Text('Back', style: TextStyle(fontSize: 13)),
          style: TextButton.styleFrom(padding: EdgeInsets.zero),
        ),
        leadingWidth: 90,
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Previous day
            IconButton(
              onPressed: () {
                final prev = day.subtract(const Duration(days: 1));
                ref.read(_calendarSelectedDayProvider.notifier).state = prev;
              },
              icon: Icon(PhosphorIcons.caretLeft(PhosphorIconsStyle.bold), size: 16),
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              padding: EdgeInsets.zero,
            ),
            Text(
              AppDateUtils.formatFull(day),
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            // Next day
            IconButton(
              onPressed: () {
                final next = day.add(const Duration(days: 1));
                ref.read(_calendarSelectedDayProvider.notifier).state = next;
              },
              icon: Icon(PhosphorIcons.caretRight(PhosphorIconsStyle.bold), size: 16),
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              padding: EdgeInsets.zero,
            ),
          ],
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
            .where((t) => t.coversDate(day))
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

// ── Calendar Grid (Month) with drag range selection ──

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
          // Tap: open day task list
          onTap: () => onDaySelected(date),
          // Long press: open create task with this date pre-filled
          onLongPress: () {
            final params = <String, String>{
              'date': date.toIso8601String().split('T').first,
            };
            final uri = Uri(path: '/create-task', queryParameters: params);
            context.push(uri.toString());
          },
          child: Container(
            margin: const EdgeInsets.all(1),
            decoration: BoxDecoration(
              color: isToday ? primaryColor.withValues(alpha: 0.08) : null,
              borderRadius: BorderRadius.circular(6),
              border: isToday ? Border.all(color: primaryColor.withValues(alpha: 0.4), width: 1.5) : null,
            ),
            child: Column(
              children: [
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
                if (tasks.isNotEmpty)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(2),
                      child: Wrap(
                        spacing: 2, runSpacing: 2,
                        children: tasks.take(5).map((t) => Container(
                          width: 4, height: 4,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _priorityColorStatic(context, t.priority),
                          ),
                        )).toList(),
                      ),
                    ),
                  )
                else
                  const Expanded(child: SizedBox()),
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
        childAspectRatio: 0.9,
        children: cells,
      ),
    );
  }
}

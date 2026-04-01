import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/router/app_router.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/models/task_model.dart';
import '../providers/tasks_provider.dart';
import 'widgets/day_header.dart';
import 'widgets/quick_add_fab.dart';
import 'widgets/swipe_action_wrapper.dart';
import 'widgets/task_card.dart';
import 'widgets/task_filters.dart';

class DailyTasksScreen extends ConsumerStatefulWidget {
  const DailyTasksScreen({super.key});

  @override
  ConsumerState<DailyTasksScreen> createState() => _DailyTasksScreenState();
}

class _DailyTasksScreenState extends ConsumerState<DailyTasksScreen> {
  late final ScrollController _scrollController;
  bool _showCalendar = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _toggleCalendar() {
    setState(() => _showCalendar = !_showCalendar);
  }

  void _selectDate(DateTime date) {
    ref.read(selectedDateProvider.notifier).state = date;
    setState(() => _showCalendar = false);
  }

  void _addTaskAtHour(int hour) {
    final selectedDate = ref.read(selectedDateProvider);
    context.push(
      '${AppRoutes.createTask}?hour=$hour&date=${selectedDate.toIso8601String().split('T').first}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedDate = ref.watch(selectedDateProvider);
    final tasksAsync = ref.watch(dailyTasksProvider);
    final profile = ref.watch(currentUserProfileProvider);
    final progress = ref.watch(dailyProgressProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => ref.read(dailyTasksProvider.notifier).refresh(),
        color: AppColors.primary,
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // App bar
            SliverAppBar(
              floating: true,
              snap: true,
              title: Row(
                children: [
                  Text(
                    'Kuziini',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  onPressed: () => context.push(AppRoutes.search),
                  icon: Icon(PhosphorIcons.magnifyingGlass(PhosphorIconsStyle.regular)),
                ),
                const SizedBox(width: 4),
              ],
            ),

            // Compact day header with date tap to toggle calendar
            SliverToBoxAdapter(
              child: _CompactDayHeader(
                date: selectedDate,
                tasksAsync: tasksAsync,
                progress: progress,
                userName: profile.valueOrNull?.displayName,
                onDateTap: _toggleCalendar,
                showCalendar: _showCalendar,
              ),
            ),

            // Collapsible calendar
            if (_showCalendar)
              SliverToBoxAdapter(
                child: _DateSelector(
                  selectedDate: selectedDate,
                  onDateSelected: _selectDate,
                ).animate().fadeIn(duration: 200.ms).slideY(begin: -0.1, end: 0),
              ),

            // Filter chips
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(top: 4, bottom: 4),
                child: TaskFilters(),
              ),
            ),

            // Task content - full screen, no empty time slots
            tasksAsync.when(
              data: (tasks) {
                if (tasks.isEmpty) {
                  return SliverFillRemaining(
                    child: EmptyState.tasks(
                      onCreateTask: () => context.push(AppRoutes.createTask),
                    ),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        // Separate unscheduled and scheduled tasks
                        final unscheduled = tasks.where((t) => t.startTime == null).toList();
                        final scheduled = tasks.where((t) => t.startTime != null).toList()
                          ..sort((a, b) => a.startTime!.compareTo(b.startTime!));

                        final allItems = <_TaskListItem>[];

                        // Add unscheduled header + tasks
                        if (unscheduled.isNotEmpty) {
                          allItems.add(_TaskListItem(isHeader: true, headerTitle: 'Unscheduled', headerCount: unscheduled.length));
                          for (final task in unscheduled) {
                            allItems.add(_TaskListItem(task: task));
                          }
                        }

                        // Group scheduled tasks by hour and add only hours with tasks
                        if (scheduled.isNotEmpty) {
                          int? lastHour;
                          for (final task in scheduled) {
                            final hour = task.startTime!.toLocal().hour;
                            if (hour != lastHour) {
                              allItems.add(_TaskListItem(isHeader: true, headerTitle: _formatHour(hour), hour: hour));
                              lastHour = hour;
                            }
                            allItems.add(_TaskListItem(task: task));
                          }
                        }

                        if (index >= allItems.length) return null;
                        final item = allItems[index];

                        if (item.isHeader) {
                          return _TimeHeader(
                            title: item.headerTitle!,
                            count: item.headerCount,
                            hour: item.hour,
                            onAddTask: item.hour != null ? () => _addTaskAtHour(item.hour!) : null,
                          );
                        }

                        return SwipeActionWrapper(
                          onSwipeLeft: () {
                            ref.read(dailyTasksProvider.notifier).completeTask(item.task!.id);
                          },
                          child: TaskCard(
                            task: item.task!,
                            animationIndex: index,
                            onStatusChanged: (status) {
                              ref.read(dailyTasksProvider.notifier).updateTaskStatus(item.task!.id, status);
                            },
                          ),
                        );
                      },
                      childCount: _calculateItemCount(tasks),
                    ),
                  ),
                );
              },
              loading: () => const SliverFillRemaining(
                child: LoadingIndicator(message: 'Loading tasks...'),
              ),
              error: (error, _) => SliverFillRemaining(
                child: ErrorView(
                  message: error.toString(),
                  onRetry: () => ref.read(dailyTasksProvider.notifier).refresh(),
                ),
              ),
            ),

            // Bottom padding
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
      floatingActionButton: const QuickAddFab(),
    );
  }

  int _calculateItemCount(List<TaskModel> tasks) {
    final unscheduled = tasks.where((t) => t.startTime == null).toList();
    final scheduled = tasks.where((t) => t.startTime != null).toList();

    int count = 0;
    if (unscheduled.isNotEmpty) count += 1 + unscheduled.length; // header + tasks
    if (scheduled.isNotEmpty) {
      final hours = scheduled.map((t) => t.startTime!.toLocal().hour).toSet();
      count += hours.length + scheduled.length; // headers + tasks
    }
    return count;
  }

  String _formatHour(int hour) {
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:00 $period';
  }
}

// ── Compact Day Header ──
class _CompactDayHeader extends StatelessWidget {
  const _CompactDayHeader({
    required this.date,
    required this.tasksAsync,
    required this.progress,
    this.userName,
    required this.onDateTap,
    required this.showCalendar,
  });

  final DateTime date;
  final AsyncValue<List<TaskModel>> tasksAsync;
  final double progress;
  final String? userName;
  final VoidCallback onDateTap;
  final bool showCalendar;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isToday = AppDateUtils.isToday(date);
    final greeting = _getGreeting();

    final totalTasks = tasksAsync.valueOrNull?.length ?? 0;
    final completedTasks = tasksAsync.valueOrNull?.where((t) => t.isCompleted).length ?? 0;
    final remaining = totalTasks - completedTasks;

    return InkWell(
      onTap: onDateTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$greeting${userName != null ? ', $userName' : ''}',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        PhosphorIcons.calendarBlank(PhosphorIconsStyle.regular),
                        size: 14,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isToday
                            ? 'Today, ${AppDateUtils.formatDate(date)}'
                            : AppDateUtils.formatDate(date),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        showCalendar
                            ? PhosphorIcons.caretUp(PhosphorIconsStyle.bold)
                            : PhosphorIcons.caretDown(PhosphorIconsStyle.bold),
                        size: 12,
                        color: AppColors.primary,
                      ),
                      const Spacer(),
                      if (totalTasks > 0) ...[
                        _StatBadge(
                          icon: PhosphorIcons.listChecks(PhosphorIconsStyle.regular),
                          label: '$totalTasks',
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 8),
                        _StatBadge(
                          icon: PhosphorIcons.checkCircle(PhosphorIconsStyle.fill),
                          label: '$completedTasks',
                          color: AppColors.success,
                        ),
                        if (remaining > 0) ...[
                          const SizedBox(width: 8),
                          _StatBadge(
                            icon: PhosphorIcons.clock(PhosphorIconsStyle.regular),
                            label: '$remaining',
                            color: AppColors.warning,
                          ),
                        ],
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Progress circle
            SizedBox(
              width: 44,
              height: 44,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: progress,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    color: AppColors.primary,
                    strokeWidth: 3.5,
                  ),
                  Text(
                    '${(progress * 100).toInt()}%',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }
}

// ── Stat Badge ──
class _StatBadge extends StatelessWidget {
  const _StatBadge({required this.icon, required this.label, required this.color});

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 2),
        Text(
          label,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
        ),
      ],
    );
  }
}

// ── Date Selector (collapsible) ──
class _DateSelector extends StatelessWidget {
  const _DateSelector({required this.selectedDate, required this.onDateSelected});

  final DateTime selectedDate;
  final void Function(DateTime) onDateSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: 76,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: AppSpacing.paddingHorizontalLg,
        itemCount: 31,
        itemBuilder: (context, index) {
          final date = DateTime.now()
              .subtract(const Duration(days: 15))
              .add(Duration(days: index));
          final dateOnly = DateTime(date.year, date.month, date.day);
          final isSelected = AppDateUtils.isSameDay(dateOnly, selectedDate);
          final isToday = AppDateUtils.isToday(dateOnly);

          return GestureDetector(
            onTap: () => onDateSelected(dateOnly),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 50,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary
                    : isToday
                        ? AppColors.primary.withValues(alpha: 0.08)
                        : Colors.transparent,
                borderRadius: AppSpacing.borderRadiusMd,
                border: isToday && !isSelected
                    ? Border.all(color: AppColors.primary.withValues(alpha: 0.3))
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    AppDateUtils.formatShortDay(dateOnly).toUpperCase(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.8)
                          : theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${dateOnly.day}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: isSelected ? Colors.white : theme.colorScheme.onSurface,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Time Header (only shown for hours with tasks) ──
class _TimeHeader extends StatelessWidget {
  const _TimeHeader({
    required this.title,
    this.count,
    this.hour,
    this.onAddTask,
  });

  final String title;
  final int? count;
  final int? hour;
  final VoidCallback? onAddTask;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final isCurrentHour = hour != null && hour == now.hour;

    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isCurrentHour
                  ? AppColors.primary.withValues(alpha: 0.12)
                  : theme.colorScheme.surfaceContainerHighest,
              borderRadius: AppSpacing.borderRadiusFull,
            ),
            child: Text(
              title,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: isCurrentHour ? AppColors.primary : theme.colorScheme.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
          ),
          if (count != null) ...[
            const SizedBox(width: 6),
            Text(
              '$count task${count == 1 ? '' : 's'}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const Spacer(),
          if (isCurrentHour)
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
            ),
          if (onAddTask != null)
            IconButton(
              onPressed: onAddTask,
              icon: Icon(
                PhosphorIcons.plus(PhosphorIconsStyle.bold),
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              padding: EdgeInsets.zero,
              tooltip: 'Add task at $title',
            ),
          Expanded(
            child: Divider(
              height: 1,
              indent: 8,
              color: isCurrentHour
                  ? AppColors.primary.withValues(alpha: 0.3)
                  : theme.dividerColor.withValues(alpha: 0.3),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Task List Item ──
class _TaskListItem {
  final bool isHeader;
  final String? headerTitle;
  final int? headerCount;
  final int? hour;
  final TaskModel? task;

  _TaskListItem({
    this.isHeader = false,
    this.headerTitle,
    this.headerCount,
    this.hour,
    this.task,
  });
}

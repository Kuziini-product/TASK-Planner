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
import '../providers/tasks_provider.dart';
import 'widgets/day_header.dart';
import 'widgets/quick_add_fab.dart';
import 'widgets/swipe_action_wrapper.dart';
import 'widgets/task_card.dart';
import 'widgets/task_filters.dart';
import 'widgets/task_timeline.dart';

class DailyTasksScreen extends ConsumerStatefulWidget {
  const DailyTasksScreen({super.key});

  @override
  ConsumerState<DailyTasksScreen> createState() => _DailyTasksScreenState();
}

class _DailyTasksScreenState extends ConsumerState<DailyTasksScreen> {
  late final ScrollController _scrollController;
  late final PageController _datePageController;
  bool _showTimeline = true;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _datePageController = PageController(
      viewportFraction: 0.17,
      initialPage: 15, // Center on today (index 15 of a 30-day range)
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _datePageController.dispose();
    super.dispose();
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
                  icon: Icon(
                      PhosphorIcons.magnifyingGlass(PhosphorIconsStyle.regular)),
                ),
                IconButton(
                  onPressed: () {
                    setState(() => _showTimeline = !_showTimeline);
                  },
                  icon: Icon(
                    _showTimeline
                        ? PhosphorIcons.listBullets(PhosphorIconsStyle.regular)
                        : PhosphorIcons.clockAfternoon(
                            PhosphorIconsStyle.regular),
                  ),
                ),
                const SizedBox(width: 4),
              ],
            ),

            // Day header
            SliverToBoxAdapter(
              child: tasksAsync.when(
                data: (tasks) => DayHeader(
                  date: selectedDate,
                  totalTasks: tasks.length,
                  completedTasks:
                      tasks.where((t) => t.isCompleted).length,
                  userName: profile.valueOrNull?.displayName,
                ),
                loading: () => DayHeader(
                  date: selectedDate,
                  totalTasks: 0,
                  completedTasks: 0,
                  userName: profile.valueOrNull?.displayName,
                ),
                error: (_, __) => DayHeader(
                  date: selectedDate,
                  totalTasks: 0,
                  completedTasks: 0,
                  userName: profile.valueOrNull?.displayName,
                ),
              ),
            ),

            // Horizontal date selector
            SliverToBoxAdapter(
              child: Container(
                height: 80,
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: AppSpacing.paddingHorizontalLg,
                  itemCount: 31,
                  itemBuilder: (context, index) {
                    final date = DateTime.now()
                        .subtract(const Duration(days: 15))
                        .add(Duration(days: index));
                    final dateOnly =
                        DateTime(date.year, date.month, date.day);
                    final isSelected = AppDateUtils.isSameDay(
                        dateOnly, selectedDate);
                    final isToday = AppDateUtils.isToday(dateOnly);

                    return GestureDetector(
                      onTap: () {
                        ref.read(selectedDateProvider.notifier).state =
                            dateOnly;
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 52,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary
                              : isToday
                                  ? AppColors.primary.withValues(alpha: 0.08)
                                  : Colors.transparent,
                          borderRadius: AppSpacing.borderRadiusMd,
                          border: isToday && !isSelected
                              ? Border.all(
                                  color: AppColors.primary.withValues(alpha: 0.3),
                                )
                              : null,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              AppDateUtils.formatShortDay(dateOnly)
                                  .toUpperCase(),
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
                                color: isSelected
                                    ? Colors.white
                                    : theme.colorScheme.onSurface,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ).animate().fadeIn(duration: 300.ms, delay: 200.ms),
            ),

            // Filter chips
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(top: 4, bottom: 8),
                child: TaskFilters(),
              ),
            ),

            // Task content
            tasksAsync.when(
              data: (tasks) {
                if (tasks.isEmpty) {
                  return SliverFillRemaining(
                    child: EmptyState.tasks(
                      onCreateTask: () => context.push(AppRoutes.createTask),
                    ),
                  );
                }

                if (_showTimeline) {
                  return SliverToBoxAdapter(
                    child: TaskTimeline(
                      tasks: tasks,
                      onStatusChanged: (taskId, status) {
                        ref
                            .read(dailyTasksProvider.notifier)
                            .updateTaskStatus(taskId, status);
                      },
                    ),
                  );
                }

                // List view
                return SliverPadding(
                  padding: AppSpacing.paddingHorizontalLg,
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final task = tasks[index];
                        return SwipeActionWrapper(
                          onSwipeLeft: () {
                            ref
                                .read(dailyTasksProvider.notifier)
                                .completeTask(task.id);
                          },
                          child: TaskCard(
                            task: task,
                            animationIndex: index,
                            onStatusChanged: (status) {
                              ref
                                  .read(dailyTasksProvider.notifier)
                                  .updateTaskStatus(task.id, status);
                            },
                          ),
                        );
                      },
                      childCount: tasks.length,
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
                  onRetry: () =>
                      ref.read(dailyTasksProvider.notifier).refresh(),
                ),
              ),
            ),

            // Bottom padding
            const SliverToBoxAdapter(
              child: SizedBox(height: 100),
            ),
          ],
        ),
      ),
      floatingActionButton: const QuickAddFab(),
    );
  }
}

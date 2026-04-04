import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/services/presence_service.dart';
import '../../../core/widgets/alerts_button.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/router/app_router.dart';
import '../../../core/utils/extensions.dart';
import '../../../core/widgets/kuziini_card.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../auth/providers/auth_provider.dart';
import '../../tasks/data/models/task_model.dart';
import '../../tasks/presentation/widgets/task_card.dart';
import '../../tasks/presentation/widgets/user_picker.dart';
import '../../tasks/providers/tasks_provider.dart';
import '../providers/profile_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final profileAsync = ref.watch(profileProvider);
    final statsAsync = ref.watch(taskStatsProvider);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        leading: const AlertsButton(),
        title: Image.asset('assets/images/kuziini_logo.png', height: 32, color: theme.colorScheme.onSurface),
        actions: [
          IconButton(
            onPressed: () => context.push(AppRoutes.settings),
            icon: Icon(PhosphorIcons.gear(PhosphorIconsStyle.regular)),
          ),
        ],
      ),
      body: profileAsync.when(
        data: (profile) {
          if (profile == null) {
            return const Center(child: Text('Not signed in'));
          }

          return SingleChildScrollView(
            padding: AppSpacing.paddingLg,
            child: Column(
              children: [
                // Avatar and name
                Center(
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: () async {
                          final picker = ImagePicker();
                          final image = await picker.pickImage(
                            source: ImageSource.gallery,
                            maxWidth: 512,
                            maxHeight: 512,
                            imageQuality: 80,
                          );
                          if (image != null) {
                            final bytes = await image.readAsBytes();
                            await ref
                                .read(profileActionsProvider)
                                .uploadAvatar(bytes, image.name);
                          }
                        },
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 48,
                              backgroundColor: primaryColor.withValues(alpha: 0.1),
                              backgroundImage: profile.avatarUrl != null
                                  ? NetworkImage(profile.avatarUrl!)
                                  : null,
                              child: profile.avatarUrl == null
                                  ? Text(
                                      profile.initials,
                                      style: TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.w700,
                                        color: primaryColor,
                                      ),
                                    )
                                  : null,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: primaryColor,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: theme.scaffoldBackgroundColor,
                                    width: 2,
                                  ),
                                ),
                                child: Icon(
                                  PhosphorIcons.camera(PhosphorIconsStyle.fill),
                                  size: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(duration: 400.ms).scale(
                            begin: const Offset(0.8, 0.8),
                            duration: 400.ms,
                          ),
                      AppSpacing.vGapMd,
                      Text(
                        profile.displayName,
                        style: theme.textTheme.titleLarge,
                      ).animate().fadeIn(duration: 400.ms, delay: 100.ms),
                      AppSpacing.vGapXs,
                      Text(
                        profile.email,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ).animate().fadeIn(duration: 400.ms, delay: 150.ms),
                      AppSpacing.vGapSm,
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: primaryColor.withValues(alpha: 0.08),
                              borderRadius: AppSpacing.borderRadiusFull,
                            ),
                            child: Text(
                              profile.role.toUpperCase(),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: primaryColor,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                          if (profile.isAdmin) ...[
                            const SizedBox(width: 8),
                            _LiveUsersCount(),
                          ],
                        ],
                      ).animate().fadeIn(duration: 400.ms, delay: 200.ms),
                    ],
                  ),
                ),

                AppSpacing.vGapXxl,

                // Stats
                statsAsync.when(
                  data: (stats) {
                    final overdue = stats['overdue'] ?? 0;
                    return Column(
                      children: [
                        // Overdue badge - prominent at top
                        if (overdue > 0)
                          GestureDetector(
                            onTap: () {
                              ref.read(taskFilterProvider.notifier).state = TaskFilterType.overdue;
                              context.go(AppRoutes.today);
                            },
                            child: Container(
                              width: double.infinity,
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: AppColors.error.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                children: [
                                  Icon(PhosphorIcons.warning(PhosphorIconsStyle.fill), color: AppColors.error, size: 20),
                                  const SizedBox(width: 10),
                                  Text('Overdue Tasks', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.error)),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(color: AppColors.error, borderRadius: BorderRadius.circular(12)),
                                    child: Text('$overdue', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        Row(
                          children: [
                            _StatCard(
                              label: 'Total',
                              value: '${stats['total'] ?? 0}',
                              color: AppColors.info,
                              onTap: () {
                                ref.read(taskFilterProvider.notifier).state = TaskFilterType.all;
                                context.go(AppRoutes.today);
                              },
                            ),
                            AppSpacing.hGapMd,
                            _StatCard(
                              label: 'Done',
                              value: '${stats['done'] ?? 0}',
                              color: AppColors.success,
                              onTap: () {
                                ref.read(taskFilterProvider.notifier).state = TaskFilterType.done;
                                context.go(AppRoutes.today);
                              },
                            ),
                            AppSpacing.hGapMd,
                            _StatCard(
                              label: 'In Progress',
                              value: '${stats['in_progress'] ?? 0}',
                              color: AppColors.warning,
                              onTap: () {
                                ref.read(taskFilterProvider.notifier).state = TaskFilterType.inProgress;
                                context.go(AppRoutes.today);
                              },
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                  loading: () => const LoadingIndicator(size: 24),
                  error: (_, __) => const SizedBox.shrink(),
                ),

                AppSpacing.vGapLg,

                // Weekly stats
                _WeeklyStatsRow(),

                // Admin & Sign Out are in Settings

                const SizedBox(height: 40),
              ],
            ),
          );
        },
        loading: () => const LoadingIndicator(message: 'Loading profile...'),
        error: (error, _) => Center(child: Text('Error: $error')),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
    this.onTap,
  });

  final String label;
  final String value;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Expanded(
      child: KuziiniCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        child: Column(
          children: [
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            AppSpacing.vGapXs,
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileMenuItem extends StatelessWidget {
  const _ProfileMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveColor = color ?? theme.colorScheme.onSurface;

    return InkWell(
      onTap: onTap,
      borderRadius: AppSpacing.borderRadiusMd,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 22, color: effectiveColor),
            AppSpacing.hGapLg,
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: effectiveColor,
                ),
              ),
            ),
            Icon(
              PhosphorIcons.caretRight(PhosphorIconsStyle.regular),
              size: 18,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

class _LiveUsersCount extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onlineIds = ref.watch(onlineUsersProvider);
    final allUsersAsync = ref.watch(activeUsersProvider);
    final count = onlineIds.length;

    if (count == 0) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () {
        final allUsers = allUsersAsync.valueOrNull ?? [];
        final onlineUsers = allUsers.where((u) => onlineIds.contains(u.id)).toList();

        showModalBottomSheet(
          context: context,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          builder: (ctx) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 40, height: 4, margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(color: Theme.of(ctx).dividerColor, borderRadius: BorderRadius.circular(2))),
                Text('Online Now', style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text('$count active on the app', style: TextStyle(fontSize: 12, color: Theme.of(ctx).colorScheme.onSurfaceVariant)),
                const SizedBox(height: 12),
                ...onlineUsers.map((user) => ListTile(
                  leading: CircleAvatar(
                    radius: 18,
                    backgroundColor: Theme.of(ctx).colorScheme.primary.withValues(alpha: 0.1),
                    backgroundImage: user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
                    child: user.avatarUrl == null ? Text(user.displayName[0].toUpperCase(),
                      style: TextStyle(fontWeight: FontWeight.w600, color: Theme.of(ctx).colorScheme.primary)) : null,
                  ),
                  title: Text(user.displayName, style: const TextStyle(fontWeight: FontWeight.w500)),
                  subtitle: Text(user.email, style: TextStyle(fontSize: 12, color: Theme.of(ctx).colorScheme.onSurfaceVariant)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Theme.of(ctx).colorScheme.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(user.role.toUpperCase(), style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Theme.of(ctx).colorScheme.primary)),
                      ),
                      const SizedBox(width: 6),
                      Container(width: 8, height: 8,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.success,
                          boxShadow: [BoxShadow(color: AppColors.success.withValues(alpha: 0.5), blurRadius: 4)])),
                    ],
                  ),
                  dense: true,
                )),
                if (onlineUsers.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text('Only you are online', style: TextStyle(color: Theme.of(ctx).colorScheme.onSurfaceVariant)),
                  ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 7, height: 7,
              decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.success,
                boxShadow: [BoxShadow(color: AppColors.success.withValues(alpha: 0.5), blurRadius: 4)]),
            ),
            const SizedBox(width: 5),
            Text('$count online', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.success)),
          ],
        ),
      ),
    );
  }
}

class _WeeklyStatsRow extends ConsumerStatefulWidget {
  @override
  ConsumerState<_WeeklyStatsRow> createState() => _WeeklyStatsRowState();
}

class _WeeklyStatsRowState extends ConsumerState<_WeeklyStatsRow> {
  int _weekOffset = 0;

  DateTime get _weekStart {
    final now = DateTime.now();
    final thisWeekStart = now.subtract(Duration(days: now.weekday - 1));
    return DateTime(thisWeekStart.year, thisWeekStart.month, thisWeekStart.day)
        .add(Duration(days: _weekOffset * 7));
  }

  DateTime get _weekEnd => _weekStart.add(const Duration(days: 6));

  int get _weekNumber {
    final jan1 = DateTime(_weekStart.year, 1, 1);
    return ((_weekStart.difference(jan1).inDays + jan1.weekday) / 7).ceil();
  }

  String get _weekLabel {
    if (_weekOffset == 0) return 'This Week';
    if (_weekOffset == -1) return 'Last Week';
    if (_weekOffset == 1) return 'Next Week';
    return 'W$_weekNumber';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final repo = ref.watch(taskRepositoryProvider);
    final days = List.generate(7, (i) => _weekStart.add(Duration(days: i)));

    return FutureBuilder<List<TaskModel>>(
      future: repo.fetchTasks(fromDate: _weekStart, toDate: _weekEnd, limit: 500),
      builder: (context, snapshot) {
        final tasks = snapshot.data?.where((t) => t.status != TaskStatus.archived).toList() ?? [];
        final total = tasks.length;
        final done = tasks.where((t) => t.status == TaskStatus.done).length;
        final inProgress = tasks.where((t) => t.status == TaskStatus.in_progress).length;
        final todo = tasks.where((t) => t.status == TaskStatus.todo).length;

        return GestureDetector(
          onHorizontalDragEnd: (details) {
            if (details.primaryVelocity != null) {
              if (details.primaryVelocity! < -100) {
                setState(() => _weekOffset++);
              } else if (details.primaryVelocity! > 100) {
                setState(() => _weekOffset--);
              }
            }
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Week header with swipe hint
              Row(
                children: [
                  GestureDetector(
                    onTap: _weekOffset != 0 ? () => setState(() => _weekOffset = 0) : null,
                    child: Text(_weekLabel, style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _weekOffset == 0 ? primaryColor : theme.colorScheme.onSurfaceVariant,
                    )),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text('W$_weekNumber', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: primaryColor)),
                  ),
                  const Spacer(),
                  Text('${_weekStart.day}/${_weekStart.month} - ${_weekEnd.day}/${_weekEnd.month}',
                    style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurfaceVariant)),
                  const SizedBox(width: 4),
                  Icon(PhosphorIcons.arrowsLeftRight(PhosphorIconsStyle.regular), size: 12, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4)),
                ],
              ),
              const SizedBox(height: 8),
              // Day buttons - click to add task
              Row(
                children: days.map((day) {
                  final isToday = day.year == DateTime.now().year && day.month == DateTime.now().month && day.day == DateTime.now().day;
                  final dayTasks = tasks.where((t) => t.dueDate != null && t.dueDate!.day == day.day && t.dueDate!.month == day.month).length;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        final params = <String, String>{'date': day.toIso8601String().split('T').first};
                        context.push(Uri(path: '/create-task', queryParameters: params).toString());
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(
                          color: isToday ? primaryColor : null,
                          borderRadius: BorderRadius.circular(6),
                          border: isToday ? null : Border.all(color: theme.dividerColor.withValues(alpha: 0.2)),
                        ),
                        child: Column(
                          children: [
                            Text(['L', 'M', 'M', 'J', 'V', 'S', 'D'][day.weekday - 1],
                              style: TextStyle(fontSize: 8, fontWeight: FontWeight.w600, color: isToday ? Colors.white70 : theme.colorScheme.onSurfaceVariant)),
                            Text('${day.day}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: isToday ? Colors.white : null)),
                            if (dayTasks > 0)
                              Container(
                                width: 4, height: 4, margin: const EdgeInsets.only(top: 1),
                                decoration: BoxDecoration(shape: BoxShape.circle, color: isToday ? Colors.white70 : primaryColor),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
              // Stats chips - clickable
              Row(
                children: [
                  _WeekStatChip(label: 'Total', value: total, color: AppColors.info,
                    onTap: () => _showWeekTasks(context, 'All Tasks', tasks)),
                  const SizedBox(width: 6),
                  _WeekStatChip(label: 'Done', value: done, color: AppColors.success,
                    onTap: () => _showWeekTasks(context, 'Done', tasks.where((t) => t.isCompleted).toList())),
                  const SizedBox(width: 6),
                  _WeekStatChip(label: 'In Progress', value: inProgress, color: AppColors.warning,
                    onTap: () => _showWeekTasks(context, 'In Progress', tasks.where((t) => t.status == TaskStatus.in_progress).toList())),
                  const SizedBox(width: 6),
                  _WeekStatChip(label: 'To Do', value: todo, color: primaryColor,
                    onTap: () => _showWeekTasks(context, 'To Do', tasks.where((t) => t.status == TaskStatus.todo).toList())),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showWeekTasks(BuildContext context, String title, List<TaskModel> tasks) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (ctx, scrollController) => Column(
          children: [
            Container(width: 40, height: 4, margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(color: theme.dividerColor, borderRadius: BorderRadius.circular(2))),
            Text('$title - $_weekLabel (W$_weekNumber)', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
            Text('${tasks.length} tasks', style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: 8),
            Expanded(
              child: tasks.isEmpty
                  ? Center(child: Text('No tasks', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)))
                  : ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: tasks.length,
                      itemBuilder: (context, index) => TaskCard(task: tasks[index], animationIndex: index),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeekStatChip extends StatelessWidget {
  const _WeekStatChip({required this.label, required this.value, required this.color, this.onTap});
  final String label;
  final int value;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border(left: BorderSide(color: color, width: 3)),
            color: color.withValues(alpha: 0.06),
          ),
          child: Column(
            children: [
              Text('$value', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: color)),
              const SizedBox(height: 2),
              Text(label, style: TextStyle(fontSize: 9, color: Theme.of(context).colorScheme.onSurfaceVariant)),
            ],
          ),
        ),
      ),
    );
  }
}

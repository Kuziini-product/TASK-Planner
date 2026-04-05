import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../data/models/task_model.dart';
import '../../providers/leave_provider.dart';
import '../../providers/tasks_provider.dart';
import 'user_picker.dart';

class TaskFilters extends ConsumerWidget {
  const TaskFilters({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentUserProfileProvider).valueOrNull;
    final isAdminOrManager = profile?.isAdmin == true || profile?.isManager == true;

    return Column(
      children: [
        // Team row (admin/manager only)
        if (isAdminOrManager) _TeamFilterRow(),

        // Standard filters row + Concediu button
        Row(
          children: [
            Expanded(child: _StandardFilterRow()),
            if (isAdminOrManager)
              _ConcediuButton(),
          ],
        ),
      ],
    );
  }
}

// ── Team Filter Row (Admin/Manager) ──

class _TeamFilterRow extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final selectedUser = ref.watch(selectedTeamUserProvider);
    final usersAsync = ref.watch(activeUsersProvider);
    final profile = ref.watch(currentUserProfileProvider).valueOrNull;
    final isAdmin = profile?.isAdmin == true;
    final isManager = profile?.isManager == true;
    final permittedIds = ref.watch(managerPermittedUsersProvider).valueOrNull ?? [];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          // "Me" button
          _TeamChip(
            label: 'Me',
            isSelected: selectedUser == null,
            onTap: () => ref.read(selectedTeamUserProvider.notifier).state = null,
          ),
          const SizedBox(width: 6),

          // "All Team" button (admin sees all, manager sees permitted)
          _TeamChip(
            label: isAdmin ? 'All Team' : 'Echipa mea',
            icon: PhosphorIcons.users(PhosphorIconsStyle.regular),
            isSelected: selectedUser == 'all',
            onTap: () => ref.read(selectedTeamUserProvider.notifier).state =
                selectedUser == 'all' ? null : 'all',
          ),
          const SizedBox(width: 6),

          // Individual team members (filtered by permissions for manager)
          ...usersAsync.when(
            data: (users) {
              final currentUserId = profile?.id;
              var otherUsers = users.where((u) => u.id != currentUserId).toList();

              // Manager: show only permitted users
              if (isManager && !isAdmin && permittedIds.isNotEmpty) {
                otherUsers = otherUsers.where((u) => permittedIds.contains(u.id)).toList();
              }

              return otherUsers.map((user) => Padding(
                padding: const EdgeInsets.only(right: 6),
                child: _TeamChip(
                  label: user.displayName.split(' ').first,
                  isSelected: selectedUser == user.id,
                  onTap: () => ref.read(selectedTeamUserProvider.notifier).state =
                      selectedUser == user.id ? null : user.id,
                ),
              ));
            },
            loading: () => [const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))],
            error: (_, __) => <Widget>[],
          ),
        ],
      ),
    );
  }
}

class _TeamChip extends StatelessWidget {
  const _TeamChip({required this.label, required this.isSelected, required this.onTap, this.icon});

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? primaryColor : theme.dividerColor.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: isSelected ? Colors.white : theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? Colors.white : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Standard Filter Row ──

class _StandardFilterRow extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentFilter = ref.watch(taskFilterProvider);
    final priorityFilter = ref.watch(taskPriorityFilterProvider);

    final isMoreActive = currentFilter == TaskFilterType.assignedToMe ||
        currentFilter == TaskFilterType.overdue ||
        currentFilter == TaskFilterType.done ||
        currentFilter == TaskFilterType.inProgress ||
        priorityFilter != null;

    // Build combined label
    final parts = <String>[];
    switch (currentFilter) {
      case TaskFilterType.assignedToMe: parts.add('Assigned');
      case TaskFilterType.overdue: parts.add('Overdue');
      case TaskFilterType.done: parts.add('Done');
      case TaskFilterType.inProgress: parts.add('In Progress');
      default: break;
    }
    if (priorityFilter != null) parts.add(priorityFilter.label);
    final moreLabel = parts.isEmpty ? 'More' : parts.join(' + ');

    return Padding(
      padding: AppSpacing.paddingHorizontalLg,
      child: Row(
        children: [
          _FilterChip(
            label: 'All',
            isSelected: currentFilter == TaskFilterType.all,
            onTap: () {
              ref.read(taskFilterProvider.notifier).state = TaskFilterType.all;
            },
          ),
          AppSpacing.hGapSm,
          _FilterChip(
            label: 'Azi',
            isSelected: currentFilter == TaskFilterType.today,
            onTap: () {
              ref.read(taskFilterProvider.notifier).state = TaskFilterType.today;
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
  const _MoreFilterChip({required this.label, required this.isActive, required this.currentFilter, this.priorityFilter});

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
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          builder: (ctx) => _MoreFiltersSheet(
            currentFilter: currentFilter,
            priorityFilter: priorityFilter,
            onFilterChanged: (filter) {
              // Toggle: tap same = deselect
              ref.read(taskFilterProvider.notifier).state =
                  currentFilter == filter ? TaskFilterType.all : filter;
              Navigator.pop(ctx);
            },
            onPriorityChanged: (priority) {
              // Toggle: tap same = deselect
              ref.read(taskPriorityFilterProvider.notifier).state =
                  priorityFilter == priority ? null : priority;
              Navigator.pop(ctx);
            },
            onClear: () {
              ref.read(taskFilterProvider.notifier).state = TaskFilterType.all;
              ref.read(taskPriorityFilterProvider.notifier).state = null;
              ref.read(taskStatusFilterProvider.notifier).state = null;
              Navigator.pop(ctx);
            },
          ),
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isActive ? primaryColor.withValues(alpha: 0.12) : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: AppSpacing.borderRadiusFull,
          border: Border.all(color: isActive ? primaryColor.withValues(alpha: 0.5) : Colors.transparent),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: theme.textTheme.labelMedium?.copyWith(color: isActive ? primaryColor : theme.colorScheme.onSurfaceVariant, fontWeight: isActive ? FontWeight.w600 : FontWeight.w500)),
            const SizedBox(width: 4),
            Icon(PhosphorIcons.caretDown(PhosphorIconsStyle.bold), size: 12, color: isActive ? primaryColor : theme.colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

class _MoreFiltersSheet extends StatelessWidget {
  const _MoreFiltersSheet({required this.currentFilter, this.priorityFilter, required this.onFilterChanged, required this.onPriorityChanged, required this.onClear});

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
            Container(width: 40, height: 4, decoration: BoxDecoration(color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            Text('Filter Tasks', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('STATUS', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.w700, letterSpacing: 1)),
                const SizedBox(height: 8),
                _FilterOption(label: 'Assigned to Me', isSelected: currentFilter == TaskFilterType.assignedToMe, onTap: () => onFilterChanged(TaskFilterType.assignedToMe)),
                _FilterOption(label: 'In Progress', color: AppColors.warning, isSelected: currentFilter == TaskFilterType.inProgress, onTap: () => onFilterChanged(TaskFilterType.inProgress)),
                _FilterOption(label: 'Done', color: AppColors.success, isSelected: currentFilter == TaskFilterType.done, onTap: () => onFilterChanged(TaskFilterType.done)),
                _FilterOption(label: 'Overdue', color: AppColors.error, isSelected: currentFilter == TaskFilterType.overdue, onTap: () => onFilterChanged(TaskFilterType.overdue)),
              ]),
            ),
            const SizedBox(height: 12), const Divider(), const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('PRIORITY', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.w700, letterSpacing: 1)),
                const SizedBox(height: 8),
                _FilterOption(label: 'Urgent', color: AppColors.priorityUrgent, isSelected: priorityFilter == TaskPriority.urgent, onTap: () => onPriorityChanged(TaskPriority.urgent)),
                _FilterOption(label: 'High', color: AppColors.priorityHigh, isSelected: priorityFilter == TaskPriority.high, onTap: () => onPriorityChanged(TaskPriority.high)),
                _FilterOption(label: 'Medium', color: AppColors.priorityMedium, isSelected: priorityFilter == TaskPriority.medium, onTap: () => onPriorityChanged(TaskPriority.medium)),
                _FilterOption(label: 'Low', color: AppColors.priorityLow, isSelected: priorityFilter == TaskPriority.low, onTap: () => onPriorityChanged(TaskPriority.low)),
              ]),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: onClear,
                  style: OutlinedButton.styleFrom(foregroundColor: theme.colorScheme.onSurfaceVariant, side: BorderSide(color: theme.dividerColor), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
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
  const _FilterOption({required this.label, required this.isSelected, required this.onTap, this.color});

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
            Container(width: 10, height: 10, decoration: BoxDecoration(shape: BoxShape.circle, color: effectiveColor)),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400, color: isSelected ? effectiveColor : null))),
            if (isSelected) Icon(PhosphorIcons.check(PhosphorIconsStyle.bold), size: 18, color: effectiveColor),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.isSelected, required this.onTap});

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
          color: isSelected ? chipColor.withValues(alpha: 0.12) : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: AppSpacing.borderRadiusFull,
          border: Border.all(color: isSelected ? chipColor.withValues(alpha: 0.5) : Colors.transparent),
        ),
        child: Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(color: isSelected ? chipColor : theme.colorScheme.onSurfaceVariant, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500),
        ),
      ),
    );
  }
}

// ── Concediu Button (Admin) ──

class _ConcediuButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: GestureDetector(
        onTap: () => _showLeaveDialog(context, ref),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.1),
            borderRadius: AppSpacing.borderRadiusFull,
            border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(PhosphorIcons.sun(PhosphorIconsStyle.fill), size: 14, color: AppColors.success),
              const SizedBox(width: 4),
              Text('Concediu', style: TextStyle(fontSize: 11,
                fontWeight: FontWeight.w600, color: AppColors.success)),
            ],
          ),
        ),
      ),
    );
  }

  void _showLeaveDialog(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    String? selectedUserId;
    String? selectedUserName;
    DateTime startDate = DateTime.now();
    DateTime endDate = DateTime.now().add(const Duration(days: 1));
    final reasonCtrl = TextEditingController();
    bool saving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => SafeArea(
          child: Padding(
            padding: EdgeInsets.only(left: 20, right: 20, top: 16, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4,
                  decoration: BoxDecoration(color: theme.dividerColor, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(PhosphorIcons.sun(PhosphorIconsStyle.fill), color: AppColors.success),
                    const SizedBox(width: 8),
                    Text('Adaugă Concediu / Liber', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 16),

                // Select user
                InkWell(
                  onTap: () async {
                    final result = await showUserPicker(ctx);
                    if (result != null) {
                      setSheetState(() {
                        selectedUserId = result.userId;
                        selectedUserName = result.userName;
                      });
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: selectedUserId != null ? AppColors.success : theme.dividerColor),
                      color: selectedUserId != null ? AppColors.success.withValues(alpha: 0.05) : null,
                    ),
                    child: Row(
                      children: [
                        Icon(PhosphorIcons.user(PhosphorIconsStyle.regular), size: 20,
                          color: selectedUserId != null ? AppColors.success : theme.colorScheme.onSurfaceVariant),
                        const SizedBox(width: 10),
                        Expanded(child: Text(
                          selectedUserName ?? 'Selectează persoana',
                          style: TextStyle(
                            fontWeight: selectedUserId != null ? FontWeight.w600 : FontWeight.w400,
                            color: selectedUserId != null ? AppColors.success : theme.colorScheme.onSurfaceVariant,
                          ),
                        )),
                        Icon(Icons.chevron_right, size: 20, color: theme.colorScheme.onSurfaceVariant),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Date range
                Row(
                  children: [
                    Expanded(child: InkWell(
                      onTap: () async {
                        final d = await showDatePicker(context: ctx, initialDate: startDate,
                          firstDate: DateTime.now().subtract(const Duration(days: 30)),
                          lastDate: DateTime.now().add(const Duration(days: 365)));
                        if (d != null) setSheetState(() {
                          startDate = d;
                          if (endDate.isBefore(startDate)) endDate = startDate;
                        });
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: theme.dividerColor),
                        ),
                        child: Row(children: [
                          Icon(PhosphorIcons.calendarBlank(PhosphorIconsStyle.regular), size: 18, color: theme.colorScheme.primary),
                          const SizedBox(width: 8),
                          Text('${startDate.day}/${startDate.month}/${startDate.year}', style: const TextStyle(fontWeight: FontWeight.w500)),
                        ]),
                      ),
                    )),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Icon(Icons.arrow_forward, size: 16, color: theme.colorScheme.onSurfaceVariant),
                    ),
                    Expanded(child: InkWell(
                      onTap: () async {
                        final d = await showDatePicker(context: ctx, initialDate: endDate,
                          firstDate: startDate,
                          lastDate: DateTime.now().add(const Duration(days: 365)));
                        if (d != null) setSheetState(() => endDate = d);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: theme.dividerColor),
                        ),
                        child: Row(children: [
                          Icon(PhosphorIcons.calendarBlank(PhosphorIconsStyle.regular), size: 18, color: theme.colorScheme.primary),
                          const SizedBox(width: 8),
                          Text('${endDate.day}/${endDate.month}/${endDate.year}', style: const TextStyle(fontWeight: FontWeight.w500)),
                        ]),
                      ),
                    )),
                  ],
                ),
                const SizedBox(height: 8),
                Center(child: Text(
                  '${endDate.difference(startDate).inDays + 1} zile',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.success),
                )),
                const SizedBox(height: 12),

                // Reason
                TextField(
                  controller: reasonCtrl,
                  decoration: InputDecoration(
                    labelText: 'Motiv (opțional)',
                    hintText: 'Ex: Concediu de odihnă',
                    prefixIcon: const Icon(Icons.note_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true, isDense: true,
                  ),
                ),
                const SizedBox(height: 16),

                // Save button
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: selectedUserId == null || saving ? null : () async {
                      setSheetState(() => saving = true);
                      try {
                        final currentUserId = ref.read(currentUserProfileProvider).valueOrNull?.id ?? '';
                        await addUserLeave(
                          userId: selectedUserId!,
                          startDate: startDate,
                          endDate: endDate,
                          reason: reasonCtrl.text.trim().isEmpty ? 'Concediu' : reasonCtrl.text.trim(),
                          createdBy: currentUserId,
                        );
                        // Also create a task so it shows in the daily list
                        final repo = ref.read(taskRepositoryProvider);
                        await repo.createTask(TaskModel(
                          id: '',
                          title: 'Concediu - ${selectedUserName ?? 'User'}',
                          description: reasonCtrl.text.trim().isEmpty ? null : reasonCtrl.text.trim(),
                          priority: TaskPriority.none,
                          createdBy: currentUserId,
                          assigneeId: selectedUserId,
                          assigneeName: selectedUserName,
                          dueDate: startDate,
                          endDate: endDate,
                        ));
                        ref.invalidate(dailyTasksProvider);
                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Concediu setat pentru ${selectedUserName ?? 'user'}')),
                          );
                        }
                      } catch (e) {
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Eroare: $e')),
                          );
                        }
                      } finally {
                        if (ctx.mounted) setSheetState(() => saving = false);
                      }
                    },
                    icon: saving
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.check, size: 18),
                    label: Text(saving ? 'Se salvează...' : 'Setează Concediu'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.success,
                      disabledBackgroundColor: AppColors.success.withValues(alpha: 0.3),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
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

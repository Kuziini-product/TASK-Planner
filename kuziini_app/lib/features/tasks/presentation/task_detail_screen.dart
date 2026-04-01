import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/extensions.dart';
import '../../../core/widgets/kuziini_app_bar.dart';
import '../../../core/widgets/kuziini_button.dart';
import '../../../core/widgets/kuziini_text_field.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/widgets/error_view.dart';
import '../../auth/providers/auth_provider.dart';
import '../../notifications/data/notification_repository.dart';
import '../data/models/task_model.dart';
import '../data/models/checklist_item.dart';
import '../data/models/task_comment.dart';
import '../providers/tasks_provider.dart';
import 'create_task_screen.dart';
import 'widgets/attachment_section.dart';
import 'widgets/comment_section.dart';
import 'widgets/priority_badge.dart';
import 'widgets/share_task_dialog.dart';
import 'widgets/status_chip.dart';
import 'widgets/user_picker.dart';

class TaskDetailScreen extends ConsumerStatefulWidget {
  const TaskDetailScreen({super.key, required this.taskId});

  final String taskId;

  @override
  ConsumerState<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends ConsumerState<TaskDetailScreen> {
  final _checklistController = TextEditingController();

  @override
  void dispose() {
    _checklistController.dispose();
    super.dispose();
  }

  Future<void> _addChecklistItem() async {
    final title = _checklistController.text.trim();
    if (title.isEmpty) return;

    try {
      final repo = ref.read(taskRepositoryProvider);
      await repo.addChecklistItem(taskId: widget.taskId, title: title);
      _checklistController.clear();
      ref.invalidate(taskChecklistProvider(widget.taskId));
    } catch (e) {
      if (mounted) {
        context.showSnackBar('Failed to add checklist item', isError: true);
      }
    }
  }

  Future<void> _handleEdit() async {
    final profile = ref.read(currentUserProfileProvider).valueOrNull;
    final task = ref.read(taskDetailProvider(widget.taskId)).valueOrNull;
    if (profile == null || task == null) return;

    if (profile.isAdmin) {
      final edited = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => CreateTaskScreen(existingTask: task),
        ),
      );
      if (edited == true) {
        ref.invalidate(taskDetailProvider(widget.taskId));
        ref.invalidate(dailyTasksProvider);
      }
    } else {
      final repo = ref.read(taskRepositoryProvider);
      final hasPermission = await repo.hasEditPermission(widget.taskId, profile.id);

      if (hasPermission) {
        final edited = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (_) => CreateTaskScreen(existingTask: task),
          ),
        );
        if (edited == true) {
          await repo.consumeEditPermission(widget.taskId, profile.id);
          ref.invalidate(taskDetailProvider(widget.taskId));
          ref.invalidate(dailyTasksProvider);
        }
      } else {
        final notifRepo = NotificationRepository();
        final adminIds = await notifRepo.fetchAdminUserIds();
        for (final adminId in adminIds) {
          await notifRepo.createNotification(
            userId: adminId,
            title: 'Edit Request',
            body: '${profile.displayName} requests permission to edit "${task.title}"',
            type: 'edit_request',
            data: {
              'task_id': widget.taskId,
              'requester_id': profile.id,
              'requester_name': profile.displayName,
            },
          );
        }
        if (mounted) {
          context.showSnackBar('Edit request sent to admin for approval');
        }
      }
    }
  }

  Future<void> _showRelocateDialog() async {
    final task = ref.read(taskDetailProvider(widget.taskId)).valueOrNull;
    if (task == null) return;

    DateTime? newDate = task.dueDate;
    DateTime? newEndDate = task.endDate;
    TimeOfDay? newStartTime = task.startTime != null ? TimeOfDay.fromDateTime(task.startTime!.toLocal()) : null;
    final reasonController = TextEditingController();

    final confirmed = await showModalBottomSheet<bool>(
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
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Theme.of(ctx).dividerColor, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 16),
                Text('Relocate Task', style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 16),
                // Reason (mandatory)
                TextField(
                  controller: reasonController,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'Reason for relocation *',
                    hintText: 'Why is this task being moved?',
                    prefixIcon: Icon(PhosphorIcons.notepad(PhosphorIconsStyle.regular)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                  ),
                  maxLines: 2,
                  textCapitalization: TextCapitalization.sentences,
                  onChanged: (_) => setSheetState(() {}),
                ),
                const SizedBox(height: 12),
                // Date
                ListTile(
                  leading: Icon(PhosphorIcons.calendar(PhosphorIconsStyle.regular)),
                  title: Text(newDate != null ? '${newDate!.day}/${newDate!.month}/${newDate!.year}' : 'Select date'),
                  onTap: () async {
                    final d = await showDatePicker(context: ctx, initialDate: newDate ?? DateTime.now(), firstDate: DateTime.now().subtract(const Duration(days: 365)), lastDate: DateTime.now().add(const Duration(days: 365 * 2)));
                    if (d != null) setSheetState(() => newDate = d);
                  },
                  dense: true,
                ),
                // End date
                ListTile(
                  leading: Icon(PhosphorIcons.calendarDots(PhosphorIconsStyle.regular)),
                  title: Text(newEndDate != null ? 'End: ${newEndDate!.day}/${newEndDate!.month}/${newEndDate!.year}' : 'Add end date (multi-day)'),
                  trailing: newEndDate != null ? IconButton(icon: const Icon(Icons.close, size: 16), onPressed: () => setSheetState(() => newEndDate = null)) : null,
                  onTap: () async {
                    final d = await showDatePicker(context: ctx, initialDate: newEndDate ?? newDate ?? DateTime.now(), firstDate: newDate ?? DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365 * 2)));
                    if (d != null) setSheetState(() => newEndDate = d);
                  },
                  dense: true,
                ),
                // Time
                ListTile(
                  leading: Icon(PhosphorIcons.clock(PhosphorIconsStyle.regular)),
                  title: Text(newStartTime != null ? 'Time: ${newStartTime!.format(ctx)}' : 'Select time'),
                  trailing: newStartTime != null ? IconButton(icon: const Icon(Icons.close, size: 16), onPressed: () => setSheetState(() => newStartTime = null)) : null,
                  onTap: () async {
                    final t = await showTimePicker(context: ctx, initialTime: newStartTime ?? TimeOfDay.now());
                    if (t != null) setSheetState(() => newStartTime = t);
                  },
                  dense: true,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: reasonController.text.trim().isEmpty ? null : () => Navigator.pop(ctx, true),
                    child: const Text('Relocate'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (confirmed == true && mounted) {
      try {
        final repo = ref.read(taskRepositoryProvider);
        final userId = SupabaseService.instance.currentUserId!;
        final profile = ref.read(currentUserProfileProvider).valueOrNull;
        final userName = profile?.displayName ?? 'Unknown';
        final reason = reasonController.text.trim();

        final dateOnly = newDate != null ? '${newDate!.year}-${newDate!.month.toString().padLeft(2, '0')}-${newDate!.day.toString().padLeft(2, '0')}' : null;
        final endDateOnly = newEndDate != null ? '${newEndDate!.year}-${newEndDate!.month.toString().padLeft(2, '0')}-${newEndDate!.day.toString().padLeft(2, '0')}' : null;

        final updateData = <String, dynamic>{
          'due_date': dateOnly,
          'end_date': endDateOnly,
        };

        if (newStartTime != null && newDate != null) {
          final st = DateTime(newDate!.year, newDate!.month, newDate!.day, newStartTime!.hour, newStartTime!.minute);
          updateData['start_time'] = st.toUtc().toIso8601String();
        }

        await repo.updateTask(widget.taskId, updateData);

        // Add relocation comment
        final oldDateStr = task.dueDate != null ? '${task.dueDate!.day}/${task.dueDate!.month}/${task.dueDate!.year}' : 'none';
        final newDateDisplay = newDate != null ? '${newDate!.day}/${newDate!.month}/${newDate!.year}' : 'none';
        final comment = '\u{1F4CD} Relocated by $userName\n'
            'From: $oldDateStr \u{2192} To: $newDateDisplay\n'
            'Reason: $reason';
        await repo.addComment(taskId: widget.taskId, userId: userId, content: comment);

        ref.invalidate(taskDetailProvider(widget.taskId));
        ref.invalidate(taskCommentsProvider(widget.taskId));
        ref.invalidate(dailyTasksProvider);
        if (mounted) context.showSnackBar('Task relocated');
      } catch (e) {
        if (mounted) context.showSnackBar('Failed to relocate', isError: true);
      }
    }
  }

  Future<void> _updateStatus(TaskStatus status) async {
    try {
      final repo = ref.read(taskRepositoryProvider);
      await repo.updateTaskStatus(widget.taskId, status);
      ref.invalidate(taskDetailProvider(widget.taskId));
      ref.invalidate(dailyTasksProvider);
    } catch (e) {
      if (mounted) {
        context.showSnackBar('Failed to update status', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final taskAsync = ref.watch(taskDetailProvider(widget.taskId));
    final checklistAsync = ref.watch(taskChecklistProvider(widget.taskId));

    return Scaffold(
      appBar: AppBar(
        leading: TextButton.icon(
          onPressed: () {
            ref.invalidate(dailyTasksProvider);
            Navigator.of(context).pop();
          },
          icon: Icon(PhosphorIcons.arrowLeft(PhosphorIconsStyle.bold), size: 18),
          label: const Text('Back', style: TextStyle(fontSize: 13)),
          style: TextButton.styleFrom(padding: EdgeInsets.zero),
        ),
        leadingWidth: 90,
        title: const Text('Task Detail'),
        actions: [
          // Relocate button
          IconButton(
            onPressed: () => _showRelocateDialog(),
            icon: Icon(PhosphorIcons.calendarPlus(PhosphorIconsStyle.regular)),
            tooltip: 'Relocate',
          ),
          // Edit button
          IconButton(
            onPressed: () => _handleEdit(),
            icon: Icon(PhosphorIcons.pencilSimple(PhosphorIconsStyle.regular)),
            tooltip: 'Edit',
          ),
          IconButton(
            onPressed: () {
              final task = ref.read(taskDetailProvider(widget.taskId)).valueOrNull;
              if (task != null) {
                final comments = ref.read(taskCommentsProvider(widget.taskId)).valueOrNull ?? [];
                showShareTaskDialog(context, task, comments);
              }
            },
            icon: Icon(PhosphorIcons.shareFat(PhosphorIconsStyle.regular)),
          ),
          PopupMenuButton<String>(
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'edit', child: Text('Edit')),
              const PopupMenuItem(value: 'reassign', child: Text('Reassign')),
              const PopupMenuItem(value: 'duplicate', child: Text('Duplicate')),
              const PopupMenuItem(
                value: 'delete',
                child: Text('Delete', style: TextStyle(color: AppColors.error)),
              ),
            ],
            onSelected: (value) async {
              if (value == 'edit') {
                _handleEdit();
              } else if (value == 'reassign') {
                final result = await showUserPicker(context);
                if (result != null && mounted) {
                  try {
                    await ref
                        .read(taskRepositoryProvider)
                        .reassignTask(widget.taskId, result.userId);
                    ref.invalidate(taskDetailProvider(widget.taskId));
                    ref.invalidate(taskAssigneesProvider(widget.taskId));
                    ref.invalidate(dailyTasksProvider);
                    if (mounted) {
                      context.showSnackBar(
                          'Task reassigned to ${result.userName}');
                    }
                  } catch (e) {
                    if (mounted) {
                      context.showSnackBar('Failed to reassign task',
                          isError: true);
                    }
                  }
                }
              } else if (value == 'delete') {
                final confirmed = await context.showConfirmDialog(
                  title: 'Delete Task',
                  message: 'Are you sure you want to delete this task?',
                  confirmLabel: 'Delete',
                  isDestructive: true,
                );
                if (confirmed == true && mounted) {
                  try {
                    await ref
                        .read(taskRepositoryProvider)
                        .deleteTask(widget.taskId);
                    ref.invalidate(dailyTasksProvider);
                    if (mounted) Navigator.of(context).pop();
                  } catch (e) {
                    if (mounted) {
                      context.showSnackBar('Failed to delete task',
                          isError: true);
                    }
                  }
                }
              }
            },
          ),
        ],
      ),
      body: taskAsync.when(
        data: (task) => _buildContent(
            context, task, checklistAsync),
        loading: () => const LoadingIndicator(message: 'Loading task...'),
        error: (error, _) => ErrorView(
          message: error.toString(),
          onRetry: () =>
              ref.invalidate(taskDetailProvider(widget.taskId)),
        ),
      ),
      bottomNavigationBar: taskAsync.whenOrNull(
        data: (task) => SafeArea(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: theme.cardColor,
              border: Border(
                top: BorderSide(color: theme.dividerColor),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: KuziiniButton(
                    label: task.isCompleted ? 'Reopen' : 'Mark Complete',
                    onPressed: () => _updateStatus(
                      task.isCompleted ? TaskStatus.todo : TaskStatus.done,
                    ),
                    icon: task.isCompleted
                        ? PhosphorIcons.arrowCounterClockwise(
                            PhosphorIconsStyle.bold)
                        : PhosphorIcons.check(PhosphorIconsStyle.bold),
                    variant: task.isCompleted
                        ? KuziiniButtonVariant.secondary
                        : KuziiniButtonVariant.primary,
                    height: 44,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    TaskModel task,
    AsyncValue<List<ChecklistItem>> checklistAsync,
  ) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return SingleChildScrollView(
      padding: AppSpacing.paddingLg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: TaskStatus.values
                  .map(
                    (status) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: StatusChip(
                        status: status,
                        isSelected: task.status == status,
                        onTap: () => _updateStatus(status),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ).animate().fadeIn(duration: 300.ms),

          AppSpacing.vGapXl,

          // Title
          Text(
            task.title,
            style: theme.textTheme.headlineSmall?.copyWith(
              decoration:
                  task.isCompleted ? TextDecoration.lineThrough : null,
            ),
          ).animate().fadeIn(duration: 300.ms, delay: 100.ms),

          // Description
          if (task.description != null && task.description!.isNotEmpty) ...[
            AppSpacing.vGapMd,
            Text(
              task.description!,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],

          AppSpacing.vGapXl,

          // Details section
          _DetailRow(
            icon: PhosphorIcons.flag(PhosphorIconsStyle.regular),
            label: 'Priority',
            child: PriorityBadge(priority: task.priority),
          ),

          if (task.dueDate != null)
            _DetailRow(
              icon: PhosphorIcons.calendar(PhosphorIconsStyle.regular),
              label: 'Due Date',
              child: Text(
                AppDateUtils.formatFull(task.dueDate!),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: task.isOverdue ? AppColors.error : null,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

          if (task.startTime != null)
            _DetailRow(
              icon: PhosphorIcons.clock(PhosphorIconsStyle.regular),
              label: 'Time',
              child: Text(
                task.endTime != null
                    ? '${AppDateUtils.formatTime(task.startTime!)} - ${AppDateUtils.formatTime(task.endTime!)}'
                    : AppDateUtils.formatTime(task.startTime!),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

          if (task.hasLocation)
            _DetailRow(
              icon: PhosphorIcons.mapPin(PhosphorIconsStyle.regular),
              label: 'Location',
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        final url = task.locationMapUrl;
                        if (url != null) {
                          launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                        }
                      },
                      child: Text(
                        task.locationDisplay,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: primaryColor,
                          decoration: TextDecoration.underline,
                          decorationColor: primaryColor,
                        ),
                      ),
                    ),
                  ),
                  if (task.locationMapUrl != null)
                    TextButton.icon(
                      onPressed: () {
                        final dirUrl = task.locationLat != null && task.locationLng != null
                            ? 'https://www.google.com/maps/dir/?api=1&destination=${task.locationLat},${task.locationLng}'
                            : task.locationAddress != null
                                ? 'https://www.google.com/maps/dir/?api=1&destination=${Uri.encodeComponent(task.locationAddress!)}'
                                : task.locationMapUrl!;
                        launchUrl(Uri.parse(dirUrl), mode: LaunchMode.externalApplication);
                      },
                      icon: Icon(PhosphorIcons.navigationArrow(PhosphorIconsStyle.regular), size: 14),
                      label: const Text('Navigate'),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        visualDensity: VisualDensity.compact,
                        textStyle: theme.textTheme.labelSmall,
                      ),
                    ),
                ],
              ),
            ),

          _DetailRow(
            icon: PhosphorIcons.user(PhosphorIconsStyle.regular),
            label: 'Assignee',
            child: task.isAssigned
                ? Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor:
                            theme.colorScheme.primary.withValues(alpha: 0.1),
                        child: Text(
                          (task.assigneeName ?? 'U')[0].toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                      AppSpacing.hGapSm,
                      Expanded(
                        child: Text(
                          task.assigneeName ?? 'Unknown',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () async {
                          final result = await showUserPicker(context);
                          if (result != null && mounted) {
                            try {
                              await ref
                                  .read(taskRepositoryProvider)
                                  .reassignTask(widget.taskId, result.userId);
                              ref.invalidate(
                                  taskDetailProvider(widget.taskId));
                              ref.invalidate(
                                  taskAssigneesProvider(widget.taskId));
                              ref.invalidate(dailyTasksProvider);
                              if (mounted) {
                                context.showSnackBar(
                                    'Task reassigned to ${result.userName}');
                              }
                            } catch (e) {
                              if (mounted) {
                                context.showSnackBar(
                                    'Failed to reassign', isError: true);
                              }
                            }
                          }
                        },
                        icon: Icon(
                          PhosphorIcons.arrowsClockwise(
                              PhosphorIconsStyle.regular),
                          size: 14,
                        ),
                        label: const Text('Reassign'),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          visualDensity: VisualDensity.compact,
                          textStyle: theme.textTheme.labelSmall,
                        ),
                      ),
                    ],
                  )
                : TextButton.icon(
                    onPressed: () async {
                      final result = await showUserPicker(context);
                      if (result != null && mounted) {
                        try {
                          await ref
                              .read(taskRepositoryProvider)
                              .assignTask(widget.taskId, result.userId);
                          ref.invalidate(taskDetailProvider(widget.taskId));
                          ref.invalidate(
                              taskAssigneesProvider(widget.taskId));
                          ref.invalidate(dailyTasksProvider);
                          if (mounted) {
                            context.showSnackBar(
                                'Task assigned to ${result.userName}');
                          }
                        } catch (e) {
                          if (mounted) {
                            context.showSnackBar(
                                'Failed to assign task', isError: true);
                          }
                        }
                      }
                    },
                    icon: Icon(
                      PhosphorIcons.userPlus(PhosphorIconsStyle.regular),
                      size: 14,
                    ),
                    label: const Text('Assign'),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                      textStyle: theme.textTheme.labelSmall,
                    ),
                  ),
          ),

          if (task.labels.isNotEmpty) ...[
            AppSpacing.vGapLg,
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: task.labels
                  .map((label) => Chip(
                        label: Text(label),
                        materialTapTargetSize:
                            MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ))
                  .toList(),
            ),
          ],

          AppSpacing.vGapXl,
          const Divider(),
          AppSpacing.vGapLg,

          // Checklist
          Row(
            children: [
              Icon(PhosphorIcons.checkSquare(PhosphorIconsStyle.regular),
                  size: 20),
              AppSpacing.hGapSm,
              Text('Checklist', style: theme.textTheme.titleSmall),
            ],
          ),
          AppSpacing.vGapMd,

          checklistAsync.when(
            data: (items) => Column(
              children: [
                ...items.map((item) => _ChecklistItemTile(
                      item: item,
                      onToggle: (value) async {
                        await ref
                            .read(taskRepositoryProvider)
                            .toggleChecklistItem(item.id, value);
                        ref.invalidate(
                            taskChecklistProvider(widget.taskId));
                      },
                      onDelete: () async {
                        await ref
                            .read(taskRepositoryProvider)
                            .deleteChecklistItem(item.id);
                        ref.invalidate(
                            taskChecklistProvider(widget.taskId));
                      },
                    )),
                // Add item field
                Row(
                  children: [
                    Expanded(
                      child: KuziiniTextField(
                        controller: _checklistController,
                        hint: 'Add checklist item...',
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _addChecklistItem(),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                      ),
                    ),
                    IconButton(
                      onPressed: _addChecklistItem,
                      icon: Icon(
                          PhosphorIcons.plus(PhosphorIconsStyle.bold),
                          size: 18),
                    ),
                  ],
                ),
              ],
            ),
            loading: () => const LoadingIndicator(size: 24),
            error: (_, __) =>
                const Text('Failed to load checklist'),
          ),

          AppSpacing.vGapXl,
          const Divider(),
          AppSpacing.vGapLg,

          // Attachments
          AttachmentSection(taskId: widget.taskId),

          AppSpacing.vGapXl,
          const Divider(),
          AppSpacing.vGapLg,

          // Comments (chat-style)
          CommentSection(taskId: widget.taskId),

          AppSpacing.vGapXxl,

          // Activity info
          if (task.createdAt != null) ...[
            const Divider(),
            AppSpacing.vGapMd,
            Text(
              'Created ${AppDateUtils.formatTimeAgo(task.createdAt!)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (task.updatedAt != null)
              Text(
                'Updated ${AppDateUtils.formatTimeAgo(task.updatedAt!)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            if (task.completedAt != null)
              Text(
                'Completed ${AppDateUtils.formatTimeAgo(task.completedAt!)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.success,
                ),
              ),
          ],

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.child,
  });

  final IconData icon;
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
          AppSpacing.hGapMd,
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _ChecklistItemTile extends StatelessWidget {
  const _ChecklistItemTile({
    required this.item,
    required this.onToggle,
    required this.onDelete,
  });

  final ChecklistItem item;
  final ValueChanged<bool> onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Checkbox(
            value: item.isCompleted,
            onChanged: (value) => onToggle(value ?? false),
            activeColor: theme.colorScheme.primary,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
          ),
          Expanded(
            child: Text(
              item.title,
              style: theme.textTheme.bodyMedium?.copyWith(
                decoration:
                    item.isCompleted ? TextDecoration.lineThrough : null,
                color: item.isCompleted
                    ? theme.colorScheme.onSurfaceVariant
                    : null,
              ),
            ),
          ),
          IconButton(
            onPressed: onDelete,
            icon: Icon(
              PhosphorIcons.x(PhosphorIconsStyle.regular),
              size: 16,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          ),
        ],
      ),
    );
  }
}


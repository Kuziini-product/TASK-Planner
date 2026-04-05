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
import '../../../core/widgets/voice_input_button.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/widgets/error_view.dart';
import '../../auth/providers/auth_provider.dart';
import '../../notifications/data/notification_repository.dart';
import '../data/models/task_model.dart';
import '../data/models/task_attachment.dart';
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
                // Reason (mandatory) + voice
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextField(
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
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 8, left: 4),
                      child: VoiceInputButton(
                        mini: true,
                        hintText: 'Say the reason...',
                        onResult: (text) {
                          reasonController.text = reasonController.text.isEmpty ? text : '${reasonController.text} $text';
                          setSheetState(() {});
                        },
                      ),
                    ),
                  ],
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
    final primaryColor = theme.colorScheme.primary;

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
              } else if (value == 'archive') {
                _updateStatus(TaskStatus.archived);
                if (mounted) context.showSnackBar('Task archived');
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
        data: (task) => _buildContent(context, task),
        loading: () => const LoadingIndicator(message: 'Loading task...'),
        error: (error, _) => ErrorView(
          message: error.toString(),
          onRetry: () => ref.invalidate(taskDetailProvider(widget.taskId)),
        ),
      ),
      bottomNavigationBar: taskAsync.whenOrNull(
        data: (task) {
          // Hide bottom bar for leave tasks
          if (task.isLeave) return null;

          Color prioColor;
          switch (task.priority) {
            case TaskPriority.urgent: prioColor = AppColors.priorityUrgent;
            case TaskPriority.high: prioColor = AppColors.priorityHigh;
            case TaskPriority.medium: prioColor = AppColors.priorityMedium;
            case TaskPriority.low: prioColor = AppColors.priorityLow;
            case TaskPriority.none: prioColor = theme.dividerColor;
          }
          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Mark complete
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () => _updateStatus(task.isCompleted ? TaskStatus.todo : TaskStatus.done),
                      icon: Icon(task.isCompleted ? PhosphorIcons.arrowCounterClockwise(PhosphorIconsStyle.bold) : PhosphorIcons.check(PhosphorIconsStyle.bold), size: 18),
                      label: Text(task.isCompleted ? 'Reopen' : 'Mark Complete', style: const TextStyle(fontWeight: FontWeight.w600)),
                      style: TextButton.styleFrom(foregroundColor: task.isCompleted ? theme.colorScheme.onSurfaceVariant : primaryColor),
                    ),
                  ),
                ),
                // Priority bar
                Container(height: 6, color: prioColor),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showNavigationPicker(TaskModel task) {
    final theme = Theme.of(context);

    // Build URLs for both apps
    String? googleMapsUrl;
    String? wazeUrl;

    if (task.locationLat != null && task.locationLng != null) {
      googleMapsUrl = 'https://www.google.com/maps/dir/?api=1&destination=${task.locationLat},${task.locationLng}';
      wazeUrl = 'https://waze.com/ul?ll=${task.locationLat},${task.locationLng}&navigate=yes';
    } else if (task.locationAddress != null) {
      final encoded = Uri.encodeComponent(task.locationAddress!);
      googleMapsUrl = 'https://www.google.com/maps/dir/?api=1&destination=$encoded';
      wazeUrl = 'https://waze.com/ul?q=$encoded&navigate=yes';
    } else if (task.locationUrl != null) {
      googleMapsUrl = task.locationUrl;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(color: theme.dividerColor, borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text('Navighează la ${task.locationDisplay}', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 12),
            if (googleMapsUrl != null)
              ListTile(
                leading: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4285F4).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(child: Text('G', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF4285F4)))),
                ),
                title: const Text('Google Maps'),
                subtitle: const Text('Deschide în Google Maps'),
                trailing: Icon(PhosphorIcons.arrowSquareOut(PhosphorIconsStyle.regular), size: 18),
                onTap: () {
                  Navigator.pop(ctx);
                  launchUrl(Uri.parse(googleMapsUrl!), mode: LaunchMode.externalApplication);
                },
              ),
            if (wazeUrl != null)
              ListTile(
                leading: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF05C8F7).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(child: Text('W', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF05C8F7)))),
                ),
                title: const Text('Waze'),
                subtitle: const Text('Deschide în Waze'),
                trailing: Icon(PhosphorIcons.arrowSquareOut(PhosphorIconsStyle.regular), size: 18),
                onTap: () {
                  Navigator.pop(ctx);
                  launchUrl(Uri.parse(wazeUrl!), mode: LaunchMode.externalApplication);
                },
              ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, TaskModel task) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final commentsAsync = ref.watch(taskCommentsProvider(widget.taskId));
    final commentCount = commentsAsync.valueOrNull?.length ?? task.commentCount;

    return SingleChildScrollView(
      padding: AppSpacing.paddingLg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. LOCATION (clickable, top — choose Google Maps or Waze)
          if (task.hasLocation)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: () => _showNavigationPicker(task),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: primaryColor.withValues(alpha: 0.15)),
                  ),
                  child: Row(
                    children: [
                      Icon(PhosphorIcons.mapPin(PhosphorIconsStyle.fill), size: 18, color: primaryColor),
                      const SizedBox(width: 8),
                      Expanded(child: Text(task.locationDisplay, style: TextStyle(color: primaryColor, fontWeight: FontWeight.w600, fontSize: 14))),
                      Icon(PhosphorIcons.navigationArrow(PhosphorIconsStyle.fill), size: 16, color: primaryColor),
                    ],
                  ),
                ),
              ),
            ),

          // 2. DATE + TIME (big, prominent)
          if (task.dueDate != null || task.startTime != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: (task.isOverdue ? AppColors.error : primaryColor).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    if (task.dueDate != null) ...[
                      Icon(PhosphorIcons.calendar(PhosphorIconsStyle.fill), size: 22, color: task.isOverdue ? AppColors.error : primaryColor),
                      const SizedBox(width: 8),
                      Text(
                        task.isMultiDay
                            ? '${task.dueDate!.day}/${task.dueDate!.month} → ${task.endDate!.day}/${task.endDate!.month}'
                            : AppDateUtils.formatFull(task.dueDate!),
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: task.isOverdue ? AppColors.error : primaryColor),
                      ),
                    ],
                    if (task.dueDate != null && task.startTime != null) const Spacer(),
                    if (task.startTime != null) ...[
                      Icon(PhosphorIcons.clock(PhosphorIconsStyle.fill), size: 22, color: task.isOverdue ? AppColors.error : primaryColor),
                      const SizedBox(width: 8),
                      Text(
                        task.endTime != null
                            ? '${AppDateUtils.formatTime(task.startTime!)} - ${AppDateUtils.formatTime(task.endTime!)}'
                            : AppDateUtils.formatTime(task.startTime!),
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: task.isOverdue ? AppColors.error : theme.colorScheme.onSurface),
                      ),
                    ],
                  ],
                ),
              ),
            ),

          // 3. TITLE
          Text(task.title, style: theme.textTheme.headlineSmall?.copyWith(
            decoration: task.isCompleted ? TextDecoration.lineThrough : null,
          )),

          // 4. DESCRIPTION (full, no expandable)
          if (task.description != null && task.description!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(task.description!, style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant, height: 1.5,
            )),
          ],

          const SizedBox(height: 16),

          // 5. ATTACHMENTS (visible thumbnails, clickable, single add button)
          AttachmentSection(taskId: widget.taskId),

          const SizedBox(height: 16),

          // 6. COMMENTS
          _ExpandableCard(
            icon: PhosphorIcons.chatCircle(PhosphorIconsStyle.regular),
            title: 'Comments',
            badge: commentCount,
            child: CommentSection(taskId: widget.taskId),
          ),

          const SizedBox(height: 12),

          // 7. ASSIGNEE (hidden for leave tasks)
          if (!task.isLeave) ...[
            if (task.isAssigned)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    CircleAvatar(radius: 14, backgroundColor: primaryColor.withValues(alpha: 0.1),
                      child: Text((task.assigneeName ?? 'U')[0].toUpperCase(), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: primaryColor))),
                    AppSpacing.hGapSm,
                    Expanded(child: Text(task.assigneeName ?? 'Unknown', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500))),
                    TextButton.icon(
                      onPressed: () async {
                        final result = await showUserPicker(context);
                        if (result != null && mounted) {
                          try {
                            await ref.read(taskRepositoryProvider).reassignTask(widget.taskId, result.userId);
                            ref.invalidate(taskDetailProvider(widget.taskId));
                            ref.invalidate(taskAssigneesProvider(widget.taskId));
                            ref.invalidate(dailyTasksProvider);
                            if (mounted) context.showSnackBar('Task reassigned to ${result.userName}');
                          } catch (e) { if (mounted) context.showSnackBar('Failed to reassign', isError: true); }
                        }
                      },
                      icon: Icon(PhosphorIcons.arrowsClockwise(PhosphorIconsStyle.regular), size: 14),
                      label: const Text('Reassign'),
                      style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8), visualDensity: VisualDensity.compact, textStyle: theme.textTheme.labelSmall),
                    ),
                  ],
                ),
              )
            else
              TextButton.icon(
                onPressed: () async {
                  final result = await showUserPicker(context);
                  if (result != null && mounted) {
                    try {
                      await ref.read(taskRepositoryProvider).assignTask(widget.taskId, result.userId);
                      ref.invalidate(taskDetailProvider(widget.taskId));
                      ref.invalidate(taskAssigneesProvider(widget.taskId));
                      ref.invalidate(dailyTasksProvider);
                      if (mounted) context.showSnackBar('Task assigned to ${result.userName}');
                    } catch (e) { if (mounted) context.showSnackBar('Failed to assign task', isError: true); }
                  }
                },
                icon: Icon(PhosphorIcons.userPlus(PhosphorIconsStyle.regular), size: 16),
                label: const Text('Add assign'),
                style: TextButton.styleFrom(padding: EdgeInsets.zero, visualDensity: VisualDensity.compact),
              ),

            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 8),

            // 8. Status chips (no archived)
            Center(
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 6,
                runSpacing: 6,
                children: [TaskStatus.in_progress, TaskStatus.review, TaskStatus.done]
                    .map((status) => StatusChip(status: status, isSelected: task.status == status, onTap: () => _updateStatus(status)))
                    .toList(),
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Created by + timestamps
          _CreatedByInfo(task: task),

          const SizedBox(height: 12),

          // Activity Log
          _ExpandableCard(
            icon: PhosphorIcons.clockCounterClockwise(PhosphorIconsStyle.regular),
            title: 'Activity Log',
            child: _ActivityLog(taskId: widget.taskId),
          ),

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

// ── Expandable Card ──

class _ExpandableCard extends StatefulWidget {
  const _ExpandableCard({required this.icon, required this.title, required this.child, this.badge = 0});

  final IconData icon;
  final String title;
  final Widget child;
  final int badge;

  @override
  State<_ExpandableCard> createState() => _ExpandableCardState();
}

class _ExpandableCardState extends State<_ExpandableCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Icon(widget.icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 8),
                Text(widget.title, style: theme.textTheme.titleSmall),
                if (widget.badge > 0) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('${widget.badge}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: theme.colorScheme.primary)),
                  ),
                ],
                const Spacer(),
                Icon(
                  _expanded ? PhosphorIcons.caretUp(PhosphorIconsStyle.bold) : PhosphorIcons.caretDown(PhosphorIconsStyle.bold),
                  size: 16, color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
        if (_expanded)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: widget.child,
          ),
      ],
    );
  }
}

// ── Created By Info ──

class _CreatedByInfo extends ConsumerWidget {
  const _CreatedByInfo({required this.task});
  final TaskModel task;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final creatorAsync = ref.watch(userProfileByIdProvider(task.createdBy));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Created by
        Row(
          children: [
            Icon(PhosphorIcons.userCircle(PhosphorIconsStyle.regular), size: 14, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 6),
            Text(
              'Creat de ',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            creatorAsync.when(
              data: (profile) => Text(
                profile?['full_name'] as String? ?? profile?['email'] as String? ?? 'Unknown',
                style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              loading: () => const SizedBox(width: 60, height: 12),
              error: (_, __) => Text('Unknown', style: theme.textTheme.bodySmall),
            ),
            if (task.createdAt != null) ...[
              Text(' · ', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              Text(
                AppDateUtils.formatTimeAgo(task.createdAt!),
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ],
        ),
        // Updated
        if (task.updatedAt != null && task.updatedAt != task.createdAt)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Row(
              children: [
                Icon(PhosphorIcons.pencilSimple(PhosphorIconsStyle.regular), size: 14, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 6),
                Text('Actualizat ${AppDateUtils.formatTimeAgo(task.updatedAt!)}',
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
        // Completed
        if (task.completedAt != null)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Row(
              children: [
                Icon(PhosphorIcons.checkCircle(PhosphorIconsStyle.fill), size: 14, color: AppColors.success),
                const SizedBox(width: 6),
                Text('Finalizat ${AppDateUtils.formatTimeAgo(task.completedAt!)}',
                    style: theme.textTheme.bodySmall?.copyWith(color: AppColors.success)),
              ],
            ),
          ),
      ],
    );
  }
}

// ── Activity Log ──

class _ActivityLog extends ConsumerWidget {
  const _ActivityLog({required this.taskId});
  final String taskId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final activityAsync = ref.watch(taskActivityProvider(taskId));

    return activityAsync.when(
      data: (logs) {
        if (logs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(12),
            child: Text('Nicio activitate înregistrată', style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurfaceVariant)),
          );
        }
        return Column(
          children: logs.map((log) {
            final action = log['action'] as String? ?? '';
            final createdAt = log['created_at'] != null ? DateTime.parse(log['created_at'] as String) : null;
            final profile = log['profiles'] as Map<String, dynamic>?;
            final userName = profile?['full_name'] as String? ?? profile?['email'] as String? ?? 'Unknown';
            final details = log['details'] as Map<String, dynamic>? ?? {};

            final (icon, label, color) = _actionInfo(action, details);

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, size: 12, color: color),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          text: TextSpan(
                            style: theme.textTheme.bodySmall,
                            children: [
                              TextSpan(text: userName, style: const TextStyle(fontWeight: FontWeight.w600)),
                              TextSpan(text: ' $label'),
                            ],
                          ),
                        ),
                        if (createdAt != null)
                          Text(
                            AppDateUtils.formatTimeAgo(createdAt),
                            style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurfaceVariant),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.all(12),
        child: LoadingIndicator(size: 16),
      ),
      error: (_, __) => Padding(
        padding: const EdgeInsets.all(12),
        child: Text('Failed to load activity', style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
      ),
    );
  }

  (IconData, String, Color) _actionInfo(String action, Map<String, dynamic> details) {
    return switch (action) {
      'created' => (PhosphorIcons.plus(PhosphorIconsStyle.bold), 'a creat task-ul', AppColors.info),
      'updated' => (PhosphorIcons.pencilSimple(PhosphorIconsStyle.bold), 'a actualizat task-ul', Colors.orange),
      'status_changed' => (PhosphorIcons.arrowsClockwise(PhosphorIconsStyle.bold),
          'a schimbat statusul${details['to'] != null ? ' → ${details['to']}' : ''}', Colors.purple),
      'assigned' => (PhosphorIcons.userPlus(PhosphorIconsStyle.bold),
          'a asignat${details['to_name'] != null ? ' lui ${details['to_name']}' : ''}', AppColors.info),
      'unassigned' => (PhosphorIcons.userMinus(PhosphorIconsStyle.bold), 'a dezasignat', Colors.grey),
      'commented' => (PhosphorIcons.chatCircle(PhosphorIconsStyle.bold), 'a comentat', Colors.teal),
      'attachment_added' => (PhosphorIcons.paperclip(PhosphorIconsStyle.bold), 'a adăugat un fișier', Colors.indigo),
      'attachment_removed' => (PhosphorIcons.trash(PhosphorIconsStyle.bold), 'a șters un fișier', AppColors.error),
      'due_date_changed' => (PhosphorIcons.calendar(PhosphorIconsStyle.bold),
          'a schimbat data${details['to'] != null ? ' → ${details['to']}' : ''}', Colors.deepOrange),
      'priority_changed' => (PhosphorIcons.flag(PhosphorIconsStyle.bold),
          'a schimbat prioritatea${details['to'] != null ? ' → ${details['to']}' : ''}', AppColors.warning),
      'checklist_added' => (PhosphorIcons.listChecks(PhosphorIconsStyle.bold), 'a adăugat checklist item', Colors.teal),
      'checklist_completed' => (PhosphorIcons.checkSquare(PhosphorIconsStyle.bold), 'a bifat checklist item', AppColors.success),
      'archived' => (PhosphorIcons.archive(PhosphorIconsStyle.bold), 'a arhivat task-ul', Colors.grey),
      'restored' => (PhosphorIcons.arrowCounterClockwise(PhosphorIconsStyle.bold), 'a restaurat task-ul', AppColors.info),
      _ => (PhosphorIcons.dotsThree(PhosphorIconsStyle.bold), action, Colors.grey),
    };
  }
}


import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/widgets/kuziini_card.dart';
import '../../../../core/widgets/voice_input_button.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../data/models/task_model.dart';
import '../../providers/tasks_provider.dart';
import 'status_chip.dart';

class TaskCard extends ConsumerWidget {
  const TaskCard({
    super.key,
    required this.task,
    this.onStatusChanged,
    this.onTap,
    this.showDate = false,
    this.animationIndex = 0,
  });

  final TaskModel task;
  final ValueChanged<TaskStatus>? onStatusChanged;
  final VoidCallback? onTap;
  final bool showDate;
  final int animationIndex;

  Color get _accentColor {
    switch (task.priority) {
      case TaskPriority.urgent:
        return AppColors.priorityUrgent;
      case TaskPriority.high:
        return AppColors.priorityHigh;
      case TaskPriority.medium:
        return AppColors.priorityMedium;
      case TaskPriority.low:
        return AppColors.priorityLow;
      case TaskPriority.none:
        return Colors.transparent;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap ?? () => context.push('/task/${task.id}'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        margin: const EdgeInsets.symmetric(vertical: 2),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border(
            left: BorderSide(
              color: task.priority != TaskPriority.none ? _accentColor : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Row(
          children: [
            // Relocate button (left)
            GestureDetector(
              onTap: () => _showRelocate(context, ref),
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Icon(PhosphorIcons.calendarPlus(PhosphorIconsStyle.regular), size: 16, color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
            // Status
            GestureDetector(
              onTap: () {
                if (onStatusChanged != null) {
                  onStatusChanged!(task.isCompleted ? TaskStatus.todo : TaskStatus.done);
                }
              },
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: StatusChip(status: task.status, compact: true),
              ),
            ),
            // Title + time
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                      color: task.isCompleted ? theme.colorScheme.onSurfaceVariant : null,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    children: [
                      if (task.isMultiDay)
                        Text('${task.dueDate!.day}/${task.dueDate!.month} → ${task.endDate!.day}/${task.endDate!.month}',
                          style: TextStyle(fontSize: 10, color: theme.colorScheme.primary, fontWeight: FontWeight.w500))
                      else if (task.startTime != null)
                        Text(
                          task.endTime != null
                              ? '${AppDateUtils.formatTime(task.startTime!)} - ${AppDateUtils.formatTime(task.endTime!)}'
                              : AppDateUtils.formatTime(task.startTime!),
                          style: TextStyle(fontSize: 10, color: task.isOverdue ? AppColors.error : theme.colorScheme.primary, fontWeight: FontWeight.w500),
                        )
                      else if (task.dueDate != null)
                        Text(AppDateUtils.getRelativeDateLabel(task.dueDate!),
                          style: TextStyle(fontSize: 10, color: task.isOverdue ? AppColors.error : theme.colorScheme.onSurfaceVariant)),
                      // Indicators
                      if (task.hasChecklist) ...[
                        const SizedBox(width: 8),
                        Icon(PhosphorIcons.checkSquare(PhosphorIconsStyle.regular), size: 11, color: theme.colorScheme.onSurfaceVariant),
                        Text(' ${task.checklistCompleted}/${task.checklistTotal}', style: TextStyle(fontSize: 9, color: theme.colorScheme.onSurfaceVariant)),
                      ],
                      if (task.hasAttachments) ...[
                        const SizedBox(width: 6),
                        Icon(PhosphorIcons.paperclip(PhosphorIconsStyle.regular), size: 11, color: theme.colorScheme.onSurfaceVariant),
                        Text(' ${task.attachmentCount}', style: TextStyle(fontSize: 9, color: theme.colorScheme.onSurfaceVariant)),
                      ],
                      if (task.hasComments) ...[
                        const SizedBox(width: 6),
                        Icon(PhosphorIcons.chatCircle(PhosphorIconsStyle.regular), size: 11, color: theme.colorScheme.onSurfaceVariant),
                        Text(' ${task.commentCount}', style: TextStyle(fontSize: 9, color: theme.colorScheme.onSurfaceVariant)),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            // Location (right)
            if (task.hasLocation) ...[
              const SizedBox(width: 6),
              Icon(PhosphorIcons.mapPin(PhosphorIconsStyle.regular), size: 12, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 3),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 80),
                child: Text(task.locationDisplay, style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurfaceVariant),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ],
            // Assignee
            if (task.isAssigned) ...[
              const SizedBox(width: 6),
              CircleAvatar(
                radius: 10,
                backgroundColor: _accentColor.withValues(alpha: 0.15),
                child: Text((task.assigneeName ?? 'U')[0].toUpperCase(),
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: _accentColor)),
              ),
            ],
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(
          duration: 300.ms,
          delay: Duration(milliseconds: 50 * animationIndex),
        )
        .moveX(
          begin: 20,
          duration: 300.ms,
          delay: Duration(milliseconds: 50 * animationIndex),
        );
  }

  void _showRelocate(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    DateTime? newDate = task.dueDate;
    DateTime? newEndDate = task.endDate;
    final reasonController = TextEditingController();

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
              children: [
                Container(width: 40, height: 4, decoration: BoxDecoration(color: theme.dividerColor, borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 12),
                Text('Relocate Task', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 16),
                // Reason (mandatory)
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
                  title: Text(newEndDate != null ? 'End: ${newEndDate!.day}/${newEndDate!.month}/${newEndDate!.year}' : 'Add end date'),
                  trailing: newEndDate != null ? IconButton(icon: const Icon(Icons.close, size: 16), onPressed: () => setSheetState(() => newEndDate = null)) : null,
                  onTap: () async {
                    final d = await showDatePicker(context: ctx, initialDate: newEndDate ?? newDate ?? DateTime.now(), firstDate: newDate ?? DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365 * 2)));
                    if (d != null) setSheetState(() => newEndDate = d);
                  },
                  dense: true,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: reasonController.text.trim().isEmpty ? null : () async {
                      final reason = reasonController.text.trim();
                      Navigator.pop(ctx);
                      try {
                        final repo = ref.read(taskRepositoryProvider);
                        final userId = SupabaseService.instance.currentUserId!;
                        final profile = ref.read(currentUserProfileProvider).valueOrNull;
                        final userName = profile?.displayName ?? 'Unknown';

                        final dateStr = newDate != null ? '${newDate!.year}-${newDate!.month.toString().padLeft(2, '0')}-${newDate!.day.toString().padLeft(2, '0')}' : null;
                        final endDateStr = newEndDate != null ? '${newEndDate!.year}-${newEndDate!.month.toString().padLeft(2, '0')}-${newEndDate!.day.toString().padLeft(2, '0')}' : null;

                        // Update task dates
                        await repo.updateTask(task.id, {'due_date': dateStr, 'end_date': endDateStr});

                        // Add relocation comment
                        final oldDateStr = task.dueDate != null ? '${task.dueDate!.day}/${task.dueDate!.month}/${task.dueDate!.year}' : 'none';
                        final newDateDisplay = newDate != null ? '${newDate!.day}/${newDate!.month}/${newDate!.year}' : 'none';
                        final comment = '\u{1F4CD} Relocated by $userName\n'
                            'From: $oldDateStr → To: $newDateDisplay\n'
                            'Reason: $reason';

                        await repo.addComment(taskId: task.id, userId: userId, content: comment);

                        ref.invalidate(dailyTasksProvider);
                        if (context.mounted) {
                          context.showSnackBar('Task relocated');
                        }
                      } catch (_) {}
                    },
                    child: const Text('Relocate'),
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

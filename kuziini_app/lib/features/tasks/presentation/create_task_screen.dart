import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/utils/extensions.dart';
import '../../../core/widgets/kuziini_app_bar.dart';
import '../../../core/widgets/kuziini_button.dart';
import '../../../core/widgets/kuziini_text_field.dart';
import '../data/models/task_model.dart';
import '../providers/tasks_provider.dart';

class CreateTaskScreen extends ConsumerStatefulWidget {
  const CreateTaskScreen({super.key});

  @override
  ConsumerState<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends ConsumerState<CreateTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _checklistController = TextEditingController();

  TaskPriority _priority = TaskPriority.none;
  DateTime? _dueDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  final List<String> _checklistItems = [];
  final List<String> _labels = [];
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _checklistController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppColors.primary,
                ),
          ),
          child: child!,
        );
      },
    );
    if (date != null) {
      setState(() => _dueDate = date);
    }
  }

  Future<void> _pickStartTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _startTime ?? TimeOfDay.now(),
    );
    if (time != null) {
      setState(() => _startTime = time);
    }
  }

  Future<void> _pickEndTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _endTime ?? _startTime ?? TimeOfDay.now(),
    );
    if (time != null) {
      setState(() => _endTime = time);
    }
  }

  void _addChecklistItem() {
    final text = _checklistController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _checklistItems.add(text);
      _checklistController.clear();
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final userId = SupabaseService.instance.currentUserId!;
      final now = _dueDate ?? DateTime.now();

      DateTime? startDateTime;
      DateTime? endDateTime;

      if (_startTime != null) {
        startDateTime = DateTime(
          now.year,
          now.month,
          now.day,
          _startTime!.hour,
          _startTime!.minute,
        );
      }

      if (_endTime != null) {
        endDateTime = DateTime(
          now.year,
          now.month,
          now.day,
          _endTime!.hour,
          _endTime!.minute,
        );
      }

      final task = TaskModel(
        id: '',
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().nullIfEmpty,
        priority: _priority,
        createdBy: userId,
        dueDate: _dueDate,
        startTime: startDateTime,
        endTime: endDateTime,
        labels: _labels,
      );

      final repo = ref.read(taskRepositoryProvider);
      final createdTask = await repo.createTask(task);

      // Add checklist items using the server-assigned task ID
      for (int i = 0; i < _checklistItems.length; i++) {
        await repo.addChecklistItem(
          taskId: createdTask.id,
          title: _checklistItems[i],
          sortOrder: i,
        );
      }

      ref.invalidate(dailyTasksProvider);

      if (mounted) {
        Navigator.of(context).pop();
        context.showSnackBar('Task created successfully');
      }
    } catch (e) {
      if (mounted) {
        context.showSnackBar('Failed to create task: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: KuziiniAppBar(
        showBackButton: true,
        title: 'New Task',
        actions: [
          TextButton(
            onPressed: _isSubmitting ? null : _submit,
            child: _isSubmitting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    'Create',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: AppSpacing.paddingLg,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              KuziiniTextField(
                controller: _titleController,
                hint: 'Task title',
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 0, vertical: 12),
                fillColor: Colors.transparent,
                borderRadius: 0,
              ),

              AppSpacing.vGapMd,

              // Description
              KuziiniTextField(
                controller: _descriptionController,
                hint: 'Add description...',
                maxLines: 4,
                minLines: 2,
                textCapitalization: TextCapitalization.sentences,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
                fillColor: Colors.transparent,
                borderRadius: 0,
              ),

              AppSpacing.vGapXl,

              // Date picker
              _OptionTile(
                icon: PhosphorIcons.calendar(PhosphorIconsStyle.regular),
                label: _dueDate != null
                    ? '${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}'
                    : 'Add due date',
                isActive: _dueDate != null,
                onTap: _pickDate,
                onClear: _dueDate != null
                    ? () => setState(() => _dueDate = null)
                    : null,
              ),

              // Time pickers
              _OptionTile(
                icon: PhosphorIcons.clock(PhosphorIconsStyle.regular),
                label: _startTime != null
                    ? 'Start: ${_startTime!.format(context)}'
                    : 'Add start time',
                isActive: _startTime != null,
                onTap: _pickStartTime,
                onClear: _startTime != null
                    ? () => setState(() => _startTime = null)
                    : null,
              ),

              if (_startTime != null)
                _OptionTile(
                  icon: PhosphorIcons.clockCountdown(PhosphorIconsStyle.regular),
                  label: _endTime != null
                      ? 'End: ${_endTime!.format(context)}'
                      : 'Add end time',
                  isActive: _endTime != null,
                  onTap: _pickEndTime,
                  onClear: _endTime != null
                      ? () => setState(() => _endTime = null)
                      : null,
                ),

              AppSpacing.vGapMd,

              // Priority selector
              Text('Priority', style: theme.textTheme.labelLarge),
              AppSpacing.vGapSm,
              Wrap(
                spacing: 8,
                children: TaskPriority.values.map((priority) {
                  final isSelected = _priority == priority;
                  Color color;
                  switch (priority) {
                    case TaskPriority.urgent:
                      color = AppColors.priorityUrgent;
                    case TaskPriority.high:
                      color = AppColors.priorityHigh;
                    case TaskPriority.medium:
                      color = AppColors.priorityMedium;
                    case TaskPriority.low:
                      color = AppColors.priorityLow;
                    case TaskPriority.none:
                      color = AppColors.priorityNone;
                  }

                  return ChoiceChip(
                    label: Text(priority.label),
                    selected: isSelected,
                    onSelected: (_) =>
                        setState(() => _priority = priority),
                    selectedColor: color.withValues(alpha: 0.15),
                    labelStyle: TextStyle(
                      color: isSelected ? color : null,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                    side: BorderSide(
                      color: isSelected
                          ? color
                          : theme.dividerColor,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppSpacing.borderRadiusFull,
                    ),
                  );
                }).toList(),
              ),

              AppSpacing.vGapXl,

              // Checklist
              Text('Checklist', style: theme.textTheme.labelLarge),
              AppSpacing.vGapSm,

              // Existing items
              ...List.generate(_checklistItems.length, (index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Icon(
                        PhosphorIcons.checkSquare(PhosphorIconsStyle.regular),
                        size: 18,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      AppSpacing.hGapSm,
                      Expanded(
                        child: Text(
                          _checklistItems[index],
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          setState(() => _checklistItems.removeAt(index));
                        },
                        icon: Icon(
                          PhosphorIcons.x(PhosphorIconsStyle.regular),
                          size: 16,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 28,
                          minHeight: 28,
                        ),
                      ),
                    ],
                  ),
                );
              }),

              // Add item
              Row(
                children: [
                  Expanded(
                    child: KuziiniTextField(
                      controller: _checklistController,
                      hint: 'Add item...',
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _addChecklistItem(),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _addChecklistItem,
                    icon: Icon(
                      PhosphorIcons.plus(PhosphorIconsStyle.bold),
                      size: 18,
                    ),
                  ),
                ],
              ),

              AppSpacing.vGapXxl,

              // Create button
              KuziiniButton(
                label: 'Create Task',
                onPressed: _submit,
                isLoading: _isSubmitting,
                icon: PhosphorIcons.plus(PhosphorIconsStyle.bold),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isActive = false,
    this.onClear,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isActive;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: AppSpacing.borderRadiusSm,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isActive
                  ? AppColors.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
            AppSpacing.hGapMd,
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isActive
                      ? theme.colorScheme.onSurface
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            if (onClear != null)
              IconButton(
                onPressed: onClear,
                icon: Icon(
                  PhosphorIcons.x(PhosphorIconsStyle.regular),
                  size: 16,
                ),
                padding: EdgeInsets.zero,
                constraints:
                    const BoxConstraints(minWidth: 28, minHeight: 28),
              ),
          ],
        ),
      ),
    );
  }
}

import 'dart:async';
import 'dart:js_util' as js_util;

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
import '../../../core/widgets/voice_input_button.dart';
import '../data/models/task_model.dart';
import '../providers/tasks_provider.dart';
import 'widgets/user_picker.dart';

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
  String? _assigneeId;
  String? _assigneeName;
  bool _isSubmitting = false;

  // Location fields
  bool _useDefaultLocation = true;
  final _locationNameController = TextEditingController(text: 'Kuziini');
  final _locationAddressController = TextEditingController(text: 'Bulevardul Unirii Nr 63');
  final _locationLinkController = TextEditingController();
  double? _locationLat;
  double? _locationLng;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _checklistController.dispose();
    _locationNameController.dispose();
    _locationAddressController.dispose();
    _locationLinkController.dispose();
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

  Future<void> _getMyLocation() async {
    try {
      final coords = await _jsGeolocation();
      if (coords != null && mounted) {
        setState(() {
          _locationLat = coords['lat'];
          _locationLng = coords['lng'];
          _locationAddressController.text = 'My Location (${coords['lat']!.toStringAsFixed(5)}, ${coords['lng']!.toStringAsFixed(5)})';
          _locationLinkController.text = 'https://www.google.com/maps?q=${coords['lat']},${coords['lng']}';
        });
      }
    } catch (_) {
      if (mounted) {
        context.showSnackBar('Could not get location. Allow location access in browser.', isError: true);
      }
    }
  }

  Future<Map<String, double>?> _jsGeolocation() async {
    final completer = Completer<Map<String, double>?>();
    try {
      final nav = js_util.getProperty(js_util.globalThis, 'navigator');
      final geo = js_util.getProperty(nav, 'geolocation');
      js_util.callMethod(geo, 'getCurrentPosition', [
        js_util.allowInterop((pos) {
          final coords = js_util.getProperty(pos, 'coords');
          final lat = js_util.getProperty<num>(coords, 'latitude').toDouble();
          final lng = js_util.getProperty<num>(coords, 'longitude').toDouble();
          completer.complete({'lat': lat, 'lng': lng});
        }),
        js_util.allowInterop((err) {
          completer.complete(null);
        }),
      ]);
    } catch (_) {
      completer.complete(null);
    }
    return completer.future;
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

      // Resolve location
      String? locName;
      String? locAddress;
      String? locUrl;
      double? locLat;
      double? locLng;
      if (_useDefaultLocation) {
        locName = 'Kuziini';
        locAddress = 'Bulevardul Unirii Nr 63';
      } else {
        locName = _locationNameController.text.trim().nullIfEmpty;
        locAddress = _locationAddressController.text.trim().nullIfEmpty;
        locUrl = _locationLinkController.text.trim().nullIfEmpty;
        locLat = _locationLat;
        locLng = _locationLng;
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
        locationName: locName,
        locationAddress: locAddress,
        locationUrl: locUrl,
        locationLat: locLat,
        locationLng: locLng,
      );

      final repo = ref.read(taskRepositoryProvider);
      final createdTask = await repo.createTask(task);

      // Assign task if an assignee was selected
      if (_assigneeId != null) {
        await SupabaseService.instance.client.from('task_assignees').insert({
          'task_id': createdTask.id,
          'user_id': _assigneeId,
          'assigned_by': userId,
        });
      }

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
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: KuziiniTextField(
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
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: VoiceInputButton(
                      mini: true,
                      hintText: 'Say the task title...',
                      onResult: (text) {
                        _titleController.text = text;
                      },
                    ),
                  ),
                ],
              ),

              AppSpacing.vGapMd,

              // Description
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: KuziiniTextField(
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
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: VoiceInputButton(
                      mini: true,
                      hintText: 'Say the task description...',
                      onResult: (text) {
                        final current = _descriptionController.text;
                        _descriptionController.text =
                            current.isEmpty ? text : '$current $text';
                      },
                    ),
                  ),
                ],
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

              AppSpacing.vGapXl,

              // Location section
              Text('Location', style: theme.textTheme.labelLarge),
              AppSpacing.vGapSm,
              Row(
                children: [
                  Checkbox(
                    value: _useDefaultLocation,
                    onChanged: (v) => setState(() => _useDefaultLocation = v ?? true),
                    activeColor: AppColors.primary,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _useDefaultLocation = !_useDefaultLocation),
                      child: Text(
                        'Use default location (Kuziini, Bulevardul Unirii Nr 63)',
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ),
                ],
              ),
              if (!_useDefaultLocation) ...[
                AppSpacing.vGapSm,
                KuziiniTextField(
                  controller: _locationNameController,
                  hint: 'Location name',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                AppSpacing.vGapSm,
                KuziiniTextField(
                  controller: _locationAddressController,
                  hint: 'Address',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                AppSpacing.vGapSm,
                KuziiniTextField(
                  controller: _locationLinkController,
                  hint: 'Google Maps link (optional)',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                AppSpacing.vGapSm,
                OutlinedButton.icon(
                  onPressed: _getMyLocation,
                  icon: Icon(PhosphorIcons.navigationArrow(PhosphorIconsStyle.regular), size: 16),
                  label: const Text('My Location'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],

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

              // Assign to
              Text('Assign to', style: theme.textTheme.labelLarge),
              AppSpacing.vGapSm,
              _OptionTile(
                icon: PhosphorIcons.userCircle(PhosphorIconsStyle.regular),
                label: _assigneeName ?? 'Tap to assign',
                isActive: _assigneeId != null,
                onTap: () async {
                  final result = await showUserPicker(context);
                  if (result != null) {
                    setState(() {
                      _assigneeId = result.userId;
                      _assigneeName = result.userName;
                    });
                  }
                },
                onClear: _assigneeId != null
                    ? () => setState(() {
                          _assigneeId = null;
                          _assigneeName = null;
                        })
                    : null,
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

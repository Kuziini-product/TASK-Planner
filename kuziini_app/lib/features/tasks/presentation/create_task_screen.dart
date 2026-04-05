import 'dart:async';
import 'dart:js_util' as js_util;
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/supabase_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../../notifications/data/notification_repository.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/utils/extensions.dart';
import '../../../core/widgets/kuziini_app_bar.dart';
import '../../../core/widgets/kuziini_button.dart';
import '../../../core/widgets/kuziini_text_field.dart';
import '../../../core/widgets/voice_input_button.dart';
import '../data/models/task_model.dart';
import '../providers/tasks_provider.dart';
import 'widgets/attachment_section.dart';
import 'widgets/user_picker.dart';

class CreateTaskScreen extends ConsumerStatefulWidget {
  const CreateTaskScreen({super.key, this.queryParams = const {}, this.existingTask});

  final Map<String, String> queryParams;
  final TaskModel? existingTask;

  @override
  ConsumerState<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends ConsumerState<CreateTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _descriptionFocusNode = FocusNode();
  bool _titleManuallyEdited = false;
  final _checklistController = TextEditingController();

  TaskPriority _priority = TaskPriority.medium;
  DateTime? _dueDate;
  DateTime? _endDate; // For multi-day tasks
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  final List<String> _checklistItems = [];
  final List<String> _labels = [];
  String? _assigneeId;
  String? _assigneeName;
  bool _isSubmitting = false;

  // Early-created task ID (created on first attachment pick)
  String? _earlyTaskId;
  bool _isUploading = false;

  // Location fields
  bool _useDefaultLocation = true;
  final _locationNameController = TextEditingController(text: 'Kuziini');
  final _locationAddressController = TextEditingController(text: 'Bulevardul Unirii Nr 63');
  final _locationLinkController = TextEditingController();
  double? _locationLat;
  double? _locationLng;

  bool get _isEditMode => widget.existingTask != null;

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      _titleManuallyEdited = true; // Don't auto-generate title when editing
      _applyExistingTask();
    } else {
      _applyVoiceParams();
      // Auto-generate title from first 3 words of description
      _descriptionController.addListener(_autoGenerateTitle);
      // Focus description field on new task
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_isEditMode) _descriptionFocusNode.requestFocus();
      });
    }
    // Track manual title edits
    _titleController.addListener(() {
      if (_titleController.text.isNotEmpty && _descriptionController.text.isEmpty) {
        _titleManuallyEdited = true;
      }
    });
  }

  void _autoGenerateTitle() {
    if (_titleManuallyEdited) return;
    final desc = _descriptionController.text.trim();
    if (desc.isEmpty) {
      _titleController.text = '';
      return;
    }
    final words = desc.split(RegExp(r'\s+'));
    final title = words.take(3).join(' ');
    // Only update if different to avoid cursor jumping
    if (_titleController.text != title) {
      _titleController.text = title;
    }
  }

  void _applyExistingTask() {
    final task = widget.existingTask!;
    _titleController.text = task.title;
    _descriptionController.text = task.description ?? '';
    _priority = task.priority;
    _dueDate = task.dueDate;
    if (task.startTime != null) {
      final local = task.startTime!.toLocal();
      _startTime = TimeOfDay(hour: local.hour, minute: local.minute);
    }
    if (task.endTime != null) {
      final local = task.endTime!.toLocal();
      _endTime = TimeOfDay(hour: local.hour, minute: local.minute);
    }
    if (task.locationName != null || task.locationAddress != null) {
      _useDefaultLocation = false;
      _locationNameController.text = task.locationName ?? '';
      _locationAddressController.text = task.locationAddress ?? '';
      if (task.locationUrl != null) _locationLinkController.text = task.locationUrl!;
      _locationLat = task.locationLat;
      _locationLng = task.locationLng;
    }
    if (task.assigneeId != null) {
      _assigneeId = task.assigneeId;
      _assigneeName = task.assigneeName;
    }
  }

  void _applyVoiceParams() {
    final p = widget.queryParams;
    if (p.isEmpty) return;

    if (p.containsKey('title')) _titleController.text = p['title']!;
    if (p.containsKey('desc')) _descriptionController.text = p['desc']!;

    if (p.containsKey('date')) {
      _dueDate = DateTime.tryParse(p['date']!);
    }
    if (p.containsKey('endDate')) {
      _endDate = DateTime.tryParse(p['endDate']!);
    }

    if (p.containsKey('hour')) {
      final h = int.tryParse(p['hour'] ?? '');
      final m = int.tryParse(p['minute'] ?? '0') ?? 0;
      if (h != null) _startTime = TimeOfDay(hour: h, minute: m);
    }

    if (p.containsKey('priority')) {
      switch (p['priority']) {
        case 'urgent': _priority = TaskPriority.urgent;
        case 'high': _priority = TaskPriority.high;
        case 'medium': _priority = TaskPriority.medium;
        case 'low': _priority = TaskPriority.low;
      }
    }

    if (p.containsKey('locName') || p.containsKey('locAddress')) {
      _useDefaultLocation = false;
      if (p.containsKey('locName')) _locationNameController.text = p['locName']!;
      if (p.containsKey('locAddress')) _locationAddressController.text = p['locAddress']!;
    }

    // Assignee name is resolved after build via _resolveAssignee
    if (p.containsKey('assignee')) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _resolveAssignee(p['assignee']!));
    }
  }

  Future<void> _resolveAssignee(String name) async {
    try {
      final result = await SupabaseService.instance.client
          .from('profiles')
          .select('id, display_name')
          .ilike('display_name', '%$name%')
          .limit(1)
          .maybeSingle();
      if (result != null && mounted) {
        setState(() {
          _assigneeId = result['id'] as String;
          _assigneeName = result['display_name'] as String;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _descriptionController.removeListener(_autoGenerateTitle);
    _titleController.dispose();
    _descriptionController.dispose();
    _descriptionFocusNode.dispose();
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
                  primary: Theme.of(context).colorScheme.primary,
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

  Future<void> _showLocationPicker() async {
    final nameCtrl = TextEditingController(text: _locationNameController.text);
    final addressCtrl = TextEditingController(text: _locationAddressController.text);
    final linkCtrl = TextEditingController(text: _locationLinkController.text);

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20, right: 20, top: 16,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle
                  Center(
                    child: Container(width: 40, height: 4,
                      decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(Icons.location_on, color: Theme.of(ctx).colorScheme.primary),
                      const SizedBox(width: 8),
                      Text('Set Location', style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Quick default
                  InkWell(
                    onTap: () {
                      nameCtrl.text = 'Kuziini';
                      addressCtrl.text = 'Bulevardul Unirii Nr 63';
                      linkCtrl.text = '';
                      setSheetState(() {});
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(ctx).colorScheme.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Theme.of(ctx).colorScheme.primary.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.store, color: Theme.of(ctx).colorScheme.primary, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Kuziini', style: TextStyle(fontWeight: FontWeight.w600, color: Theme.of(ctx).colorScheme.primary)),
                                Text('Bulevardul Unirii Nr 63', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right, color: Theme.of(ctx).colorScheme.primary, size: 20),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Custom fields
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      labelText: 'Location name',
                      prefixIcon: const Icon(Icons.place_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true, isDense: true,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: addressCtrl,
                    decoration: InputDecoration(
                      labelText: 'Address',
                      prefixIcon: const Icon(Icons.map_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true, isDense: true,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: linkCtrl,
                    decoration: InputDecoration(
                      labelText: 'Google Maps link (optional)',
                      prefixIcon: const Icon(Icons.link),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true, isDense: true,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Quick actions
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            try {
                              final coords = await _jsGeolocation();
                              if (coords != null) {
                                nameCtrl.text = 'My Location';
                                addressCtrl.text = '${coords['lat']!.toStringAsFixed(5)}, ${coords['lng']!.toStringAsFixed(5)}';
                                linkCtrl.text = 'https://www.google.com/maps?q=${coords['lat']},${coords['lng']}';
                                setSheetState(() {});
                              }
                            } catch (_) {}
                          },
                          icon: const Icon(Icons.my_location, size: 16),
                          label: const Text('My Location', style: TextStyle(fontSize: 12)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Confirm button
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Confirm Location'),
                      style: FilledButton.styleFrom(
                        backgroundColor: Theme.of(ctx).colorScheme.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (confirmed == true) {
      setState(() {
        _locationNameController.text = nameCtrl.text;
        _locationAddressController.text = addressCtrl.text;
        _locationLinkController.text = linkCtrl.text;
        _useDefaultLocation = false;
      });
    }

    nameCtrl.dispose();
    addressCtrl.dispose();
    linkCtrl.dispose();
  }

  void _addChecklistItem() {
    final text = _checklistController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _checklistItems.add(text);
      _checklistController.clear();
    });
  }

  Future<void> _deleteTask() async {
    if (!_isEditMode) return;
    final confirmed = await context.showConfirmDialog(
      title: 'Delete Task',
      message: 'Are you sure you want to delete this task? This cannot be undone.',
      confirmLabel: 'Delete',
      isDestructive: true,
    );
    if (confirmed == true && mounted) {
      try {
        final repo = ref.read(taskRepositoryProvider);
        await repo.deleteTask(widget.existingTask!.id);
        ref.invalidate(dailyTasksProvider);
        if (mounted) {
          Navigator.of(context).pop();
          Navigator.of(context).pop();
          context.showSnackBar('Task deleted');
        }
      } catch (e) {
        if (mounted) context.showSnackBar('Failed to delete task', isError: true);
      }
    }
  }

  /// Creates the task early (if not yet created) so attachments can be uploaded immediately.
  Future<String> _ensureTaskCreated() async {
    if (_earlyTaskId != null) return _earlyTaskId!;

    final userId = SupabaseService.instance.currentUserId!;
    final now = DateTime.now();
    final desc = _descriptionController.text.trim();
    final title = _titleController.text.trim().isNotEmpty
        ? _titleController.text.trim()
        : desc.isNotEmpty
            ? desc.split(RegExp(r'\s+')).take(3).join(' ')
            : 'Task nou';

    final repo = ref.read(taskRepositoryProvider);
    final task = TaskModel(
      id: '',
      title: title,
      priority: _priority,
      createdBy: userId,
      dueDate: _dueDate ?? now,
      startTime: now,
    );
    final created = await repo.createTask(task);
    _earlyTaskId = created.id;
    return created.id;
  }

  Future<void> _uploadFileToTask(Uint8List bytes, String fileName) async {
    setState(() => _isUploading = true);
    try {
      final taskId = await _ensureTaskCreated();
      final userId = SupabaseService.instance.currentUserId!;
      final repo = ref.read(taskRepositoryProvider);
      await repo.uploadAttachment(
        taskId: taskId,
        userId: userId,
        fileBytes: bytes,
        fileName: fileName,
      );
      ref.invalidate(taskAttachmentsProvider(taskId));
      if (mounted) context.showSnackBar('$fileName atașat ✓');
    } catch (e) {
      if (mounted) context.showSnackBar('Upload eșuat: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _pickImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
        allowMultiple: false,
      );
      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      final bytes = file.bytes;
      if (bytes == null || bytes.isEmpty) {
        if (mounted) context.showSnackBar('Nu s-au putut citi datele imaginii', isError: true);
        return;
      }

      final maxSize = AppConstants.maxAttachmentSizeMB * 1024 * 1024;
      if (bytes.length > maxSize) {
        if (mounted) context.showSnackBar('Fișierul e prea mare (max ${AppConstants.maxAttachmentSizeMB}MB)', isError: true);
        return;
      }

      await _uploadFileToTask(bytes, file.name);
    } catch (e) {
      if (mounted) context.showSnackBar('Nu s-a putut selecta imaginea: $e', isError: true);
    }
  }

  Future<void> _pickDocument() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'txt', 'csv'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      final bytes = file.bytes;
      if (bytes == null || bytes.isEmpty) {
        if (mounted) context.showSnackBar('Nu s-a putut citi fișierul', isError: true);
        return;
      }

      final maxSize = AppConstants.maxAttachmentSizeMB * 1024 * 1024;
      if (bytes.length > maxSize) {
        if (mounted) context.showSnackBar('Fișierul e prea mare (max ${AppConstants.maxAttachmentSizeMB}MB)', isError: true);
        return;
      }

      await _uploadFileToTask(bytes, file.name);
    } catch (e) {
      if (mounted) context.showSnackBar('Nu s-a putut selecta documentul: $e', isError: true);
    }
  }

  Future<void> _submit() async {
    // Auto-generate title if empty
    if (_titleController.text.trim().isEmpty) {
      final desc = _descriptionController.text.trim();
      if (desc.isEmpty) {
        context.showSnackBar('Adaugă o descriere', isError: true);
        return;
      }
      _titleController.text = desc.split(RegExp(r'\s+')).take(3).join(' ');
    }

    setState(() => _isSubmitting = true);

    try {
      final userId = SupabaseService.instance.currentUserId!;
      final currentNow = DateTime.now();

      // Default: if no date set, use today
      final effectiveDate = _dueDate ?? currentNow;

      // Default: if no time set, use current time
      final effectiveStartTime = _startTime ?? TimeOfDay(hour: currentNow.hour, minute: currentNow.minute);

      DateTime? startDateTime = DateTime(
        effectiveDate.year,
        effectiveDate.month,
        effectiveDate.day,
        effectiveStartTime.hour,
        effectiveStartTime.minute,
      );

      DateTime? endDateTime;
      if (_endTime != null) {
        endDateTime = DateTime(
          effectiveDate.year,
          effectiveDate.month,
          effectiveDate.day,
          _endTime!.hour,
          _endTime!.minute,
        );
      } else {
        // Auto-apply default duration
        final defaultMinutes = ref.read(defaultTaskDurationProvider);
        endDateTime = startDateTime.add(Duration(minutes: defaultMinutes));
      }

      // Use effective date as dueDate if not set
      if (_dueDate == null) _dueDate = DateTime(currentNow.year, currentNow.month, currentNow.day);
      final now = _dueDate!;

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

      final repo = ref.read(taskRepositoryProvider);

      if (_isEditMode) {
        // ── Edit mode: update existing task ──
        final updateData = <String, dynamic>{
          'title': _titleController.text.trim(),
          'description': _descriptionController.text.trim().nullIfEmpty,
          'priority': _priority.name,
          'due_date': _dueDate?.toIso8601String(),
          'end_date': _endDate?.toIso8601String(),
          'start_time': startDateTime?.toIso8601String(),
          'end_time': endDateTime?.toIso8601String(),
          'location_name': locName,
          'location_address': locAddress,
          'location_url': locUrl,
          'location_lat': locLat,
          'location_lng': locLng,
        };

        await repo.updateTask(widget.existingTask!.id, updateData);
        ref.invalidate(dailyTasksProvider);
        ref.invalidate(taskDetailProvider(widget.existingTask!.id));

        if (mounted) {
          Navigator.of(context).pop(true);
          context.showSnackBar('Task updated successfully');
        }
      } else {
        // ── Create mode ──
        String taskId;

        if (_earlyTaskId != null) {
          // Task was already created when user picked an attachment – update it with final data
          taskId = _earlyTaskId!;
          await repo.updateTask(taskId, {
            'title': _titleController.text.trim(),
            'description': _descriptionController.text.trim().nullIfEmpty,
            'priority': _priority.name,
            'due_date': _dueDate?.toIso8601String(),
            'end_date': _endDate?.toIso8601String(),
            'start_time': startDateTime?.toIso8601String(),
            'end_time': endDateTime?.toIso8601String(),
            'location_name': locName,
            'location_address': locAddress,
            'location_url': locUrl,
            'location_lat': locLat,
            'location_lng': locLng,
          });
        } else {
          // Normal creation (no early attachment)
          final task = TaskModel(
            id: '',
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim().nullIfEmpty,
            priority: _priority,
            createdBy: userId,
            dueDate: _dueDate,
            endDate: _endDate,
            startTime: startDateTime,
            endTime: endDateTime,
            labels: _labels,
            locationName: locName,
            locationAddress: locAddress,
            locationUrl: locUrl,
            locationLat: locLat,
            locationLng: locLng,
          );
          final createdTask = await repo.createTask(task);
          taskId = createdTask.id;
        }

        // Assign task if an assignee was selected
        if (_assigneeId != null) {
          await SupabaseService.instance.client.from('task_assignees').insert({
            'task_id': taskId,
            'user_id': _assigneeId,
            'assigned_by': userId,
          });
          // Notify assignee
          try {
            final notifRepo = NotificationRepository();
            await notifRepo.createNotification(
              userId: _assigneeId!,
              title: 'New Task Assigned',
              body: _titleController.text.trim(),
              type: 'task_assigned',
              data: {'task_id': taskId},
            );
            NotificationService.instance.notifyTaskEvent(
              title: 'Task Assigned',
              body: _titleController.text.trim(),
            );
          } catch (_) {}
        }

        // Add checklist items
        for (int i = 0; i < _checklistItems.length; i++) {
          await repo.addChecklistItem(
            taskId: taskId,
            title: _checklistItems[i],
            sortOrder: i,
          );
        }

        // Notify admins about new task
        try {
          final profile = ref.read(currentUserProfileProvider).valueOrNull;
          final notifRepo = NotificationRepository();
          await notifRepo.notifyAdmins(
            title: '${profile?.displayName ?? 'Someone'} a creat un task',
            body: _titleController.text.trim(),
            type: 'task_created',
            data: {'task_id': taskId},
          );
        } catch (_) {}

        ref.invalidate(dailyTasksProvider);

        if (mounted) {
          Navigator.of(context).pop();
          context.showSnackBar('Task creat');
        }
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
    final primaryColor = theme.colorScheme.primary;

    return Scaffold(
      appBar: KuziiniAppBar(
        showBackButton: true,
        title: _isEditMode ? 'Edit Task' : 'New Task',
        actions: [
          if (_isEditMode)
            IconButton(
              onPressed: () => _deleteTask(),
              icon: Icon(PhosphorIcons.trash(PhosphorIconsStyle.regular), color: AppColors.error),
              tooltip: 'Delete task',
            ),
          TextButton(
            onPressed: _isSubmitting ? null : _submit,
            child: _isSubmitting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    _isEditMode ? 'Save' : 'Create',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: primaryColor,
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
              // Description (primary input — title auto-generates from first 3 words)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: KuziiniTextField(
                      controller: _descriptionController,
                      focusNode: _descriptionFocusNode,
                      hint: 'Descrie task-ul...',
                      maxLines: 4,
                      minLines: 2,
                      autofocus: !_isEditMode,
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
                      hintText: 'Dictează descrierea...',
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

              // Date - show as compact info if pre-set, full picker if not
              if (_dueDate != null && widget.queryParams.containsKey('date'))
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Icon(PhosphorIcons.calendar(PhosphorIconsStyle.regular), size: 16, color: primaryColor),
                      const SizedBox(width: 8),
                      Text(
                        _endDate != null && _endDate != _dueDate
                            ? '${_dueDate!.day}/${_dueDate!.month} → ${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'
                            : '${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: primaryColor),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: _pickDate,
                        child: const Text('Change', style: TextStyle(fontSize: 11)),
                        style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                      ),
                    ],
                  ),
                )
              else
                _OptionTile(
                  icon: PhosphorIcons.calendar(PhosphorIconsStyle.regular),
                  label: _dueDate != null
                      ? _endDate != null && _endDate != _dueDate
                          ? '${_dueDate!.day}/${_dueDate!.month} → ${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'
                          : '${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}'
                      : 'Add due date',
                  isActive: _dueDate != null,
                  onTap: _pickDate,
                  onClear: _dueDate != null
                      ? () => setState(() { _dueDate = null; _endDate = null; })
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

              // End date (only if due date is set)
              if (_dueDate != null)
                _OptionTile(
                  icon: PhosphorIcons.calendarDots(PhosphorIconsStyle.regular),
                  label: _endDate != null
                      ? 'End date: ${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'
                      : 'Add end date',
                  isActive: _endDate != null,
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _endDate ?? _dueDate ?? DateTime.now(),
                      firstDate: _dueDate ?? DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                    );
                    if (date != null) setState(() => _endDate = date);
                  },
                  onClear: _endDate != null
                      ? () => setState(() => _endDate = null)
                      : null,
                ),

              // Period indicator
              if (_endDate != null && _dueDate != null && _endDate != _dueDate)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(PhosphorIcons.calendarDots(PhosphorIconsStyle.regular), size: 16, color: primaryColor),
                        const SizedBox(width: 8),
                        Text(
                          'Period: ${_endDate!.difference(_dueDate!).inDays + 1} days (${_dueDate!.day}/${_dueDate!.month} → ${_endDate!.day}/${_endDate!.month})',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: primaryColor),
                        ),
                      ],
                    ),
                  ),
                ),

              AppSpacing.vGapXl,

              // Location section
              Text('Location', style: theme.textTheme.labelLarge),
              AppSpacing.vGapSm,
              _LocationTile(
                locationName: _locationNameController.text,
                locationAddress: _locationAddressController.text,
                locationLink: _locationLinkController.text,
                onTap: () => _showLocationPicker(),
                onClear: () {
                  setState(() {
                    _locationNameController.text = '';
                    _locationAddressController.text = '';
                    _locationLinkController.text = '';
                    _locationLat = null;
                    _locationLng = null;
                    _useDefaultLocation = false;
                  });
                },
              ),

              AppSpacing.vGapMd,

              // Priority selector
              Text('Priority', style: theme.textTheme.labelLarge),
              AppSpacing.vGapSm,
              Wrap(
                spacing: 8,
                children: TaskPriority.values.where((p) => p != TaskPriority.none).map((priority) {
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

              // Add Photo / Doc
              Text('Atașamente', style: theme.textTheme.labelLarge),
              AppSpacing.vGapSm,
              Row(
                children: [
                  Expanded(
                    child: _OptionTile(
                      icon: PhosphorIcons.camera(PhosphorIconsStyle.regular),
                      label: _isUploading ? 'Se încarcă...' : 'Adaugă foto',
                      isActive: _earlyTaskId != null,
                      onTap: _isUploading ? () {} : () => _pickImage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _OptionTile(
                      icon: PhosphorIcons.file(PhosphorIconsStyle.regular),
                      label: _isUploading ? 'Se încarcă...' : 'Adaugă doc',
                      isActive: _earlyTaskId != null,
                      onTap: _isUploading ? () {} : () => _pickDocument(),
                    ),
                  ),
                ],
              ),

              // Show real uploaded attachments
              if (_earlyTaskId != null) ...[
                AppSpacing.vGapSm,
                AttachmentSection(taskId: _earlyTaskId!),
              ],

              if (_isUploading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: LinearProgressIndicator(),
                ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

class _LocationTile extends StatelessWidget {
  const _LocationTile({
    required this.locationName,
    required this.locationAddress,
    required this.locationLink,
    required this.onTap,
    this.onClear,
  });

  final String locationName;
  final String locationAddress;
  final String locationLink;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  bool get _hasLocation => locationName.isNotEmpty || locationAddress.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _hasLocation
              ? primaryColor.withValues(alpha: 0.06)
              : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _hasLocation
                ? primaryColor.withValues(alpha: 0.2)
                : theme.dividerColor.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.location_on,
              color: _hasLocation ? primaryColor : theme.colorScheme.onSurfaceVariant,
              size: 22,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _hasLocation
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (locationName.isNotEmpty)
                          Text(locationName, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14,
                            color: primaryColor)),
                        if (locationAddress.isNotEmpty)
                          Text(locationAddress, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                        if (locationLink.isNotEmpty)
                          Text(locationLink, style: TextStyle(fontSize: 11, color: Colors.blue,
                            decoration: TextDecoration.underline),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    )
                  : Text('Tap to set location',
                      style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 14)),
            ),
            if (_hasLocation && onClear != null)
              IconButton(
                onPressed: onClear,
                icon: Icon(Icons.close, size: 18, color: Colors.grey[400]),
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                padding: EdgeInsets.zero,
              )
            else
              Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
          ],
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
                  ? theme.colorScheme.primary
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


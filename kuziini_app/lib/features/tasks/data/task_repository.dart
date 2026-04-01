import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/services/supabase_service.dart';
import 'models/task_model.dart';
import 'models/task_comment.dart';
import 'models/task_attachment.dart';
import 'models/checklist_item.dart';

class TaskRepository {
  TaskRepository({SupabaseService? supabase})
      : _supabase = supabase ?? SupabaseService.instance;

  final SupabaseService _supabase;
  static const _uuid = Uuid();

  // ── Tasks CRUD ──

  Future<List<TaskModel>> fetchTasks({
    String? assigneeId,
    String? createdBy,
    TaskStatus? status,
    TaskPriority? priority,
    DateTime? fromDate,
    DateTime? toDate,
    String? orderBy,
    bool ascending = true,
    int limit = AppConstants.defaultPageSize,
    int offset = 0,
  }) async {
    var query = _supabase.client
        .from(AppConstants.tableTasks)
        .select('*');

    // assignee filtering is handled via task_assignees table
    // if (assigneeId != null) - use fetchTasksAssignedTo instead
    if (createdBy != null) {
      query = query.eq('created_by', createdBy);
    }
    if (status != null) {
      query = query.eq('status', status.name);
    }
    if (priority != null) {
      query = query.eq('priority', priority.name);
    }
    if (fromDate != null) {
      final fromStr = '${fromDate.year}-${fromDate.month.toString().padLeft(2, '0')}-${fromDate.day.toString().padLeft(2, '0')}';
      query = query.gte('due_date', fromStr);
    }
    if (toDate != null) {
      final toStr = '${toDate.year}-${toDate.month.toString().padLeft(2, '0')}-${toDate.day.toString().padLeft(2, '0')}';
      query = query.lte('due_date', toStr);
    }

    final response = await query
        .order(orderBy ?? 'created_at', ascending: ascending)
        .range(offset, offset + limit - 1);

    final tasks = (response as List)
        .map((json) => TaskModel.fromJson(json as Map<String, dynamic>))
        .toList();

    return _enrichTasksWithAssignees(tasks);
  }

  Future<List<TaskModel>> fetchTasksByDate(DateTime date) async {
    final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    final response = await _supabase.client
        .from(AppConstants.tableTasks)
        .select('*')
        .eq('due_date', dateStr)
        .order('start_time', ascending: true);

    final tasks = (response as List)
        .map((json) => TaskModel.fromJson(json as Map<String, dynamic>))
        .toList();

    return _enrichTasksWithAssignees(tasks);
  }

  Future<List<TaskModel>> fetchTodaysTasks() async {
    return fetchTasksByDate(DateTime.now());
  }

  Future<List<TaskModel>> fetchOverdueTasks() async {
    final now = DateTime.now();
    final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final response = await _supabase.client
        .from(AppConstants.tableTasks)
        .select('*')
        .lt('due_date', todayStr)
        .neq('status', 'done')
        .neq('status', 'archived')
        .order('due_date', ascending: true);

    return (response as List)
        .map((json) => TaskModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<List<TaskModel>> fetchUpcomingTasks({int days = 7}) async {
    final now = DateTime.now();
    final future = now.add(Duration(days: days));
    final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final futureStr = '${future.year}-${future.month.toString().padLeft(2, '0')}-${future.day.toString().padLeft(2, '0')}';

    final response = await _supabase.client
        .from(AppConstants.tableTasks)
        .select('*')
        .gte('due_date', todayStr)
        .lte('due_date', futureStr)
        .neq('status', 'done')
        .neq('status', 'archived')
        .order('due_date', ascending: true);

    return (response as List)
        .map((json) => TaskModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<TaskModel> fetchTaskById(String id) async {
    final response = await _supabase.selectSingle(
      AppConstants.tableTasks,
      filters: {'id': id},
    );
    var task = TaskModel.fromJson(response);

    // Enrich with assignee info
    final enriched = await _enrichTasksWithAssignees([task]);
    return enriched.first;
  }

  Future<TaskModel> createTask(TaskModel task) async {
    final data = task.toInsertJson();
    data['id'] = _uuid.v4();
    final response = await _supabase.insert(AppConstants.tableTasks, data);
    return TaskModel.fromJson(response);
  }

  Future<TaskModel> updateTask(String taskId, Map<String, dynamic> data) async {
    data['updated_at'] = DateTime.now().toIso8601String();
    final response = await _supabase.update(
      AppConstants.tableTasks,
      data,
      id: taskId,
    );
    return TaskModel.fromJson(response);
  }

  Future<TaskModel> updateTaskStatus(String taskId, TaskStatus status) async {
    final data = <String, dynamic>{'status': status.name};
    if (status == TaskStatus.done) {
      data['completed_at'] = DateTime.now().toIso8601String();
    }
    return updateTask(taskId, data);
  }

  Future<void> deleteTask(String taskId) async {
    await _supabase.delete(AppConstants.tableTasks, id: taskId);
  }

  Future<void> assignTask(String taskId, String assigneeId) async {
    final userId = _supabase.currentUserId;
    await _supabase.insert('task_assignees', {
      'task_id': taskId,
      'user_id': assigneeId,
      'assigned_by': userId,
    });
  }

  /// Fetches tasks assigned to a specific user via the task_assignees table.
  Future<List<TaskModel>> fetchTasksAssignedTo(String userId, {DateTime? date}) async {
    // Step 1: Get task IDs from task_assignees
    final assigneeRows = await _supabase.client
        .from('task_assignees')
        .select('task_id')
        .eq('user_id', userId);

    final taskIds = (assigneeRows as List)
        .map((row) => row['task_id'] as String)
        .toList();

    if (taskIds.isEmpty) return [];

    // Step 2: Fetch those tasks
    var query = _supabase.client
        .from(AppConstants.tableTasks)
        .select('*')
        .inFilter('id', taskIds);

    if (date != null) {
      final dateStr =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      query = query.eq('due_date', dateStr);
    }

    final response = await query.order('created_at', ascending: false);

    final tasks = (response as List)
        .map((json) => TaskModel.fromJson(json as Map<String, dynamic>))
        .toList();

    // Step 3: Enrich with assignee info
    return _enrichTasksWithAssignees(tasks);
  }

  /// Fetches assignee info for a single task from task_assignees joined with profiles.
  Future<List<Map<String, dynamic>>> fetchTaskAssignees(String taskId) async {
    final response = await _supabase.client
        .from('task_assignees')
        .select('*, profiles:user_id(id, full_name, email, avatar_url)')
        .eq('task_id', taskId);

    return List<Map<String, dynamic>>.from(response as List);
  }

  /// Reassign a task: delete old assignments and insert a new one.
  Future<void> reassignTask(String taskId, String newAssigneeId) async {
    final userId = _supabase.currentUserId;

    // Delete existing assignments for this task
    await _supabase.client
        .from('task_assignees')
        .delete()
        .eq('task_id', taskId);

    // Insert new assignment
    await _supabase.client.from('task_assignees').insert({
      'task_id': taskId,
      'user_id': newAssigneeId,
      'assigned_by': userId,
    });
  }

  /// Enrich a list of tasks with assignee information from task_assignees + profiles.
  Future<List<TaskModel>> _enrichTasksWithAssignees(List<TaskModel> tasks) async {
    if (tasks.isEmpty) return tasks;

    final taskIds = tasks.map((t) => t.id).toList();

    final assigneeRows = await _supabase.client
        .from('task_assignees')
        .select('task_id, profiles:user_id(id, full_name, avatar_url)')
        .inFilter('task_id', taskIds);

    // Build a map: taskId -> first assignee info
    final assigneeMap = <String, Map<String, dynamic>>{};
    for (final row in (assigneeRows as List)) {
      final taskId = row['task_id'] as String;
      if (!assigneeMap.containsKey(taskId)) {
        final profile = row['profiles'] as Map<String, dynamic>?;
        if (profile != null) {
          assigneeMap[taskId] = profile;
        }
      }
    }

    // Enrich tasks
    return tasks.map((task) {
      final assignee = assigneeMap[task.id];
      if (assignee != null) {
        return task.copyWith(
          assigneeId: assignee['id'] as String?,
          assigneeName: assignee['full_name'] as String?,
          assigneeAvatarUrl: assignee['avatar_url'] as String?,
        );
      }
      return task;
    }).toList();
  }

  // ── Real-time ──

  RealtimeChannel subscribeToTasks({
    required void Function(TaskModel task) onInsert,
    void Function(TaskModel task)? onUpdate,
    void Function(String taskId)? onDelete,
  }) {
    return _supabase.subscribe(
      AppConstants.tableTasks,
      onInsert: (payload) {
        final task = TaskModel.fromJson(payload.newRecord);
        onInsert(task);
      },
      onUpdate: onUpdate != null
          ? (payload) {
              final task = TaskModel.fromJson(payload.newRecord);
              onUpdate(task);
            }
          : null,
      onDelete: onDelete != null
          ? (payload) {
              final id = payload.oldRecord['id'] as String?;
              if (id != null) onDelete(id);
            }
          : null,
    );
  }

  void unsubscribe(RealtimeChannel channel) {
    _supabase.unsubscribe(channel);
  }

  // ── Comments ──

  Future<List<TaskComment>> fetchComments(String taskId) async {
    final response = await _supabase.select(
      AppConstants.tableTaskComments,
      filters: {'task_id': taskId},
      orderBy: 'created_at',
      ascending: true,
    );
    return response.map((json) => TaskComment.fromJson(json)).toList();
  }

  Future<TaskComment> addComment({
    required String taskId,
    required String userId,
    required String content,
  }) async {
    final comment = TaskComment(
      id: _uuid.v4(),
      taskId: taskId,
      userId: userId,
      content: content,
    );
    final response = await _supabase.insert(
      AppConstants.tableTaskComments,
      comment.toInsertJson(),
    );
    return TaskComment.fromJson(response);
  }

  Future<void> updateComment(String commentId, String content) async {
    await _supabase.update(
      AppConstants.tableTaskComments,
      {
        'content': content,
        'updated_at': DateTime.now().toIso8601String(),
        'is_edited': true,
      },
      id: commentId,
    );
  }

  Future<void> deleteComment(String commentId) async {
    await _supabase.delete(AppConstants.tableTaskComments, id: commentId);
  }

  // ── Checklist ──

  Future<List<ChecklistItem>> fetchChecklist(String taskId) async {
    final response = await _supabase.select(
      AppConstants.tableChecklistItems,
      filters: {'task_id': taskId},
      orderBy: 'sort_order',
      ascending: true,
    );
    return response.map((json) => ChecklistItem.fromJson(json)).toList();
  }

  Future<ChecklistItem> addChecklistItem({
    required String taskId,
    required String title,
    int sortOrder = 0,
  }) async {
    final item = ChecklistItem(
      id: _uuid.v4(),
      taskId: taskId,
      title: title,
      sortOrder: sortOrder,
    );
    final response = await _supabase.insert(
      AppConstants.tableChecklistItems,
      item.toInsertJson(),
    );
    return ChecklistItem.fromJson(response);
  }

  Future<void> toggleChecklistItem(String itemId, bool isCompleted) async {
    await _supabase.update(
      AppConstants.tableChecklistItems,
      {
        'is_completed': isCompleted,
        'completed_at': isCompleted ? DateTime.now().toIso8601String() : null,
      },
      id: itemId,
    );
  }

  Future<void> deleteChecklistItem(String itemId) async {
    await _supabase.delete(AppConstants.tableChecklistItems, id: itemId);
  }

  // ── Attachments ──

  Future<List<TaskAttachment>> fetchAttachments(String taskId) async {
    final response = await _supabase.select(
      AppConstants.tableTaskAttachments,
      filters: {'task_id': taskId},
      orderBy: 'created_at',
      ascending: false,
    );
    return response.map((json) => TaskAttachment.fromJson(json)).toList();
  }

  Future<TaskAttachment> uploadAttachment({
    required String taskId,
    required String userId,
    required Uint8List fileBytes,
    required String fileName,
  }) async {
    final fileExt = fileName.split('.').last;
    final storagePath = 'tasks/$taskId/${_uuid.v4()}.$fileExt';

    final fileUrl = await _supabase.uploadFile(
      AppConstants.bucketAttachments,
      storagePath,
      fileBytes,
    );

    final attachment = TaskAttachment(
      id: _uuid.v4(),
      taskId: taskId,
      uploadedBy: userId,
      fileName: fileName,
      fileUrl: fileUrl,
      fileType: fileExt,
      fileSizeBytes: fileBytes.length,
    );

    final response = await _supabase.insert(
      AppConstants.tableTaskAttachments,
      attachment.toInsertJson(),
    );
    return TaskAttachment.fromJson(response);
  }

  Future<void> deleteAttachment(TaskAttachment attachment) async {
    try {
      final uri = Uri.parse(attachment.fileUrl);
      final path = uri.pathSegments.skip(1).join('/');
      await _supabase.deleteFile(AppConstants.bucketAttachments, path);
    } catch (e) {
      debugPrint('Failed to delete file from storage: $e');
    }
    await _supabase.delete(AppConstants.tableTaskAttachments, id: attachment.id);
  }

  // ── Search ──

  Future<List<TaskModel>> searchTasks(String query, {int limit = 20}) async {
    final response = await _supabase.client
        .from(AppConstants.tableTasks)
        .select('*')
        .or('title.ilike.%$query%,description.ilike.%$query%')
        .order('created_at', ascending: false)
        .limit(limit);

    return (response as List)
        .map((json) => TaskModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  // ── Statistics ──

  Future<Map<String, int>> getTaskStats({String? userId}) async {
    var query = _supabase.client.from(AppConstants.tableTasks).select('status');
    if (userId != null) {
      query = query.eq('created_by', userId);
    }

    final response = await query;
    final tasks = response as List;

    int total = tasks.length;
    int done = tasks.where((t) => t['status'] == 'done').length;
    int inProgress = tasks.where((t) => t['status'] == 'in_progress').length;
    int todo = tasks.where((t) => t['status'] == 'todo').length;
    int review = tasks.where((t) => t['status'] == 'review').length;

    return {
      'total': total,
      'done': done,
      'in_progress': inProgress,
      'todo': todo,
      'review': review,
    };
  }
}

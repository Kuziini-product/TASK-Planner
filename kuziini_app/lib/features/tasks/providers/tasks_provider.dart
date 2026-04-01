import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/supabase_service.dart';
import '../data/models/task_model.dart';
import '../data/models/task_comment.dart';
import '../data/models/task_attachment.dart';
import '../data/models/checklist_item.dart';
import '../data/task_repository.dart';

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  return TaskRepository();
});

// ── Selected Date ──

final selectedDateProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});

// ── Daily Tasks ──

final dailyTasksProvider =
    AsyncNotifierProvider<DailyTasksNotifier, List<TaskModel>>(
  DailyTasksNotifier.new,
);

class DailyTasksNotifier extends AsyncNotifier<List<TaskModel>> {
  late TaskRepository _repo;
  RealtimeChannel? _subscription;

  @override
  Future<List<TaskModel>> build() async {
    _repo = ref.read(taskRepositoryProvider);
    final date = ref.watch(selectedDateProvider);
    final filter = ref.watch(taskFilterProvider);
    final teamUser = ref.watch(selectedTeamUserProvider);

    // Set up real-time subscription
    _subscription?.unsubscribe();
    _subscription = _repo.subscribeToTasks(
      onInsert: (task) => _refreshTasks(),
      onUpdate: (task) => _refreshTasks(),
      onDelete: (taskId) => _refreshTasks(),
    );

    ref.onDispose(() {
      if (_subscription != null) {
        _repo.unsubscribe(_subscription!);
      }
    });

    return _fetchFiltered(date, filter, teamUser);
  }

  Future<List<TaskModel>> _fetchFiltered(DateTime date, TaskFilterType filter, String? teamUserId) async {
    final userId = SupabaseService.instance.currentUserId;

    // If viewing team tasks
    if (teamUserId != null) {
      final tasks = await _repo.fetchTasksByDate(date);
      if (teamUserId == 'all') {
        // Show all team tasks (no filter)
        return tasks;
      }
      // Filter by specific team member
      return tasks.where((t) => t.createdBy == teamUserId || t.assigneeId == teamUserId).toList();
    }

    switch (filter) {
      case TaskFilterType.assignedToMe:
        if (userId == null) return [];
        return _repo.fetchTasksAssignedTo(userId, date: date);
      case TaskFilterType.myTasks:
        if (userId == null) return [];
        return _repo.fetchTasks(createdBy: userId, fromDate: date, toDate: date);
      case TaskFilterType.overdue:
        return _repo.fetchOverdueTasks();
      case TaskFilterType.done:
        final all = await _repo.fetchTasksByDate(date);
        return all.where((t) => t.isCompleted).toList();
      case TaskFilterType.inProgress:
        final all = await _repo.fetchTasksByDate(date);
        return all.where((t) => t.status == TaskStatus.in_progress).toList();
      case TaskFilterType.all:
        return _repo.fetchTasksByDate(date);
    }
  }

  Future<void> _refreshTasks() async {
    final date = ref.read(selectedDateProvider);
    final filter = ref.read(taskFilterProvider);
    final teamUser = ref.read(selectedTeamUserProvider);
    state = await AsyncValue.guard(() => _fetchFiltered(date, filter, teamUser));
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    await _refreshTasks();
  }

  Future<void> completeTask(String taskId) async {
    state = await AsyncValue.guard(() async {
      await _repo.updateTaskStatus(taskId, TaskStatus.done);
      final date = ref.read(selectedDateProvider);
      final filter = ref.read(taskFilterProvider);
      final teamUser = ref.read(selectedTeamUserProvider);
      return _fetchFiltered(date, filter, teamUser);
    });
  }

  Future<void> updateTaskStatus(String taskId, TaskStatus status) async {
    state = await AsyncValue.guard(() async {
      await _repo.updateTaskStatus(taskId, status);
      final date = ref.read(selectedDateProvider);
      final filter = ref.read(taskFilterProvider);
      final teamUser = ref.read(selectedTeamUserProvider);
      return _fetchFiltered(date, filter, teamUser);
    });
  }
}

// ── Task Detail ──

final taskDetailProvider =
    FutureProvider.family<TaskModel, String>((ref, taskId) async {
  final repo = ref.watch(taskRepositoryProvider);
  return repo.fetchTaskById(taskId);
});

// ── Task Comments ──

final taskCommentsProvider =
    FutureProvider.family<List<TaskComment>, String>((ref, taskId) async {
  final repo = ref.watch(taskRepositoryProvider);
  return repo.fetchComments(taskId);
});

// ── Task Checklist ──

final taskChecklistProvider =
    FutureProvider.family<List<ChecklistItem>, String>((ref, taskId) async {
  final repo = ref.watch(taskRepositoryProvider);
  return repo.fetchChecklist(taskId);
});

// ── Task Attachments ──

final taskAttachmentsProvider =
    FutureProvider.family<List<TaskAttachment>, String>((ref, taskId) async {
  final repo = ref.watch(taskRepositoryProvider);
  return repo.fetchAttachments(taskId);
});

// ── Task Assignees ──

final taskAssigneesProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((ref, taskId) async {
  final repo = ref.watch(taskRepositoryProvider);
  return repo.fetchTaskAssignees(taskId);
});

// ── Overdue Tasks ──

final overdueTasksProvider = FutureProvider<List<TaskModel>>((ref) async {
  final repo = ref.watch(taskRepositoryProvider);
  return repo.fetchOverdueTasks();
});

// ── Upcoming Tasks ──

final upcomingTasksProvider = FutureProvider<List<TaskModel>>((ref) async {
  final repo = ref.watch(taskRepositoryProvider);
  return repo.fetchUpcomingTasks();
});

// ── Task Filters ──

enum TaskFilterType { all, myTasks, assignedToMe, overdue, done, inProgress }

final taskFilterProvider = StateProvider<TaskFilterType>((ref) {
  return TaskFilterType.all;
});

final taskPriorityFilterProvider = StateProvider<TaskPriority?>((ref) {
  return null;
});

final taskStatusFilterProvider = StateProvider<TaskStatus?>((ref) {
  return null;
});

/// Selected team member ID for admin/manager view.
/// null = show all team tasks, non-null = filter by specific user.
final selectedTeamUserProvider = StateProvider<String?>((ref) {
  return null;
});

// ── Daily Progress ──

final dailyProgressProvider = Provider<double>((ref) {
  final tasks = ref.watch(dailyTasksProvider);
  return tasks.when(
    data: (taskList) {
      if (taskList.isEmpty) return 0.0;
      final completed = taskList.where((t) => t.isCompleted).length;
      return completed / taskList.length;
    },
    loading: () => 0.0,
    error: (_, __) => 0.0,
  );
});

// ── Task Stats ──

final taskStatsProvider = FutureProvider<Map<String, int>>((ref) async {
  final repo = ref.watch(taskRepositoryProvider);
  return repo.getTaskStats();
});

// ── Calendar Tasks ──

final calendarTasksProvider = FutureProvider.family<List<TaskModel>,
    ({DateTime from, DateTime to})>((ref, range) async {
  final repo = ref.watch(taskRepositoryProvider);
  return repo.fetchTasks(
    fromDate: range.from,
    toDate: range.to,
    limit: 200,
  );
});

import 'dart:async';

import 'package:flutter/foundation.dart';
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
    // Watch priority and status filters to auto-refresh
    ref.watch(taskPriorityFilterProvider);
    ref.watch(taskStatusFilterProvider);

    // Set up real-time subscription
    _subscription?.unsubscribe();
    _subscription = _repo.subscribeToTasks(
      onInsert: (task) {
        debugPrint('RT: task inserted');
        _refreshTasks();
      },
      onUpdate: (task) {
        debugPrint('RT: task updated');
        _refreshTasks();
      },
      onDelete: (taskId) {
        debugPrint('RT: task deleted');
        _refreshTasks();
      },
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
    final priorityFilter = ref.read(taskPriorityFilterProvider);
    final statusFilter = ref.read(taskStatusFilterProvider);

    // Fetch base tasks - always fetch broadly enough
    List<TaskModel> tasks;
    if (filter == TaskFilterType.all) {
      // All: fetch all tasks
      if (teamUserId != null && teamUserId != 'all') {
        // Fetch all for specific user
        tasks = await _repo.fetchTasks(createdBy: teamUserId, limit: 200);
        final assigned = await _repo.fetchTasksAssignedTo(teamUserId);
        final ids = tasks.map((t) => t.id).toSet();
        for (final t in assigned) {
          if (!ids.contains(t.id)) tasks.add(t);
        }
      } else {
        tasks = await _repo.fetchTasks(limit: 200);
      }
    } else if (filter == TaskFilterType.today) {
      // Today: selected date tasks
      tasks = await _repo.fetchTasksByDate(date);
      // Add tasks without due_date
      final allRecent = await _repo.fetchTasks(limit: 100);
      final noDueDate = allRecent.where((t) => t.dueDate == null).toList();
      final ids = tasks.map((t) => t.id).toSet();
      for (final t in noDueDate) {
        if (!ids.contains(t.id)) tasks.add(t);
      }
    } else if (filter == TaskFilterType.overdue) {
      tasks = await _repo.fetchOverdueTasks();
    } else if (filter == TaskFilterType.assignedToMe) {
      if (userId == null) return [];
      tasks = await _repo.fetchTasksAssignedTo(userId);
    } else if (filter == TaskFilterType.done || filter == TaskFilterType.inProgress) {
      // Done/InProgress: fetch all tasks so we can filter by status
      tasks = await _repo.fetchTasks(limit: 500);
    } else {
      tasks = await _repo.fetchTasksByDate(date);
    }

    // Apply all filters simultaneously
    var result = tasks.where((t) => !t.isArchived);

    // Team user filter (for today/overdue/done/inProgress which fetch all users)
    if (teamUserId != null && teamUserId != 'all' && filter != TaskFilterType.all) {
      result = result.where((t) => t.createdBy == teamUserId || t.assigneeId == teamUserId);
    }

    // Status filter from More menu
    if (filter == TaskFilterType.done) {
      result = result.where((t) => t.isCompleted);
    } else if (filter == TaskFilterType.inProgress) {
      result = result.where((t) => t.status == TaskStatus.in_progress);
    }

    // Additional status filter (from statusFilterProvider)
    if (statusFilter != null) {
      result = result.where((t) => t.status == statusFilter);
    }

    // Priority filter
    if (priorityFilter != null) {
      result = result.where((t) => t.priority == priorityFilter);
    }

    final sorted = result.toList();

    if (filter == TaskFilterType.all) {
      // Sort by date (newest first for past, oldest first for future)
      sorted.sort((a, b) {
        final da = a.dueDate ?? a.createdAt ?? DateTime(2099);
        final db = b.dueDate ?? b.createdAt ?? DateTime(2099);
        return da.compareTo(db);
      });
    } else {
      // Sort: priority first (urgent→low), then by time
      sorted.sort((a, b) {
        final pa = a.priority.index;
        final pb = b.priority.index;
        if (pa != pb) return pa.compareTo(pb);
        final ta = a.startTime ?? a.dueDate ?? DateTime(2099);
        final tb = b.startTime ?? b.dueDate ?? DateTime(2099);
        return ta.compareTo(tb);
      });
    }

    return sorted;
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

// ── Weekly Stats ──

final weeklyStatsProvider = FutureProvider<Map<String, int>>((ref) async {
  final repo = ref.watch(taskRepositoryProvider);
  final now = DateTime.now();
  final weekStart = now.subtract(Duration(days: now.weekday - 1));
  final weekEnd = weekStart.add(const Duration(days: 6));
  final tasks = await repo.fetchTasks(fromDate: weekStart, toDate: weekEnd, limit: 500);
  final nonArchived = tasks.where((t) => t.status != TaskStatus.archived).toList();

  return {
    'total': nonArchived.length,
    'done': nonArchived.where((t) => t.status == TaskStatus.done).length,
    'in_progress': nonArchived.where((t) => t.status == TaskStatus.in_progress).length,
    'todo': nonArchived.where((t) => t.status == TaskStatus.todo).length,
  };
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

enum TaskFilterType { all, today, assignedToMe, overdue, done, inProgress }

final taskFilterProvider = StateProvider<TaskFilterType>((ref) {
  return TaskFilterType.today;
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

// ── Calendar Tasks (auto-refresh when daily tasks change via realtime) ──

final calendarTasksProvider = FutureProvider.family<List<TaskModel>,
    ({DateTime from, DateTime to})>((ref, range) async {
  // Watch dailyTasksProvider to auto-refresh when realtime updates arrive
  ref.watch(dailyTasksProvider);
  final repo = ref.watch(taskRepositoryProvider);
  return repo.fetchTasks(
    fromDate: range.from,
    toDate: range.to,
    limit: 200,
  );
});

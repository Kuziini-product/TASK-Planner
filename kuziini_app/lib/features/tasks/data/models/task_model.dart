enum TaskStatus {
  todo('To Do'),
  in_progress('In Progress'),
  review('Review'),
  done('Done'),
  archived('Archived');

  const TaskStatus(this.label);
  final String label;

  static TaskStatus fromString(String value) {
    return TaskStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => TaskStatus.todo,
    );
  }
}

enum TaskPriority {
  urgent('Urgent', 0),
  high('High', 1),
  medium('Medium', 2),
  low('Low', 3),
  none('None', 4);

  const TaskPriority(this.label, this.sortOrder);
  final String label;
  final int sortOrder;

  static TaskPriority fromString(String value) {
    return TaskPriority.values.firstWhere(
      (e) => e.name == value,
      orElse: () => TaskPriority.none,
    );
  }
}

class TaskModel {
  const TaskModel({
    required this.id,
    required this.title,
    this.description,
    this.status = TaskStatus.todo,
    this.priority = TaskPriority.none,
    required this.createdBy,
    this.assigneeId,
    this.assigneeName,
    this.assigneeAvatarUrl,
    this.creatorName,
    this.creatorAvatarUrl,
    this.dueDate,
    this.startTime,
    this.endTime,
    this.labels = const [],
    this.checklistTotal = 0,
    this.checklistCompleted = 0,
    this.commentCount = 0,
    this.attachmentCount = 0,
    this.isRecurring = false,
    this.recurringPattern,
    this.parentTaskId,
    this.createdAt,
    this.updatedAt,
    this.completedAt,
  });

  final String id;
  final String title;
  final String? description;
  final TaskStatus status;
  final TaskPriority priority;
  final String createdBy;
  final String? assigneeId;
  final String? assigneeName;
  final String? assigneeAvatarUrl;
  final String? creatorName;
  final String? creatorAvatarUrl;
  final DateTime? dueDate;
  final DateTime? startTime;
  final DateTime? endTime;
  final List<String> labels;
  final int checklistTotal;
  final int checklistCompleted;
  final int commentCount;
  final int attachmentCount;
  final bool isRecurring;
  final String? recurringPattern;
  final String? parentTaskId;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? completedAt;

  bool get isCompleted => status == TaskStatus.done;
  bool get isArchived => status == TaskStatus.archived;
  bool get isOverdue =>
      dueDate != null && dueDate!.isBefore(DateTime.now()) && !isCompleted;
  bool get hasChecklist => checklistTotal > 0;
  bool get hasComments => commentCount > 0;
  bool get hasAttachments => attachmentCount > 0;
  bool get isAssigned => assigneeId != null;
  bool get isSubtask => parentTaskId != null;

  double get checklistProgress =>
      checklistTotal > 0 ? checklistCompleted / checklistTotal : 0;

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      status: TaskStatus.fromString(json['status'] as String? ?? 'todo'),
      priority: TaskPriority.fromString(json['priority'] as String? ?? 'none'),
      createdBy: json['created_by'] as String,
      assigneeId: json['assignee_id'] as String?,
      assigneeName: json['assignee_name'] as String?,
      assigneeAvatarUrl: json['assignee_avatar_url'] as String?,
      creatorName: json['creator_name'] as String?,
      creatorAvatarUrl: json['creator_avatar_url'] as String?,
      dueDate: json['due_date'] != null
          ? DateTime.parse(json['due_date'] as String)
          : null,
      startTime: json['start_time'] != null
          ? DateTime.parse(json['start_time'] as String)
          : null,
      endTime: json['end_time'] != null
          ? DateTime.parse(json['end_time'] as String)
          : null,
      labels: json['labels'] != null
          ? List<String>.from(json['labels'] as List)
          : const [],
      checklistTotal: json['checklist_total'] as int? ?? 0,
      checklistCompleted: json['checklist_completed'] as int? ?? 0,
      commentCount: json['comment_count'] as int? ?? 0,
      attachmentCount: json['attachment_count'] as int? ?? 0,
      isRecurring: json['is_recurring'] as bool? ?? false,
      recurringPattern: json['recurring_pattern'] as String?,
      parentTaskId: json['parent_task_id'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'title': title,
      'description': description ?? '',
      'status': status.name,
      'priority': priority.name,
      'created_by': createdBy,
      'due_date': dueDate != null
          ? '${dueDate!.year}-${dueDate!.month.toString().padLeft(2, '0')}-${dueDate!.day.toString().padLeft(2, '0')}'
          : null,
      'start_time': startTime?.toUtc().toIso8601String(),
      'end_time': endTime?.toUtc().toIso8601String(),
      'recurrence_rule': recurringPattern,
      'parent_task_id': parentTaskId,
    };
    json.removeWhere((key, value) => value == null);
    return json;
  }

  Map<String, dynamic> toInsertJson() {
    final json = toJson();
    return json;
  }

  TaskModel copyWith({
    String? id,
    String? title,
    String? description,
    TaskStatus? status,
    TaskPriority? priority,
    String? createdBy,
    String? assigneeId,
    String? assigneeName,
    String? assigneeAvatarUrl,
    String? creatorName,
    String? creatorAvatarUrl,
    DateTime? dueDate,
    DateTime? startTime,
    DateTime? endTime,
    List<String>? labels,
    int? checklistTotal,
    int? checklistCompleted,
    int? commentCount,
    int? attachmentCount,
    bool? isRecurring,
    String? recurringPattern,
    String? parentTaskId,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? completedAt,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      createdBy: createdBy ?? this.createdBy,
      assigneeId: assigneeId ?? this.assigneeId,
      assigneeName: assigneeName ?? this.assigneeName,
      assigneeAvatarUrl: assigneeAvatarUrl ?? this.assigneeAvatarUrl,
      creatorName: creatorName ?? this.creatorName,
      creatorAvatarUrl: creatorAvatarUrl ?? this.creatorAvatarUrl,
      dueDate: dueDate ?? this.dueDate,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      labels: labels ?? this.labels,
      checklistTotal: checklistTotal ?? this.checklistTotal,
      checklistCompleted: checklistCompleted ?? this.checklistCompleted,
      commentCount: commentCount ?? this.commentCount,
      attachmentCount: attachmentCount ?? this.attachmentCount,
      isRecurring: isRecurring ?? this.isRecurring,
      recurringPattern: recurringPattern ?? this.recurringPattern,
      parentTaskId: parentTaskId ?? this.parentTaskId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}

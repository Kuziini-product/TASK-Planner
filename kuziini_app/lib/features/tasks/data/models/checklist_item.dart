class ChecklistItem {
  const ChecklistItem({
    required this.id,
    required this.taskId,
    required this.title,
    this.isCompleted = false,
    this.sortOrder = 0,
    this.createdAt,
    this.completedAt,
  });

  final String id;
  final String taskId;
  final String title;
  final bool isCompleted;
  final int sortOrder;
  final DateTime? createdAt;
  final DateTime? completedAt;

  factory ChecklistItem.fromJson(Map<String, dynamic> json) {
    return ChecklistItem(
      id: json['id'] as String,
      taskId: json['task_id'] as String,
      title: json['title'] as String,
      isCompleted: json['is_completed'] as bool? ?? false,
      sortOrder: json['sort_order'] as int? ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'task_id': taskId,
      'title': title,
      'is_completed': isCompleted,
      'sort_order': sortOrder,
      'created_at': createdAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
    };
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'task_id': taskId,
      'title': title,
      'is_completed': isCompleted,
      'sort_order': sortOrder,
      'created_at': DateTime.now().toIso8601String(),
    };
  }

  ChecklistItem copyWith({
    String? id,
    String? taskId,
    String? title,
    bool? isCompleted,
    int? sortOrder,
    DateTime? createdAt,
    DateTime? completedAt,
  }) {
    return ChecklistItem(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}

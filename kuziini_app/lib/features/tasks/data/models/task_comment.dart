class TaskComment {
  const TaskComment({
    required this.id,
    required this.taskId,
    required this.userId,
    required this.content,
    this.userName,
    this.userAvatarUrl,
    this.createdAt,
    this.updatedAt,
    this.isEdited = false,
  });

  final String id;
  final String taskId;
  final String userId;
  final String content;
  final String? userName;
  final String? userAvatarUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool isEdited;

  factory TaskComment.fromJson(Map<String, dynamic> json) {
    return TaskComment(
      id: json['id'] as String,
      taskId: json['task_id'] as String,
      userId: json['user_id'] as String,
      content: json['content'] as String,
      userName: json['user_name'] as String?,
      userAvatarUrl: json['user_avatar_url'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      isEdited: json['is_edited'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'task_id': taskId,
      'user_id': userId,
      'content': content,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'is_edited': isEdited,
    };
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'task_id': taskId,
      'user_id': userId,
      'content': content,
      'created_at': DateTime.now().toIso8601String(),
    };
  }

  TaskComment copyWith({
    String? id,
    String? taskId,
    String? userId,
    String? content,
    String? userName,
    String? userAvatarUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isEdited,
  }) {
    return TaskComment(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      userId: userId ?? this.userId,
      content: content ?? this.content,
      userName: userName ?? this.userName,
      userAvatarUrl: userAvatarUrl ?? this.userAvatarUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isEdited: isEdited ?? this.isEdited,
    );
  }
}

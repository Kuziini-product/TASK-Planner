class TaskAttachment {
  const TaskAttachment({
    required this.id,
    required this.taskId,
    required this.uploadedBy,
    required this.fileName,
    required this.fileUrl,
    this.fileType,
    this.fileSizeBytes,
    this.thumbnailUrl,
    this.uploaderName,
    this.createdAt,
  });

  final String id;
  final String taskId;
  final String uploadedBy;
  final String fileName;
  final String fileUrl;
  final String? fileType;
  final int? fileSizeBytes;
  final String? thumbnailUrl;
  final String? uploaderName;
  final DateTime? createdAt;

  bool get isImage {
    final ext = fileName.split('.').last.toLowerCase();
    return ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'].contains(ext);
  }

  bool get isPdf {
    return fileName.toLowerCase().endsWith('.pdf');
  }

  String get fileSizeFormatted {
    if (fileSizeBytes == null) return '';
    if (fileSizeBytes! < 1024) return '${fileSizeBytes}B';
    if (fileSizeBytes! < 1024 * 1024) {
      return '${(fileSizeBytes! / 1024).toStringAsFixed(1)}KB';
    }
    return '${(fileSizeBytes! / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  String get fileExtension => fileName.split('.').last.toUpperCase();

  factory TaskAttachment.fromJson(Map<String, dynamic> json) {
    return TaskAttachment(
      id: json['id'] as String,
      taskId: json['task_id'] as String,
      uploadedBy: json['uploaded_by'] as String,
      fileName: json['file_name'] as String,
      fileUrl: json['file_url'] as String,
      fileType: json['file_type'] as String?,
      fileSizeBytes: json['file_size_bytes'] as int?,
      thumbnailUrl: json['thumbnail_url'] as String?,
      uploaderName: json['uploader_name'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'task_id': taskId,
      'uploaded_by': uploadedBy,
      'file_name': fileName,
      'file_url': fileUrl,
      'file_type': fileType,
      'file_size_bytes': fileSizeBytes,
      'thumbnail_url': thumbnailUrl,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'task_id': taskId,
      'uploaded_by': uploadedBy,
      'file_name': fileName,
      'file_url': fileUrl,
      'file_type': fileType,
      'file_size_bytes': fileSizeBytes,
      'thumbnail_url': thumbnailUrl,
      'created_at': DateTime.now().toIso8601String(),
    };
  }

  TaskAttachment copyWith({
    String? id,
    String? taskId,
    String? uploadedBy,
    String? fileName,
    String? fileUrl,
    String? fileType,
    int? fileSizeBytes,
    String? thumbnailUrl,
    String? uploaderName,
    DateTime? createdAt,
  }) {
    return TaskAttachment(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      uploadedBy: uploadedBy ?? this.uploadedBy,
      fileName: fileName ?? this.fileName,
      fileUrl: fileUrl ?? this.fileUrl,
      fileType: fileType ?? this.fileType,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      uploaderName: uploaderName ?? this.uploaderName,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

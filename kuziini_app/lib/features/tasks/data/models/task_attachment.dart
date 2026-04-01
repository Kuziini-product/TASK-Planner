class TaskAttachment {
  const TaskAttachment({
    required this.id,
    required this.taskId,
    required this.uploadedBy,
    required this.fileName,
    required this.filePath,
    this.fileSize,
    this.mimeType,
    this.thumbnailUrl,
    this.uploaderName,
    this.createdAt,
  });

  final String id;
  final String taskId;
  final String uploadedBy;
  final String fileName;
  final String filePath;
  final int? fileSize;
  final String? mimeType;
  final String? thumbnailUrl;
  final String? uploaderName;
  final DateTime? createdAt;

  bool get isImage {
    final ext = fileName.split('.').last.toLowerCase();
    return ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'].contains(ext);
  }

  bool get isPdf => fileName.toLowerCase().endsWith('.pdf');

  String get fileSizeFormatted {
    if (fileSize == null) return '';
    if (fileSize! < 1024) return '${fileSize}B';
    if (fileSize! < 1024 * 1024) return '${(fileSize! / 1024).toStringAsFixed(1)}KB';
    return '${(fileSize! / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  String get fileExtension => fileName.split('.').last.toUpperCase();

  factory TaskAttachment.fromJson(Map<String, dynamic> json) {
    return TaskAttachment(
      id: json['id'] as String,
      taskId: json['task_id'] as String,
      uploadedBy: json['uploaded_by'] as String,
      fileName: json['file_name'] as String,
      filePath: json['file_path'] as String,
      fileSize: json['file_size'] as int?,
      mimeType: json['mime_type'] as String?,
      thumbnailUrl: json['thumbnail_url'] as String?,
      uploaderName: json['uploader_name'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'task_id': taskId,
      'uploaded_by': uploadedBy,
      'file_name': fileName,
      'file_path': filePath,
      'file_size': fileSize ?? 0,
      'mime_type': mimeType ?? 'application/octet-stream',
      'thumbnail_url': thumbnailUrl,
    };
  }
}

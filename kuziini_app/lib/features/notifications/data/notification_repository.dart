import '../../../core/constants/app_constants.dart';
import '../../../core/services/supabase_service.dart';

class NotificationModel {
  const NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    this.type,
    this.data,
    this.isRead = false,
    this.createdAt,
  });

  final String id;
  final String userId;
  final String title;
  final String body;
  final String? type;
  final Map<String, dynamic>? data;
  final bool isRead;
  final DateTime? createdAt;

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      type: json['type'] as String?,
      data: json['data'] as Map<String, dynamic>?,
      isRead: json['is_read'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'body': body,
      'type': type,
      'data': data,
      'is_read': isRead,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  NotificationModel copyWith({bool? isRead}) {
    return NotificationModel(
      id: id,
      userId: userId,
      title: title,
      body: body,
      type: type,
      data: data,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
    );
  }
}

class NotificationRepository {
  NotificationRepository({SupabaseService? supabase})
      : _supabase = supabase ?? SupabaseService.instance;

  final SupabaseService _supabase;

  Future<List<NotificationModel>> fetchNotifications({
    int limit = 50,
    int offset = 0,
  }) async {
    final userId = _supabase.currentUserId;
    if (userId == null) return [];

    final response = await _supabase.select(
      AppConstants.tableNotifications,
      filters: {'user_id': userId},
      orderBy: 'created_at',
      ascending: false,
      limit: limit,
      offset: offset,
    );

    return response.map((json) => NotificationModel.fromJson(json)).toList();
  }

  Future<int> getUnreadCount() async {
    final userId = _supabase.currentUserId;
    if (userId == null) return 0;

    final response = await _supabase.client
        .from(AppConstants.tableNotifications)
        .select('id')
        .eq('user_id', userId)
        .eq('is_read', false);

    return (response as List).length;
  }

  Future<void> markAsRead(String notificationId) async {
    await _supabase.update(
      AppConstants.tableNotifications,
      {'is_read': true},
      id: notificationId,
    );
  }

  Future<void> markAllAsRead() async {
    final userId = _supabase.currentUserId;
    if (userId == null) return;

    await _supabase.client
        .from(AppConstants.tableNotifications)
        .update({'is_read': true})
        .eq('user_id', userId)
        .eq('is_read', false);
  }

  Future<void> deleteNotification(String notificationId) async {
    await _supabase.delete(AppConstants.tableNotifications, id: notificationId);
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/services/notification_service.dart';
import '../data/notification_repository.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository();
});

final notificationsProvider =
    AsyncNotifierProvider<NotificationsNotifier, List<NotificationModel>>(
  NotificationsNotifier.new,
);

class NotificationsNotifier extends AsyncNotifier<List<NotificationModel>> {
  late final NotificationRepository _repo;
  RealtimeChannel? _channel;

  @override
  Future<List<NotificationModel>> build() async {
    _repo = ref.watch(notificationRepositoryProvider);

    // Real-time subscription for notifications
    _channel?.unsubscribe();
    _channel = Supabase.instance.client
        .channel('notifications_realtime')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: AppConstants.tableNotifications,
          callback: (payload) {
            _autoRefresh();
            // Show browser push for new notifications
            if (payload.eventType == PostgresChangeEvent.insert) {
              final title = payload.newRecord['title'] as String? ?? 'New notification';
              final body = payload.newRecord['body'] as String? ?? '';
              NotificationService.instance.notifyTaskEvent(title: title, body: body);
            }
          },
        )
        .subscribe();

    ref.onDispose(() {
      _channel?.unsubscribe();
    });

    return _repo.fetchNotifications();
  }

  Future<void> _autoRefresh() async {
    state = await AsyncValue.guard(() => _repo.fetchNotifications());
    ref.invalidate(unreadCountProvider);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repo.fetchNotifications());
  }

  Future<void> markAsRead(String id) async {
    await _repo.markAsRead(id);
    state = await AsyncValue.guard(() => _repo.fetchNotifications());
    ref.invalidate(unreadCountProvider);
  }

  Future<void> markAllAsRead() async {
    await _repo.markAllAsRead();
    state = await AsyncValue.guard(() => _repo.fetchNotifications());
    ref.invalidate(unreadCountProvider);
  }

  Future<void> deleteNotification(String id) async {
    await _repo.deleteNotification(id);
    state = await AsyncValue.guard(() => _repo.fetchNotifications());
    ref.invalidate(unreadCountProvider);
  }
}

final unreadCountProvider = FutureProvider<int>((ref) async {
  // Auto-refresh when notifications change
  final notifications = ref.watch(notificationsProvider);
  return notifications.valueOrNull?.where((n) => !n.isRead).length ?? 0;
});

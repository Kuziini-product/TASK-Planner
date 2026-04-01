import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  @override
  Future<List<NotificationModel>> build() async {
    _repo = ref.watch(notificationRepositoryProvider);
    return _repo.fetchNotifications();
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
  final repo = ref.watch(notificationRepositoryProvider);
  return repo.getUnreadCount();
});

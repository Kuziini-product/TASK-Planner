import 'dart:js_util' as js_util;
import 'package:flutter/foundation.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  bool _initialized = false;
  bool _permissionGranted = false;

  Future<void> initialize() async {
    if (_initialized) return;

    try {
      if (kIsWeb) {
        // Check if browser supports notifications
        final notifSupported = js_util.hasProperty(js_util.globalThis, 'Notification');
        if (notifSupported) {
          final permission = js_util.getProperty<String>(
            js_util.getProperty(js_util.globalThis, 'Notification'),
            'permission',
          );
          _permissionGranted = permission == 'granted';
          debugPrint('Notifications: Web - permission: $permission');
        }
        _initialized = true;
        return;
      }
      _initialized = true;
    } catch (e) {
      debugPrint('Notification initialization failed: $e');
    }
  }

  Future<bool> requestPermission() async {
    if (!kIsWeb) return false;

    try {
      final notifCtor = js_util.getProperty(js_util.globalThis, 'Notification');
      if (notifCtor == null) return false;

      final result = await js_util.promiseToFuture<String>(
        js_util.callMethod(notifCtor, 'requestPermission', []),
      );
      _permissionGranted = result == 'granted';
      return _permissionGranted;
    } catch (e) {
      debugPrint('Permission request failed: $e');
      return false;
    }
  }

  bool get isPermissionGranted => _permissionGranted;

  Future<String?> getToken() async => null;

  /// Show a browser push notification (works on desktop + mobile Safari/Chrome).
  Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
    int id = 0,
  }) async {
    if (!kIsWeb || !_permissionGranted) {
      debugPrint('Local notification (no permission): $title - $body');
      return;
    }

    try {
      final notifCtor = js_util.getProperty(js_util.globalThis, 'Notification');
      if (notifCtor == null) return;

      final options = js_util.newObject();
      js_util.setProperty(options, 'body', body);
      js_util.setProperty(options, 'icon', '/icons/Icon-192.png');
      js_util.setProperty(options, 'badge', '/icons/Icon-192.png');
      js_util.setProperty(options, 'tag', 'kuziini-$id');
      js_util.setProperty(options, 'renotify', true);

      js_util.callConstructor(notifCtor, [title, options]);
    } catch (e) {
      debugPrint('Show notification failed: $e');
    }
  }

  /// Show notification for task events.
  Future<void> notifyTaskEvent({
    required String title,
    required String body,
  }) async {
    await showLocalNotification(title: title, body: body, id: DateTime.now().millisecondsSinceEpoch % 100000);
  }

  Future<void> cancelAllNotifications() async {}
  Future<void> cancelNotification(int id) async {}
}

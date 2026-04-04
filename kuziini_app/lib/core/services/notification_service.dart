import 'dart:async';
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

  // ── Task Reminder System ──
  Timer? _reminderTimer;
  final Set<String> _notifiedTaskIds = {};

  /// Start checking for upcoming tasks every 60 seconds.
  void startTaskReminders(Future<List<dynamic>> Function() fetchTasks) {
    _reminderTimer?.cancel();
    _reminderTimer = Timer.periodic(const Duration(seconds: 60), (_) async {
      try {
        final tasks = await fetchTasks();
        final now = DateTime.now();

        for (final task in tasks) {
          if (task.startTime == null) continue;
          final startLocal = task.startTime!.toLocal();
          final diff = startLocal.difference(now).inMinutes;

          // Alert 15 minutes before
          if (diff > 0 && diff <= 15 && !_notifiedTaskIds.contains(task.id)) {
            _notifiedTaskIds.add(task.id);
            // Play sound
            _playAlertSound();
            // Show notification
            await showLocalNotification(
              title: '\u{23F0} Task in $diff min',
              body: task.title,
              id: task.id.hashCode,
            );
          }
        }

        // Clean old entries
        _notifiedTaskIds.removeWhere((id) => _notifiedTaskIds.length > 100);
      } catch (_) {}
    });
  }

  void stopTaskReminders() {
    _reminderTimer?.cancel();
    _reminderTimer = null;
  }

  /// Play alert sound using Web Audio API.
  void _playAlertSound() {
    if (!kIsWeb) return;
    try {
      // Create a short beep using AudioContext
      final audioCtx = js_util.callConstructor(
        js_util.getProperty(js_util.globalThis, 'AudioContext') ??
            js_util.getProperty(js_util.globalThis, 'webkitAudioContext'),
        [],
      );
      final oscillator = js_util.callMethod(audioCtx, 'createOscillator', []);
      final gainNode = js_util.callMethod(audioCtx, 'createGain', []);

      // Connect oscillator -> gain -> output
      js_util.callMethod(oscillator, 'connect', [gainNode]);
      js_util.callMethod(gainNode, 'connect', [js_util.getProperty(audioCtx, 'destination')]);

      // Set tone
      js_util.setProperty(js_util.getProperty(oscillator, 'frequency'), 'value', 880);
      js_util.setProperty(js_util.getProperty(gainNode, 'gain'), 'value', 0.3);

      // Play for 200ms
      js_util.callMethod(oscillator, 'start', []);
      final currentTime = js_util.getProperty<num>(audioCtx, 'currentTime');
      js_util.callMethod(oscillator, 'stop', [currentTime.toDouble() + 0.2]);

      // Second beep after 300ms
      Future.delayed(const Duration(milliseconds: 300), () {
        try {
          final osc2 = js_util.callMethod(audioCtx, 'createOscillator', []);
          final gain2 = js_util.callMethod(audioCtx, 'createGain', []);
          js_util.callMethod(osc2, 'connect', [gain2]);
          js_util.callMethod(gain2, 'connect', [js_util.getProperty(audioCtx, 'destination')]);
          js_util.setProperty(js_util.getProperty(osc2, 'frequency'), 'value', 1100);
          js_util.setProperty(js_util.getProperty(gain2, 'gain'), 'value', 0.3);
          js_util.callMethod(osc2, 'start', []);
          final ct2 = js_util.getProperty<num>(audioCtx, 'currentTime');
          js_util.callMethod(osc2, 'stop', [ct2.toDouble() + 0.2]);
        } catch (_) {}
      });
    } catch (e) {
      debugPrint('Alert sound failed: $e');
    }
  }

  /// Set app badge count everywhere possible.
  void setAppBadge(int count) {
    if (!kIsWeb) return;

    // 1. Navigator Badge API (Chrome Android/Desktop, Edge)
    try {
      final navigator = js_util.getProperty(js_util.globalThis, 'navigator');
      if (count > 0) {
        js_util.callMethod(navigator, 'setAppBadge', [count]);
      } else {
        js_util.callMethod(navigator, 'clearAppBadge', []);
      }
    } catch (_) {}

    // 2. Update page title with count (works on ALL platforms including iOS)
    try {
      final document = js_util.getProperty(js_util.globalThis, 'document');
      js_util.setProperty(document, 'title', count > 0 ? '($count) Kuziini' : 'Kuziini');
    } catch (_) {}

    // 3. Dynamic favicon with badge number (visible on browser tab)
    try {
      _updateFaviconBadge(count);
    } catch (_) {}
  }

  void _updateFaviconBadge(int count) {
    try {
      final document = js_util.getProperty(js_util.globalThis, 'document');
      final canvas = js_util.callMethod(document, 'createElement', ['canvas']);
      js_util.setProperty(canvas, 'width', 64);
      js_util.setProperty(canvas, 'height', 64);
      final ctx = js_util.callMethod(canvas, 'getContext', ['2d']);

      // Draw base icon (K letter)
      js_util.setProperty(ctx, 'fillStyle', '#0D7377');
      js_util.callMethod(ctx, 'fillRect', [0, 0, 64, 64]);
      js_util.setProperty(ctx, 'fillStyle', '#ffffff');
      js_util.setProperty(ctx, 'font', 'bold 36px Arial');
      js_util.setProperty(ctx, 'textAlign', 'center');
      js_util.setProperty(ctx, 'textBaseline', 'middle');
      js_util.callMethod(ctx, 'fillText', ['K', 32, 32]);

      // Draw badge if count > 0
      if (count > 0) {
        // Red circle
        js_util.callMethod(ctx, 'beginPath', []);
        js_util.callMethod(ctx, 'arc', [52, 12, 14, 0, 2 * 3.14159]);
        js_util.setProperty(ctx, 'fillStyle', '#E53935');
        js_util.callMethod(ctx, 'fill', []);
        // Badge text
        js_util.setProperty(ctx, 'fillStyle', '#ffffff');
        js_util.setProperty(ctx, 'font', 'bold 16px Arial');
        js_util.callMethod(ctx, 'fillText', [count > 99 ? '99' : '$count', 52, 13]);
      }

      // Set as favicon
      final dataUrl = js_util.callMethod(canvas, 'toDataURL', ['image/png']);
      var link = js_util.callMethod(document, 'querySelector', ["link[rel*='icon']"]);
      if (link == null) {
        link = js_util.callMethod(document, 'createElement', ['link']);
        js_util.setProperty(link, 'rel', 'icon');
        final head = js_util.getProperty(document, 'head');
        js_util.callMethod(head, 'appendChild', [link]);
      }
      js_util.setProperty(link, 'href', dataUrl);
    } catch (_) {}
  }

  Future<void> cancelAllNotifications() async {}
  Future<void> cancelNotification(int id) async {}
}

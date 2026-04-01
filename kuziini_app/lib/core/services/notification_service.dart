import 'dart:convert';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';
import 'supabase_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Background message: ${message.messageId}');
}

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const _channelId = 'kuziini_tasks';
  static const _channelName = 'Task Notifications';
  static const _channelDescription = 'Notifications for task updates';

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Set up background handler
      FirebaseMessaging.onBackgroundMessage(
          _firebaseMessagingBackgroundHandler);

      // Initialize local notifications
      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // Create Android notification channel
      if (Platform.isAndroid) {
        const channel = AndroidNotificationChannel(
          _channelId,
          _channelName,
          description: _channelDescription,
          importance: Importance.high,
        );
        await _localNotifications
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.createNotificationChannel(channel);
      }

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle notification taps when app is in background
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

      // Check for initial message (app opened from terminated state)
      final initialMessage = await _fcm.getInitialMessage();
      if (initialMessage != null) {
        _handleMessageOpenedApp(initialMessage);
      }

      _initialized = true;
    } catch (e) {
      debugPrint('Notification initialization failed: $e');
    }
  }

  Future<bool> requestPermission() async {
    try {
      final settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      return settings.authorizationStatus == AuthorizationStatus.authorized;
    } catch (e) {
      debugPrint('Permission request failed: $e');
      return false;
    }
  }

  Future<String?> getToken() async {
    try {
      final token = await _fcm.getToken();
      if (token != null) {
        await _saveToken(token);
      }
      return token;
    } catch (e) {
      debugPrint('Get token failed: $e');
      return null;
    }
  }

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    final oldToken = prefs.getString(AppConstants.prefFcmToken);

    if (oldToken != token) {
      await prefs.setString(AppConstants.prefFcmToken, token);

      // Update token on server
      final userId = SupabaseService.instance.currentUserId;
      if (userId != null) {
        try {
          await SupabaseService.instance.update(
            AppConstants.tableUsers,
            {'fcm_token': token},
            id: userId,
          );
        } catch (e) {
          debugPrint('Token update failed: $e');
        }
      }
    }
  }

  void listenToTokenRefresh() {
    _fcm.onTokenRefresh.listen(_saveToken);
  }

  void _handleForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    showLocalNotification(
      title: notification.title ?? 'Kuziini',
      body: notification.body ?? '',
      payload: jsonEncode(message.data),
    );
  }

  void _handleMessageOpenedApp(RemoteMessage message) {
    final data = message.data;
    final type = data['type'] as String?;
    final taskId = data['task_id'] as String?;

    if (type == 'task_update' && taskId != null) {
      // Navigation will be handled by the router
      debugPrint('Open task: $taskId');
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    if (response.payload == null) return;

    try {
      final data = jsonDecode(response.payload!) as Map<String, dynamic>;
      final type = data['type'] as String?;
      final taskId = data['task_id'] as String?;

      if (type == 'task_update' && taskId != null) {
        debugPrint('Tapped notification for task: $taskId');
      }
    } catch (e) {
      debugPrint('Failed to parse notification payload: $e');
    }
  }

  Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
    int id = 0,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(id, title, body, details, payload: payload);
  }

  Future<void> cancelAllNotifications() async {
    await _localNotifications.cancelAll();
  }

  Future<void> cancelNotification(int id) async {
    await _localNotifications.cancel(id);
  }
}

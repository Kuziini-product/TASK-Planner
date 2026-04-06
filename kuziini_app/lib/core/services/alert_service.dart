import 'dart:js_util' as js_util;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/notification_service.dart';

/// Checks alert rules on app load and sends notifications to users who match triggers.
class AlertService {
  AlertService._();
  static final AlertService instance = AlertService._();

  /// Run alert checks (called by admin on app load)
  Future<void> checkAndSendAlerts() async {
    try {
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null) return;

      // Check if current user is admin
      final profile = await Supabase.instance.client
          .from('profiles')
          .select('role')
          .eq('id', currentUser.id)
          .maybeSingle();
      if (profile == null || profile['role'] != 'admin') return;

      // Load alert rules
      final prefs = await SharedPreferences.getInstance();
      final rulesJson = prefs.getStringList('auto_alert_rules') ?? [];
      if (rulesJson.isEmpty) return;

      final rules = rulesJson
          .map((r) => _parseRule(r))
          .where((r) => r != null && r['enabled'] == true)
          .toList();
      if (rules.isEmpty) return;

      // Check if already sent today
      final today = DateTime.now().toIso8601String().split('T').first;
      final lastCheck = prefs.getString('last_alert_check');
      if (lastCheck == today) return; // Already checked today
      await prefs.setString('last_alert_check', today);

      // Fetch all users
      final usersResponse = await Supabase.instance.client
          .from('profiles')
          .select('id, full_name, email, phone, last_seen, status')
          .eq('status', 'active');
      final users = usersResponse as List;

      for (final user in users) {
        final userId = user['id'] as String;
        final userName = user['full_name'] as String? ?? user['email'] as String? ?? 'User';
        final email = user['email'] as String?;
        final phone = user['phone'] as String?;
        final lastSeen = user['last_seen'] as String?;

        // Fetch user's tasks
        final tasks = await Supabase.instance.client
            .from('tasks')
            .select('status, due_date, title')
            .eq('created_by', userId);

        final taskList = (tasks as List).where((t) {
          final title = (t['title'] as String? ?? '').toLowerCase();
          return !title.contains('concediu') && !title.contains('liber') && t['status'] != 'archived';
        }).toList();

        final total = taskList.length;
        final done = taskList.where((t) => t['status'] == 'done').length;
        final overdue = taskList.where((t) {
          if (t['status'] == 'done') return false;
          final dd = t['due_date'] as String?;
          return dd != null && dd.compareTo(today) < 0;
        }).length;
        final completionPct = total > 0 ? (done * 100 / total).round() : 100;

        // Check inactive days
        int inactiveDays = 0;
        if (lastSeen != null) {
          final ls = DateTime.tryParse(lastSeen);
          if (ls != null) inactiveDays = DateTime.now().difference(ls).inDays;
        }

        // Check each rule
        for (final rule in rules) {
          final trigger = rule!['trigger'] as String;
          final message = rule['message'] as String;
          final channel = rule['channel'] as String;
          bool shouldTrigger = false;

          switch (trigger) {
            case 'overdue_3': shouldTrigger = overdue >= 3;
            case 'overdue_5': shouldTrigger = overdue >= 5;
            case 'completion_low': shouldTrigger = completionPct < 50 && total > 0;
            case 'completion_vlow': shouldTrigger = completionPct < 30 && total > 0;
            case 'inactive_3d': shouldTrigger = inactiveDays >= 3;
            case 'inactive_7d': shouldTrigger = inactiveDays >= 7;
            case 'weekly_report': shouldTrigger = DateTime.now().weekday == 1; // Monday
            case 'daily_reminder': shouldTrigger = true;
          }

          if (!shouldTrigger) continue;

          // Send alert based on channel
          final alertTitle = 'Alertă: $userName';
          final alertBody = message.replaceAll('{name}', userName)
              .replaceAll('{overdue}', '$overdue')
              .replaceAll('{pct}', '$completionPct%');

          // Always send in-app notification
          try {
            await Supabase.instance.client.from('notifications').insert({
              'user_id': userId,
              'title': alertTitle,
              'body': alertBody,
              'type': 'auto_alert',
              'data': {'trigger': trigger},
            });
          } catch (_) {}

          // Email via mailto (opens in browser - basic fallback)
          if (channel == 'email' && email != null) {
            try {
              final subject = Uri.encodeComponent(alertTitle);
              final body = Uri.encodeComponent(alertBody);
              final mailtoUrl = 'mailto:$email?subject=$subject&body=$body';
              // Open mailto link via JS
              js_util.callMethod(js_util.globalThis, 'open', [mailtoUrl, '_blank']);
            } catch (_) {}
          }

          // WhatsApp via wa.me link
          if (channel == 'whatsapp' && phone != null && phone.isNotEmpty) {
            try {
              final cleanPhone = phone.replaceAll(RegExp(r'[^0-9+]'), '').replaceFirst('+', '');
              final waUrl = 'https://wa.me/$cleanPhone?text=${Uri.encodeComponent(alertBody)}';
              js_util.callMethod(js_util.globalThis, 'open', [waUrl, '_blank']);
            } catch (_) {}
          }

          debugPrint('Alert sent: $trigger → $userName via $channel');
        }
      }

      // Show admin notification
      NotificationService.instance.notifyTaskEvent(
        title: 'Alerte trimise',
        body: 'Verificarea alertelor automate s-a finalizat',
      );
    } catch (e) {
      debugPrint('AlertService error: $e');
    }
  }

  Map<String, dynamic>? _parseRule(String s) {
    final parts = s.split('|||');
    if (parts.length < 4) return null;
    return {
      'trigger': parts[0],
      'message': parts[1],
      'enabled': parts[2] == 'true',
      'channel': parts[3],
    };
  }
}

import 'dart:js_util' as js_util;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Tracks which users are currently active on the app using Supabase Presence.
class PresenceService {
  PresenceService._();
  static final PresenceService instance = PresenceService._();

  RealtimeChannel? _channel;
  final _onlineUsers = <String, Map<String, dynamic>>{};
  void Function()? _onChanged;

  /// Start tracking presence for current user.
  void start({void Function()? onChanged}) {
    _onChanged = onChanged;
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    _channel?.unsubscribe();
    _channel = Supabase.instance.client.channel('online-users');

    _channel!
        .onPresenceSync((payload) {
          _onlineUsers.clear();
          final presences = _channel!.presenceState();
          for (final presence in presences) {
            final userId = presence.presences.isNotEmpty
                ? presence.presences.first.payload['user_id'] as String?
                : null;
            if (userId != null) {
              _onlineUsers[userId] = Map<String, dynamic>.from(presence.presences.first.payload);
            }
          }
          _onChanged?.call();
        })
        .onPresenceJoin((payload) {
          _onChanged?.call();
        })
        .onPresenceLeave((payload) {
          _onChanged?.call();
        })
        .subscribe((status, [error]) async {
          if (status == RealtimeSubscribeStatus.subscribed) {
            await _channel!.track({
              'user_id': user.id,
              'email': user.email,
              'online_at': DateTime.now().toIso8601String(),
            });
          }
        });

    // Listen for page visibility changes (web only)
    if (kIsWeb) {
      _listenVisibility(user.id);
    }
  }

  void _listenVisibility(String userId) {
    try {
      final document = js_util.getProperty(js_util.globalThis, 'document');
      js_util.callMethod(document, 'addEventListener', [
        'visibilitychange',
        js_util.allowInterop((_) {
          final hidden = js_util.getProperty<bool>(document, 'hidden');
          if (hidden) {
            // App went to background - untrack
            _channel?.untrack();
          } else {
            // App came to foreground - track again
            _channel?.track({
              'user_id': userId,
              'email': Supabase.instance.client.auth.currentUser?.email,
              'online_at': DateTime.now().toIso8601String(),
            });
          }
        }),
      ]);
    } catch (_) {}
  }

  /// Get list of online user IDs.
  List<String> get onlineUserIds => _onlineUsers.keys.toList();

  /// Get count of online users.
  int get onlineCount => _onlineUsers.length;

  /// Check if a specific user is online.
  bool isOnline(String userId) => _onlineUsers.containsKey(userId);

  void stop() {
    _channel?.unsubscribe();
    _channel = null;
    _onlineUsers.clear();
  }
}

/// Provider that watches online users and refreshes on changes.
final onlineUsersProvider = StateNotifierProvider<OnlineUsersNotifier, List<String>>((ref) {
  return OnlineUsersNotifier();
});

class OnlineUsersNotifier extends StateNotifier<List<String>> {
  OnlineUsersNotifier() : super([]) {
    PresenceService.instance.start(onChanged: _refresh);
    _refresh();
  }

  void _refresh() {
    state = PresenceService.instance.onlineUserIds;
  }

  @override
  void dispose() {
    PresenceService.instance.stop();
    super.dispose();
  }
}

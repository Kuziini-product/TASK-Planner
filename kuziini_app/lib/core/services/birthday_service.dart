import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/domain/auth_state.dart';
import 'supabase_service.dart';

/// Fetches all active users with birth dates.
/// keepAlive ensures it doesn't auto-dispose between navigations.
final birthdayUsersProvider = FutureProvider<List<UserProfile>>((ref) async {
  ref.keepAlive();
  try {
    final data = await SupabaseService.instance.client
        .from('profiles')
        .select('*')
        .eq('status', 'active');
    return (data as List)
        .map((json) => UserProfile.fromJson(json as Map<String, dynamic>))
        .toList();
  } catch (e) {
    debugPrint('[Birthday] ERROR: $e');
    return [];
  }
});

/// Users whose birthday is TODAY
final todayBirthdayUsersProvider = Provider<List<UserProfile>>((ref) {
  final usersAsync = ref.watch(birthdayUsersProvider);
  final users = usersAsync.valueOrNull ?? [];
  return users.where((u) => u.isBirthdayToday).toList();
});

/// Users whose birthday is THIS WEEK (but not today)
final weekBirthdayUsersProvider = Provider<List<UserProfile>>((ref) {
  final usersAsync = ref.watch(birthdayUsersProvider);
  return usersAsync.valueOrNull
          ?.where((u) => u.isBirthdayThisWeek && !u.isBirthdayToday)
          .toList() ??
      [];
});

/// Whether anyone has a birthday today
final hasBirthdayTodayProvider = Provider<bool>((ref) {
  return ref.watch(todayBirthdayUsersProvider).isNotEmpty;
});

/// All birthday dates for the year (for calendar marking)
final birthdayDatesProvider = Provider<Map<String, List<String>>>((ref) {
  final usersAsync = ref.watch(birthdayUsersProvider);
  final users = usersAsync.valueOrNull ?? [];
  final map = <String, List<String>>{};
  for (final user in users) {
    if (user.birthDate != null) {
      final key = '${user.birthDate!.month}-${user.birthDate!.day}';
      map.putIfAbsent(key, () => []).add(user.displayName);
    }
  }
  return map;
});

// ── Active Custom Banner ──

final activeCustomBannerProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  ref.keepAlive();
  try {
    final now = DateTime.now();
    final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final response = await SupabaseService.instance.client
        .from('custom_banners')
        .select('*')
        .eq('is_active', true)
        .lte('start_date', todayStr)
        .gte('end_date', todayStr)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();
    return response;
  } catch (_) {
    return null;
  }
});

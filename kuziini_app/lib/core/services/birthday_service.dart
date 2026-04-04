import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/domain/auth_state.dart';
import 'supabase_service.dart';

/// Fetches all active users with birth dates — independent provider
/// that stays alive as long as MainShell is mounted.
/// keepAlive ensures it doesn't auto-dispose between navigations.
final birthdayUsersProvider = FutureProvider<List<UserProfile>>((ref) async {
  ref.keepAlive();
  try {
    final data = await SupabaseService.instance.client
        .from('profiles')
        .select('*')
        .eq('status', 'active');
    final users = (data as List)
        .map((json) => UserProfile.fromJson(json as Map<String, dynamic>))
        .toList();
    final now = DateTime.now();
    final withDates = users.where((u) => u.birthDate != null).toList();
    final todayMatches = users.where((u) => u.isBirthdayToday).toList();
    // Use print() instead of debugPrint() — works in release mode on web
    print('[Birthday] === CHECK === '
        'Today: ${now.day}/${now.month}/${now.year} | '
        'Users: ${users.length} | '
        'With dates: ${withDates.length} | '
        'Match today: ${todayMatches.length} | '
        'Details: ${withDates.map((u) => "${u.displayName}=${u.birthDate!.day}/${u.birthDate!.month}(${u.isBirthdayToday})").join(", ")}');
    return users;
  } catch (e, st) {
    print('[Birthday] ERROR: $e\n$st');
    return [];
  }
});

/// Users whose birthday is TODAY
final todayBirthdayUsersProvider = Provider<List<UserProfile>>((ref) {
  final usersAsync = ref.watch(birthdayUsersProvider);
  final users = usersAsync.valueOrNull ?? [];
  final today = users.where((u) => u.isBirthdayToday).toList();
  if (today.isNotEmpty) {
    print('[Birthday] TODAY: ${today.map((u) => u.displayName).join(', ')}');
  } else if (users.isNotEmpty) {
    final now = DateTime.now();
    print('[Birthday] No birthdays today (${now.day}/${now.month}). '
        'Users with dates: ${users.where((u) => u.birthDate != null).map((u) => "${u.displayName}=${u.birthDate!.day}/${u.birthDate!.month}").join(", ")}');
  }
  return today;
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

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/domain/auth_state.dart';
import 'supabase_service.dart';

/// Birthday users provider — fetches all active users and filters birthdays
final birthdayUsersProvider = FutureProvider<List<UserProfile>>((ref) async {
  final supabase = SupabaseService.instance;
  final data = await supabase.select(
    'profiles',
    filters: {'status': 'active'},
  );
  return data.map((json) => UserProfile.fromJson(json)).toList();
});

/// Users whose birthday is TODAY
final todayBirthdayUsersProvider = Provider<List<UserProfile>>((ref) {
  final usersAsync = ref.watch(birthdayUsersProvider);
  return usersAsync.valueOrNull
          ?.where((u) => u.isBirthdayToday)
          .toList() ??
      [];
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
      final key =
          '${user.birthDate!.month}-${user.birthDate!.day}';
      map.putIfAbsent(key, () => []).add(user.displayName);
    }
  }
  return map;
});

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// A leave record for a user.
class UserLeave {
  final String id;
  final String userId;
  final String? userName;
  final DateTime startDate;
  final DateTime endDate;
  final String? reason;

  const UserLeave({
    required this.id,
    required this.userId,
    this.userName,
    required this.startDate,
    required this.endDate,
    this.reason,
  });

  factory UserLeave.fromJson(Map<String, dynamic> json) {
    return UserLeave(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      userName: json['profiles']?['full_name'] as String?,
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
      reason: json['reason'] as String?,
    );
  }

  bool coversDate(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    final s = DateTime(startDate.year, startDate.month, startDate.day);
    final e = DateTime(endDate.year, endDate.month, endDate.day);
    return !d.isBefore(s) && !d.isAfter(e);
  }
}

/// Toggle for showing leave overlay on calendar.
final showLeaveOverlayProvider = StateProvider<bool>((ref) => false);

/// Fetch all leaves for a month range.
final monthLeavesProvider = FutureProvider.family<List<UserLeave>, ({DateTime from, DateTime to})>((ref, range) async {
  final response = await Supabase.instance.client
      .from('user_leaves')
      .select('*, profiles:user_id(full_name)')
      .lte('start_date', range.to.toIso8601String())
      .gte('end_date', range.from.toIso8601String())
      .order('start_date');

  return (response as List).map((j) => UserLeave.fromJson(j as Map<String, dynamic>)).toList();
});

/// Add a leave for a user (admin only).
Future<void> addUserLeave({
  required String userId,
  required DateTime startDate,
  required DateTime endDate,
  String? reason,
  required String createdBy,
}) async {
  await Supabase.instance.client.from('user_leaves').insert({
    'user_id': userId,
    'start_date': '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}',
    'end_date': '${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}',
    'reason': reason,
    'created_by': createdBy,
  });
}

/// Count how many users are on leave for a specific date.
int leaveCountForDate(List<UserLeave> leaves, DateTime date) {
  return leaves.where((l) => l.coversDate(date)).length;
}

/// Get users on leave for a specific date.
List<UserLeave> leavesForDate(List<UserLeave> leaves, DateTime date) {
  return leaves.where((l) => l.coversDate(date)).toList();
}

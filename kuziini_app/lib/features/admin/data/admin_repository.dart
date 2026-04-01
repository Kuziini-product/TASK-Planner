import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/services/supabase_service.dart';
import '../../auth/domain/auth_state.dart';

class AdminRepository {
  AdminRepository({SupabaseService? supabase})
      : _supabase = supabase ?? SupabaseService.instance;

  final SupabaseService _supabase;
  static const _uuid = Uuid();

  Future<List<UserProfile>> listUsers({String? roleFilter}) async {
    try {
      var query = _supabase.client.from(AppConstants.tableUsers).select('*');
      if (roleFilter != null) {
        query = query.eq('role', roleFilter);
      }
      final response = await query.order('created_at', ascending: false);
      return (response as List)
          .map((json) => UserProfile.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Failed to list users: $e');
      return [];
    }
  }

  Future<List<UserProfile>> listPendingUsers() async {
    try {
      final response = await _supabase.client
          .from(AppConstants.tableUsers)
          .select('*')
          .eq('status', 'pending')
          .order('created_at', ascending: false);
      return (response as List)
          .map((json) => UserProfile.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Failed to list pending users: $e');
      return [];
    }
  }

  Future<bool> approveUser(String userId) async {
    try {
      await _supabase.update(
        AppConstants.tableUsers,
        {
          'status': 'active',
          'updated_at': DateTime.now().toIso8601String(),
        },
        id: userId,
      );
      return true;
    } catch (e) {
      debugPrint('Failed to approve user: $e');
      return false;
    }
  }

  Future<bool> rejectUser(String userId) async {
    try {
      await _supabase.update(
        AppConstants.tableUsers,
        {
          'status': 'suspended',
          'updated_at': DateTime.now().toIso8601String(),
        },
        id: userId,
      );
      return true;
    } catch (e) {
      debugPrint('Failed to reject user: $e');
      return false;
    }
  }

  Future<bool> updateUserRole(String userId, String role) async {
    try {
      await _supabase.update(
        AppConstants.tableUsers,
        {
          'role': role,
          'updated_at': DateTime.now().toIso8601String(),
        },
        id: userId,
      );
      return true;
    } catch (e) {
      debugPrint('Failed to update role: $e');
      return false;
    }
  }

  Future<bool> sendInvitation({
    required String email,
    String role = 'member',
  }) async {
    try {
      final token = _uuid.v4();
      await _supabase.insert(AppConstants.tableInvitations, {
        'id': _uuid.v4(),
        'email': email,
        'role': role,
        'token': token,
        'status': 'pending',
        'invited_by': _supabase.currentUserId,
        'created_at': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (e) {
      debugPrint('Failed to send invitation: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> listInvitations() async {
    try {
      final response = await _supabase.select(
        AppConstants.tableInvitations,
        orderBy: 'created_at',
        ascending: false,
      );
      return response;
    } catch (e) {
      debugPrint('Failed to list invitations: $e');
      return [];
    }
  }

  Future<void> cancelInvitation(String invitationId) async {
    await _supabase.update(
      AppConstants.tableInvitations,
      {'status': 'cancelled'},
      id: invitationId,
    );
  }

  Future<Map<String, int>> getAdminStats() async {
    try {
      final users = await _supabase.client
          .from(AppConstants.tableUsers)
          .select('status');
      final tasks = await _supabase.client
          .from(AppConstants.tableTasks)
          .select('status');

      final totalUsers = (users as List).length;
      final pendingUsers =
          users.where((u) => u['status'] == 'pending').length;
      final approvedUsers =
          users.where((u) => u['status'] == 'active').length;

      final totalTasks = (tasks as List).length;
      final completedTasks =
          tasks.where((t) => t['status'] == 'done').length;
      final activeTasks = totalTasks - completedTasks;

      return {
        'totalUsers': totalUsers,
        'pendingUsers': pendingUsers,
        'approvedUsers': approvedUsers,
        'totalTasks': totalTasks,
        'completedTasks': completedTasks,
        'activeTasks': activeTasks,
      };
    } catch (e) {
      debugPrint('Failed to get admin stats: $e');
      return {};
    }
  }

  Future<List<Map<String, dynamic>>> getActivityLogs({int limit = 20}) async {
    try {
      return await _supabase.select(
        AppConstants.tableActivityLogs,
        orderBy: 'created_at',
        ascending: false,
        limit: limit,
      );
    } catch (e) {
      debugPrint('Failed to get activity logs: $e');
      return [];
    }
  }
}

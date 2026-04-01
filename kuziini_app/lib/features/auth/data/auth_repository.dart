import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/services/supabase_service.dart';
import '../domain/auth_state.dart';

class AuthRepository {
  AuthRepository({SupabaseService? supabase})
      : _supabase = supabase ?? SupabaseService.instance;

  final SupabaseService _supabase;

  Stream<AuthState> get onAuthStateChange => _supabase.onAuthStateChange;

  User? get currentUser => _supabase.currentUser;
  bool get isAuthenticated => _supabase.isAuthenticated;

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? fullName,
  }) async {
    return await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {
        'full_name': fullName ?? '',
      },
    );
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  Future<void> resetPassword(String email) async {
    await _supabase.auth.resetPasswordForEmail(email);
  }

  Future<UserProfile?> getUserProfile([String? userId]) async {
    final id = userId ?? _supabase.currentUserId;
    if (id == null) return null;

    try {
      final data = await _supabase.selectSingle(
        AppConstants.tableUsers,
        filters: {'id': id},
      );
      return UserProfile.fromJson(data);
    } catch (e) {
      debugPrint('Failed to get user profile: $e');
      return null;
    }
  }

  Future<AuthStatus> checkAuthStatus() async {
    if (!isAuthenticated) return AuthStatus.unauthenticated;

    try {
      final profile = await getUserProfile();
      if (profile == null) return AuthStatus.pendingApproval;
      if (!profile.isApproved) return AuthStatus.pendingApproval;
      return AuthStatus.authenticated;
    } catch (e) {
      debugPrint('Auth status check failed: $e');
      return AuthStatus.unauthenticated;
    }
  }

  Future<UserProfile?> updateProfile(Map<String, dynamic> data) async {
    final userId = _supabase.currentUserId;
    if (userId == null) return null;

    try {
      final updated = await _supabase.update(
        AppConstants.tableUsers,
        data,
        id: userId,
      );
      return UserProfile.fromJson(updated);
    } catch (e) {
      debugPrint('Failed to update profile: $e');
      return null;
    }
  }

  Future<bool> acceptInvitation(String token) async {
    try {
      final invitations = await _supabase.select(
        AppConstants.tableInvitations,
        filters: {'token': token, 'status': 'pending'},
      );

      if (invitations.isEmpty) return false;

      await _supabase.update(
        AppConstants.tableInvitations,
        {'status': 'accepted'},
        id: invitations.first['id'] as String,
      );

      return true;
    } catch (e) {
      debugPrint('Failed to accept invitation: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> getInvitationByToken(String token) async {
    try {
      final invitations = await _supabase.select(
        AppConstants.tableInvitations,
        filters: {'token': token},
      );
      return invitations.isNotEmpty ? invitations.first : null;
    } catch (e) {
      debugPrint('Failed to get invitation: $e');
      return null;
    }
  }
}

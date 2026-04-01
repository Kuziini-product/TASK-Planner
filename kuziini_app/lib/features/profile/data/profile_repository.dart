import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/services/supabase_service.dart';
import '../../auth/domain/auth_state.dart';

class ProfileRepository {
  ProfileRepository({SupabaseService? supabase})
      : _supabase = supabase ?? SupabaseService.instance;

  final SupabaseService _supabase;
  static const _uuid = Uuid();

  Future<UserProfile?> getProfile([String? userId]) async {
    final id = userId ?? _supabase.currentUserId;
    if (id == null) return null;

    try {
      final data = await _supabase.selectSingle(
        AppConstants.tableUsers,
        filters: {'id': id},
      );
      return UserProfile.fromJson(data);
    } catch (e) {
      debugPrint('Failed to get profile: $e');
      return null;
    }
  }

  Future<UserProfile?> updateProfile({
    String? fullName,
    String? avatarUrl,
  }) async {
    final userId = _supabase.currentUserId;
    if (userId == null) return null;

    final data = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (fullName != null) data['full_name'] = fullName;
    if (avatarUrl != null) data['avatar_url'] = avatarUrl;

    try {
      final response = await _supabase.update(
        AppConstants.tableUsers,
        data,
        id: userId,
      );
      return UserProfile.fromJson(response);
    } catch (e) {
      debugPrint('Failed to update profile: $e');
      return null;
    }
  }

  Future<String?> uploadAvatar(Uint8List bytes, String fileName) async {
    final userId = _supabase.currentUserId;
    if (userId == null) return null;

    try {
      final ext = fileName.split('.').last;
      final path = '$userId/avatar_${_uuid.v4()}.$ext';

      final url = await _supabase.uploadFile(
        AppConstants.bucketAvatars,
        path,
        bytes,
      );

      await updateProfile(avatarUrl: url);
      return url;
    } catch (e) {
      debugPrint('Failed to upload avatar: $e');
      return null;
    }
  }
}

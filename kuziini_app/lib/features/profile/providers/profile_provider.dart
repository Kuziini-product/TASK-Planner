import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/domain/auth_state.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/profile_repository.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository();
});

final profileProvider = FutureProvider<UserProfile?>((ref) async {
  final authState = ref.watch(authStateProvider);
  if (authState.valueOrNull != AuthStatus.authenticated) return null;

  final repo = ref.watch(profileRepositoryProvider);
  return repo.getProfile();
});

final profileActionsProvider =
    Provider<ProfileActions>((ref) => ProfileActions(ref));

class ProfileActions {
  ProfileActions(this._ref);
  final Ref _ref;

  ProfileRepository get _repo => _ref.read(profileRepositoryProvider);

  Future<UserProfile?> updateName(String name) async {
    final result = await _repo.updateProfile(fullName: name);
    _ref.invalidate(profileProvider);
    _ref.invalidate(currentUserProfileProvider);
    return result;
  }

  Future<String?> uploadAvatar(Uint8List bytes, String fileName) async {
    final url = await _repo.uploadAvatar(bytes, fileName);
    if (url != null) {
      _ref.invalidate(profileProvider);
      _ref.invalidate(currentUserProfileProvider);
    }
    return url;
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/domain/auth_state.dart';
import '../data/admin_repository.dart';

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepository();
});

final adminStatsProvider = FutureProvider<Map<String, int>>((ref) async {
  final repo = ref.watch(adminRepositoryProvider);
  return repo.getAdminStats();
});

final allUsersProvider = FutureProvider<List<UserProfile>>((ref) async {
  final repo = ref.watch(adminRepositoryProvider);
  return repo.listUsers();
});

final pendingUsersProvider = FutureProvider<List<UserProfile>>((ref) async {
  final repo = ref.watch(adminRepositoryProvider);
  return repo.listPendingUsers();
});

final invitationsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repo = ref.watch(adminRepositoryProvider);
  return repo.listInvitations();
});

final adminActionsProvider =
    Provider<AdminActions>((ref) => AdminActions(ref));

class AdminActions {
  AdminActions(this._ref);
  final Ref _ref;

  AdminRepository get _repo => _ref.read(adminRepositoryProvider);

  Future<bool> approveUser(String userId) async {
    final result = await _repo.approveUser(userId);
    if (result) {
      _ref.invalidate(pendingUsersProvider);
      _ref.invalidate(allUsersProvider);
      _ref.invalidate(adminStatsProvider);
    }
    return result;
  }

  Future<bool> rejectUser(String userId) async {
    final result = await _repo.rejectUser(userId);
    if (result) {
      _ref.invalidate(pendingUsersProvider);
      _ref.invalidate(allUsersProvider);
      _ref.invalidate(adminStatsProvider);
    }
    return result;
  }

  Future<bool> sendInvitation({
    required String email,
    String role = 'member',
  }) async {
    final result = await _repo.sendInvitation(email: email, role: role);
    if (result) {
      _ref.invalidate(invitationsProvider);
    }
    return result;
  }

  Future<void> cancelInvitation(String invitationId) async {
    await _repo.cancelInvitation(invitationId);
    _ref.invalidate(invitationsProvider);
  }

  Future<bool> updateUserRole(String userId, String role) async {
    final result = await _repo.updateUserRole(userId, role);
    if (result) {
      _ref.invalidate(allUsersProvider);
    }
    return result;
  }
}

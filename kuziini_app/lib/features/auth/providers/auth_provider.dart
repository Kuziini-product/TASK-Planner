import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/auth_repository.dart';
import '../domain/auth_state.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

final authStateProvider =
    AsyncNotifierProvider<AuthNotifier, AuthStatus>(AuthNotifier.new);

class AuthNotifier extends AsyncNotifier<AuthStatus> {
  late final AuthRepository _repo;

  @override
  Future<AuthStatus> build() async {
    _repo = ref.watch(authRepositoryProvider);

    // Listen to auth state changes
    _repo.onAuthStateChange.listen((event) {
      _refreshStatus();
    });

    return _repo.checkAuthStatus();
  }

  Future<void> _refreshStatus() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repo.checkAuthStatus());
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repo.signIn(email: email, password: password);
      return _repo.checkAuthStatus();
    });
  }

  Future<void> signUp({
    required String email,
    required String password,
    String? fullName,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repo.signUp(email: email, password: password, fullName: fullName);
      return _repo.checkAuthStatus();
    });
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();
    await _repo.signOut();
    state = const AsyncValue.data(AuthStatus.unauthenticated);
  }

  Future<void> resetPassword(String email) async {
    await _repo.resetPassword(email);
  }

  Future<void> checkApprovalStatus() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repo.checkAuthStatus());
  }
}

final currentUserProfileProvider = FutureProvider<UserProfile?>((ref) async {
  final authState = ref.watch(authStateProvider);
  if (authState.valueOrNull != AuthStatus.authenticated &&
      authState.valueOrNull != AuthStatus.pendingApproval) {
    return null;
  }
  final repo = ref.watch(authRepositoryProvider);
  return repo.getUserProfile();
});

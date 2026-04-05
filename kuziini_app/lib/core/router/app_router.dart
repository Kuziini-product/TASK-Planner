import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/invite_screen.dart';
import '../../features/auth/presentation/pending_approval_screen.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/domain/auth_state.dart';
import '../../features/tasks/presentation/daily_tasks_screen.dart';
import '../../features/tasks/presentation/task_detail_screen.dart';
import '../../features/tasks/presentation/create_task_screen.dart';
import '../../features/tasks/presentation/calendar_screen.dart';
import '../../features/notifications/presentation/notifications_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/profile/presentation/settings_screen.dart';
import '../../features/admin/presentation/admin_dashboard_screen.dart';
import '../../features/admin/presentation/user_approval_screen.dart';
import '../../features/admin/presentation/invitations_screen.dart';
import '../../features/search/presentation/search_screen.dart';
import '../../shell/main_shell.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

abstract final class AppRoutes {
  static const String login = '/login';
  static const String invite = '/invite';
  static const String pendingApproval = '/pending-approval';
  static const String today = '/today';
  static const String calendar = '/calendar';
  static const String notifications = '/notifications';
  static const String profile = '/profile';
  static const String settings = '/settings';
  static const String taskDetail = '/task/:id';
  static const String createTask = '/create-task';
  static const String search = '/search';
  static const String adminDashboard = '/admin';
  static const String userApproval = '/admin/approvals';
  static const String invitations = '/admin/invitations';
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.profile,
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final currentAuth = authState.valueOrNull ?? AuthStatus.initial;
      final isOnAuth = state.matchedLocation == AppRoutes.login ||
          state.matchedLocation == AppRoutes.invite;
      final isOnPending = state.matchedLocation == AppRoutes.pendingApproval;

      if (currentAuth == AuthStatus.initial) {
        return null;
      }

      if (currentAuth == AuthStatus.unauthenticated) {
        if (state.matchedLocation == AppRoutes.invite) return null;
        return isOnAuth ? null : AppRoutes.login;
      }

      if (currentAuth == AuthStatus.pendingApproval) {
        return isOnPending ? null : AppRoutes.pendingApproval;
      }

      if (currentAuth == AuthStatus.authenticated) {
        if (isOnAuth || isOnPending) return AppRoutes.profile;
      }

      return null;
    },
    routes: [
      // ── Auth Routes ──
      GoRoute(
        path: AppRoutes.login,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.invite,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final token = state.uri.queryParameters['token'] ?? '';
          return InviteScreen(token: token);
        },
      ),
      GoRoute(
        path: AppRoutes.pendingApproval,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const PendingApprovalScreen(),
      ),

      // ── Shell Route (Bottom Nav) ──
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.today,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: DailyTasksScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.calendar,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: CalendarScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.notifications,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: NotificationsScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.profile,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ProfileScreen(),
            ),
          ),
        ],
      ),

      // ── Full-Screen Routes ──
      GoRoute(
        path: AppRoutes.taskDetail,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final taskId = state.pathParameters['id']!;
          return TaskDetailScreen(taskId: taskId);
        },
      ),
      GoRoute(
        path: AppRoutes.createTask,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => CreateTaskScreen(
          queryParams: state.uri.queryParameters,
        ),
      ),
      GoRoute(
        path: AppRoutes.search,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SearchScreen(),
      ),
      GoRoute(
        path: AppRoutes.settings,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SettingsScreen(),
      ),

      // ── Admin Routes ──
      GoRoute(
        path: AppRoutes.adminDashboard,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.userApproval,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const UserApprovalScreen(),
      ),
      GoRoute(
        path: AppRoutes.invitations,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const InvitationsScreen(),
      ),
    ],
  );
});

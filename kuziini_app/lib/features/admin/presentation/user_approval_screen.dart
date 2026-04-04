import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/extensions.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/kuziini_app_bar.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/widgets/error_view.dart';
import '../providers/admin_provider.dart';
import 'widgets/user_list_tile.dart';

class UserApprovalScreen extends ConsumerWidget {
  const UserApprovalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingAsync = ref.watch(pendingUsersProvider);
    final allUsersAsync = ref.watch(allUsersProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: KuziiniAppBar(
          showBackButton: true,
          title: 'User Management',
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Pending'),
              Tab(text: 'All Users'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Pending tab
            RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(pendingUsersProvider);
              },
              child: pendingAsync.when(
                data: (users) {
                  if (users.isEmpty) {
                    return const EmptyState(
                      title: 'No pending users',
                      message: 'All registrations have been processed.',
                    );
                  }

                  return ListView.builder(
                    padding: AppSpacing.paddingLg,
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final user = users[index];
                      return UserListTile(
                        user: user,
                        isPending: true,
                        onApprove: () async {
                          final success = await ref
                              .read(adminActionsProvider)
                              .approveUser(user.id);
                          if (context.mounted) {
                            context.showSnackBar(
                              success
                                  ? '${user.displayName} approved'
                                  : 'Failed to approve user',
                              isError: !success,
                            );
                          }
                        },
                        onReject: () async {
                          final confirmed = await context.showConfirmDialog(
                            title: 'Reject User',
                            message:
                                'Are you sure you want to reject ${user.displayName}?',
                            confirmLabel: 'Reject',
                            isDestructive: true,
                          );
                          if (confirmed == true) {
                            final success = await ref
                                .read(adminActionsProvider)
                                .rejectUser(user.id);
                            if (context.mounted) {
                              context.showSnackBar(
                                success
                                    ? 'User rejected'
                                    : 'Failed to reject user',
                                isError: !success,
                              );
                            }
                          }
                        },
                      )
                          .animate()
                          .fadeIn(
                            duration: 300.ms,
                            delay: Duration(milliseconds: 50 * index),
                          )
                          .moveY(
                            begin: 10,
                            duration: 300.ms,
                            delay: Duration(milliseconds: 50 * index),
                          );
                    },
                  );
                },
                loading: () =>
                    const LoadingIndicator(message: 'Loading pending users...'),
                error: (error, _) => ErrorView(
                  message: error.toString(),
                  onRetry: () => ref.invalidate(pendingUsersProvider),
                ),
              ),
            ),

            // All users tab
            RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(allUsersProvider);
              },
              child: allUsersAsync.when(
                data: (users) {
                  if (users.isEmpty) {
                    return const EmptyState(
                      title: 'No users',
                      message: 'No users found.',
                    );
                  }

                  return ListView.builder(
                    padding: AppSpacing.paddingLg,
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final user = users[index];
                      return UserListTile(
                        user: user,
                        isPending: false,
                        showActions: false,
                        onDelete: () async {
                          final confirmed = await context.showConfirmDialog(
                            title: 'Delete User',
                            message: 'Are you sure you want to delete ${user.displayName}? This will remove all their data.',
                            confirmLabel: 'Delete',
                            isDestructive: true,
                          );
                          if (confirmed == true && context.mounted) {
                            final success = await ref.read(adminActionsProvider).deleteUser(user.id);
                            if (context.mounted) {
                              context.showSnackBar(success ? 'User deleted' : 'Failed to delete user', isError: !success);
                            }
                          }
                        },
                      );
                    },
                  );
                },
                loading: () =>
                    const LoadingIndicator(message: 'Loading users...'),
                error: (error, _) => ErrorView(
                  message: error.toString(),
                  onRetry: () => ref.invalidate(allUsersProvider),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

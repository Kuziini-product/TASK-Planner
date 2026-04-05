import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../core/services/birthday_service.dart';
import '../../../core/utils/extensions.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/kuziini_app_bar.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/widgets/error_view.dart';
import '../../auth/domain/auth_state.dart';
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
                        onBirthDateChanged: (date) async {
                          try {
                            await Supabase.instance.client.from('profiles').update({
                              'birth_date': '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
                            }).eq('id', user.id);
                            ref.invalidate(allUsersProvider);
                            ref.invalidate(birthdayUsersProvider);
                            if (context.mounted) context.showSnackBar('Birthday set for ${user.displayName}');
                          } catch (e) {
                            if (context.mounted) context.showSnackBar('Failed to set birthday: $e', isError: true);
                          }
                        },
                        onRoleChange: (newRole) async {
                          final success = await ref.read(adminActionsProvider).updateUserRole(user.id, newRole);
                          if (context.mounted) {
                            context.showSnackBar(success
                                ? '${user.displayName} is now ${newRole.toUpperCase()}'
                                : 'Failed to change role', isError: !success);
                          }
                        },
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
                        // Show manage access button for managers
                        onManageAccess: user.isManager ? () {
                          _showManageAccessSheet(context, ref, user, users);
                        } : null,
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

  void _showManageAccessSheet(BuildContext context, WidgetRef ref, UserProfile manager, List<UserProfile> allUsers) {
    // Get non-admin, non-self users
    final assignableUsers = allUsers.where((u) => u.id != manager.id && !u.isAdmin && u.isApproved).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => _ManagerAccessSheet(managerId: manager.id, managerName: manager.displayName, users: assignableUsers),
    );
  }
}

class _ManagerAccessSheet extends ConsumerStatefulWidget {
  const _ManagerAccessSheet({required this.managerId, required this.managerName, required this.users});
  final String managerId;
  final String managerName;
  final List<UserProfile> users;

  @override
  ConsumerState<_ManagerAccessSheet> createState() => _ManagerAccessSheetState();
}

class _ManagerAccessSheetState extends ConsumerState<_ManagerAccessSheet> {
  final Set<String> _selectedUserIds = {};
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentPermissions();
  }

  Future<void> _loadCurrentPermissions() async {
    try {
      final response = await Supabase.instance.client
          .from('manager_permissions')
          .select('user_id')
          .eq('manager_id', widget.managerId);
      final ids = (response as List).map((r) => r['user_id'] as String).toSet();
      if (mounted) setState(() { _selectedUserIds.addAll(ids); _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      // Delete all existing permissions for this manager
      await Supabase.instance.client
          .from('manager_permissions')
          .delete()
          .eq('manager_id', widget.managerId);

      // Insert new permissions
      if (_selectedUserIds.isNotEmpty) {
        final rows = _selectedUserIds.map((uid) => {
          'manager_id': widget.managerId,
          'user_id': uid,
          'granted_by': Supabase.instance.client.auth.currentUser?.id,
        }).toList();
        await Supabase.instance.client.from('manager_permissions').insert(rows);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Acces actualizat pentru ${widget.managerName}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Eroare: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _toggleAll() {
    setState(() {
      if (_selectedUserIds.length == widget.users.length) {
        _selectedUserIds.clear();
      } else {
        _selectedUserIds.addAll(widget.users.map((u) => u.id));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final allSelected = _selectedUserIds.length == widget.users.length;

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (ctx, scrollController) => Column(
        children: [
          Container(width: 40, height: 4, margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: theme.dividerColor, borderRadius: BorderRadius.circular(2))),
          Text('Acces ${widget.managerName}', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
          Text('Selectează userii pe care îi poate vedea', style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 8),

          // Select all toggle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GestureDetector(
              onTap: _toggleAll,
              child: Row(
                children: [
                  Icon(allSelected
                      ? PhosphorIcons.checkSquare(PhosphorIconsStyle.fill)
                      : PhosphorIcons.square(PhosphorIconsStyle.regular),
                    size: 20, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Text('Toți userii', style: TextStyle(fontWeight: FontWeight.w600, color: theme.colorScheme.primary)),
                  const Spacer(),
                  Text('${_selectedUserIds.length}/${widget.users.length}',
                    style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
          ),
          const Divider(),

          // User list
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: scrollController,
                    itemCount: widget.users.length,
                    itemBuilder: (ctx, index) {
                      final user = widget.users[index];
                      final isChecked = _selectedUserIds.contains(user.id);
                      return CheckboxListTile(
                        value: isChecked,
                        onChanged: (v) {
                          setState(() {
                            if (v == true) _selectedUserIds.add(user.id);
                            else _selectedUserIds.remove(user.id);
                          });
                        },
                        title: Text(user.displayName, style: const TextStyle(fontWeight: FontWeight.w500)),
                        subtitle: Text(user.email, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
                        secondary: CircleAvatar(
                          radius: 16,
                          backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                          child: Text(user.initials, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: theme.colorScheme.primary)),
                        ),
                        activeColor: theme.colorScheme.primary,
                        dense: true,
                      );
                    },
                  ),
          ),

          // Save button
          Padding(
            padding: EdgeInsets.only(left: 16, right: 16, bottom: MediaQuery.of(ctx).padding.bottom + 12, top: 8),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _saving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Salvează'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

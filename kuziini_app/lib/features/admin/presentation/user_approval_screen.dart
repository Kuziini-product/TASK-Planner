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
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final pendingCount = pendingAsync.valueOrNull?.length ?? 0;

    return Scaffold(
      appBar: KuziiniAppBar(
        showBackButton: true,
        title: 'User Management',
        actions: [
          // Reports button
          IconButton(
            onPressed: () => _showReports(context, ref),
            icon: Icon(PhosphorIcons.chartBar(PhosphorIconsStyle.regular)),
            tooltip: 'Rapoarte',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(allUsersProvider);
          ref.invalidate(pendingUsersProvider);
        },
        child: allUsersAsync.when(
          data: (users) {
            final pendingUsers = pendingAsync.valueOrNull ?? [];

            return ListView(
              padding: AppSpacing.paddingLg,
              children: [
                // Pending approvals banner (only if there are pending users)
                if (pendingCount > 0) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(PhosphorIcons.userPlus(PhosphorIconsStyle.fill), size: 20, color: Colors.orange),
                            const SizedBox(width: 8),
                            Text('$pendingCount Cereri de înregistrare', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.orange)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ...pendingUsers.map((user) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: Colors.orange.withValues(alpha: 0.15),
                                child: Text(user.initials, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.orange)),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(user.displayName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                    Text(user.email, style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant)),
                                  ],
                                ),
                              ),
                              TextButton(
                                onPressed: () async {
                                  final success = await ref.read(adminActionsProvider).approveUser(user.id);
                                  if (context.mounted) context.showSnackBar(success ? '${user.displayName} aprobat' : 'Eroare', isError: !success);
                                },
                                style: TextButton.styleFrom(foregroundColor: Colors.green, padding: const EdgeInsets.symmetric(horizontal: 8)),
                                child: const Text('Aprobă', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                              ),
                              TextButton(
                                onPressed: () async {
                                  final confirmed = await context.showConfirmDialog(title: 'Respinge', message: 'Respingi ${user.displayName}?', confirmLabel: 'Respinge', isDestructive: true);
                                  if (confirmed == true) {
                                    final success = await ref.read(adminActionsProvider).rejectUser(user.id);
                                    if (context.mounted) context.showSnackBar(success ? 'Respins' : 'Eroare', isError: !success);
                                  }
                                },
                                style: TextButton.styleFrom(foregroundColor: Colors.red, padding: const EdgeInsets.symmetric(horizontal: 8)),
                                child: const Text('Respinge', style: TextStyle(fontSize: 12)),
                              ),
                            ],
                          ),
                        )),
                      ],
                    ),
                  ),
                ],

                // User count
                Text('${users.length} Utilizatori', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: primaryColor)),
                const SizedBox(height: 8),

                // All users list
                ...users.asMap().entries.map((entry) {
                  final user = entry.value;
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
                    onManageAccess: user.isManager ? () {
                      _showManageAccessSheet(context, ref, user, users);
                    } : null,
                  );
                }),
              ],
            );
          },
          loading: () => const LoadingIndicator(message: 'Loading users...'),
          error: (error, _) => ErrorView(
            message: error.toString(),
            onRetry: () => ref.invalidate(allUsersProvider),
          ),
        ),
      ),
    );
  }

  void _showReports(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final allUsersAsync = ref.read(allUsersProvider);
    final users = allUsersAsync.valueOrNull ?? [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (ctx, scrollController) => FutureBuilder<List<Map<String, dynamic>>>(
          future: _fetchReportData(users),
          builder: (ctx, snapshot) {
            final reportData = snapshot.data ?? [];

            return Column(
              children: [
                Container(width: 40, height: 4, margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(color: theme.dividerColor, borderRadius: BorderRadius.circular(2))),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(PhosphorIcons.chartBar(PhosphorIconsStyle.fill), color: primaryColor, size: 22),
                    const SizedBox(width: 8),
                    Text('Rapoarte', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 16),

                if (snapshot.connectionState == ConnectionState.waiting)
                  const Expanded(child: Center(child: CircularProgressIndicator()))
                else
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        // Performance ranking
                        _ReportSection(
                          title: 'Performanță (task-uri completate)',
                          icon: PhosphorIcons.trophy(PhosphorIconsStyle.fill),
                          color: Colors.amber,
                          children: reportData.asMap().entries.map((e) {
                            final d = e.value;
                            final rank = e.key + 1;
                            final total = d['total'] as int;
                            final done = d['done'] as int;
                            final pct = total > 0 ? (done * 100 / total).round() : 0;
                            return _ReportRow(
                              rank: rank,
                              name: d['name'] as String,
                              value: '$done/$total ($pct%)',
                              barValue: total > 0 ? done / total : 0,
                              color: rank == 1 ? Colors.amber : rank == 2 ? Colors.grey : rank == 3 ? Colors.brown : primaryColor,
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: 16),

                        // Overdue ranking
                        _ReportSection(
                          title: 'Task-uri Overdue',
                          icon: PhosphorIcons.warning(PhosphorIconsStyle.fill),
                          color: Colors.red,
                          children: reportData.where((d) => (d['overdue'] as int) > 0).map((d) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  CircleAvatar(radius: 14, backgroundColor: Colors.red.withValues(alpha: 0.1),
                                    child: Text((d['name'] as String)[0], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.red))),
                                  const SizedBox(width: 10),
                                  Expanded(child: Text(d['name'] as String, style: const TextStyle(fontWeight: FontWeight.w500))),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                                    child: Text('${d['overdue']} overdue', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.red)),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: 16),

                        // Task distribution
                        _ReportSection(
                          title: 'Distribuție Task-uri',
                          icon: PhosphorIcons.listChecks(PhosphorIconsStyle.fill),
                          color: primaryColor,
                          children: reportData.map((d) {
                            final total = d['total'] as int;
                            final done = d['done'] as int;
                            final inProg = d['in_progress'] as int;
                            final todo = d['todo'] as int;
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(d['name'] as String, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      _MiniStat('Total', '$total', primaryColor),
                                      const SizedBox(width: 8),
                                      _MiniStat('Done', '$done', Colors.green),
                                      const SizedBox(width: 8),
                                      _MiniStat('In Prog', '$inProg', Colors.orange),
                                      const SizedBox(width: 8),
                                      _MiniStat('To Do', '$todo', Colors.blue),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _fetchReportData(List<UserProfile> users) async {
    final results = <Map<String, dynamic>>[];
    final now = DateTime.now();
    final today = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    for (final user in users) {
      try {
        final tasks = await Supabase.instance.client
            .from('tasks')
            .select('status, due_date, title')
            .eq('created_by', user.id);

        final taskList = (tasks as List).where((t) {
          final title = (t['title'] as String? ?? '').toLowerCase();
          return !title.contains('concediu') && !title.contains('liber') && t['status'] != 'archived';
        }).toList();

        final total = taskList.length;
        final done = taskList.where((t) => t['status'] == 'done').length;
        final inProgress = taskList.where((t) => t['status'] == 'in_progress').length;
        final todo = taskList.where((t) => t['status'] == 'todo').length;
        final overdue = taskList.where((t) {
          if (t['status'] == 'done') return false;
          final dd = t['due_date'] as String?;
          return dd != null && dd.compareTo(today) < 0;
        }).length;

        results.add({
          'name': user.displayName,
          'total': total,
          'done': done,
          'in_progress': inProgress,
          'todo': todo,
          'overdue': overdue,
        });
      } catch (_) {}
    }

    // Sort by done percentage descending
    results.sort((a, b) {
      final pctA = (a['total'] as int) > 0 ? (a['done'] as int) / (a['total'] as int) : 0.0;
      final pctB = (b['total'] as int) > 0 ? (b['done'] as int) / (b['total'] as int) : 0.0;
      return pctB.compareTo(pctA);
    });

    return results;
  }

  void _showManageAccessSheet(BuildContext context, WidgetRef ref, UserProfile manager, List<UserProfile> allUsers) {
    // Get non-admin, non-self users
    final assignableUsers = allUsers.where((u) => u.id != manager.id && u.isApproved).toList();

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

// ── Report Widgets ──

class _ReportSection extends StatelessWidget {
  const _ReportSection({required this.title, required this.icon, required this.color, required this.children});
  final String title;
  final IconData icon;
  final Color color;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color)),
            ],
          ),
          const SizedBox(height: 12),
          if (children.isEmpty)
            Text('Fără date', style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant))
          else
            ...children,
        ],
      ),
    );
  }
}

class _ReportRow extends StatelessWidget {
  const _ReportRow({required this.rank, required this.name, required this.value, required this.barValue, required this.color});
  final int rank;
  final String name;
  final String value;
  final double barValue;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 22, child: Text('$rank.', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color))),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                const SizedBox(height: 3),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: barValue,
                    backgroundColor: color.withValues(alpha: 0.1),
                    color: color,
                    minHeight: 5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat(this.label, this.value, this.color);
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(6),
          border: Border(left: BorderSide(color: color, width: 2)),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color)),
            Text(label, style: TextStyle(fontSize: 8, color: color.withValues(alpha: 0.7))),
          ],
        ),
      ),
    );
  }
}

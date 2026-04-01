import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/widgets/kuziini_text_field.dart';
import '../../../auth/domain/auth_state.dart';

/// Provider that fetches all active users from the profiles table.
final activeUsersProvider = FutureProvider<List<UserProfile>>((ref) async {
  final response = await Supabase.instance.client
      .from(AppConstants.tableUsers)
      .select('*')
      .eq('status', 'active')
      .order('full_name');
  return (response as List)
      .map((j) => UserProfile.fromJson(j as Map<String, dynamic>))
      .toList();
});

/// Result returned when a user is picked.
class UserPickerResult {
  const UserPickerResult({required this.userId, required this.userName});
  final String userId;
  final String userName;
}

/// Shows a bottom sheet with a searchable list of active users.
/// Returns a [UserPickerResult] if a user is selected, or null if dismissed.
Future<UserPickerResult?> showUserPicker(BuildContext context) {
  return showModalBottomSheet<UserPickerResult>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) => _UserPickerSheet(
        scrollController: scrollController,
      ),
    ),
  );
}

class _UserPickerSheet extends ConsumerStatefulWidget {
  const _UserPickerSheet({required this.scrollController});

  final ScrollController scrollController;

  @override
  ConsumerState<_UserPickerSheet> createState() => _UserPickerSheetState();
}

class _UserPickerSheetState extends ConsumerState<_UserPickerSheet> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final usersAsync = ref.watch(activeUsersProvider);

    return Column(
      children: [
        // Handle bar
        Container(
          margin: const EdgeInsets.only(top: 8),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(2),
          ),
        ),

        // Title
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            'Select User',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        // Search bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: KuziiniTextField(
            controller: _searchController,
            hint: 'Search by name or email...',
            prefixIcon: PhosphorIcons.magnifyingGlass(PhosphorIconsStyle.regular),
            onChanged: (value) => setState(() => _query = value.toLowerCase()),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),

        const Divider(height: 1),

        // User list
        Expanded(
          child: usersAsync.when(
            data: (users) {
              final filtered = _query.isEmpty
                  ? users
                  : users.where((u) {
                      final name = (u.fullName ?? '').toLowerCase();
                      final email = u.email.toLowerCase();
                      return name.contains(_query) || email.contains(_query);
                    }).toList();

              if (filtered.isEmpty) {
                return Center(
                  child: Padding(
                    padding: AppSpacing.paddingLg,
                    child: Text(
                      _query.isEmpty
                          ? 'No active users found'
                          : 'No users match "$_query"',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                );
              }

              return ListView.builder(
                controller: widget.scrollController,
                itemCount: filtered.length,
                padding: const EdgeInsets.symmetric(vertical: 4),
                itemBuilder: (context, index) {
                  final user = filtered[index];
                  return _UserListTile(
                    user: user,
                    onTap: () {
                      Navigator.of(context).pop(
                        UserPickerResult(
                          userId: user.id,
                          userName: user.displayName,
                        ),
                      );
                    },
                  );
                },
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(),
            ),
            error: (error, _) => Center(
              child: Padding(
                padding: AppSpacing.paddingLg,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      PhosphorIcons.warningCircle(PhosphorIconsStyle.regular),
                      size: 32,
                      color: AppColors.error,
                    ),
                    AppSpacing.vGapMd,
                    Text(
                      'Failed to load users',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                    AppSpacing.vGapSm,
                    TextButton(
                      onPressed: () => ref.invalidate(activeUsersProvider),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _UserListTile extends StatelessWidget {
  const _UserListTile({required this.user, required this.onTap});

  final UserProfile user;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            // Avatar circle with initials
            CircleAvatar(
              radius: 20,
              backgroundColor:
                  theme.colorScheme.primary.withValues(alpha: 0.1),
              child: Text(
                user.initials,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
            AppSpacing.hGapMd,
            // Name and email
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.displayName,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    user.email,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            // Chevron
            Icon(
              PhosphorIcons.caretRight(PhosphorIconsStyle.regular),
              size: 16,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

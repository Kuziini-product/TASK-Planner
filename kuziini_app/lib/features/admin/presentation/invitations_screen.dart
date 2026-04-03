import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/extensions.dart';
import '../../../core/widgets/kuziini_app_bar.dart';
import '../../../core/widgets/kuziini_button.dart';
import '../../../core/widgets/kuziini_card.dart';
import '../../../core/widgets/kuziini_text_field.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../providers/admin_provider.dart';

class InvitationsScreen extends ConsumerStatefulWidget {
  const InvitationsScreen({super.key});

  @override
  ConsumerState<InvitationsScreen> createState() => _InvitationsScreenState();
}

class _InvitationsScreenState extends ConsumerState<InvitationsScreen> {
  final _emailController = TextEditingController();
  String _selectedRole = 'user';
  bool _isSending = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendInvitation() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.isValidEmail) {
      context.showSnackBar('Please enter a valid email', isError: true);
      return;
    }

    setState(() => _isSending = true);

    try {
      final inviteLink = await ref.read(adminActionsProvider).sendInvitation(
            email: email,
            role: _selectedRole,
          );

      if (mounted) {
        if (inviteLink != null) {
          _emailController.clear();
          // Show dialog with link to copy/share
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Row(
                children: [
                  Icon(PhosphorIcons.checkCircle(PhosphorIconsStyle.fill), color: AppColors.success),
                  const SizedBox(width: 8),
                  const Text('Invitation Created'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Send this link to $email:'),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Theme.of(ctx).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SelectableText(inviteLink, style: const TextStyle(fontSize: 12)),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Close'),
                ),
                FilledButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: inviteLink));
                    Navigator.pop(ctx);
                    context.showSnackBar('Link copied!');
                  },
                  icon: Icon(PhosphorIcons.copy(PhosphorIconsStyle.regular), size: 16),
                  label: const Text('Copy Link'),
                ),
                FilledButton.icon(
                  onPressed: () {
                    Share.share('Join Kuziini Task Manager:\n$inviteLink');
                    Navigator.pop(ctx);
                  },
                  icon: Icon(PhosphorIcons.shareFat(PhosphorIconsStyle.regular), size: 16),
                  label: const Text('Share'),
                ),
              ],
            ),
          );
        } else {
          context.showSnackBar('Failed to send invitation', isError: true);
        }
      }
    } catch (e) {
      if (mounted) {
        context.showSnackBar('Error: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final invitationsAsync = ref.watch(invitationsProvider);

    return Scaffold(
      appBar: const KuziiniAppBar(
        showBackButton: true,
        title: 'Invitations',
      ),
      body: ListView(
        padding: AppSpacing.paddingLg,
        children: [
          // Send invitation form
          KuziiniCard(
            padding: AppSpacing.paddingLg,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Send Invitation', style: theme.textTheme.titleSmall),
                AppSpacing.vGapMd,
                KuziiniTextField(
                  controller: _emailController,
                  hint: 'Email address',
                  prefixIcon:
                      PhosphorIcons.envelope(PhosphorIconsStyle.regular),
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _sendInvitation(),
                ),
                AppSpacing.vGapMd,

                // Role selector
                Row(
                  children: [
                    Text('Role:', style: theme.textTheme.labelMedium),
                    AppSpacing.hGapMd,
                    ChoiceChip(
                      label: const Text('User'),
                      selected: _selectedRole == 'user',
                      onSelected: (_) =>
                          setState(() => _selectedRole = 'user'),
                    ),
                    AppSpacing.hGapSm,
                    ChoiceChip(
                      label: const Text('Manager'),
                      selected: _selectedRole == 'manager',
                      onSelected: (_) =>
                          setState(() => _selectedRole = 'manager'),
                    ),
                    AppSpacing.hGapSm,
                    ChoiceChip(
                      label: const Text('Admin'),
                      selected: _selectedRole == 'admin',
                      onSelected: (_) =>
                          setState(() => _selectedRole = 'admin'),
                    ),
                  ],
                ),

                AppSpacing.vGapLg,

                KuziiniButton(
                  label: 'Send Invitation',
                  onPressed: _sendInvitation,
                  isLoading: _isSending,
                  icon: PhosphorIcons.paperPlaneRight(PhosphorIconsStyle.fill),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 300.ms),

          AppSpacing.vGapXl,

          // Sent invitations
          Text(
            'SENT INVITATIONS',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          AppSpacing.vGapMd,

          invitationsAsync.when(
            data: (invitations) {
              if (invitations.isEmpty) {
                return const EmptyState(
                  title: 'No invitations sent',
                  message: 'Send your first invitation above.',
                );
              }

              return Column(
                children: invitations.asMap().entries.map((entry) {
                  final invitation = entry.value;
                  final status = invitation['status'] as String? ?? 'pending';
                  final email = invitation['email'] as String? ?? '';
                  final createdAt = invitation['created_at'] != null
                      ? DateTime.parse(invitation['created_at'] as String)
                      : null;

                  Color statusColor;
                  switch (status) {
                    case 'accepted':
                      statusColor = AppColors.success;
                    case 'cancelled':
                      statusColor = AppColors.error;
                    default:
                      statusColor = AppColors.warning;
                  }

                  return KuziiniCard(
                    padding: const EdgeInsets.all(14),
                    margin: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            PhosphorIcons.envelope(PhosphorIconsStyle.fill),
                            size: 16,
                            color: statusColor,
                          ),
                        ),
                        AppSpacing.hGapMd,
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                email,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 1,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          statusColor.withValues(alpha: 0.1),
                                      borderRadius:
                                          AppSpacing.borderRadiusFull,
                                    ),
                                    child: Text(
                                      status.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                        color: statusColor,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                  AppSpacing.hGapSm,
                                  if (createdAt != null)
                                    Text(
                                      AppDateUtils.formatTimeAgo(createdAt),
                                      style:
                                          theme.textTheme.labelSmall?.copyWith(
                                        color: theme
                                            .colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (status == 'pending')
                          IconButton(
                            onPressed: () async {
                              final id = invitation['id'] as String;
                              await ref
                                  .read(adminActionsProvider)
                                  .cancelInvitation(id);
                            },
                            icon: Icon(
                              PhosphorIcons.x(PhosphorIconsStyle.bold),
                              size: 16,
                              color: AppColors.error,
                            ),
                          ),
                      ],
                    ),
                  )
                      .animate()
                      .fadeIn(
                        duration: 300.ms,
                        delay: Duration(milliseconds: 50 * entry.key),
                      );
                }).toList(),
              );
            },
            loading: () => const LoadingIndicator(size: 24),
            error: (_, __) =>
                const Center(child: Text('Failed to load invitations')),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

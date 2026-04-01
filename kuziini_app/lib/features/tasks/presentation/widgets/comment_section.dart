import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/widgets/voice_input_button.dart';
import '../../data/models/task_comment.dart';
import '../../providers/tasks_provider.dart';

// ── Color Assignment ──

Color getUserColor(String userId) {
  const colors = [
    Color(0xFF0D7377), // teal
    Color(0xFF7C3AED), // purple
    Color(0xFFEC4899), // pink
    Color(0xFFF59E0B), // amber
    Color(0xFF10B981), // emerald
    Color(0xFF3B82F6), // blue
    Color(0xFFEF4444), // red
    Color(0xFF8B5CF6), // violet
    Color(0xFF06B6D4), // cyan
    Color(0xFFF97316), // orange
  ];
  final hash = userId.hashCode.abs();
  return colors[hash % colors.length];
}

// ── Comment Section Widget ──

class CommentSection extends ConsumerStatefulWidget {
  const CommentSection({super.key, required this.taskId});

  final String taskId;

  @override
  ConsumerState<CommentSection> createState() => _CommentSectionState();
}

class _CommentSectionState extends ConsumerState<CommentSection> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  bool _isSending = false;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom({bool animated = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        if (animated) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        } else {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        }
      }
    });
  }

  Future<void> _sendComment() async {
    final content = _controller.text.trim();
    if (content.isEmpty) return;

    setState(() => _isSending = true);

    try {
      final repo = ref.read(taskRepositoryProvider);
      final userId = SupabaseService.instance.currentUserId!;
      await repo.addComment(
        taskId: widget.taskId,
        userId: userId,
        content: content,
      );
      _controller.clear();
      ref.invalidate(taskCommentsProvider(widget.taskId));
    } catch (e) {
      if (mounted) {
        context.showSnackBar('Failed to send comment', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final commentsAsync = ref.watch(taskCommentsProvider(widget.taskId));
    final currentUserId = SupabaseService.instance.currentUserId;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: Row(
            children: [
              Icon(
                PhosphorIcons.chatCircle(PhosphorIconsStyle.regular),
                size: 20,
              ),
              AppSpacing.hGapSm,
              Text('Comments', style: theme.textTheme.titleSmall),
              commentsAsync.whenOrNull<Widget>(
                data: (comments) => comments.isNotEmpty
                    ? Container(
                        margin: const EdgeInsets.only(left: AppSpacing.sm),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: AppSpacing.borderRadiusFull,
                        ),
                        child: Text(
                          '${comments.length}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ) ?? const SizedBox.shrink(),
            ],
          ),
        ),

        // Messages area
        commentsAsync.when(
          data: (comments) {
            if (comments.isNotEmpty) {
              _scrollToBottom(animated: false);
            }

            return Container(
              constraints: BoxConstraints(
                maxHeight: comments.isEmpty ? 100 : 360,
              ),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.surfaceVariantDark.withValues(alpha: 0.5)
                    : AppColors.surfaceVariantLight.withValues(alpha: 0.6),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppSpacing.radiusMd),
                  topRight: Radius.circular(AppSpacing.radiusMd),
                ),
              ),
              child: comments.isEmpty
                  ? Center(
                      child: Padding(
                        padding: AppSpacing.paddingLg,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              PhosphorIcons.chatTeardrop(
                                  PhosphorIconsStyle.light),
                              size: 32,
                              color: theme.colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.4),
                            ),
                            AppSpacing.vGapSm,
                            Text(
                              'No comments yet',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant
                                    .withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      itemCount: comments.length,
                      itemBuilder: (context, index) {
                        final comment = comments[index];
                        final isCurrentUser =
                            comment.userId == currentUserId;

                        // Check if we should show the date separator
                        final showDateSeparator = index == 0 ||
                            !_isSameDay(
                              comments[index - 1].createdAt,
                              comment.createdAt,
                            );

                        // Check if previous comment is from the same user
                        final showAvatar = index == 0 ||
                            comments[index - 1].userId != comment.userId ||
                            showDateSeparator;

                        return Column(
                          children: [
                            if (showDateSeparator && comment.createdAt != null)
                              _DateSeparator(date: comment.createdAt!),
                            _CommentBubble(
                              comment: comment,
                              isCurrentUser: isCurrentUser,
                              showAvatar: showAvatar,
                            ),
                          ],
                        );
                      },
                    ),
            );
          },
          loading: () => Container(
            height: 100,
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.surfaceVariantDark.withValues(alpha: 0.5)
                  : AppColors.surfaceVariantLight.withValues(alpha: 0.6),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppSpacing.radiusMd),
                topRight: Radius.circular(AppSpacing.radiusMd),
              ),
            ),
            child: const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
          error: (_, __) => Container(
            height: 80,
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.surfaceVariantDark.withValues(alpha: 0.5)
                  : AppColors.surfaceVariantLight.withValues(alpha: 0.6),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppSpacing.radiusMd),
                topRight: Radius.circular(AppSpacing.radiusMd),
              ),
            ),
            child: Center(
              child: Text(
                'Failed to load comments',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.error,
                ),
              ),
            ),
          ),
        ),

        // Input bar
        Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : AppColors.cardLight,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(AppSpacing.radiusMd),
              bottomRight: Radius.circular(AppSpacing.radiusMd),
            ),
            border: Border(
              top: BorderSide(
                color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
                width: 0.5,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, -1),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.surfaceVariantDark
                        : AppColors.surfaceVariantLight,
                    borderRadius: AppSpacing.borderRadiusXl,
                  ),
                  child: TextField(
                    controller: _controller,
                    maxLines: 4,
                    minLines: 1,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendComment(),
                    onChanged: (_) => setState(() {}),
                    style: theme.textTheme.bodyMedium,
                    decoration: InputDecoration(
                      hintText: 'Write a comment...',
                      hintStyle: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant
                            .withValues(alpha: 0.5),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.md,
                      ),
                      isDense: true,
                    ),
                  ),
                ),
              ),
              AppSpacing.hGapSm,
              VoiceInputButton(
                mini: true,
                size: 32,
                hintText: 'Say your comment...',
                onResult: (text) {
                  final current = _controller.text;
                  _controller.text =
                      current.isEmpty ? text : '$current $text';
                  setState(() {});
                },
              ),
              AppSpacing.hGapSm,
              _SendButton(
                onPressed: _controller.text.trim().isNotEmpty && !_isSending
                    ? _sendComment
                    : null,
                isSending: _isSending,
              ),
            ],
          ),
        ),
      ],
    );
  }

  bool _isSameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

// ── Send Button ──

class _SendButton extends StatelessWidget {
  const _SendButton({required this.onPressed, required this.isSending});

  final VoidCallback? onPressed;
  final bool isSending;

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: isEnabled
            ? AppColors.primary
            : AppColors.primary.withValues(alpha: 0.3),
        shape: BoxShape.circle,
        boxShadow: isEnabled
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: AppSpacing.borderRadiusFull,
          child: Center(
            child: isSending
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  )
                : Icon(
                    PhosphorIcons.paperPlaneRight(PhosphorIconsStyle.fill),
                    color: Colors.white,
                    size: 18,
                  ),
          ),
        ),
      ),
    );
  }
}

// ── Date Separator ──

class _DateSeparator extends StatelessWidget {
  const _DateSeparator({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    String label;
    if (AppDateUtils.isToday(date)) {
      label = 'Today';
    } else if (AppDateUtils.isYesterday(date)) {
      label = 'Yesterday';
    } else {
      label = AppDateUtils.formatDate(date);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: Divider(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.15),
            ),
          ),
          Padding(
            padding: AppSpacing.paddingHorizontalMd,
            child: Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color:
                    theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                fontWeight: FontWeight.w500,
                letterSpacing: 0.3,
              ),
            ),
          ),
          Expanded(
            child: Divider(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.15),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Comment Bubble ──

class _CommentBubble extends StatelessWidget {
  const _CommentBubble({
    required this.comment,
    required this.isCurrentUser,
    required this.showAvatar,
  });

  final TaskComment comment;
  final bool isCurrentUser;
  final bool showAvatar;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final userColor = getUserColor(comment.userId);
    final initials = _getInitials(comment.userName);

    return Padding(
      padding: EdgeInsets.only(
        top: showAvatar ? AppSpacing.sm : 2,
        bottom: 2,
      ),
      child: Row(
        mainAxisAlignment:
            isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Avatar (left side, other users only)
          if (!isCurrentUser) ...[
            if (showAvatar)
              Container(
                width: AppSpacing.avatarSm,
                height: AppSpacing.avatarSm,
                decoration: BoxDecoration(
                  color: userColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: userColor,
                    ),
                  ),
                ),
              )
            else
              SizedBox(width: AppSpacing.avatarSm),
            AppSpacing.hGapSm,
          ],

          // Bubble
          Flexible(
            child: Column(
              crossAxisAlignment: isCurrentUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                // User name (other users only, when avatar is shown)
                if (!isCurrentUser && showAvatar)
                  Padding(
                    padding: const EdgeInsets.only(
                      left: AppSpacing.xs,
                      bottom: 3,
                    ),
                    child: Text(
                      comment.userName ?? 'Unknown',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: userColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ),

                // Message bubble
                GestureDetector(
                  onLongPress: () {
                    Clipboard.setData(ClipboardData(text: comment.content));
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Comment copied'),
                        duration: Duration(seconds: 1),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.70,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: isCurrentUser
                          ? AppColors.primary
                          : (isDark
                              ? AppColors.surfaceVariantDark
                              : Colors.white),
                      borderRadius: BorderRadius.only(
                        topLeft:
                            const Radius.circular(AppSpacing.radiusLg),
                        topRight:
                            const Radius.circular(AppSpacing.radiusLg),
                        bottomLeft: Radius.circular(
                          isCurrentUser
                              ? AppSpacing.radiusLg
                              : AppSpacing.radiusXs,
                        ),
                        bottomRight: Radius.circular(
                          isCurrentUser
                              ? AppSpacing.radiusXs
                              : AppSpacing.radiusLg,
                        ),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (isCurrentUser
                                  ? AppColors.primary
                                  : Colors.black)
                              .withValues(alpha: 0.08),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          comment.content,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: isCurrentUser
                                ? Colors.white
                                : (isDark
                                    ? AppColors.textPrimaryDark
                                    : AppColors.textPrimaryLight),
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Timestamp
                if (comment.createdAt != null)
                  Padding(
                    padding: const EdgeInsets.only(
                      top: 3,
                      left: AppSpacing.xs,
                      right: AppSpacing.xs,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          AppDateUtils.formatTime(comment.createdAt!),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.45),
                            fontSize: 10,
                          ),
                        ),
                        if (comment.isEdited) ...[
                          const SizedBox(width: 4),
                          Text(
                            'edited',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.35),
                              fontSize: 10,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // Spacing on the right for other users' messages
          if (isCurrentUser) ...[
            AppSpacing.hGapSm,
          ],
        ],
      ),
    );
  }

  String _getInitials(String? name) {
    if (name == null || name.isEmpty) return 'U';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }
}

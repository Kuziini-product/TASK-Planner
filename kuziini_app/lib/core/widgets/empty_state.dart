import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../constants/app_spacing.dart';
import 'kuziini_button.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.message,
    this.title,
    this.icon,
    this.actionLabel,
    this.onAction,
    this.iconSize = 80,
  });

  final String message;
  final String? title;
  final IconData? icon;
  final String? actionLabel;
  final VoidCallback? onAction;
  final double iconSize;

  factory EmptyState.tasks({VoidCallback? onCreateTask}) {
    return EmptyState(
      icon: PhosphorIcons.checkSquare(PhosphorIconsStyle.light),
      title: 'No tasks yet',
      message: 'Start by creating your first task.\nStay organized and productive!',
      actionLabel: 'Create Task',
      onAction: onCreateTask,
    );
  }

  factory EmptyState.notifications() {
    return EmptyState(
      icon: PhosphorIcons.bellSimple(PhosphorIconsStyle.light),
      title: 'All caught up!',
      message: 'No new notifications.\nYou\'re on top of everything.',
    );
  }

  factory EmptyState.search() {
    return EmptyState(
      icon: PhosphorIcons.magnifyingGlass(PhosphorIconsStyle.light),
      title: 'No results found',
      message: 'Try adjusting your search or filters.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: AppSpacing.paddingXl,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon ?? PhosphorIcons.folder(PhosphorIconsStyle.light),
              size: iconSize,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
            )
                .animate()
                .fadeIn(duration: 500.ms)
                .scale(begin: const Offset(0.8, 0.8), duration: 500.ms),
            AppSpacing.vGapXl,
            if (title != null) ...[
              Text(
                title!,
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              AppSpacing.vGapSm,
            ],
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              AppSpacing.vGapXl,
              KuziiniButton(
                label: actionLabel!,
                onPressed: onAction,
                isFullWidth: false,
                height: 44,
              ),
            ],
          ],
        )
            .animate()
            .fadeIn(duration: 400.ms, delay: 200.ms)
            .moveY(begin: 10, duration: 400.ms, delay: 200.ms),
      ),
    );
  }
}

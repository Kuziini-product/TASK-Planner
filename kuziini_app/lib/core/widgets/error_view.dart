import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import 'kuziini_button.dart';

class ErrorView extends StatelessWidget {
  const ErrorView({
    super.key,
    required this.message,
    this.title,
    this.onRetry,
    this.icon,
    this.fullScreen = false,
  });

  final String message;
  final String? title;
  final VoidCallback? onRetry;
  final IconData? icon;
  final bool fullScreen;

  factory ErrorView.generic({VoidCallback? onRetry}) {
    return ErrorView(
      title: 'Something went wrong',
      message: 'An unexpected error occurred. Please try again.',
      onRetry: onRetry,
    );
  }

  factory ErrorView.network({VoidCallback? onRetry}) {
    return ErrorView(
      icon: PhosphorIcons.wifiSlash(PhosphorIconsStyle.light),
      title: 'No connection',
      message: 'Please check your internet connection and try again.',
      onRetry: onRetry,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final content = Padding(
      padding: AppSpacing.paddingXl,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: AppSpacing.paddingLg,
            decoration: BoxDecoration(
              color: AppColors.errorLight.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon ?? PhosphorIcons.warning(PhosphorIconsStyle.light),
              size: 48,
              color: AppColors.error,
            ),
          ),
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
          if (onRetry != null) ...[
            AppSpacing.vGapXl,
            KuziiniButton(
              label: 'Try Again',
              onPressed: onRetry,
              variant: KuziiniButtonVariant.secondary,
              icon: PhosphorIcons.arrowClockwise(PhosphorIconsStyle.bold),
              isFullWidth: false,
              height: 44,
            ),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);

    if (fullScreen) {
      return Scaffold(body: Center(child: content));
    }

    return Center(child: content);
  }
}

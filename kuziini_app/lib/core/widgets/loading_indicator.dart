import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';

class LoadingIndicator extends StatelessWidget {
  const LoadingIndicator({
    super.key,
    this.message,
    this.size = 40,
    this.color,
    this.strokeWidth = 3,
    this.fullScreen = false,
  });

  final String? message;
  final double size;
  final Color? color;
  final double strokeWidth;
  final bool fullScreen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveColor = color ?? theme.colorScheme.primary;

    final indicator = Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: CircularProgressIndicator(
            strokeWidth: strokeWidth,
            valueColor: AlwaysStoppedAnimation<Color>(effectiveColor),
          ),
        ),
        if (message != null) ...[
          AppSpacing.vGapLg,
          Text(
            message!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    )
        .animate(onPlay: (c) => c.repeat())
        .fadeIn(duration: 300.ms);

    if (fullScreen) {
      return Scaffold(
        body: Center(child: indicator),
      );
    }

    return Center(child: indicator);
  }
}

class ShimmerLoading extends StatelessWidget {
  const ShimmerLoading({
    super.key,
    required this.child,
    this.isLoading = true,
  });

  final Widget child;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    if (!isLoading) return child;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return child
        .animate(onPlay: (c) => c.repeat())
        .shimmer(
          duration: 1200.ms,
          color: isDark
              ? AppColors.shimmerHighlightDark
              : AppColors.shimmerHighlight,
        );
  }
}

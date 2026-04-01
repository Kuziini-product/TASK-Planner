import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

class DailyProgress extends StatelessWidget {
  const DailyProgress({
    super.key,
    required this.progress,
    required this.completedCount,
    required this.totalCount,
    this.size = 56,
    this.strokeWidth = 4,
  });

  final double progress;
  final int completedCount;
  final int totalCount;
  final double size;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percentage = (progress * 100).round();

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background ring
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: 1,
              strokeWidth: strokeWidth,
              valueColor: AlwaysStoppedAnimation<Color>(
                theme.colorScheme.outline.withValues(alpha: 0.15),
              ),
            ),
          ),
          // Progress ring
          SizedBox(
            width: size,
            height: size,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return CircularProgressIndicator(
                  value: value,
                  strokeWidth: strokeWidth,
                  strokeCap: StrokeCap.round,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _getProgressColor(value),
                  ),
                );
              },
            ),
          ),
          // Percentage text
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$percentage%',
                style: TextStyle(
                  fontSize: size * 0.22,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getProgressColor(double value) {
    if (value >= 1.0) return AppColors.success;
    if (value >= 0.7) return AppColors.primaryLight;
    if (value >= 0.4) return AppColors.warning;
    return AppColors.primary;
  }
}

class LinearDailyProgress extends StatelessWidget {
  const LinearDailyProgress({
    super.key,
    required this.progress,
    this.height = 6,
    this.showLabel = true,
  });

  final double progress;
  final double height;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percentage = (progress * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showLabel) ...[
          Text(
            '$percentage% complete',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
        ],
        ClipRRect(
          borderRadius: BorderRadius.circular(height / 2),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: progress),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return LinearProgressIndicator(
                value: value,
                minHeight: height,
                backgroundColor:
                    theme.colorScheme.outline.withValues(alpha: 0.15),
                valueColor: AlwaysStoppedAnimation<Color>(
                  value >= 1.0 ? AppColors.success : AppColors.primary,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

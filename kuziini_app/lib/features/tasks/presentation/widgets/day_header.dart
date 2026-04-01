import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/utils/date_utils.dart';
import 'daily_progress.dart';

class DayHeader extends StatelessWidget {
  const DayHeader({
    super.key,
    required this.date,
    required this.totalTasks,
    required this.completedTasks,
    this.userName,
  });

  final DateTime date;
  final int totalTasks;
  final int completedTasks;
  final String? userName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final greeting = AppDateUtils.getGreeting();
    final dateLabel = AppDateUtils.getRelativeDateLabel(date);
    final progress = totalTasks > 0 ? completedTasks / totalTasks : 0.0;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border(
          bottom: BorderSide(
            color: theme.dividerTheme.color ?? AppColors.dividerLight,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName != null
                          ? '$greeting, ${userName!.split(' ').first}'
                          : greeting,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ).animate().fadeIn(duration: 400.ms),
                    AppSpacing.vGapXs,
                    Text(
                      dateLabel == 'Today'
                          ? 'Today, ${AppDateUtils.formatDate(date)}'
                          : '${AppDateUtils.formatDay(date)}, ${AppDateUtils.formatDate(date)}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ).animate().fadeIn(duration: 400.ms, delay: 100.ms),
                  ],
                ),
              ),
              // Progress circle
              DailyProgress(
                progress: progress,
                completedCount: completedTasks,
                totalCount: totalTasks,
              ).animate().fadeIn(duration: 400.ms, delay: 200.ms).scale(
                    begin: const Offset(0.8, 0.8),
                    duration: 400.ms,
                    delay: 200.ms,
                  ),
            ],
          ),

          AppSpacing.vGapMd,

          // Stats row
          Row(
            children: [
              _StatPill(
                label: '$totalTasks tasks',
                icon: Icons.list_rounded,
                color: AppColors.info,
              ),
              AppSpacing.hGapSm,
              _StatPill(
                label: '$completedTasks done',
                icon: Icons.check_circle_outline_rounded,
                color: AppColors.success,
              ),
              AppSpacing.hGapSm,
              if (totalTasks - completedTasks > 0)
                _StatPill(
                  label: '${totalTasks - completedTasks} remaining',
                  icon: Icons.pending_outlined,
                  color: AppColors.warning,
                ),
            ],
          ).animate().fadeIn(duration: 400.ms, delay: 300.ms),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: AppSpacing.borderRadiusFull,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

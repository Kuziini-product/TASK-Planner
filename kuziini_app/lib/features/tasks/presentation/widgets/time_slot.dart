import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../data/models/task_model.dart';
import 'task_card.dart';

class TimeSlot extends StatelessWidget {
  const TimeSlot({
    super.key,
    required this.hour,
    required this.tasks,
    this.isCurrentHour = false,
    this.onStatusChanged,
  });

  final int hour;
  final List<TaskModel> tasks;
  final bool isCurrentHour;
  final void Function(String taskId, TaskStatus status)? onStatusChanged;

  String get _timeLabel {
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour $period';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return SizedBox(
      height: tasks.isEmpty
          ? AppConstants.timelineSlotHeight
          : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time label
          SizedBox(
            width: 56,
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                _timeLabel,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: isCurrentHour
                      ? primaryColor
                      : theme.colorScheme.onSurfaceVariant,
                  fontWeight:
                      isCurrentHour ? FontWeight.w700 : FontWeight.w500,
                ),
                textAlign: TextAlign.right,
              ),
            ),
          ),

          AppSpacing.hGapSm,

          // Divider line and tasks
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Hour separator line
                Container(
                  height: 1,
                  margin: const EdgeInsets.only(top: 8),
                  color: isCurrentHour
                      ? primaryColor.withValues(alpha: 0.4)
                      : theme.dividerTheme.color?.withValues(alpha: 0.5) ??
                          AppColors.dividerLight,
                ),

                // Current time indicator
                if (isCurrentHour)
                  Container(
                    height: 2,
                    margin: const EdgeInsets.only(top: 0),
                    decoration: BoxDecoration(
                      color: primaryColor,
                      borderRadius: AppSpacing.borderRadiusFull,
                    ),
                  ),

                // Tasks for this hour
                if (tasks.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Column(
                      children: tasks
                          .asMap()
                          .entries
                          .map(
                            (entry) => TaskCard(
                              task: entry.value,
                              animationIndex: entry.key,
                              onStatusChanged: onStatusChanged != null
                                  ? (status) =>
                                      onStatusChanged!(entry.value.id, status)
                                  : null,
                            ),
                          )
                          .toList(),
                    ),
                  ),

                // Empty space for slots without tasks
                if (tasks.isEmpty)
                  SizedBox(
                    height: AppConstants.timelineSlotHeight - 10,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

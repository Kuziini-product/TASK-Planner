import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../data/models/task_model.dart';

class PriorityBadge extends StatelessWidget {
  const PriorityBadge({
    super.key,
    required this.priority,
    this.compact = false,
  });

  final TaskPriority priority;
  final bool compact;

  Color get _color {
    switch (priority) {
      case TaskPriority.urgent:
        return AppColors.priorityUrgent;
      case TaskPriority.high:
        return AppColors.priorityHigh;
      case TaskPriority.medium:
        return AppColors.priorityMedium;
      case TaskPriority.low:
        return AppColors.priorityLow;
      case TaskPriority.none:
        return AppColors.priorityNone;
    }
  }

  Color get _bgColor {
    switch (priority) {
      case TaskPriority.urgent:
        return AppColors.priorityUrgentBg;
      case TaskPriority.high:
        return AppColors.priorityHighBg;
      case TaskPriority.medium:
        return AppColors.priorityMediumBg;
      case TaskPriority.low:
        return AppColors.priorityLowBg;
      case TaskPriority.none:
        return AppColors.priorityNoneBg;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: _color,
          shape: BoxShape.circle,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _bgColor,
        borderRadius: AppSpacing.borderRadiusFull,
      ),
      child: Text(
        priority.label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: _color,
        ),
      ),
    );
  }
}

class PriorityDot extends StatelessWidget {
  const PriorityDot({
    super.key,
    required this.priority,
    this.size = 4,
  });

  final TaskPriority priority;
  final double size;

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (priority) {
      case TaskPriority.urgent:
        color = AppColors.priorityUrgent;
      case TaskPriority.high:
        color = AppColors.priorityHigh;
      case TaskPriority.medium:
        color = AppColors.priorityMedium;
      case TaskPriority.low:
        color = AppColors.priorityLow;
      case TaskPriority.none:
        color = AppColors.priorityNone;
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../data/models/task_model.dart';

class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.status,
    this.onTap,
    this.isSelected = false,
    this.compact = false,
  });

  final TaskStatus status;
  final VoidCallback? onTap;
  final bool isSelected;
  final bool compact;

  Color get _color {
    switch (status) {
      case TaskStatus.todo:
        return AppColors.statusTodo;
      case TaskStatus.in_progress:
        return AppColors.statusInProgress;
      case TaskStatus.review:
        return Colors.orange;
      case TaskStatus.done:
        return AppColors.statusDone;
      case TaskStatus.archived:
        return Colors.grey;
    }
  }

  IconData get _icon {
    switch (status) {
      case TaskStatus.todo:
        return PhosphorIcons.circle(PhosphorIconsStyle.regular);
      case TaskStatus.in_progress:
        return PhosphorIcons.circleHalf(PhosphorIconsStyle.fill);
      case TaskStatus.review:
        return PhosphorIcons.eye(PhosphorIconsStyle.fill);
      case TaskStatus.done:
        return PhosphorIcons.checkCircle(PhosphorIconsStyle.fill);
      case TaskStatus.archived:
        return PhosphorIcons.archive(PhosphorIconsStyle.fill);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = isSelected
        ? _color.withValues(alpha: 0.15)
        : Colors.transparent;

    if (compact) {
      return Icon(_icon, size: 20, color: _color);
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: AppSpacing.borderRadiusFull,
          border: Border.all(
            color: isSelected ? _color : _color.withValues(alpha: 0.3),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_icon, size: 14, color: _color),
            const SizedBox(width: 4),
            Text(
              status.label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: _color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

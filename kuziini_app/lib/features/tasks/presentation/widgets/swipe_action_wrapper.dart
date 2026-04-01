import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/constants/app_colors.dart';

class SwipeActionWrapper extends StatelessWidget {
  const SwipeActionWrapper({
    super.key,
    required this.child,
    this.onSwipeLeft,
    this.onSwipeRight,
    this.leftLabel = 'Complete',
    this.rightLabel = 'Options',
    this.leftColor = AppColors.success,
    this.rightColor = AppColors.info,
    this.leftIcon,
    this.rightIcon,
    this.confirmDismiss,
  });

  final Widget child;
  final VoidCallback? onSwipeLeft;
  final VoidCallback? onSwipeRight;
  final String leftLabel;
  final String rightLabel;
  final Color leftColor;
  final Color rightColor;
  final IconData? leftIcon;
  final IconData? rightIcon;
  final Future<bool> Function(DismissDirection)? confirmDismiss;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: UniqueKey(),
      background: _buildBackground(
        alignment: Alignment.centerLeft,
        color: rightColor,
        icon: rightIcon ??
            PhosphorIcons.dotsThree(PhosphorIconsStyle.bold),
        label: rightLabel,
      ),
      secondaryBackground: _buildBackground(
        alignment: Alignment.centerRight,
        color: leftColor,
        icon: leftIcon ??
            PhosphorIcons.check(PhosphorIconsStyle.bold),
        label: leftLabel,
      ),
      confirmDismiss: confirmDismiss ??
          (direction) async {
            if (direction == DismissDirection.endToStart) {
              onSwipeLeft?.call();
              return false;
            } else if (direction == DismissDirection.startToEnd) {
              onSwipeRight?.call();
              return false;
            }
            return false;
          },
      child: child,
    );
  }

  Widget _buildBackground({
    required AlignmentGeometry alignment,
    required Color color,
    required IconData icon,
    required String label,
  }) {
    final isLeft = alignment == Alignment.centerLeft;

    return Container(
      alignment: alignment,
      padding: EdgeInsets.only(
        left: isLeft ? 20 : 0,
        right: isLeft ? 0 : 20,
      ),
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isLeft) ...[
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 6),
          ],
          Icon(icon, color: color, size: 22),
          if (isLeft) ...[
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

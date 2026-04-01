import 'package:flutter/material.dart';

import '../constants/app_spacing.dart';

enum KuziiniButtonVariant { primary, secondary, text, destructive }

class KuziiniButton extends StatelessWidget {
  const KuziiniButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = KuziiniButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.isEnabled = true,
    this.isFullWidth = true,
    this.height = 52,
    this.borderRadius,
  });

  final String label;
  final VoidCallback? onPressed;
  final KuziiniButtonVariant variant;
  final IconData? icon;
  final bool isLoading;
  final bool isEnabled;
  final bool isFullWidth;
  final double height;
  final double? borderRadius;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveOnPressed = (isLoading || !isEnabled) ? null : onPressed;

    Widget child = isLoading
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                variant == KuziiniButtonVariant.primary
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.primary,
              ),
            ),
          )
        : Row(
            mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20),
                AppSpacing.hGapSm,
              ],
              Text(label),
            ],
          );

    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(borderRadius ?? AppSpacing.radiusMd),
    );
    final minSize = Size(
      isFullWidth ? double.infinity : 0,
      height,
    );

    switch (variant) {
      case KuziiniButtonVariant.primary:
        return ElevatedButton(
          onPressed: effectiveOnPressed,
          style: ElevatedButton.styleFrom(
            minimumSize: minSize,
            shape: shape,
          ),
          child: child,
        );
      case KuziiniButtonVariant.secondary:
        return OutlinedButton(
          onPressed: effectiveOnPressed,
          style: OutlinedButton.styleFrom(
            minimumSize: minSize,
            shape: shape,
          ),
          child: child,
        );
      case KuziiniButtonVariant.text:
        return TextButton(
          onPressed: effectiveOnPressed,
          style: TextButton.styleFrom(
            minimumSize: minSize,
            shape: shape,
          ),
          child: child,
        );
      case KuziiniButtonVariant.destructive:
        return ElevatedButton(
          onPressed: effectiveOnPressed,
          style: ElevatedButton.styleFrom(
            minimumSize: minSize,
            shape: shape,
            backgroundColor: theme.colorScheme.error,
            foregroundColor: theme.colorScheme.onError,
          ),
          child: child,
        );
    }
  }
}

import 'package:flutter/material.dart';

import '../constants/app_spacing.dart';

class KuziiniCard extends StatelessWidget {
  const KuziiniCard({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.padding,
    this.margin,
    this.borderRadius,
    this.color,
    this.borderColor,
    this.elevation,
    this.leftAccentColor,
    this.leftAccentWidth = 4.0,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? borderRadius;
  final Color? color;
  final Color? borderColor;
  final double? elevation;
  final Color? leftAccentColor;
  final double leftAccentWidth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveRadius = borderRadius ?? AppSpacing.radiusMd;
    final effectiveColor = color ?? theme.cardTheme.color ?? theme.cardColor;

    Widget cardContent = Container(
      padding: padding ?? AppSpacing.paddingLg,
      decoration: BoxDecoration(
        color: effectiveColor,
        borderRadius: BorderRadius.circular(effectiveRadius),
        border: Border.all(
          color: borderColor ??
              theme.colorScheme.outline.withValues(alpha: 0.15),
        ),
        boxShadow: elevation != null && elevation! > 0
            ? [
                BoxShadow(
                  color: theme.colorScheme.shadow.withValues(alpha: 0.08),
                  blurRadius: elevation! * 2,
                  offset: Offset(0, elevation!),
                ),
              ]
            : null,
      ),
      child: child,
    );

    if (leftAccentColor != null) {
      cardContent = ClipRRect(
        borderRadius: BorderRadius.circular(effectiveRadius),
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: leftAccentColor!,
                width: leftAccentWidth,
              ),
            ),
          ),
          child: cardContent,
        ),
      );
    }

    if (onTap != null || onLongPress != null) {
      cardContent = Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(effectiveRadius),
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(effectiveRadius),
          child: cardContent,
        ),
      );
    }

    if (margin != null) {
      cardContent = Padding(padding: margin!, child: cardContent);
    }

    return cardContent;
  }
}

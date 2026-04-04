import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../constants/app_spacing.dart';
import '../services/birthday_service.dart';

class KuziiniAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const KuziiniAppBar({
    super.key,
    this.title,
    this.titleWidget,
    this.leading,
    this.actions,
    this.showBackButton = false,
    this.onBackPressed,
    this.elevation,
    this.backgroundColor,
    this.bottom,
    this.centerTitle = false,
  });

  final String? title;
  final Widget? titleWidget;
  final Widget? leading;
  final List<Widget>? actions;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final double? elevation;
  final Color? backgroundColor;
  final PreferredSizeWidget? bottom;
  final bool centerTitle;

  @override
  Size get preferredSize => Size.fromHeight(
        kToolbarHeight + (bottom?.preferredSize.height ?? 0),
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasBirthday = ref.watch(hasBirthdayTodayProvider);

    // Build actions: prepend cake emoji if someone has a birthday
    final effectiveActions = <Widget>[
      if (hasBirthday)
        const Padding(
          padding: EdgeInsets.only(right: 4),
          child: Text('🎂', style: TextStyle(fontSize: 20)),
        ),
      if (actions != null) ...actions!,
      const SizedBox(width: 8),
    ];

    return AppBar(
      title: titleWidget ??
          (title != null
              ? Text(
                  title!,
                  style: Theme.of(context).textTheme.titleLarge,
                )
              : null),
      centerTitle: centerTitle,
      leading: showBackButton
          ? IconButton(
              onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
              icon: Icon(PhosphorIcons.arrowLeft(PhosphorIconsStyle.bold)),
              padding: AppSpacing.paddingSm,
            )
          : leading,
      actions: effectiveActions.length > 1 ? effectiveActions : null,
      elevation: elevation,
      backgroundColor: backgroundColor,
      bottom: bottom,
    );
  }
}

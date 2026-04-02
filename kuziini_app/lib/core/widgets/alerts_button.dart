import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../features/notifications/providers/notifications_provider.dart';
import '../constants/app_colors.dart';
import '../router/app_router.dart';

/// Bell icon with unread badge – navigates to notifications screen.
class AlertsButton extends ConsumerWidget {
  const AlertsButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = ref.watch(unreadCountProvider);
    final badge = unreadCount.valueOrNull ?? 0;

    return IconButton(
      onPressed: () => context.go(AppRoutes.notifications),
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(badge > 0
              ? PhosphorIcons.bellRinging(PhosphorIconsStyle.fill)
              : PhosphorIcons.bell(PhosphorIconsStyle.regular),
            color: badge > 0 ? AppColors.error : null,
          ),
          if (badge > 0)
            Positioned(
              top: -6,
              right: -8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                constraints: const BoxConstraints(minWidth: 18),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 1.5),
                ),
                child: Text(
                  badge > 99 ? '99+' : '$badge',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
      tooltip: 'Notifications',
    );
  }
}

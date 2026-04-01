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
    final badge = unreadCount.whenOrNull(data: (count) => count) ?? 0;

    return IconButton(
      onPressed: () => context.go(AppRoutes.notifications),
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(PhosphorIcons.bell(PhosphorIconsStyle.regular)),
          if (badge > 0)
            Positioned(
              top: -4,
              right: -6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                constraints: const BoxConstraints(minWidth: 16),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badge > 99 ? '99+' : '$badge',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
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

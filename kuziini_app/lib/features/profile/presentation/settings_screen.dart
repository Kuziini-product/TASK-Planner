import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/utils/extensions.dart';
import '../../../core/widgets/kuziini_app_bar.dart';
import '../../auth/providers/auth_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final themeMode = ref.watch(themeModeProvider);
    final currentColor = ref.watch(primaryColorProvider);

    return Scaffold(
      appBar: const KuziiniAppBar(
        showBackButton: true,
        title: 'Settings',
      ),
      body: ListView(
        padding: AppSpacing.paddingLg,
        children: [
          // Appearance
          _SectionHeader(title: 'Appearance'),
          AppSpacing.vGapSm,

          _SettingsTile(
            icon: PhosphorIcons.sun(PhosphorIconsStyle.regular),
            title: 'Theme',
            subtitle: themeMode == ThemeMode.dark
                ? 'Dark'
                : themeMode == ThemeMode.light
                    ? 'Light'
                    : 'System',
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Choose Theme'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: ThemeMode.values.map((mode) {
                      final label = mode == ThemeMode.system
                          ? 'System'
                          : mode == ThemeMode.light
                              ? 'Light'
                              : 'Dark';
                      return RadioListTile<ThemeMode>(
                        title: Text(label),
                        value: mode,
                        groupValue: themeMode,
                        activeColor: theme.colorScheme.primary,
                        onChanged: (value) {
                          if (value != null) {
                            ref
                                .read(themeModeProvider.notifier)
                                .setThemeMode(value);
                            Navigator.pop(context);
                          }
                        },
                      );
                    }).toList(),
                  ),
                ),
              );
            },
          ),

          AppSpacing.vGapLg,

          // Accent Color
          _SectionHeader(title: 'Accent Color'),
          AppSpacing.vGapSm,
          _AccentColorPicker(
            currentColor: currentColor,
            onColorSelected: (color) {
              ref.read(primaryColorProvider.notifier).setColor(color);
            },
          ),

          AppSpacing.vGapXl,

          // Notifications
          _SectionHeader(title: 'Notifications'),
          AppSpacing.vGapSm,

          _SettingsTile(
            icon: PhosphorIcons.bell(PhosphorIconsStyle.regular),
            title: 'Push Notifications',
            subtitle: 'Manage notification preferences',
            onTap: () async {
              final granted =
                  await NotificationService.instance.requestPermission();
              if (context.mounted) {
                context.showSnackBar(
                  granted
                      ? 'Notifications enabled'
                      : 'Please enable notifications in Settings',
                );
              }
            },
          ),

          AppSpacing.vGapXl,

          // About
          _SectionHeader(title: 'About'),
          AppSpacing.vGapSm,

          _SettingsTile(
            icon: PhosphorIcons.info(PhosphorIconsStyle.regular),
            title: 'About Kuziini',
            subtitle: 'Version ${AppConstants.appVersion}',
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: AppConstants.appName,
                applicationVersion: AppConstants.appVersion,
                applicationLegalese: 'Kuziini Task Manager',
                children: [
                  AppSpacing.vGapMd,
                  const Text(
                    'A premium task management application designed for teams.',
                  ),
                ],
              );
            },
          ),

          _SettingsTile(
            icon: PhosphorIcons.shieldCheck(PhosphorIconsStyle.regular),
            title: 'Privacy Policy',
            subtitle: 'Read our privacy policy',
            onTap: () {
              launchUrl(Uri.parse('https://kuziini.app/privacy'));
            },
          ),

          _SettingsTile(
            icon: PhosphorIcons.fileText(PhosphorIconsStyle.regular),
            title: 'Terms of Service',
            subtitle: 'Read our terms of service',
            onTap: () {
              launchUrl(Uri.parse('https://kuziini.app/terms'));
            },
          ),

          AppSpacing.vGapXxl,

          // Sign out
          _SettingsTile(
            icon: PhosphorIcons.signOut(PhosphorIconsStyle.regular),
            title: 'Sign Out',
            color: AppColors.error,
            onTap: () async {
              final confirmed = await context.showConfirmDialog(
                title: 'Sign Out',
                message: 'Are you sure you want to sign out?',
                confirmLabel: 'Sign Out',
                isDestructive: true,
              );
              if (confirmed == true) {
                ref.read(authStateProvider.notifier).signOut();
                if (context.mounted) {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                }
              }
            },
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveColor = color ?? theme.colorScheme.onSurface;

    return InkWell(
      onTap: onTap,
      borderRadius: AppSpacing.borderRadiusMd,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 22, color: effectiveColor),
            AppSpacing.hGapLg,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: effectiveColor,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            Icon(
              PhosphorIcons.caretRight(PhosphorIconsStyle.regular),
              size: 18,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

class _AccentColorPicker extends StatelessWidget {
  const _AccentColorPicker({
    required this.currentColor,
    required this.onColorSelected,
  });

  final Color currentColor;
  final ValueChanged<Color> onColorSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SizedBox(
      height: 60,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: accentColorOptions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final option = accentColorOptions[index];
          final isSelected = option.color.value == currentColor.value;

          return GestureDetector(
            onTap: () => onColorSelected(option.color),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: option.color,
                shape: BoxShape.circle,
                border: isSelected
                    ? Border.all(
                        color: isDark ? Colors.white : Colors.black87,
                        width: 2.5,
                      )
                    : Border.all(
                        color: isDark
                            ? Colors.white12
                            : Colors.black.withValues(alpha: 0.08),
                        width: 1,
                      ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: option.color.withValues(alpha: 0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 22,
                    )
                  : null,
            ),
          );
        },
      ),
    );
  }
}

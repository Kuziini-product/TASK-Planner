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
import 'package:go_router/go_router.dart';
import '../../../core/router/app_router.dart';
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

          // Admin section (visible only to admins)
          Builder(
            builder: (context) {
              final profile = ref.watch(currentUserProfileProvider);
              final isAdmin = profile.valueOrNull?.isAdmin ?? false;
              if (!isAdmin) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppSpacing.vGapXl,
                  _SectionHeader(title: 'Administration'),
                  AppSpacing.vGapSm,
                  _SettingsTile(
                    icon: PhosphorIcons.shieldCheck(PhosphorIconsStyle.regular),
                    title: 'Admin Dashboard',
                    subtitle: 'Overview and statistics',
                    onTap: () => context.push(AppRoutes.adminDashboard),
                  ),
                  _SettingsTile(
                    icon: PhosphorIcons.userCheck(PhosphorIconsStyle.regular),
                    title: 'User Approvals',
                    subtitle: 'Approve or reject pending users',
                    onTap: () => context.push(AppRoutes.userApproval),
                  ),
                  _SettingsTile(
                    icon: PhosphorIcons.envelopeSimple(PhosphorIconsStyle.regular),
                    title: 'Invitations',
                    subtitle: 'Send and manage invitations',
                    onTap: () => context.push(AppRoutes.invitations),
                  ),
                ],
              );
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

class _AccentColorPicker extends StatefulWidget {
  const _AccentColorPicker({
    required this.currentColor,
    required this.onColorSelected,
  });

  final Color currentColor;
  final ValueChanged<Color> onColorSelected;

  @override
  State<_AccentColorPicker> createState() => _AccentColorPickerState();
}

class _AccentColorPickerState extends State<_AccentColorPicker> {
  int _selectedBaseIndex = 0;
  double _intensity = 0.5; // 0=light, 0.5=normal, 1=dark

  @override
  void initState() {
    super.initState();
    // Find closest base color
    _selectedBaseIndex = _findClosestColor(widget.currentColor);
  }

  int _findClosestColor(Color color) {
    int closest = 0;
    double minDist = double.infinity;
    for (int i = 0; i < accentColorOptions.length; i++) {
      final c = accentColorOptions[i].color;
      final dist = ((c.red - color.red) * (c.red - color.red) +
              (c.green - color.green) * (c.green - color.green) +
              (c.blue - color.blue) * (c.blue - color.blue))
          .toDouble();
      if (dist < minDist) {
        minDist = dist;
        closest = i;
      }
    }
    return closest;
  }

  Color _adjustIntensity(Color base, double intensity) {
    // intensity: 0 = very light, 0.5 = normal, 1 = very dark
    if (intensity <= 0.5) {
      // Lighten: mix with white
      final t = 1.0 - (intensity * 2); // 0->1 (white), 0.5->0 (normal)
      return Color.fromARGB(
        255,
        (base.red + (255 - base.red) * t).round().clamp(0, 255),
        (base.green + (255 - base.green) * t).round().clamp(0, 255),
        (base.blue + (255 - base.blue) * t).round().clamp(0, 255),
      );
    } else {
      // Darken: mix with black
      final t = (intensity - 0.5) * 2; // 0.5->0 (normal), 1->1 (black)
      return Color.fromARGB(
        255,
        (base.red * (1 - t)).round().clamp(0, 255),
        (base.green * (1 - t)).round().clamp(0, 255),
        (base.blue * (1 - t)).round().clamp(0, 255),
      );
    }
  }

  void _selectColor(int index) {
    setState(() => _selectedBaseIndex = index);
    final adjusted = _adjustIntensity(accentColorOptions[index].color, _intensity);
    widget.onColorSelected(adjusted);
  }

  void _updateIntensity(double value) {
    setState(() => _intensity = value);
    final adjusted = _adjustIntensity(accentColorOptions[_selectedBaseIndex].color, value);
    widget.onColorSelected(adjusted);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currentAdjusted = _adjustIntensity(
      accentColorOptions[_selectedBaseIndex].color, _intensity,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Color circles
        SizedBox(
          height: 56,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: accentColorOptions.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final option = accentColorOptions[index];
              final isSelected = index == _selectedBaseIndex;
              final displayColor = _adjustIntensity(option.color, _intensity);

              return GestureDetector(
                onTap: () => _selectColor(index),
                child: Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: displayColor,
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(
                                color: isDark ? Colors.white : Colors.black87,
                                width: 2.5,
                              )
                            : Border.all(
                                color: isDark ? Colors.white12 : Colors.black12,
                                width: 1,
                              ),
                        boxShadow: isSelected
                            ? [BoxShadow(color: displayColor.withValues(alpha: 0.4), blurRadius: 8, offset: const Offset(0, 2))]
                            : null,
                      ),
                      child: isSelected
                          ? const Icon(Icons.check_rounded, color: Colors.white, size: 20)
                          : null,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      option.name,
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                        color: isSelected ? currentAdjusted : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 16),

        // Intensity label
        Row(
          children: [
            Text('Intensity', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600)),
            const Spacer(),
            Container(
              width: 24, height: 24,
              decoration: BoxDecoration(
                color: currentAdjusted,
                shape: BoxShape.circle,
                border: Border.all(color: isDark ? Colors.white24 : Colors.black12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),

        // Intensity slider
        Row(
          children: [
            Icon(Icons.wb_sunny, size: 16, color: theme.colorScheme.onSurfaceVariant),
            Expanded(
              child: SliderTheme(
                data: SliderThemeData(
                  activeTrackColor: currentAdjusted,
                  thumbColor: currentAdjusted,
                  inactiveTrackColor: currentAdjusted.withValues(alpha: 0.2),
                  overlayColor: currentAdjusted.withValues(alpha: 0.1),
                  trackHeight: 6,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                ),
                child: Slider(
                  value: _intensity,
                  min: 0.0,
                  max: 1.0,
                  onChanged: _updateIntensity,
                ),
              ),
            ),
            Icon(Icons.dark_mode, size: 16, color: theme.colorScheme.onSurfaceVariant),
          ],
        ),

        // Preview bar
        const SizedBox(height: 8),
        Container(
          height: 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            gradient: LinearGradient(
              colors: List.generate(11, (i) {
                return _adjustIntensity(
                  accentColorOptions[_selectedBaseIndex].color,
                  i / 10.0,
                );
              }),
            ),
          ),
        ),
      ],
    );
  }
}

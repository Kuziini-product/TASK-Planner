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
                builder: (dialogCtx) => _ThemePickerDialog(
                  currentThemeMode: themeMode,
                  currentColor: currentColor,
                  onThemeModeChanged: (mode) {
                    ref.read(themeModeProvider.notifier).setThemeMode(mode);
                  },
                  onColorChanged: (color) {
                    ref.read(primaryColorProvider.notifier).setColor(color);
                  },
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

// ── Theme Picker Dialog ──

class _ThemePickerDialog extends ConsumerStatefulWidget {
  const _ThemePickerDialog({
    required this.currentThemeMode,
    required this.currentColor,
    required this.onThemeModeChanged,
    required this.onColorChanged,
  });

  final ThemeMode currentThemeMode;
  final Color currentColor;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final ValueChanged<Color> onColorChanged;

  @override
  ConsumerState<_ThemePickerDialog> createState() => _ThemePickerDialogState();
}

class _ThemePickerDialogState extends ConsumerState<_ThemePickerDialog> {
  late ThemeMode _selectedMode;
  late Color _selectedColor;
  bool _isCustom = false;
  int _selectedBaseIndex = 0;
  double _intensity = 0.5;

  @override
  void initState() {
    super.initState();
    _selectedMode = widget.currentThemeMode;
    _selectedColor = widget.currentColor;
    // Check if current color matches any preset exactly
    _isCustom = !accentColorOptions.any((o) =>
        o.color.red == _selectedColor.red &&
        o.color.green == _selectedColor.green &&
        o.color.blue == _selectedColor.blue);
    _selectedBaseIndex = _findClosest(_selectedColor);
  }

  int _findClosest(Color color) {
    int closest = 0;
    double minDist = double.infinity;
    for (int i = 0; i < accentColorOptions.length; i++) {
      final c = accentColorOptions[i].color;
      final d = ((c.red - color.red) * (c.red - color.red) +
              (c.green - color.green) * (c.green - color.green) +
              (c.blue - color.blue) * (c.blue - color.blue))
          .toDouble();
      if (d < minDist) { minDist = d; closest = i; }
    }
    return closest;
  }

  Color _adjustIntensity(Color base, double intensity) {
    if (intensity <= 0.5) {
      final t = 1.0 - (intensity * 2);
      return Color.fromARGB(255,
        (base.red + (255 - base.red) * t).round().clamp(0, 255),
        (base.green + (255 - base.green) * t).round().clamp(0, 255),
        (base.blue + (255 - base.blue) * t).round().clamp(0, 255));
    } else {
      final t = (intensity - 0.5) * 2;
      return Color.fromARGB(255,
        (base.red * (1 - t)).round().clamp(0, 255),
        (base.green * (1 - t)).round().clamp(0, 255),
        (base.blue * (1 - t)).round().clamp(0, 255));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Choose Theme'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // System / Light / Dark
            ...ThemeMode.values.map((mode) {
              final label = mode == ThemeMode.system ? 'System'
                  : mode == ThemeMode.light ? 'Light' : 'Dark';
              final icon = mode == ThemeMode.system ? Icons.brightness_auto
                  : mode == ThemeMode.light ? Icons.wb_sunny : Icons.dark_mode;
              return RadioListTile<ThemeMode>(
                title: Row(children: [
                  Icon(icon, size: 18), const SizedBox(width: 8), Text(label),
                ]),
                value: mode,
                groupValue: _selectedMode,
                activeColor: theme.colorScheme.primary,
                contentPadding: EdgeInsets.zero,
                dense: true,
                onChanged: (value) {
                  if (value != null) {
                    setState(() { _selectedMode = value; _isCustom = false; });
                    widget.onThemeModeChanged(value);
                    Navigator.pop(context);
                  }
                },
              );
            }),

            const Divider(),

            // Custom option
            RadioListTile<bool>(
              title: Row(children: [
                Icon(Icons.palette, size: 18, color: _selectedColor),
                const SizedBox(width: 8),
                const Text('Custom', style: TextStyle(fontWeight: FontWeight.w600)),
              ]),
              value: true,
              groupValue: _isCustom,
              activeColor: _selectedColor,
              contentPadding: EdgeInsets.zero,
              dense: true,
              onChanged: (_) => setState(() => _isCustom = true),
            ),

            // Color picker (visible when Custom is selected)
            if (_isCustom) ...[
              const SizedBox(height: 12),

              // Color circles
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(accentColorOptions.length, (i) {
                  final option = accentColorOptions[i];
                  final isSelected = i == _selectedBaseIndex;
                  final displayColor = _adjustIntensity(option.color, _intensity);
                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedBaseIndex = i);
                      final color = _adjustIntensity(option.color, _intensity);
                      setState(() => _selectedColor = color);
                      widget.onColorChanged(color);
                    },
                    child: Column(
                      children: [
                        Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(
                            color: displayColor,
                            shape: BoxShape.circle,
                            border: isSelected
                                ? Border.all(color: theme.colorScheme.onSurface, width: 2.5)
                                : Border.all(color: Colors.black12, width: 1),
                            boxShadow: isSelected
                                ? [BoxShadow(color: displayColor.withValues(alpha: 0.4), blurRadius: 6)]
                                : null,
                          ),
                          child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 16) : null,
                        ),
                        const SizedBox(height: 2),
                        Text(option.name, style: TextStyle(fontSize: 7,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                          color: isSelected ? displayColor : Colors.grey)),
                      ],
                    ),
                  );
                }),
              ),

              const SizedBox(height: 16),

              // Intensity slider
              Row(
                children: [
                  const Icon(Icons.wb_sunny, size: 14, color: Colors.grey),
                  Expanded(
                    child: SliderTheme(
                      data: SliderThemeData(
                        activeTrackColor: _selectedColor,
                        thumbColor: _selectedColor,
                        inactiveTrackColor: _selectedColor.withValues(alpha: 0.2),
                        trackHeight: 4,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                      ),
                      child: Slider(
                        value: _intensity,
                        min: 0.0, max: 1.0,
                        onChanged: (v) {
                          final color = _adjustIntensity(accentColorOptions[_selectedBaseIndex].color, v);
                          setState(() { _intensity = v; _selectedColor = color; });
                          widget.onColorChanged(color);
                        },
                      ),
                    ),
                  ),
                  const Icon(Icons.dark_mode, size: 14, color: Colors.grey),
                ],
              ),

              // Gradient preview
              Container(
                height: 6,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  gradient: LinearGradient(
                    colors: List.generate(11, (i) => _adjustIntensity(
                      accentColorOptions[_selectedBaseIndex].color, i / 10.0)),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Background color
              Text('Background', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              _BackgroundColorRow(
                onColorChanged: (color) {
                  ref.read(backgroundColorProvider.notifier).setColor(color);
                },
                currentBg: ref.watch(backgroundColorProvider),
              ),

              const SizedBox(height: 16),

              // Button color
              Text('Button Color', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              _BackgroundColorRow(
                onColorChanged: (color) {
                  ref.read(buttonColorProvider.notifier).setColor(color);
                },
                currentBg: ref.watch(buttonColorProvider),
              ),

              const SizedBox(height: 16),

              // Border width
              Text('Button Border', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text('0', style: TextStyle(fontSize: 11, color: Colors.grey)),
                  Expanded(
                    child: SliderTheme(
                      data: SliderThemeData(
                        activeTrackColor: _selectedColor,
                        thumbColor: _selectedColor,
                        inactiveTrackColor: _selectedColor.withValues(alpha: 0.2),
                        trackHeight: 4,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                      ),
                      child: Slider(
                        value: ref.watch(buttonBorderWidthProvider),
                        min: 0, max: 3,
                        divisions: 6,
                        label: ref.watch(buttonBorderWidthProvider).toStringAsFixed(1),
                        onChanged: (v) {
                          ref.read(buttonBorderWidthProvider.notifier).setWidth(v);
                        },
                      ),
                    ),
                  ),
                  Text('3', style: TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),

              // Border color
              if (ref.watch(buttonBorderWidthProvider) > 0) ...[
                const SizedBox(height: 8),
                Text('Border Color', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _miniColorCircle(null, 'Default', ref.watch(buttonBorderColorProvider) == null, theme, () {
                      ref.read(buttonBorderColorProvider.notifier).setColor(null);
                    }),
                    ...accentColorOptions.map((o) {
                      final isSelected = ref.watch(buttonBorderColorProvider) != null &&
                          o.color.red == ref.watch(buttonBorderColorProvider)!.red &&
                          o.color.green == ref.watch(buttonBorderColorProvider)!.green &&
                          o.color.blue == ref.watch(buttonBorderColorProvider)!.blue;
                      return _miniColorCircle(o.color, o.name, isSelected, theme, () {
                        ref.read(buttonBorderColorProvider.notifier).setColor(o.color);
                      });
                    }),
                    _miniColorCircle(Colors.black, 'Black',
                      ref.watch(buttonBorderColorProvider)?.red == 0 && ref.watch(buttonBorderColorProvider)?.green == 0 && ref.watch(buttonBorderColorProvider)?.blue == 0,
                      theme, () { ref.read(buttonBorderColorProvider.notifier).setColor(Colors.black); }),
                    _miniColorCircle(Colors.white, 'White',
                      ref.watch(buttonBorderColorProvider)?.red == 255 && ref.watch(buttonBorderColorProvider)?.green == 255 && ref.watch(buttonBorderColorProvider)?.blue == 255,
                      theme, () { ref.read(buttonBorderColorProvider.notifier).setColor(Colors.white); }),
                  ],
                ),
              ],

              const SizedBox(height: 16),

              // Preview button
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    Text('Preview', style: theme.textTheme.labelSmall?.copyWith(color: Colors.grey)),
                    const SizedBox(height: 8),
                    ElevatedButton(onPressed: () {}, child: const Text('Button Preview')),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Apply button
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context),
                  style: FilledButton.styleFrom(
                    backgroundColor: _selectedColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Apply'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _miniColorCircle(Color? color, String name, bool isSelected, ThemeData theme, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              color: color ?? theme.colorScheme.primary,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? theme.colorScheme.onSurface : Colors.black12,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: color == null
                ? Icon(Icons.auto_awesome, size: 12, color: Colors.white)
                : (isSelected ? Icon(Icons.check, size: 12, color: _isLightColor(color) ? Colors.black : Colors.white) : null),
          ),
          const SizedBox(height: 1),
          Text(name, style: TextStyle(fontSize: 6, color: Colors.grey)),
        ],
      ),
    );
  }

  bool _isLightColor(Color c) => (c.red * 0.299 + c.green * 0.587 + c.blue * 0.114) > 186;
}

class _BackgroundColorRow extends StatelessWidget {
  const _BackgroundColorRow({required this.onColorChanged, this.currentBg});

  final ValueChanged<Color?> onColorChanged;
  final Color? currentBg;

  static const _bgColors = [
    _BgOption('Default', null, Icons.format_color_reset),
    _BgOption('White', Color(0xFFFFFFFF), null),
    _BgOption('Snow', Color(0xFFFAFAFA), null),
    _BgOption('Cream', Color(0xFFFFFDD0), null),
    _BgOption('Mint', Color(0xFFF0FFF0), null),
    _BgOption('Ice', Color(0xFFF0F8FF), null),
    _BgOption('Lavender', Color(0xFFF5F0FF), null),
    _BgOption('Blush', Color(0xFFFFF0F5), null),
    _BgOption('Smoke', Color(0xFFF5F5F5), null),
    _BgOption('Sand', Color(0xFFFAF0E6), null),
    _BgOption('Charcoal', Color(0xFF1A1A2E), null),
    _BgOption('Navy', Color(0xFF0F0E17), null),
    _BgOption('Forest', Color(0xFF0A1F0A), null),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: _bgColors.map((bg) {
        final isSelected = (bg.color == null && currentBg == null) ||
            (bg.color != null && currentBg != null &&
                bg.color!.red == currentBg!.red &&
                bg.color!.green == currentBg!.green &&
                bg.color!.blue == currentBg!.blue);

        return GestureDetector(
          onTap: () => onColorChanged(bg.color),
          child: Column(
            children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: bg.color ?? theme.scaffoldBackgroundColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? theme.colorScheme.primary : Colors.black12,
                    width: isSelected ? 2.5 : 1,
                  ),
                  boxShadow: isSelected
                      ? [BoxShadow(color: theme.colorScheme.primary.withValues(alpha: 0.3), blurRadius: 4)]
                      : null,
                ),
                child: bg.icon != null
                    ? Icon(bg.icon, size: 14, color: isSelected ? theme.colorScheme.primary : Colors.grey)
                    : (isSelected ? Icon(Icons.check, size: 14, color: _isLight(bg.color!) ? Colors.black : Colors.white) : null),
              ),
              const SizedBox(height: 2),
              Text(bg.name, style: TextStyle(fontSize: 7, color: isSelected ? theme.colorScheme.primary : Colors.grey)),
            ],
          ),
        );
      }).toList(),
    );
  }

  bool _isLight(Color c) => (c.red * 0.299 + c.green * 0.587 + c.blue * 0.114) > 186;
}

class _BgOption {
  final String name;
  final Color? color;
  final IconData? icon;
  const _BgOption(this.name, this.color, this.icon);
}

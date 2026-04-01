import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/router/app_router.dart';
import '../../../core/utils/extensions.dart';
import '../../../core/widgets/kuziini_card.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../auth/providers/auth_provider.dart';
import '../../tasks/providers/tasks_provider.dart';
import '../providers/profile_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final profileAsync = ref.watch(profileProvider);
    final statsAsync = ref.watch(taskStatsProvider);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/images/kuziini_logo.png', height: 32, color: theme.colorScheme.onSurface),
            const SizedBox(width: 12),
            Text('Profile', style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w300, letterSpacing: 1.2)),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => context.push(AppRoutes.settings),
            icon: Icon(PhosphorIcons.gear(PhosphorIconsStyle.regular)),
          ),
        ],
      ),
      body: profileAsync.when(
        data: (profile) {
          if (profile == null) {
            return const Center(child: Text('Not signed in'));
          }

          return SingleChildScrollView(
            padding: AppSpacing.paddingLg,
            child: Column(
              children: [
                // Avatar and name
                Center(
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: () async {
                          final picker = ImagePicker();
                          final image = await picker.pickImage(
                            source: ImageSource.gallery,
                            maxWidth: 512,
                            maxHeight: 512,
                            imageQuality: 80,
                          );
                          if (image != null) {
                            final bytes = await image.readAsBytes();
                            await ref
                                .read(profileActionsProvider)
                                .uploadAvatar(bytes, image.name);
                          }
                        },
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 48,
                              backgroundColor: primaryColor.withValues(alpha: 0.1),
                              backgroundImage: profile.avatarUrl != null
                                  ? NetworkImage(profile.avatarUrl!)
                                  : null,
                              child: profile.avatarUrl == null
                                  ? Text(
                                      profile.initials,
                                      style: TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.w700,
                                        color: primaryColor,
                                      ),
                                    )
                                  : null,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: primaryColor,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: theme.scaffoldBackgroundColor,
                                    width: 2,
                                  ),
                                ),
                                child: Icon(
                                  PhosphorIcons.camera(PhosphorIconsStyle.fill),
                                  size: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(duration: 400.ms).scale(
                            begin: const Offset(0.8, 0.8),
                            duration: 400.ms,
                          ),
                      AppSpacing.vGapMd,
                      Text(
                        profile.displayName,
                        style: theme.textTheme.titleLarge,
                      ).animate().fadeIn(duration: 400.ms, delay: 100.ms),
                      AppSpacing.vGapXs,
                      Text(
                        profile.email,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ).animate().fadeIn(duration: 400.ms, delay: 150.ms),
                      AppSpacing.vGapSm,
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.08),
                          borderRadius: AppSpacing.borderRadiusFull,
                        ),
                        child: Text(
                          profile.role.toUpperCase(),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: primaryColor,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                          ),
                        ),
                      ).animate().fadeIn(duration: 400.ms, delay: 200.ms),
                    ],
                  ),
                ),

                AppSpacing.vGapXxl,

                // Stats
                statsAsync.when(
                  data: (stats) => Row(
                    children: [
                      _StatCard(
                        label: 'Total',
                        value: '${stats['total'] ?? 0}',
                        color: AppColors.info,
                        onTap: () {
                          ref.read(taskFilterProvider.notifier).state = TaskFilterType.all;
                          context.go(AppRoutes.today);
                        },
                      ),
                      AppSpacing.hGapMd,
                      _StatCard(
                        label: 'Done',
                        value: '${stats['done'] ?? 0}',
                        color: AppColors.success,
                        onTap: () {
                          ref.read(taskFilterProvider.notifier).state = TaskFilterType.done;
                          context.go(AppRoutes.today);
                        },
                      ),
                      AppSpacing.hGapMd,
                      _StatCard(
                        label: 'In Progress',
                        value: '${stats['in_progress'] ?? 0}',
                        color: AppColors.warning,
                        onTap: () {
                          ref.read(taskFilterProvider.notifier).state = TaskFilterType.inProgress;
                          context.go(AppRoutes.today);
                        },
                      ),
                    ],
                  ).animate().fadeIn(duration: 400.ms, delay: 300.ms),
                  loading: () => const LoadingIndicator(size: 24),
                  error: (_, __) => const SizedBox.shrink(),
                ),

                AppSpacing.vGapXxl,

                // Menu items
                _ProfileMenuItem(
                  icon: PhosphorIcons.gear(PhosphorIconsStyle.regular),
                  label: 'Settings',
                  onTap: () => context.push(AppRoutes.settings),
                ),

                // Admin & Sign Out are in Settings

                const SizedBox(height: 40),
              ],
            ),
          );
        },
        loading: () => const LoadingIndicator(message: 'Loading profile...'),
        error: (error, _) => Center(child: Text('Error: $error')),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
    this.onTap,
  });

  final String label;
  final String value;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Expanded(
      child: KuziiniCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        child: Column(
          children: [
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            AppSpacing.vGapXs,
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileMenuItem extends StatelessWidget {
  const _ProfileMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String label;
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
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 22, color: effectiveColor),
            AppSpacing.hGapLg,
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: effectiveColor,
                ),
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

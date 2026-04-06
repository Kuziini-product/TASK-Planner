import 'dart:js_util' as js_util;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../core/constants/app_colors.dart';
import '../core/router/app_router.dart';
import '../core/services/alert_service.dart';
import '../core/services/birthday_service.dart';
import '../core/services/notification_service.dart';
import '../core/services/presence_service.dart';
import '../core/services/voice_task_parser.dart';
import '../features/auth/providers/auth_provider.dart';
import '../features/notifications/providers/notifications_provider.dart';
import '../core/widgets/birthday_banner.dart';
import '../core/widgets/confetti_widget.dart';
import '../features/tasks/providers/tasks_provider.dart';

class MainShell extends ConsumerWidget {
  const MainShell({super.key, required this.child});

  final Widget child;

  static int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith(AppRoutes.today)) return -1;
    if (location.startsWith(AppRoutes.calendar)) return 0;
    // Index 1 is the center FAB (no tab)
    if (location.startsWith(AppRoutes.notifications)) return -1;
    if (location.startsWith(AppRoutes.profile)) return 2;
    return -1;
  }

  void _openVoiceTaskCreator(BuildContext context) {
    showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _VoiceTaskSheet(),
    ).then((rawTranscript) {
      if (rawTranscript != null && rawTranscript.isNotEmpty) {
        // Extract flag markers appended by _confirm()
        final hasPhotoMarker = rawTranscript.contains('__PHOTO__');
        final hasAttachMarker = rawTranscript.contains('__ATTACHMENT__');
        final transcript = rawTranscript.replaceAll('__PHOTO__', '').replaceAll('__ATTACHMENT__', '').trim();

        final result = VoiceTaskParser.parse(transcript);
        // Build query params from parsed voice data
        // Title auto-generates from description, so voice title goes to desc
        final params = <String, String>{};
        // Combine title + description as full description
        final fullDesc = [result.title, result.description].whereType<String>().join(' ').trim();
        if (fullDesc.isNotEmpty) params['desc'] = fullDesc;
        if (result.dueDate != null) params['date'] = result.dueDate!.toIso8601String().split('T').first;
        if (result.hour != null) params['hour'] = result.hour.toString();
        if (result.minute != null) params['minute'] = result.minute.toString();
        if (result.priority != null) params['priority'] = result.priority!;
        if (result.address != null) params['locAddress'] = result.address!;
        if (result.assignees.isNotEmpty) params['assignee'] = result.assignees.first;
        if (hasPhotoMarker || result.wantsPhoto) params['photo'] = '1';
        if (hasAttachMarker || result.wantsAttachment) params['attachment'] = '1';

        final uri = Uri(path: AppRoutes.createTask, queryParameters: params.isNotEmpty ? params : null);
        context.push(uri.toString());
      }
    });
  }

  void _onItemTapped(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go(AppRoutes.calendar);
      case 1:
        // FAB action - handled separately
        context.push(AppRoutes.createTask);
      case 2:
        context.go(AppRoutes.profile);
    }
  }

  void _refreshOnNav(WidgetRef ref) {
    ref.invalidate(dailyTasksProvider);
    ref.invalidate(taskStatsProvider);
    ref.invalidate(weeklyStatsProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = _calculateSelectedIndex(context);
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    final hasBirthday = ref.watch(hasBirthdayTodayProvider);
    // Keep presence active on all screens
    ref.watch(onlineUsersProvider);

    // Update app badge: unread notifications only
    final unreadNotifs = ref.watch(unreadCountProvider).valueOrNull ?? 0;
    NotificationService.instance.setAppBadge(unreadNotifs);

    // Run auto-alert checks (admin only, once per day)
    ref.listen(currentUserProfileProvider, (_, next) {
      if (next.valueOrNull?.isAdmin == true) {
        AlertService.instance.checkAndSendAlerts();
      }
    });

    final customBanner = ref.watch(activeCustomBannerProvider).valueOrNull;

    return Scaffold(
      body: Column(
        children: [
          // Custom banner takes priority over birthday banner
          if (customBanner != null)
            _CustomBannerWidget(banner: customBanner)
          else if (hasBirthday)
            const BirthdayBanner(),
          Expanded(child: child),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: theme.bottomNavigationBarTheme.backgroundColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            height: 64,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  icon: PhosphorIcons.calendar(PhosphorIconsStyle.regular),
                  activeIcon: PhosphorIcons.calendar(PhosphorIconsStyle.fill),
                  label: 'Calendar',
                  isSelected: selectedIndex == 0,
                  onTap: () { _refreshOnNav(ref); _onItemTapped(context, 0); },
                ),
                // Center FAB – tap: create task, long-press: voice task
                GestureDetector(
                  onTap: () => _onItemTapped(context, 1),
                  onLongPress: () => _openVoiceTaskCreator(context),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: primaryColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      PhosphorIcons.plus(PhosphorIconsStyle.bold),
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
                _NavItem(
                  icon: PhosphorIcons.user(PhosphorIconsStyle.regular),
                  activeIcon: PhosphorIcons.user(PhosphorIconsStyle.fill),
                  label: 'Profile',
                  isSelected: selectedIndex == 2,
                  onTap: () { _refreshOnNav(ref); _onItemTapped(context, 2); },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.badge = 0,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final int badge;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isSelected
        ? theme.colorScheme.primary
        : theme.bottomNavigationBarTheme.unselectedItemColor ??
            theme.colorScheme.onSurfaceVariant;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 56,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    isSelected ? activeIcon : icon,
                    key: ValueKey(isSelected),
                    size: 24,
                    color: color,
                  ),
                ),
                if (badge > 0)
                  Positioned(
                    top: -4,
                    right: -8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 1,
                      ),
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
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Voice Task Sheet v3 ──
// Live card-based UI: each field is a card, active field is highlighted.

class _VoiceTaskSheet extends StatefulWidget {
  const _VoiceTaskSheet();
  @override
  State<_VoiceTaskSheet> createState() => _VoiceTaskSheetState();
}

class _VoiceTaskSheetState extends State<_VoiceTaskSheet> with SingleTickerProviderStateMixin {
  String _text = '';
  String _confirmedText = ''; // Text from previous recognition sessions (before auto-restart)
  bool _listening = false;
  String _error = '';
  bool _wantsPhoto = false;
  bool _wantsAttachment = false;
  late AnimationController _pulse;
  late Animation<double> _pulseAnim;
  Object? _rec;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.35).animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut));
    _start();
  }

  @override
  void dispose() {
    _stop();
    _pulse.dispose();
    super.dispose();
  }

  void _start() {
    Object? recognition;
    try {
      final global = _jsGlobalThis;
      final ctor = _jsGetProp(global, 'webkitSpeechRecognition') ?? _jsGetProp(global, 'SpeechRecognition');
      if (ctor == null) throw 'not supported';
      recognition = _jsConstruct(ctor);
    } catch (_) {
      if (mounted) setState(() { _error = 'Speech recognition not supported.\nPlease use Chrome.'; _listening = false; });
      return;
    }

    _rec = recognition;
    _jsSetProp(recognition!, 'continuous', true);
    _jsSetProp(recognition, 'interimResults', true);
    _jsSetProp(recognition, 'lang', 'ro-RO');

    _jsSetProp(recognition, 'onresult', _jsAllowInterop((event) {
      String sessionTranscript = '';
      try {
        final results = _jsGetProp(event, 'results')!;
        final len = _jsGetPropInt(results, 'length');
        for (int i = 0; i < len; i++) {
          final result = _jsCallMethod(results, 'item', [i]);
          final alt = _jsCallMethod(result, 'item', [0]);
          sessionTranscript += _jsGetPropString(alt, 'transcript');
        }
      } catch (_) {}
      // Combine confirmed text from previous sessions with current session
      if (mounted) {
        setState(() => _text = _confirmedText.isEmpty
            ? sessionTranscript
            : '$_confirmedText $sessionTranscript');
      }
    }));

    _jsSetProp(recognition, 'onerror', _jsAllowInterop((event) {
      try {
        final err = _jsGetPropString(event, 'error');
        if (err != 'no-speech' && mounted) setState(() { _error = 'Error: $err'; _listening = false; });
      } catch (_) {}
    }));

    _jsSetProp(recognition, 'onend', _jsAllowInterop((event) {
      // Chrome stops recognition after silence — auto-restart to keep listening
      if (mounted && _listening) {
        // Save current text before restart (new session resets results)
        _confirmedText = _text;
        try {
          _jsCallMethod(recognition!, 'start', []);
        } catch (_) {
          setState(() => _listening = false);
        }
      } else if (mounted) {
        setState(() => _listening = false);
      }
    }));

    try {
      _jsCallMethod(recognition, 'start', []);
      if (mounted) setState(() { _listening = true; _error = ''; });
    } catch (e) {
      if (mounted) setState(() { _error = 'Failed: $e'; _listening = false; });
    }
  }

  void _stop() {
    _listening = false;
    try { if (_rec != null) _jsCallMethod(_rec!, 'stop', []); } catch (_) {}
  }

  void _confirm() {
    _stop();
    // Append flag markers so _openVoiceTaskCreator can detect them
    var result = _text;
    if (_wantsPhoto) result += ' __PHOTO__';
    if (_wantsAttachment) result += ' __ATTACHMENT__';
    Navigator.of(context).pop(result);
  }
  void _cancel() { _stop(); Navigator.of(context).pop(null); }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;
    final parsed = _text.isNotEmpty ? VoiceTaskParser.parse(_text) : null;
    final activeField = parsed?.activeField ?? VoiceField.title;

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 20)],
        ),
        child: ListView(
          controller: scrollController,
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 16),
          children: [
            // Handle
            Center(child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40, height: 4,
              decoration: BoxDecoration(color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(2)),
            )),

            // Header + mic
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Voice Task', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text('Speak naturally — keywords switch fields', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant, fontSize: 11)),
                    ],
                  )),
                  // Pulsing mic
                  GestureDetector(
                    onTap: _listening ? _stop : _start,
                    child: AnimatedBuilder(
                      animation: _pulseAnim,
                      builder: (context, _) => Transform.scale(
                        scale: _listening ? _pulseAnim.value : 1.0,
                        child: Container(
                          width: 52, height: 52,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _listening ? AppColors.error : primaryColor,
                            boxShadow: _listening ? [BoxShadow(color: AppColors.error.withValues(alpha: 0.4), blurRadius: 12)] : null,
                          ),
                          child: Icon(
                            _listening ? PhosphorIcons.microphone(PhosphorIconsStyle.fill) : PhosphorIcons.microphoneSlash(PhosphorIconsStyle.fill),
                            color: Colors.white, size: 24),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                _listening ? 'Listening...' : _error.isNotEmpty ? _error : 'Tap mic to start',
                style: TextStyle(fontSize: 11, color: _listening ? AppColors.error : theme.colorScheme.onSurfaceVariant),
              ),
            ),

            const SizedBox(height: 16),

            // ── Field Cards ──
            _FieldCard(
              field: VoiceField.title,
              activeField: activeField,
              icon: PhosphorIcons.article(PhosphorIconsStyle.regular),
              label: 'Description',
              value: parsed?.title != null
                  ? '${parsed!.title!}${parsed.description != null ? '\n${parsed.description}' : ''}'
                  : null,
              placeholder: 'Start speaking — title auto-generates...',
            ),

            // Time + Date in a row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(child: _FieldCard(
                    field: VoiceField.time,
                    activeField: activeField,
                    icon: PhosphorIcons.clock(PhosphorIconsStyle.regular),
                    label: 'Time',
                    value: parsed?.hour != null ? '${parsed!.hour.toString().padLeft(2, '0')}:${(parsed.minute ?? 0).toString().padLeft(2, '0')}' : null,
                    placeholder: '"time ora 14"',
                    compact: true,
                  )),
                  Expanded(child: _FieldCard(
                    field: VoiceField.date,
                    activeField: activeField,
                    icon: PhosphorIcons.calendar(PhosphorIconsStyle.regular),
                    label: 'Date',
                    value: parsed?.dueDate != null ? '${parsed!.dueDate!.day}/${parsed.dueDate!.month}/${parsed.dueDate!.year}' : null,
                    placeholder: '"date 4 aprilie"',
                    compact: true,
                  )),
                ],
              ),
            ),

            _FieldCard(
              field: VoiceField.address,
              activeField: activeField,
              icon: PhosphorIcons.mapPin(PhosphorIconsStyle.regular),
              label: 'Address',
              value: parsed?.address,
              placeholder: 'Say "adresă" to switch here',
            ),

            // Priority card with chips
            _PriorityCard(
              activeField: activeField,
              currentPriority: parsed?.priority,
            ),

            // Assign card with user chips
            _AssignCard(
              activeField: activeField,
              assignees: parsed?.assignees ?? [],
            ),

            // Take a picture + Add attachment buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: _ActionCard(
                      icon: PhosphorIcons.camera(PhosphorIconsStyle.regular),
                      label: 'Take a picture',
                      isActive: _wantsPhoto || parsed?.wantsPhoto == true,
                      onTap: () {
                        _wantsPhoto = true;
                        _confirm();
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ActionCard(
                      icon: PhosphorIcons.paperclip(PhosphorIconsStyle.regular),
                      label: 'Add attachment',
                      isActive: _wantsAttachment || parsed?.wantsAttachment == true,
                      onTap: () {
                        _wantsAttachment = true;
                        _confirm();
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Raw transcript (collapsible)
            if (_text.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.grey.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(10)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('RAW TRANSCRIPT', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5), letterSpacing: 1)),
                      const SizedBox(height: 4),
                      Text(_text, style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6), height: 1.3)),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // Action buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(children: [
                Expanded(child: OutlinedButton.icon(
                  onPressed: _cancel,
                  icon: Icon(PhosphorIcons.x(PhosphorIconsStyle.bold), size: 16),
                  label: const Text('Cancel'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.onSurfaceVariant,
                    side: BorderSide(color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.2)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14)),
                )),
                const SizedBox(width: 12),
                Expanded(child: FilledButton.icon(
                  onPressed: _text.isNotEmpty ? _confirm : null,
                  icon: Icon(PhosphorIcons.check(PhosphorIconsStyle.bold), size: 16),
                  label: const Text('Create Task'),
                  style: FilledButton.styleFrom(
                    backgroundColor: primaryColor,
                    disabledBackgroundColor: primaryColor.withValues(alpha: 0.3),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14)),
                )),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Field Card Widget ──
class _FieldCard extends StatelessWidget {
  const _FieldCard({
    required this.field,
    required this.activeField,
    required this.icon,
    required this.label,
    this.value,
    this.placeholder,
    this.compact = false,
  });

  final VoiceField field;
  final VoiceField activeField;
  final IconData icon;
  final String label;
  final String? value;
  final String? placeholder;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final isActive = field == activeField;
    final hasValue = value != null && value!.isNotEmpty;

    return Container(
      margin: compact ? const EdgeInsets.all(4) : const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      padding: EdgeInsets.all(compact ? 10 : 12),
      decoration: BoxDecoration(
        color: isActive
            ? primaryColor.withValues(alpha: 0.08)
            : hasValue
                ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)
                : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive
              ? primaryColor
              : hasValue
                  ? primaryColor.withValues(alpha: 0.2)
                  : theme.dividerColor.withValues(alpha: 0.15),
          width: isActive ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: compact ? 16 : 18, color: isActive ? primaryColor : theme.colorScheme.onSurfaceVariant),
          SizedBox(width: compact ? 6 : 10),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$label:',
                style: TextStyle(
                  fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5,
                  color: isActive ? primaryColor : theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (hasValue)
                Text(value!, style: TextStyle(fontSize: compact ? 13 : 14, fontWeight: FontWeight.w500, height: 1.3))
              else
                Text(placeholder ?? '', style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4))),
            ],
          )),
          if (isActive)
            Container(
              width: 8, height: 8,
              decoration: BoxDecoration(shape: BoxShape.circle, color: primaryColor),
            ),
        ],
      ),
    );
  }
}

// ── Priority Card ──
class _PriorityCard extends StatelessWidget {
  const _PriorityCard({required this.activeField, this.currentPriority});
  final VoiceField activeField;
  final String? currentPriority;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final isActive = activeField == VoiceField.priority;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isActive ? primaryColor.withValues(alpha: 0.08) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? primaryColor : currentPriority != null ? primaryColor.withValues(alpha: 0.2) : theme.dividerColor.withValues(alpha: 0.15),
          width: isActive ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(PhosphorIcons.flag(PhosphorIconsStyle.regular), size: 18, color: isActive ? primaryColor : theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 10),
              Text('Priority:', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: isActive ? primaryColor : theme.colorScheme.onSurfaceVariant)),
              const Spacer(),
              if (isActive) Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: primaryColor)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: ['high', 'medium', 'low', 'none'].map((p) {
              final selected = currentPriority == p;
              final color = p == 'high' ? AppColors.priorityUrgent
                  : p == 'medium' ? AppColors.priorityMedium
                  : p == 'low' ? AppColors.priorityLow
                  : theme.colorScheme.onSurfaceVariant;
              return Expanded(child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: selected ? color.withValues(alpha: 0.15) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: selected ? color : theme.dividerColor.withValues(alpha: 0.2)),
                ),
                child: Center(child: Text(
                  p[0].toUpperCase() + p.substring(1),
                  style: TextStyle(fontSize: 11, fontWeight: selected ? FontWeight.w700 : FontWeight.w400, color: selected ? color : theme.colorScheme.onSurfaceVariant),
                )),
              ));
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ── Assign Card ──
class _AssignCard extends StatelessWidget {
  const _AssignCard({required this.activeField, required this.assignees});
  final VoiceField activeField;
  final List<String> assignees;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final isActive = activeField == VoiceField.assign;
    final hasValue = assignees.isNotEmpty;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isActive ? primaryColor.withValues(alpha: 0.08) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? primaryColor : hasValue ? primaryColor.withValues(alpha: 0.2) : theme.dividerColor.withValues(alpha: 0.15),
          width: isActive ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(PhosphorIcons.users(PhosphorIconsStyle.regular), size: 18, color: isActive ? primaryColor : theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 10),
              Text('Assign:', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: isActive ? primaryColor : theme.colorScheme.onSurfaceVariant)),
              const Spacer(),
              if (isActive) Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: primaryColor)),
            ],
          ),
          if (hasValue) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: assignees.map((name) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(PhosphorIcons.user(PhosphorIconsStyle.fill), size: 12, color: primaryColor),
                    const SizedBox(width: 4),
                    Text(name, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: primaryColor)),
                  ],
                ),
              )).toList(),
            ),
          ] else
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('Say "cc Radu" or "trimite și la Radu"', style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4))),
            ),
        ],
      ),
    );
  }
}

// ── Action Card (Take picture / Add attachment) ──
class _ActionCard extends StatelessWidget {
  const _ActionCard({required this.icon, required this.label, required this.onTap, this.isActive = false});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? AppColors.success : primaryColor.withValues(alpha: 0.3),
            width: isActive ? 2 : 1,
          ),
          color: isActive ? AppColors.success.withValues(alpha: 0.1) : primaryColor.withValues(alpha: 0.05),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isActive ? PhosphorIcons.checkCircle(PhosphorIconsStyle.fill) : icon,
              size: 18,
              color: isActive ? AppColors.success : primaryColor,
            ),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isActive ? AppColors.success : primaryColor)),
          ],
        ),
      ),
    );
  }
}

// ── JS interop helpers ──
Object get _jsGlobalThis => js_util.globalThis;

// ── Custom Banner Widget ──

class _CustomBannerWidget extends StatelessWidget {
  const _CustomBannerWidget({required this.banner});
  final Map<String, dynamic> banner;

  Color _parseColor(String? hex, Color fallback) {
    if (hex == null || hex.length < 7) return fallback;
    try { return Color(int.parse(hex.substring(1), radix: 16) + 0xFF000000); } catch (_) { return fallback; }
  }

  @override
  Widget build(BuildContext context) {
    final title = banner['title'] as String? ?? '';
    final subtitle = banner['subtitle'] as String?;
    final imageUrl = banner['image_url'] as String?;
    final effect = banner['effect'] as String? ?? 'none';
    final gradStart = _parseColor(banner['gradient_start'] as String?, const Color(0xFFFF6B9D));
    final gradEnd = _parseColor(banner['gradient_end'] as String?, const Color(0xFFFFA751));
    final images = imageUrl != null && imageUrl.isNotEmpty ? imageUrl.split('|||') : <String>[];

    return GestureDetector(
      onTap: () => _showFullBanner(context, banner),
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [gradStart, gradEnd], begin: Alignment.topLeft, end: Alignment.bottomRight),
            ),
            child: SafeArea(
              bottom: false,
              child: Stack(
                children: [
                  if (images.isNotEmpty)
                    Positioned.fill(child: Opacity(opacity: 0.3,
                      child: images.length == 1
                          ? Image.network(images.first, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox.shrink())
                          : Row(children: images.take(4).map((url) => Expanded(
                              child: Image.network(url, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox.shrink()))).toList()))),
                  Center(child: Column(
                    children: [
                      if (title.isNotEmpty)
                        Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700,
                          shadows: [Shadow(color: Colors.black26, blurRadius: 4)]), textAlign: TextAlign.center),
                      if (subtitle != null && subtitle.isNotEmpty)
                        Padding(padding: const EdgeInsets.only(top: 2),
                          child: Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 12), textAlign: TextAlign.center)),
                    ],
                  )),
                ],
              ),
            ),
          ),
          if (effect == 'confetti') const Positioned.fill(child: ConfettiOverlay(duration: Duration(seconds: 5))),
        ],
      ),
    );
  }

  void _showFullBanner(BuildContext context, Map<String, dynamic> banner) {
    final title = banner['title'] as String? ?? '';
    final subtitle = banner['subtitle'] as String?;
    final imageUrl = banner['image_url'] as String?;
    final effect = banner['effect'] as String? ?? 'none';
    final gradStart = _parseColor(banner['gradient_start'] as String?, const Color(0xFFFF6B9D));
    final gradEnd = _parseColor(banner['gradient_end'] as String?, const Color(0xFFFFA751));
    final images = imageUrl != null && imageUrl.isNotEmpty ? imageUrl.split('|||') : <String>[];

    showDialog(
      context: context,
      builder: (ctx) => GestureDetector(
        onTap: () => Navigator.pop(ctx),
        child: Scaffold(
          backgroundColor: Colors.black54,
          body: Center(
            child: Container(
              margin: const EdgeInsets.all(20),
              constraints: const BoxConstraints(maxHeight: 400),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [gradStart, gradEnd], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(20),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  children: [
                    if (images.isNotEmpty)
                      Positioned.fill(child: Opacity(opacity: 0.35,
                        child: images.length == 1
                            ? Image.network(images.first, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox.shrink())
                            : Row(children: images.take(4).map((url) => Expanded(
                                child: Image.network(url, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox.shrink()))).toList()))),
                    Center(child: Padding(
                      padding: const EdgeInsets.all(30),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        if (title.isNotEmpty)
                          Text(title, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w700,
                            shadows: [Shadow(color: Colors.black38, blurRadius: 8)]), textAlign: TextAlign.center),
                        if (subtitle != null && subtitle.isNotEmpty)
                          Padding(padding: const EdgeInsets.only(top: 8),
                            child: Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 16), textAlign: TextAlign.center)),
                      ]),
                    )),
                    if (effect == 'confetti') const Positioned.fill(child: ConfettiOverlay(duration: Duration(seconds: 6))),
                    Positioned(top: 12, right: 12, child: IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close, color: Colors.white70, size: 28))),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
Object? _jsGetProp(Object o, String prop) => js_util.getProperty(o, prop);
int _jsGetPropInt(Object o, String prop) => js_util.getProperty<int>(o, prop);
String _jsGetPropString(Object o, String prop) => js_util.getProperty<String>(o, prop);
void _jsSetProp(Object o, String prop, Object? val) => js_util.setProperty(o, prop, val);
Object _jsConstruct(Object ctor) => js_util.callConstructor(ctor, []);
Object _jsCallMethod(Object? o, String method, List<Object?> args) => js_util.callMethod(o!, method, args);
Function _jsAllowInterop(Function f) => js_util.allowInterop(f);

import 'dart:js_util' as js_util;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../core/constants/app_colors.dart';
import '../core/router/app_router.dart';
import '../core/services/voice_task_parser.dart';
import '../features/notifications/providers/notifications_provider.dart';

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
    ).then((transcript) {
      if (transcript != null && transcript.isNotEmpty) {
        final result = VoiceTaskParser.parse(transcript);
        // Build query params from parsed voice data
        final params = <String, String>{};
        if (result.title != null) params['title'] = result.title!;
        if (result.description != null) params['desc'] = result.description!;
        if (result.dueDate != null) params['date'] = result.dueDate!.toIso8601String().split('T').first;
        if (result.hour != null) params['hour'] = result.hour.toString();
        if (result.minute != null) params['minute'] = result.minute.toString();
        if (result.priority != null) params['priority'] = result.priority!;
        if (result.address != null) params['locAddress'] = result.address!;
        if (result.assignees.isNotEmpty) params['assignee'] = result.assignees.first;

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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = _calculateSelectedIndex(context);
    final unreadCount = ref.watch(unreadCountProvider);
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Scaffold(
      body: child,
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
                  onTap: () => _onItemTapped(context, 0),
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
                  onTap: () => _onItemTapped(context, 2),
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
  bool _listening = false;
  String _error = '';
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
      String transcript = '';
      try {
        final results = _jsGetProp(event, 'results')!;
        final len = _jsGetPropInt(results, 'length');
        for (int i = 0; i < len; i++) {
          final result = _jsCallMethod(results, 'item', [i]);
          final alt = _jsCallMethod(result, 'item', [0]);
          transcript += _jsGetPropString(alt, 'transcript');
        }
      } catch (_) {}
      if (mounted) setState(() => _text = transcript);
    }));

    _jsSetProp(recognition, 'onerror', _jsAllowInterop((event) {
      try {
        final err = _jsGetPropString(event, 'error');
        if (err != 'no-speech' && mounted) setState(() { _error = 'Error: $err'; _listening = false; });
      } catch (_) {}
    }));

    _jsSetProp(recognition, 'onend', _jsAllowInterop((event) {
      if (mounted) setState(() => _listening = false);
    }));

    try {
      _jsCallMethod(recognition, 'start', []);
      if (mounted) setState(() { _listening = true; _error = ''; });
    } catch (e) {
      if (mounted) setState(() { _error = 'Failed: $e'; _listening = false; });
    }
  }

  void _stop() {
    try { if (_rec != null) _jsCallMethod(_rec!, 'stop', []); } catch (_) {}
  }

  void _confirm() { _stop(); Navigator.of(context).pop(_text); }
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
              icon: PhosphorIcons.textT(PhosphorIconsStyle.bold),
              label: 'Title',
              value: parsed?.title,
              placeholder: 'Start speaking to set the title...',
            ),
            _FieldCard(
              field: VoiceField.description,
              activeField: activeField,
              icon: PhosphorIcons.article(PhosphorIconsStyle.regular),
              label: 'Description',
              value: parsed?.description,
              placeholder: 'Say "descriere" to switch here',
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

// ── JS interop helpers ──
Object get _jsGlobalThis => js_util.globalThis;
Object? _jsGetProp(Object o, String prop) => js_util.getProperty(o, prop);
int _jsGetPropInt(Object o, String prop) => js_util.getProperty<int>(o, prop);
String _jsGetPropString(Object o, String prop) => js_util.getProperty<String>(o, prop);
void _jsSetProp(Object o, String prop, Object? val) => js_util.setProperty(o, prop, val);
Object _jsConstruct(Object ctor) => js_util.callConstructor(ctor, []);
Object _jsCallMethod(Object? o, String method, List<Object?> args) => js_util.callMethod(o!, method, args);
Function _jsAllowInterop(Function f) => js_util.allowInterop(f);

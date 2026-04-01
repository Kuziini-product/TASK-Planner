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
    if (location.startsWith(AppRoutes.notifications)) return 2;
    if (location.startsWith(AppRoutes.profile)) return 3;
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
        if (result.locationName != null) params['locName'] = result.locationName!;
        if (result.locationAddress != null) params['locAddress'] = result.locationAddress!;
        if (result.assigneeName != null) params['assignee'] = result.assigneeName!;

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
        context.go(AppRoutes.notifications);
      case 3:
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
                  icon: PhosphorIcons.bell(PhosphorIconsStyle.regular),
                  activeIcon: PhosphorIcons.bell(PhosphorIconsStyle.fill),
                  label: 'Alerts',
                  isSelected: selectedIndex == 2,
                  onTap: () => _onItemTapped(context, 2),
                  badge: unreadCount.whenOrNull(data: (count) => count) ?? 0,
                ),
                _NavItem(
                  icon: PhosphorIcons.user(PhosphorIconsStyle.regular),
                  activeIcon: PhosphorIcons.user(PhosphorIconsStyle.fill),
                  label: 'Profile',
                  isSelected: selectedIndex == 3,
                  onTap: () => _onItemTapped(context, 3),
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

// ── Voice Task Sheet ──
// Full-screen voice input that shows parsed task fields live.

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
      // ignore: avoid_dynamic_calls
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

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 20, offset: const Offset(0, -4))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Container(width: 40, height: 4,
                decoration: BoxDecoration(color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 12),

            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(PhosphorIcons.microphone(PhosphorIconsStyle.fill), color: primaryColor, size: 20),
                const SizedBox(width: 8),
                Text('Voice Task Creator', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Speak: task title, descriere, data, ora, locație, urgent/medium/low, arond [name]',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant, fontSize: 10),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 16),

            // Pulsing mic
            AnimatedBuilder(
              animation: _pulseAnim,
              builder: (context, _) => Container(
                width: 64, height: 64,
                decoration: BoxDecoration(shape: BoxShape.circle, color: (_listening ? AppColors.error : primaryColor).withValues(alpha: 0.1)),
                child: Center(
                  child: Transform.scale(
                    scale: _listening ? _pulseAnim.value : 1.0,
                    child: Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _listening ? AppColors.error : primaryColor,
                        boxShadow: _listening ? [BoxShadow(color: AppColors.error.withValues(alpha: 0.4), blurRadius: 12)] : null,
                      ),
                      child: Icon(
                        _listening ? PhosphorIcons.microphone(PhosphorIconsStyle.fill) : PhosphorIcons.microphoneSlash(PhosphorIconsStyle.fill),
                        color: Colors.white, size: 24,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),
            Text(
              _listening ? 'Listening...' : _error.isNotEmpty ? 'Error' : 'Tap mic to restart',
              style: theme.textTheme.bodySmall?.copyWith(
                color: _listening ? AppColors.error : theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.w500, fontSize: 11),
            ),

            const SizedBox(height: 12),

            // Transcript
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(12),
              constraints: const BoxConstraints(minHeight: 50),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12)),
              width: double.infinity,
              child: Text(
                _text.isNotEmpty ? _text : 'Say something like:\n"măsurătoare Radu slash întâlnire Radu slash ora 14 4 aprilie adresă strada Solstițiului 11 urgent"',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: _text.isNotEmpty ? null : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4), height: 1.3, fontSize: 13),
              ),
            ),

            // Parsed fields preview
            if (parsed != null && !parsed.isEmpty) ...[
              const SizedBox(height: 12),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: primaryColor.withValues(alpha: 0.15)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Parsed Fields', style: theme.textTheme.labelSmall?.copyWith(color: primaryColor, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    if (parsed.title != null) _ParsedField(icon: PhosphorIcons.textT(PhosphorIconsStyle.bold), label: 'Title', value: parsed.title!),
                    if (parsed.description != null) _ParsedField(icon: PhosphorIcons.article(PhosphorIconsStyle.regular), label: 'Description', value: parsed.description!),
                    if (parsed.dueDate != null) _ParsedField(icon: PhosphorIcons.calendar(PhosphorIconsStyle.regular), label: 'Date', value: '${parsed.dueDate!.day}/${parsed.dueDate!.month}/${parsed.dueDate!.year}'),
                    if (parsed.hour != null) _ParsedField(icon: PhosphorIcons.clock(PhosphorIconsStyle.regular), label: 'Time', value: '${parsed.hour}:${(parsed.minute ?? 0).toString().padLeft(2, '0')}'),
                    if (parsed.priority != null) _ParsedField(icon: PhosphorIcons.flag(PhosphorIconsStyle.regular), label: 'Priority', value: parsed.priority!),
                    if (parsed.locationAddress != null) _ParsedField(icon: PhosphorIcons.mapPin(PhosphorIconsStyle.regular), label: 'Address', value: [parsed.locationName, parsed.locationAddress].whereType<String>().where((s) => s.isNotEmpty).join(' - ')),
                    if (parsed.assigneeName != null) _ParsedField(icon: PhosphorIcons.user(PhosphorIconsStyle.regular), label: 'Assign', value: parsed.assigneeName!),
                  ],
                ),
              ),
            ],

            if (_error.isNotEmpty) ...[
              const SizedBox(height: 8),
              Padding(padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(_error, style: theme.textTheme.bodySmall?.copyWith(color: AppColors.error), textAlign: TextAlign.center)),
            ],

            const SizedBox(height: 16),
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
                    padding: const EdgeInsets.symmetric(vertical: 12)),
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
                    padding: const EdgeInsets.symmetric(vertical: 12)),
                )),
              ]),
            ),

            if (!_listening && _error.isEmpty) ...[
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: _start,
                icon: Icon(PhosphorIcons.arrowClockwise(PhosphorIconsStyle.regular), size: 14),
                label: const Text('Restart', style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(foregroundColor: primaryColor)),
            ],

            SizedBox(height: 16 + MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }
}

class _ParsedField extends StatelessWidget {
  const _ParsedField({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 14, color: theme.colorScheme.primary),
          const SizedBox(width: 6),
          Text('$label: ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurfaceVariant)),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 11), overflow: TextOverflow.ellipsis)),
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

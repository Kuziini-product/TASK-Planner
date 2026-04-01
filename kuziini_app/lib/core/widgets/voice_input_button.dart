import 'dart:js_interop';
import 'dart:js_util' as js_util;
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';

class VoiceInputButton extends StatelessWidget {
  final ValueChanged<String> onResult;
  final String? hintText;
  final double size;
  final bool mini;

  const VoiceInputButton({
    super.key,
    required this.onResult,
    this.hintText,
    this.size = 36,
    this.mini = false,
  });

  void _openSheet(BuildContext context) {
    showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _VoiceSheet(hintText: hintText ?? 'Listening...'),
    ).then((result) {
      if (result != null && result.isNotEmpty) onResult(result);
    });
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    if (mini) {
      return SizedBox(
        width: size, height: size,
        child: IconButton(
          onPressed: () => _openSheet(context),
          padding: EdgeInsets.zero,
          constraints: BoxConstraints(minWidth: size, minHeight: size),
          icon: Icon(PhosphorIcons.microphone(PhosphorIconsStyle.regular), size: 18, color: primaryColor),
          tooltip: 'Voice input',
        ),
      );
    }
    return SizedBox(
      width: size, height: size,
      child: Material(
        color: primaryColor, shape: const CircleBorder(), elevation: 2,
        child: InkWell(
          onTap: () => _openSheet(context),
          customBorder: const CircleBorder(),
          child: Center(child: Icon(PhosphorIcons.microphone(PhosphorIconsStyle.fill), color: Colors.white, size: size * 0.5)),
        ),
      ),
    );
  }
}

class _VoiceSheet extends StatefulWidget {
  const _VoiceSheet({required this.hintText});
  final String hintText;
  @override
  State<_VoiceSheet> createState() => _VoiceSheetState();
}

class _VoiceSheetState extends State<_VoiceSheet> with SingleTickerProviderStateMixin {
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
      final global = js_util.globalThis;
      final ctor = js_util.getProperty(global, 'webkitSpeechRecognition') ?? js_util.getProperty(global, 'SpeechRecognition');
      if (ctor == null) throw 'not supported';
      recognition = js_util.callConstructor(ctor, []);
    } catch (_) {
      if (mounted) setState(() { _error = 'Speech recognition not supported.\nPlease use Chrome.'; _listening = false; });
      return;
    }

    _rec = recognition;
    js_util.setProperty(recognition!, 'continuous', true);
    js_util.setProperty(recognition, 'interimResults', true);
    js_util.setProperty(recognition, 'lang', 'ro-RO');

    js_util.setProperty(recognition, 'onresult', js_util.allowInterop((event) {
      String transcript = '';
      try {
        final results = js_util.getProperty(event, 'results');
        final len = js_util.getProperty<int>(results, 'length');
        for (int i = 0; i < len; i++) {
          final result = js_util.callMethod(results, 'item', [i]);
          final alt = js_util.callMethod(result, 'item', [0]);
          transcript += js_util.getProperty<String>(alt, 'transcript');
        }
      } catch (_) {}
      if (mounted) setState(() => _text = transcript);
    }));

    js_util.setProperty(recognition, 'onerror', js_util.allowInterop((event) {
      try {
        final err = js_util.getProperty<String>(event, 'error');
        if (err != 'no-speech' && mounted) setState(() { _error = 'Error: $err'; _listening = false; });
      } catch (_) {}
    }));

    js_util.setProperty(recognition, 'onend', js_util.allowInterop((event) {
      if (mounted) setState(() => _listening = false);
    }));

    try {
      js_util.callMethod(recognition, 'start', []);
      if (mounted) setState(() { _listening = true; _error = ''; });
    } catch (e) {
      if (mounted) setState(() { _error = 'Failed: $e'; _listening = false; });
    }
  }

  void _stop() {
    try { if (_rec != null) js_util.callMethod(_rec!, 'stop', []); } catch (_) {}
  }

  void _confirm() { _stop(); Navigator.of(context).pop(_text); }
  void _cancel() { _stop(); Navigator.of(context).pop(null); }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        margin: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.cardLight,
          borderRadius: AppSpacing.borderRadiusXl,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 20, offset: const Offset(0, -4))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.md),
              child: Container(width: 40, height: 4,
                decoration: BoxDecoration(color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.2), borderRadius: AppSpacing.borderRadiusFull)),
            ),
            AppSpacing.vGapXl,

            // Pulsing mic
            AnimatedBuilder(
              animation: _pulseAnim,
              builder: (context, _) => Container(
                width: 80, height: 80,
                decoration: BoxDecoration(shape: BoxShape.circle, color: (_listening ? AppColors.error : primaryColor).withValues(alpha: 0.1)),
                child: Center(
                  child: Transform.scale(
                    scale: _listening ? _pulseAnim.value : 1.0,
                    child: Container(
                      width: 56, height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _listening ? AppColors.error : primaryColor,
                        boxShadow: _listening ? [BoxShadow(color: AppColors.error.withValues(alpha: 0.4), blurRadius: 16, spreadRadius: 2)] : null,
                      ),
                      child: Icon(
                        _listening ? PhosphorIcons.microphone(PhosphorIconsStyle.fill) : PhosphorIcons.microphoneSlash(PhosphorIconsStyle.fill),
                        color: Colors.white, size: 28,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            AppSpacing.vGapLg,
            Text(
              _listening ? 'Listening...' : _error.isNotEmpty ? 'Error' : 'Tap mic to restart',
              style: theme.textTheme.bodySmall?.copyWith(
                color: _listening ? AppColors.error : theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.w500),
            ),

            AppSpacing.vGapLg,
            Container(
              margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              padding: AppSpacing.paddingLg,
              constraints: const BoxConstraints(minHeight: 80),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariantLight,
                borderRadius: AppSpacing.borderRadiusMd),
              width: double.infinity,
              child: Text(
                _text.isNotEmpty ? _text : widget.hintText,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: _text.isNotEmpty ? null : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5), height: 1.4),
              ),
            ),

            if (_error.isNotEmpty) ...[
              AppSpacing.vGapSm,
              Padding(padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                child: Text(_error, style: theme.textTheme.bodySmall?.copyWith(color: AppColors.error), textAlign: TextAlign.center)),
            ],

            AppSpacing.vGapXl,
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: Row(children: [
                Expanded(child: OutlinedButton.icon(
                  onPressed: _cancel,
                  icon: Icon(PhosphorIcons.x(PhosphorIconsStyle.bold), size: 18),
                  label: const Text('Cancel'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.onSurfaceVariant,
                    side: BorderSide(color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.2)),
                    shape: RoundedRectangleBorder(borderRadius: AppSpacing.borderRadiusMd),
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md)),
                )),
                AppSpacing.hGapMd,
                Expanded(child: FilledButton.icon(
                  onPressed: _text.isNotEmpty ? _confirm : null,
                  icon: Icon(PhosphorIcons.check(PhosphorIconsStyle.bold), size: 18),
                  label: const Text('Confirm'),
                  style: FilledButton.styleFrom(
                    backgroundColor: primaryColor,
                    disabledBackgroundColor: primaryColor.withValues(alpha: 0.3),
                    shape: RoundedRectangleBorder(borderRadius: AppSpacing.borderRadiusMd),
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md)),
                )),
              ]),
            ),

            if (!_listening && _error.isEmpty) ...[
              AppSpacing.vGapMd,
              TextButton.icon(
                onPressed: _start,
                icon: Icon(PhosphorIcons.arrowClockwise(PhosphorIconsStyle.regular), size: 16),
                label: const Text('Restart'),
                style: TextButton.styleFrom(foregroundColor: primaryColor)),
            ],

            SizedBox(height: AppSpacing.xl + MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }
}

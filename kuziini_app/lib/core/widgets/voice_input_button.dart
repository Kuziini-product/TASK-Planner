import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';

/// A reusable voice input button that uses speech-to-text recognition.
///
/// Shows a microphone icon button. When pressed, starts listening for speech
/// and shows a bottom sheet with live transcription. Works on web via the
/// Web Speech API.
class VoiceInputButton extends StatefulWidget {
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

  @override
  State<VoiceInputButton> createState() => _VoiceInputButtonState();
}

class _VoiceInputButtonState extends State<VoiceInputButton> {
  final SpeechToText _speech = SpeechToText();
  bool _isAvailable = false;
  bool _checking = true;

  @override
  void initState() {
    super.initState();
    _checkAvailability();
  }

  Future<void> _checkAvailability() async {
    try {
      final available = await _speech.initialize(
        onError: (_) {},
        onStatus: (_) {},
      );
      if (mounted) {
        setState(() {
          _isAvailable = available;
          _checking = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isAvailable = false;
          _checking = false;
        });
      }
    }
  }

  void _startListening() {
    showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _VoiceListeningSheet(
        speech: _speech,
        hintText: widget.hintText ?? 'Listening...',
      ),
    ).then((result) {
      if (result != null && result.isNotEmpty) {
        widget.onResult(result);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_checking || !_isAvailable) {
      return const SizedBox.shrink();
    }

    if (widget.mini) {
      return SizedBox(
        width: widget.size,
        height: widget.size,
        child: IconButton(
          onPressed: _startListening,
          padding: EdgeInsets.zero,
          constraints: BoxConstraints(
            minWidth: widget.size,
            minHeight: widget.size,
          ),
          icon: Icon(
            PhosphorIcons.microphone(PhosphorIconsStyle.regular),
            size: 18,
            color: AppColors.primary,
          ),
          tooltip: 'Voice input',
        ),
      );
    }

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Material(
        color: AppColors.primary,
        shape: const CircleBorder(),
        elevation: 2,
        shadowColor: AppColors.primary.withValues(alpha: 0.3),
        child: InkWell(
          onTap: _startListening,
          customBorder: const CircleBorder(),
          child: Center(
            child: Icon(
              PhosphorIcons.microphone(PhosphorIconsStyle.fill),
              color: Colors.white,
              size: widget.size * 0.5,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Listening Bottom Sheet ──

class _VoiceListeningSheet extends StatefulWidget {
  const _VoiceListeningSheet({
    required this.speech,
    required this.hintText,
  });

  final SpeechToText speech;
  final String hintText;

  @override
  State<_VoiceListeningSheet> createState() => _VoiceListeningSheetState();
}

class _VoiceListeningSheetState extends State<_VoiceListeningSheet>
    with SingleTickerProviderStateMixin {
  String _transcribedText = '';
  bool _isListening = false;
  String _error = '';
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.35).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _startListening();
  }

  @override
  void dispose() {
    _stopListening();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _startListening() async {
    try {
      final available = await widget.speech.initialize(
        onError: (error) {
          if (mounted) {
            setState(() {
              _error = error.errorMsg;
              _isListening = false;
            });
          }
        },
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            if (mounted) {
              setState(() => _isListening = false);
            }
          }
        },
      );

      if (!available) {
        if (mounted) {
          setState(() {
            _error = 'Speech recognition not available';
            _isListening = false;
          });
        }
        return;
      }

      widget.speech.listen(
        onResult: (result) {
          if (mounted) {
            setState(() {
              _transcribedText = result.recognizedWords;
            });
          }
        },
        listenMode: ListenMode.dictation,
        cancelOnError: false,
        partialResults: true,
      );

      if (mounted) {
        setState(() {
          _isListening = true;
          _error = '';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to start listening: $e';
          _isListening = false;
        });
      }
    }
  }

  Future<void> _stopListening() async {
    try {
      await widget.speech.stop();
    } catch (_) {}
  }

  void _confirm() {
    _stopListening();
    Navigator.of(context).pop(_transcribedText);
  }

  void _cancel() {
    _stopListening();
    Navigator.of(context).pop(null);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        margin: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.cardLight,
          borderRadius: AppSpacing.borderRadiusXl,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.md),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurfaceVariant
                      .withValues(alpha: 0.2),
                  borderRadius: AppSpacing.borderRadiusFull,
                ),
              ),
            ),

            AppSpacing.vGapXl,

            // Pulsing mic indicator
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isListening
                        ? AppColors.error.withValues(alpha: 0.1)
                        : AppColors.primary.withValues(alpha: 0.1),
                  ),
                  child: Center(
                    child: Transform.scale(
                      scale: _isListening ? _pulseAnimation.value : 1.0,
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color:
                              _isListening ? AppColors.error : AppColors.primary,
                          boxShadow: _isListening
                              ? [
                                  BoxShadow(
                                    color:
                                        AppColors.error.withValues(alpha: 0.4),
                                    blurRadius: 16,
                                    spreadRadius: 2,
                                  ),
                                ]
                              : null,
                        ),
                        child: Icon(
                          _isListening
                              ? PhosphorIcons.microphone(
                                  PhosphorIconsStyle.fill)
                              : PhosphorIcons.microphoneSlash(
                                  PhosphorIconsStyle.fill),
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),

            AppSpacing.vGapLg,

            // Status text
            Text(
              _isListening
                  ? 'Listening... Tap to stop'
                  : _error.isNotEmpty
                      ? 'Error occurred'
                      : 'Tap mic to restart',
              style: theme.textTheme.bodySmall?.copyWith(
                color: _isListening
                    ? AppColors.error
                    : theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),

            AppSpacing.vGapLg,

            // Transcribed text area
            Container(
              margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              padding: AppSpacing.paddingLg,
              constraints: const BoxConstraints(minHeight: 80),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.surfaceVariantDark
                    : AppColors.surfaceVariantLight,
                borderRadius: AppSpacing.borderRadiusMd,
              ),
              width: double.infinity,
              child: Text(
                _transcribedText.isNotEmpty
                    ? _transcribedText
                    : widget.hintText,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: _transcribedText.isNotEmpty
                      ? null
                      : theme.colorScheme.onSurfaceVariant
                          .withValues(alpha: 0.5),
                  height: 1.4,
                ),
              ),
            ),

            if (_error.isNotEmpty) ...[
              AppSpacing.vGapSm,
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                child: Text(
                  _error,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.error,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],

            AppSpacing.vGapXl,

            // Action buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: Row(
                children: [
                  // Cancel button
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _cancel,
                      icon: Icon(
                        PhosphorIcons.x(PhosphorIconsStyle.bold),
                        size: 18,
                      ),
                      label: const Text('Cancel'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor:
                            theme.colorScheme.onSurfaceVariant,
                        side: BorderSide(
                          color: theme.colorScheme.onSurfaceVariant
                              .withValues(alpha: 0.2),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: AppSpacing.borderRadiusMd,
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.md,
                        ),
                      ),
                    ),
                  ),
                  AppSpacing.hGapMd,
                  // Confirm button
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _transcribedText.isNotEmpty ? _confirm : null,
                      icon: Icon(
                        PhosphorIcons.check(PhosphorIconsStyle.bold),
                        size: 18,
                      ),
                      label: const Text('Confirm'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        disabledBackgroundColor:
                            AppColors.primary.withValues(alpha: 0.3),
                        shape: RoundedRectangleBorder(
                          borderRadius: AppSpacing.borderRadiusMd,
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.md,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Restart button when not listening
            if (!_isListening && _error.isEmpty) ...[
              AppSpacing.vGapMd,
              TextButton.icon(
                onPressed: _startListening,
                icon: Icon(
                  PhosphorIcons.arrowClockwise(PhosphorIconsStyle.regular),
                  size: 16,
                ),
                label: const Text('Restart listening'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                ),
              ),
            ],

            SizedBox(height: AppSpacing.xl + MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }
}

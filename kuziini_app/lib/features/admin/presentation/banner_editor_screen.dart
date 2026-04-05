import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/extensions.dart';
import '../../../core/widgets/confetti_widget.dart';
import '../../../core/widgets/kuziini_app_bar.dart';

// ── Effect presets ──
class BannerEffect {
  final String id;
  final String name;
  final String emoji;
  const BannerEffect(this.id, this.name, this.emoji);
}

const _effects = [
  BannerEffect('none', 'Fără', '❌'),
  BannerEffect('confetti', 'Confetti', '🎊'),
  BannerEffect('stars', 'Stele', '⭐'),
  BannerEffect('balloons', 'Baloane', '🎈'),
  BannerEffect('hearts', 'Inimi', '❤️'),
  BannerEffect('snow', 'Zăpadă', '❄️'),
];

// ── Gradient presets ──
class GradientPreset {
  final String name;
  final Color start;
  final Color end;
  const GradientPreset(this.name, this.start, this.end);
}

const _gradients = [
  GradientPreset('Sunset', Color(0xFFFF6B9D), Color(0xFFFFA751)),
  GradientPreset('Ocean', Color(0xFF2196F3), Color(0xFF00BCD4)),
  GradientPreset('Forest', Color(0xFF2D6A4F), Color(0xFF95D5B2)),
  GradientPreset('Purple', Color(0xFF7C3AED), Color(0xFFA855F7)),
  GradientPreset('Fire', Color(0xFFE91E63), Color(0xFFFF5722)),
  GradientPreset('Gold', Color(0xFFFFB300), Color(0xFFFF6F00)),
  GradientPreset('Night', Color(0xFF1A1A2E), Color(0xFF16213E)),
  GradientPreset('Teal', Color(0xFF0D7377), Color(0xFF14B8A6)),
];

class BannerEditorScreen extends ConsumerStatefulWidget {
  const BannerEditorScreen({super.key});

  @override
  ConsumerState<BannerEditorScreen> createState() => _BannerEditorScreenState();
}

class _BannerEditorScreenState extends ConsumerState<BannerEditorScreen> {
  final _titleController = TextEditingController();
  final _subtitleController = TextEditingController();
  String _effect = 'none';
  int _gradientIndex = 0;
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();
  String? _imageUrl;
  Uint8List? _imageBytes;
  bool _saving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery, maxWidth: 800);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() => _imageBytes = bytes);

      // Upload to Supabase storage
      try {
        final fileName = '${const Uuid().v4()}.${image.name.split('.').last}';
        await Supabase.instance.client.storage
            .from('banners')
            .uploadBinary(fileName, bytes, fileOptions: const FileOptions(upsert: true));
        final url = Supabase.instance.client.storage.from('banners').getPublicUrl(fileName);
        setState(() => _imageUrl = url);
      } catch (e) {
        if (mounted) context.showSnackBar('Upload failed: $e', isError: true);
      }
    }
  }

  Future<void> _pickStartDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now().subtract(const Duration(days: 7)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) setState(() => _startDate = date);
  }

  Future<void> _pickEndDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _endDate.isBefore(_startDate) ? _startDate : _endDate,
      firstDate: _startDate,
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) setState(() => _endDate = date);
  }

  Future<void> _save() async {
    if (_titleController.text.trim().isEmpty) {
      context.showSnackBar('Adaugă un titlu', isError: true);
      return;
    }
    setState(() => _saving = true);

    try {
      final gradient = _gradients[_gradientIndex];
      await Supabase.instance.client.from('custom_banners').insert({
        'title': _titleController.text.trim(),
        'subtitle': _subtitleController.text.trim().isEmpty ? null : _subtitleController.text.trim(),
        'image_url': _imageUrl,
        'effect': _effect,
        'gradient_start': '#${gradient.start.value.toRadixString(16).substring(2)}',
        'gradient_end': '#${gradient.end.value.toRadixString(16).substring(2)}',
        'text_color': '#FFFFFF',
        'start_date': '${_startDate.year}-${_startDate.month.toString().padLeft(2, '0')}-${_startDate.day.toString().padLeft(2, '0')}',
        'end_date': '${_endDate.year}-${_endDate.month.toString().padLeft(2, '0')}-${_endDate.day.toString().padLeft(2, '0')}',
        'is_active': true,
        'created_by': Supabase.instance.client.auth.currentUser!.id,
      });

      if (mounted) {
        context.showSnackBar('Banner creat!');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) context.showSnackBar('Eroare: $e', isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gradient = _gradients[_gradientIndex];

    return Scaffold(
      appBar: const KuziiniAppBar(showBackButton: true, title: 'Creare Banner'),
      body: ListView(
        padding: AppSpacing.paddingLg,
        children: [
          // ── LIVE PREVIEW ──
          Text('PREVIEW', style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.w700, letterSpacing: 1)),
          AppSpacing.vGapSm,
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Stack(
              children: [
                // Background
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(minHeight: 80),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [gradient.start, gradient.end],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    children: [
                      // Image
                      if (_imageBytes != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.memory(_imageBytes!, height: 60, fit: BoxFit.contain),
                          ),
                        ),
                      // Title
                      if (_titleController.text.isNotEmpty)
                        Text(
                          _titleController.text,
                          style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700,
                            shadows: [Shadow(color: Colors.black26, blurRadius: 4)]),
                          textAlign: TextAlign.center,
                        ),
                      // Subtitle
                      if (_subtitleController.text.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            _subtitleController.text,
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                        ),
                    ],
                  ),
                ),
                // Effect overlay
                if (_effect == 'confetti')
                  const Positioned.fill(child: ConfettiOverlay(duration: Duration(seconds: 4))),
                if (_effect == 'stars')
                  Positioned.fill(child: _ParticleOverlay(emoji: '⭐', count: 20)),
                if (_effect == 'balloons')
                  Positioned.fill(child: _ParticleOverlay(emoji: '🎈', count: 15)),
                if (_effect == 'hearts')
                  Positioned.fill(child: _ParticleOverlay(emoji: '❤️', count: 18)),
                if (_effect == 'snow')
                  Positioned.fill(child: _ParticleOverlay(emoji: '❄️', count: 25)),
              ],
            ),
          ),

          AppSpacing.vGapXl,

          // ── TITLE ──
          Text('TITLU', style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.w700, letterSpacing: 1)),
          AppSpacing.vGapSm,
          TextField(
            controller: _titleController,
            decoration: InputDecoration(
              hintText: 'Ex: La Multi Ani, Echipa!',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onChanged: (_) => setState(() {}),
          ),

          AppSpacing.vGapMd,

          // ── SUBTITLE ──
          Text('SUBTITLU (opțional)', style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.w700, letterSpacing: 1)),
          AppSpacing.vGapSm,
          TextField(
            controller: _subtitleController,
            decoration: InputDecoration(
              hintText: 'Ex: Sărbători fericite!',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onChanged: (_) => setState(() {}),
          ),

          AppSpacing.vGapXl,

          // ── IMAGE ──
          Text('IMAGINE (opțional)', style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.w700, letterSpacing: 1)),
          AppSpacing.vGapSm,
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              height: 80,
              decoration: BoxDecoration(
                border: Border.all(color: theme.dividerColor),
                borderRadius: BorderRadius.circular(12),
              ),
              child: _imageBytes != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.memory(_imageBytes!, fit: BoxFit.contain, width: double.infinity))
                  : Center(child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(PhosphorIcons.image(PhosphorIconsStyle.regular), size: 28, color: theme.colorScheme.onSurfaceVariant),
                        const SizedBox(height: 4),
                        Text('Tap pentru a încărca', style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant)),
                      ],
                    )),
            ),
          ),

          AppSpacing.vGapXl,

          // ── GRADIENT ──
          Text('CULOARE FUNDAL', style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.w700, letterSpacing: 1)),
          AppSpacing.vGapSm,
          SizedBox(
            height: 50,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _gradients.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, index) {
                final g = _gradients[index];
                final isSelected = index == _gradientIndex;
                return GestureDetector(
                  onTap: () => setState(() => _gradientIndex = index),
                  child: Column(
                    children: [
                      Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [g.start, g.end]),
                          shape: BoxShape.circle,
                          border: isSelected ? Border.all(color: theme.colorScheme.onSurface, width: 2.5) : null,
                        ),
                        child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 16) : null,
                      ),
                      Text(g.name, style: TextStyle(fontSize: 8, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400)),
                    ],
                  ),
                );
              },
            ),
          ),

          AppSpacing.vGapXl,

          // ── EFFECTS ──
          Text('EFECT', style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.w700, letterSpacing: 1)),
          AppSpacing.vGapSm,
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _effects.map((e) {
              final isSelected = e.id == _effect;
              return GestureDetector(
                onTap: () => setState(() => _effect = e.id),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? theme.colorScheme.primary.withValues(alpha: 0.12) : null,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? theme.colorScheme.primary : theme.dividerColor,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(e.emoji, style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 6),
                      Text(e.name, style: TextStyle(fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                        color: isSelected ? theme.colorScheme.primary : null)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),

          AppSpacing.vGapXl,

          // ── DATES ──
          Text('PERIOADĂ', style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.w700, letterSpacing: 1)),
          AppSpacing.vGapSm,
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _pickStartDate,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: theme.dividerColor),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(PhosphorIcons.calendar(PhosphorIconsStyle.regular), size: 18, color: theme.colorScheme.onSurfaceVariant),
                        const SizedBox(width: 8),
                        Text('${_startDate.day}/${_startDate.month}/${_startDate.year}', style: const TextStyle(fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text('→', style: TextStyle(fontSize: 18, color: theme.colorScheme.onSurfaceVariant)),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: _pickEndDate,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: theme.dividerColor),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(PhosphorIcons.calendar(PhosphorIconsStyle.regular), size: 18, color: theme.colorScheme.onSurfaceVariant),
                        const SizedBox(width: 8),
                        Text('${_endDate.day}/${_endDate.month}/${_endDate.year}', style: const TextStyle(fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          AppSpacing.vGapXxl,

          // ── SAVE ──
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Icon(PhosphorIcons.check(PhosphorIconsStyle.bold), size: 18),
              label: const Text('Publică Banner'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

// ── Particle Overlay (emoji-based) ──
class _ParticleOverlay extends StatefulWidget {
  const _ParticleOverlay({required this.emoji, this.count = 20});
  final String emoji;
  final int count;

  @override
  State<_ParticleOverlay> createState() => _ParticleOverlayState();
}

class _ParticleOverlayState extends State<_ParticleOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 5))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Stack(
            children: List.generate(widget.count, (i) {
              final seed = i * 137.5;
              final x = ((seed % 100) / 100);
              final startY = ((seed * 3.7 % 100) / 100);
              final t = (_controller.value + startY) % 1.0;
              final opacity = t < 0.1 ? t / 0.1 : t > 0.8 ? (1.0 - t) / 0.2 : 1.0;

              return Positioned(
                left: x * MediaQuery.of(context).size.width * 0.8,
                top: t * 100,
                child: Opacity(
                  opacity: opacity.clamp(0.0, 0.7),
                  child: Text(widget.emoji, style: TextStyle(fontSize: 10 + (seed % 8))),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}

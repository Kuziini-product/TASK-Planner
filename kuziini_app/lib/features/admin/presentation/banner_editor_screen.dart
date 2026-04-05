import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
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
  final String id, name, emoji;
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
  final Color start, end;
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

// ── Font presets ──
enum BannerFont { classic, italic, shadow3d }

TextStyle _fontStyle(BannerFont font, {double size = 17, Color color = Colors.white}) {
  switch (font) {
    case BannerFont.classic:
      return GoogleFonts.inter(fontSize: size, fontWeight: FontWeight.w700, color: color,
        shadows: [const Shadow(color: Colors.black26, blurRadius: 4)]);
    case BannerFont.italic:
      return GoogleFonts.dancingScript(fontSize: size + 4, fontWeight: FontWeight.w700, color: color,
        fontStyle: FontStyle.italic,
        shadows: [const Shadow(color: Colors.black26, blurRadius: 4)]);
    case BannerFont.shadow3d:
      return GoogleFonts.permanentMarker(fontSize: size, color: color,
        shadows: [
          Shadow(color: Colors.black.withValues(alpha: 0.5), offset: const Offset(2, 2), blurRadius: 0),
          Shadow(color: Colors.black.withValues(alpha: 0.3), offset: const Offset(4, 4), blurRadius: 2),
        ]);
  }
}

class BannerEditorScreen extends ConsumerStatefulWidget {
  const BannerEditorScreen({super.key, this.existingBanner});
  final Map<String, dynamic>? existingBanner;

  @override
  ConsumerState<BannerEditorScreen> createState() => _BannerEditorScreenState();
}

class _BannerEditorScreenState extends ConsumerState<BannerEditorScreen> {
  final _titleController = TextEditingController();
  final _subtitleController = TextEditingController();
  String _effect = 'none';
  int _gradientIndex = 0;
  BannerFont _font = BannerFont.classic;
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();
  final List<String> _imageUrls = [];
  final List<Uint8List> _imageBytes = [];
  bool _saving = false;
  bool _isEdit = false;
  String? _editId;
  Offset _textOffset = Offset.zero; // drag position relative to center

  @override
  void initState() {
    super.initState();
    if (widget.existingBanner != null) {
      _loadExisting(widget.existingBanner!);
    }
  }

  void _loadExisting(Map<String, dynamic> b) {
    _isEdit = true;
    _editId = b['id'] as String?;
    _titleController.text = b['title'] as String? ?? '';
    _subtitleController.text = b['subtitle'] as String? ?? '';
    _effect = b['effect'] as String? ?? 'none';
    final fontStr = b['font'] as String? ?? 'classic';
    _font = BannerFont.values.firstWhere((f) => f.name == fontStr, orElse: () => BannerFont.classic);
    // Parse gradient
    final gs = b['gradient_start'] as String?;
    if (gs != null) {
      for (int i = 0; i < _gradients.length; i++) {
        if ('#${_gradients[i].start.value.toRadixString(16).substring(2)}' == gs) {
          _gradientIndex = i;
          break;
        }
      }
    }
    // Parse images
    final imgs = b['image_url'] as String?;
    if (imgs != null && imgs.isNotEmpty) {
      _imageUrls.addAll(imgs.split('|||'));
    }
    // Parse dates
    final sd = b['start_date'] as String?;
    final ed = b['end_date'] as String?;
    if (sd != null) _startDate = DateTime.tryParse(sd) ?? DateTime.now();
    if (ed != null) _endDate = DateTime.tryParse(ed) ?? DateTime.now();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final images = await picker.pickMultiImage(maxWidth: 400);
    if (images.isEmpty) {
      // Fallback: single image picker
      final single = await picker.pickImage(source: ImageSource.gallery, maxWidth: 400);
      if (single != null) {
        await _uploadSingleImage(single);
      }
      return;
    }
    for (final image in images) {
      await _uploadSingleImage(image);
    }
  }

  Future<void> _uploadSingleImage(XFile image) async {
    final bytes = await image.readAsBytes();
    try {
      final fileName = '${const Uuid().v4()}.${image.name.split('.').last}';
      await Supabase.instance.client.storage
          .from('banners')
          .uploadBinary(fileName, bytes, fileOptions: const FileOptions(upsert: true));
      final url = Supabase.instance.client.storage.from('banners').getPublicUrl(fileName);
      setState(() {
        _imageUrls.add(url);
        _imageBytes.add(bytes);
      });
    } catch (e) {
      if (mounted) context.showSnackBar('Upload failed: $e', isError: true);
    }
  }

  void _removeImage(int index) {
    setState(() {
      if (index < _imageUrls.length) _imageUrls.removeAt(index);
      if (index < _imageBytes.length) _imageBytes.removeAt(index);
    });
  }

  Future<void> _pickStartDate() async {
    final date = await showDatePicker(context: context, initialDate: _startDate,
      firstDate: DateTime.now().subtract(const Duration(days: 7)),
      lastDate: DateTime.now().add(const Duration(days: 365)));
    if (date != null) setState(() => _startDate = date);
  }

  Future<void> _pickEndDate() async {
    final date = await showDatePicker(context: context,
      initialDate: _endDate.isBefore(_startDate) ? _startDate : _endDate,
      firstDate: _startDate, lastDate: DateTime.now().add(const Duration(days: 365)));
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
      final data = {
        'title': _titleController.text.trim(),
        'subtitle': _subtitleController.text.trim().isEmpty ? null : _subtitleController.text.trim(),
        'image_url': _imageUrls.isNotEmpty ? _imageUrls.join('|||') : null,
        'effect': _effect,
        'font': _font.name,
        'gradient_start': '#${gradient.start.value.toRadixString(16).substring(2)}',
        'gradient_end': '#${gradient.end.value.toRadixString(16).substring(2)}',
        'text_color': '#FFFFFF',
        'start_date': '${_startDate.year}-${_startDate.month.toString().padLeft(2, '0')}-${_startDate.day.toString().padLeft(2, '0')}',
        'end_date': '${_endDate.year}-${_endDate.month.toString().padLeft(2, '0')}-${_endDate.day.toString().padLeft(2, '0')}',
        'is_active': true,
      };

      if (_isEdit && _editId != null) {
        await Supabase.instance.client.from('custom_banners').update(data).eq('id', _editId!);
      } else {
        data['created_by'] = Supabase.instance.client.auth.currentUser!.id;
        await Supabase.instance.client.from('custom_banners').insert(data);
      }

      if (mounted) {
        context.showSnackBar(_isEdit ? 'Banner actualizat!' : 'Banner creat!');
        Navigator.pop(context, true);
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
      appBar: KuziiniAppBar(showBackButton: true, title: _isEdit ? 'Editare Banner' : 'Creare Banner'),
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
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(minHeight: 90),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [gradient.start, gradient.end],
                      begin: Alignment.topLeft, end: Alignment.bottomRight),
                  ),
                  child: SizedBox(
                    height: 120,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Images as background collage
                        if (_imageUrls.isNotEmpty || _imageBytes.isNotEmpty)
                          Positioned.fill(
                            child: Opacity(opacity: 0.4, child: _buildImageCollage()),
                          ),
                        // Draggable text overlay
                        Positioned(
                          left: 0, right: 0, top: 0, bottom: 0,
                          child: Stack(
                            children: [
                              Positioned(
                                left: _textOffset.dx + 16,
                                top: _textOffset.dy + 16,
                                child: GestureDetector(
                                  onPanUpdate: (d) => setState(() =>
                                    _textOffset = Offset(
                                      _textOffset.dx + d.delta.dx,
                                      _textOffset.dy + d.delta.dy,
                                    )),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.white30, width: 1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (_titleController.text.isNotEmpty)
                                          Text(_titleController.text,
                                            style: _fontStyle(_font, size: 17), textAlign: TextAlign.center),
                                        if (_subtitleController.text.isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 4),
                                            child: Text(_subtitleController.text,
                                              style: _fontStyle(_font, size: 12, color: Colors.white70),
                                              textAlign: TextAlign.center),
                                          ),
                                        if (_titleController.text.isEmpty && _subtitleController.text.isEmpty)
                                          Text('Drag text here', style: TextStyle(color: Colors.white38, fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
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
          _sectionLabel(theme, 'TITLU'),
          TextField(controller: _titleController, onChanged: (_) => setState(() {}),
            decoration: _inputDecor('Ex: La Multi Ani, Echipa!')),

          AppSpacing.vGapMd,

          // ── SUBTITLE ──
          _sectionLabel(theme, 'SUBTITLU (opțional)'),
          TextField(controller: _subtitleController, onChanged: (_) => setState(() {}),
            decoration: _inputDecor('Ex: Sărbători fericite!')),

          AppSpacing.vGapXl,

          // ── FONT ──
          _sectionLabel(theme, 'FONT'),
          Row(
            children: BannerFont.values.map((f) {
              final isSelected = f == _font;
              final label = f == BannerFont.classic ? 'Classic' : f == BannerFont.italic ? 'Italic' : '3D';
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _font = f),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? theme.colorScheme.primary.withValues(alpha: 0.12) : null,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: isSelected ? theme.colorScheme.primary : theme.dividerColor, width: isSelected ? 2 : 1),
                    ),
                    child: Center(child: Text(label, style: _fontStyle(f, size: 14,
                      color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface))),
                  ),
                ),
              );
            }).toList(),
          ),

          AppSpacing.vGapXl,

          // ── IMAGES ──
          _sectionLabel(theme, 'IMAGINI'),
          GestureDetector(
            onTap: _pickImages,
            child: Container(
              height: 80,
              decoration: BoxDecoration(border: Border.all(color: theme.dividerColor), borderRadius: BorderRadius.circular(12)),
              child: (_imageUrls.isEmpty && _imageBytes.isEmpty)
                  ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(PhosphorIcons.images(PhosphorIconsStyle.regular), size: 28, color: theme.colorScheme.onSurfaceVariant),
                      const SizedBox(height: 4),
                      Text('Tap pentru a adăuga imagini', style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant)),
                    ]))
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.all(8),
                      itemCount: max(_imageBytes.length, _imageUrls.length) + 1,
                      itemBuilder: (_, i) {
                        if (i == max(_imageBytes.length, _imageUrls.length)) {
                          // Add more button
                          return GestureDetector(
                            onTap: _pickImages,
                            child: Container(width: 60, margin: const EdgeInsets.only(right: 6),
                              decoration: BoxDecoration(border: Border.all(color: theme.dividerColor), borderRadius: BorderRadius.circular(8)),
                              child: Icon(PhosphorIcons.plus(PhosphorIconsStyle.regular), color: theme.colorScheme.onSurfaceVariant)),
                          );
                        }
                        return Stack(
                          children: [
                            Container(
                              width: 60, height: 60, margin: const EdgeInsets.only(right: 6),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: i < _imageBytes.length
                                    ? Image.memory(_imageBytes[i], fit: BoxFit.cover)
                                    : Image.network(_imageUrls[i], fit: BoxFit.cover),
                              ),
                            ),
                            Positioned(top: 0, right: 6, child: GestureDetector(
                              onTap: () => _removeImage(i),
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                child: const Icon(Icons.close, size: 12, color: Colors.white),
                              ),
                            )),
                          ],
                        );
                      },
                    ),
            ),
          ),

          AppSpacing.vGapXl,

          // ── GRADIENT ──
          _sectionLabel(theme, 'CULOARE FUNDAL'),
          SizedBox(
            height: 50,
            child: ListView.separated(
              scrollDirection: Axis.horizontal, itemCount: _gradients.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final g = _gradients[i];
                final sel = i == _gradientIndex;
                return GestureDetector(
                  onTap: () => setState(() => _gradientIndex = i),
                  child: Column(children: [
                    Container(width: 36, height: 36, decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [g.start, g.end]), shape: BoxShape.circle,
                      border: sel ? Border.all(color: theme.colorScheme.onSurface, width: 2.5) : null),
                      child: sel ? const Icon(Icons.check, color: Colors.white, size: 16) : null),
                    Text(g.name, style: TextStyle(fontSize: 8, fontWeight: sel ? FontWeight.w700 : FontWeight.w400)),
                  ]),
                );
              },
            ),
          ),

          AppSpacing.vGapXl,

          // ── EFFECTS ──
          _sectionLabel(theme, 'EFECT'),
          Wrap(spacing: 8, runSpacing: 8, children: _effects.map((e) {
            final sel = e.id == _effect;
            return GestureDetector(
              onTap: () => setState(() => _effect = e.id),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: sel ? theme.colorScheme.primary.withValues(alpha: 0.12) : null,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: sel ? theme.colorScheme.primary : theme.dividerColor, width: sel ? 2 : 1)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(e.emoji, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 6),
                  Text(e.name, style: TextStyle(fontSize: 12, fontWeight: sel ? FontWeight.w700 : FontWeight.w400,
                    color: sel ? theme.colorScheme.primary : null)),
                ]),
              ),
            );
          }).toList()),

          AppSpacing.vGapXl,

          // ── DATES ──
          _sectionLabel(theme, 'PERIOADĂ'),
          Row(children: [
            Expanded(child: GestureDetector(onTap: _pickStartDate, child: _dateBox(theme, _startDate))),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text('→', style: TextStyle(fontSize: 18, color: theme.colorScheme.onSurfaceVariant))),
            Expanded(child: GestureDetector(onTap: _pickEndDate, child: _dateBox(theme, _endDate))),
          ]),

          AppSpacing.vGapXxl,

          // ── SAVE ──
          SizedBox(width: double.infinity, child: FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Icon(PhosphorIcons.check(PhosphorIconsStyle.bold), size: 18),
            label: Text(_isEdit ? 'Actualizează' : 'Publică Banner'),
            style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
          )),

          AppSpacing.vGapXl,

          // ── LIBRARY ──
          _sectionLabel(theme, 'BIBLIOTECA BANNERELOR'),
          AppSpacing.vGapSm,
          _BannerLibrary(onEdit: (banner) {
            Navigator.pushReplacement(context, MaterialPageRoute(
              builder: (_) => BannerEditorScreen(existingBanner: banner)));
          }),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildImageCollage() {
    if (_imageUrls.isEmpty) return const SizedBox.shrink();
    final count = _imageUrls.length;

    Widget buildImg(int i) {
      // Prefer bytes (local preview), fallback to url
      if (i < _imageBytes.length) {
        return Image.memory(_imageBytes[i], fit: BoxFit.cover, width: double.infinity, height: 120);
      }
      return Image.network(_imageUrls[i], fit: BoxFit.cover, width: double.infinity, height: 120,
        errorBuilder: (_, __, ___) => const SizedBox.shrink());
    }

    if (count == 1) return buildImg(0);
    if (count == 2) {
      return Row(children: [Expanded(child: buildImg(0)), const SizedBox(width: 2), Expanded(child: buildImg(1))]);
    }
    if (count == 3) {
      return Row(children: [
        Expanded(flex: 2, child: buildImg(0)),
        const SizedBox(width: 2),
        Expanded(child: Column(children: [
          Expanded(child: buildImg(1)), const SizedBox(height: 2), Expanded(child: buildImg(2)),
        ])),
      ]);
    }
    // 4+ images: 2x2 grid
    return Column(children: [
      Expanded(child: Row(children: [
        Expanded(child: buildImg(0)), const SizedBox(width: 2), Expanded(child: buildImg(1)),
      ])),
      const SizedBox(height: 2),
      Expanded(child: Row(children: [
        Expanded(child: buildImg(min(2, count - 1))), const SizedBox(width: 2),
        Expanded(child: Stack(children: [
          buildImg(min(3, count - 1)),
          if (count > 4) Positioned.fill(child: Container(
            color: Colors.black38,
            child: Center(child: Text('+${count - 4}', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700))),
          )),
        ])),
      ])),
    ]);
  }

  Widget _sectionLabel(ThemeData theme, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(text, style: theme.textTheme.labelSmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.w700, letterSpacing: 1)),
  );

  InputDecoration _inputDecor(String hint) => InputDecoration(
    hintText: hint, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)));

  Widget _dateBox(ThemeData theme, DateTime date) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(border: Border.all(color: theme.dividerColor), borderRadius: BorderRadius.circular(12)),
    child: Row(children: [
      Icon(PhosphorIcons.calendar(PhosphorIconsStyle.regular), size: 18, color: theme.colorScheme.onSurfaceVariant),
      const SizedBox(width: 8),
      Text('${date.day}/${date.month}/${date.year}', style: const TextStyle(fontWeight: FontWeight.w500)),
    ]),
  );
}

// ── Banner Library ──

class _BannerLibrary extends StatefulWidget {
  const _BannerLibrary({required this.onEdit});
  final ValueChanged<Map<String, dynamic>> onEdit;

  @override
  State<_BannerLibrary> createState() => _BannerLibraryState();
}

class _BannerLibraryState extends State<_BannerLibrary> {
  List<Map<String, dynamic>> _banners = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final response = await Supabase.instance.client
          .from('custom_banners')
          .select('*')
          .order('created_at', ascending: false);
      if (mounted) setState(() { _banners = List<Map<String, dynamic>>.from(response as List); _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _delete(String id) async {
    await Supabase.instance.client.from('custom_banners').delete().eq('id', id);
    _load();
  }

  Future<void> _toggleActive(String id, bool active) async {
    await Supabase.instance.client.from('custom_banners').update({'is_active': active}).eq('id', id);
    _load();
  }

  Color _parseColor(String? hex, Color fallback) {
    if (hex == null || hex.length < 7) return fallback;
    try { return Color(int.parse(hex.substring(1), radix: 16) + 0xFF000000); } catch (_) { return fallback; }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_banners.isEmpty) return Text('Niciun banner salvat', style: TextStyle(color: theme.colorScheme.onSurfaceVariant));

    return Column(
      children: _banners.map((b) {
        final gs = _parseColor(b['gradient_start'] as String?, const Color(0xFFFF6B9D));
        final ge = _parseColor(b['gradient_end'] as String?, const Color(0xFFFFA751));
        final active = b['is_active'] as bool? ?? false;

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12),
            border: Border.all(color: active ? theme.colorScheme.primary : theme.dividerColor, width: active ? 2 : 1)),
          child: Column(children: [
            // Mini preview
            Container(
              width: double.infinity, height: 50,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [gs, ge]),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(11))),
              child: Center(child: Text(b['title'] as String? ?? '',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13))),
            ),
            // Actions
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(children: [
                if (active)
                  Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                    child: Text('ACTIV', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.success)))
                else
                  Text('Inactiv', style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurfaceVariant)),
                const Spacer(),
                IconButton(icon: Icon(active ? PhosphorIcons.eyeSlash(PhosphorIconsStyle.regular) : PhosphorIcons.eye(PhosphorIconsStyle.regular), size: 18),
                  onPressed: () => _toggleActive(b['id'] as String, !active), tooltip: active ? 'Dezactivează' : 'Activează',
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32), padding: EdgeInsets.zero),
                IconButton(icon: Icon(PhosphorIcons.pencilSimple(PhosphorIconsStyle.regular), size: 18, color: theme.colorScheme.primary),
                  onPressed: () => widget.onEdit(b), tooltip: 'Editează',
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32), padding: EdgeInsets.zero),
                IconButton(icon: Icon(PhosphorIcons.trash(PhosphorIconsStyle.regular), size: 18, color: AppColors.error),
                  onPressed: () => _delete(b['id'] as String), tooltip: 'Șterge',
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32), padding: EdgeInsets.zero),
              ]),
            ),
          ]),
        );
      }).toList(),
    );
  }
}

// ── Particle Overlay ──
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
  void dispose() { _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => Stack(
          children: List.generate(widget.count, (i) {
            final seed = i * 137.5;
            final x = (seed % 100) / 100;
            final startY = (seed * 3.7 % 100) / 100;
            final t = (_controller.value + startY) % 1.0;
            final opacity = t < 0.1 ? t / 0.1 : t > 0.8 ? (1.0 - t) / 0.2 : 1.0;
            return Positioned(
              left: x * (MediaQuery.of(context).size.width * 0.8),
              top: t * 100,
              child: Opacity(opacity: opacity.clamp(0.0, 0.7),
                child: Text(widget.emoji, style: TextStyle(fontSize: 10 + (seed % 8)))),
            );
          }),
        ),
      ),
    );
  }
}

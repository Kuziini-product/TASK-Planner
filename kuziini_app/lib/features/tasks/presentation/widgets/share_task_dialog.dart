import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/utils/extensions.dart';
import '../../data/models/task_model.dart';
import '../../data/models/task_comment.dart';

void showShareTaskDialog(
  BuildContext context,
  TaskModel task,
  List<TaskComment> comments,
) {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) => _ShareTaskSheet(task: task, comments: comments),
  );
}

class _ShareTaskSheet extends StatefulWidget {
  const _ShareTaskSheet({required this.task, required this.comments});

  final TaskModel task;
  final List<TaskComment> comments;

  @override
  State<_ShareTaskSheet> createState() => _ShareTaskSheetState();
}

class _ShareTaskSheetState extends State<_ShareTaskSheet> {
  bool _includeDetails = true;
  bool _includeLocation = true;
  bool _includeComments = false;

  String _buildShareText() {
    final buf = StringBuffer();

    buf.writeln('\u{1F4CB} *Task: ${widget.task.title}*');

    if (_includeDetails &&
        widget.task.description != null &&
        widget.task.description!.isNotEmpty) {
      buf.writeln(widget.task.description!);
    }

    if (_includeLocation && widget.task.hasLocation) {
      buf.writeln();
      buf.write('\u{1F4CD} *Location:* ${widget.task.locationDisplay}');
      if (widget.task.locationAddress != null &&
          widget.task.locationAddress!.isNotEmpty &&
          widget.task.locationAddress != widget.task.locationDisplay) {
        buf.writeln();
        buf.write(widget.task.locationAddress!);
      }
      final mapUrl = widget.task.locationMapUrl;
      if (mapUrl != null) {
        buf.writeln();
        buf.write(mapUrl);
      }
    }

    if (_includeComments && widget.comments.isNotEmpty) {
      buf.writeln();
      buf.writeln();
      buf.writeln('\u{1F4AC} *Messages:*');
      for (final c in widget.comments) {
        final name = c.userName ?? 'User';
        buf.writeln('$name: ${c.content}');
      }
    }

    buf.writeln();
    buf.write('\u{2014} Sent from Kuziini Task Manager');
    return buf.toString();
  }

  void _shareViaWhatsApp() {
    final text = _buildShareText();
    final whatsappUrl = 'https://wa.me/?text=${Uri.encodeComponent(text)}';
    launchUrl(Uri.parse(whatsappUrl), mode: LaunchMode.externalApplication);
    Navigator.pop(context);
  }

  void _copyToClipboard() {
    final text = _buildShareText();
    Clipboard.setData(ClipboardData(text: text));
    Navigator.pop(context);
    context.showSnackBar('Copied to clipboard');
  }

  void _nativeShare() {
    final text = _buildShareText();
    Share.share(text);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return SafeArea(
      child: Padding(
        padding: AppSpacing.paddingLg,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: theme.dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            Text(
              'Share Task',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            AppSpacing.vGapMd,

            // Checkboxes
            CheckboxListTile(
              value: _includeDetails,
              onChanged: (v) => setState(() => _includeDetails = v ?? true),
              title: const Text('Share title & description'),
              activeColor: primaryColor,
              controlAffinity: ListTileControlAffinity.leading,
              dense: true,
              contentPadding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
            ),

            if (widget.task.hasLocation)
              CheckboxListTile(
                value: _includeLocation,
                onChanged: (v) =>
                    setState(() => _includeLocation = v ?? true),
                title: const Text('Share location'),
                activeColor: primaryColor,
                controlAffinity: ListTileControlAffinity.leading,
                dense: true,
                contentPadding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              ),

            if (widget.comments.isNotEmpty)
              CheckboxListTile(
                value: _includeComments,
                onChanged: (v) =>
                    setState(() => _includeComments = v ?? false),
                title: const Text('Share comments/messages'),
                activeColor: primaryColor,
                controlAffinity: ListTileControlAffinity.leading,
                dense: true,
                contentPadding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              ),

            AppSpacing.vGapLg,

            // Share via label
            Text(
              'Share via',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            AppSpacing.vGapMd,

            // Share buttons
            Row(
              children: [
                // WhatsApp
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _shareViaWhatsApp,
                    icon: Icon(
                      PhosphorIcons.whatsappLogo(PhosphorIconsStyle.regular),
                      size: 20,
                      color: const Color(0xFF25D366),
                    ),
                    label: const Text('WhatsApp'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                AppSpacing.hGapMd,
                // Copy
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _copyToClipboard,
                    icon: Icon(
                      PhosphorIcons.copy(PhosphorIconsStyle.regular),
                      size: 20,
                    ),
                    label: const Text('Copy'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                AppSpacing.hGapMd,
                // Native share
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _nativeShare,
                    icon: Icon(
                      PhosphorIcons.shareFat(PhosphorIconsStyle.regular),
                      size: 20,
                    ),
                    label: const Text('More'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            AppSpacing.vGapMd,
          ],
        ),
      ),
    );
  }
}

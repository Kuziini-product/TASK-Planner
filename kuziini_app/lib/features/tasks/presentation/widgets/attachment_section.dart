import 'dart:async';
import 'dart:js_util' as js_util;
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/utils/extensions.dart';
import '../../data/models/task_attachment.dart';
import '../../providers/tasks_provider.dart';

class AttachmentSection extends ConsumerStatefulWidget {
  const AttachmentSection({super.key, required this.taskId});

  final String taskId;

  @override
  ConsumerState<AttachmentSection> createState() => _AttachmentSectionState();
}

class _AttachmentSectionState extends ConsumerState<AttachmentSection> {
  bool _isUploading = false;

  // ── Upload handlers ──

  Future<void> _pickImageFromGallery() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        imageQuality: 80,
      );
      if (image == null) return;

      final bytes = await image.readAsBytes();
      await _uploadFile(
        bytes: bytes,
        fileName: image.name,
        mimeType: 'image/${image.name.split('.').last.toLowerCase()}',
      );
    } catch (e) {
      if (mounted) {
        context.showSnackBar('Failed to pick image', isError: true);
      }
    }
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        imageQuality: 80,
      );
      if (image == null) return;

      final bytes = await image.readAsBytes();
      await _uploadFile(
        bytes: bytes,
        fileName: image.name,
        mimeType: 'image/${image.name.split('.').last.toLowerCase()}',
      );
    } catch (e) {
      if (mounted) {
        context.showSnackBar('Failed to take photo', isError: true);
      }
    }
  }

  Future<void> _pickDocument() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          'pdf', 'doc', 'docx', 'xls', 'xlsx', 'txt', 'csv',
        ],
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      final bytes = file.bytes;
      if (bytes == null) {
        if (mounted) {
          context.showSnackBar('Could not read file data', isError: true);
        }
        return;
      }

      final ext = file.extension?.toLowerCase() ?? '';
      String mimeType;
      switch (ext) {
        case 'pdf':
          mimeType = 'application/pdf';
          break;
        case 'doc':
          mimeType = 'application/msword';
          break;
        case 'docx':
          mimeType =
              'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
          break;
        case 'xls':
          mimeType = 'application/vnd.ms-excel';
          break;
        case 'xlsx':
          mimeType =
              'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
          break;
        case 'csv':
          mimeType = 'text/csv';
          break;
        case 'txt':
          mimeType = 'text/plain';
          break;
        default:
          mimeType = 'application/octet-stream';
      }

      await _uploadFile(
        bytes: bytes,
        fileName: file.name,
        mimeType: mimeType,
      );
    } catch (e) {
      if (mounted) {
        context.showSnackBar('Failed to pick document', isError: true);
      }
    }
  }

  Future<void> _uploadFile({
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
  }) async {
    final maxSize = AppConstants.maxAttachmentSizeMB * 1024 * 1024;
    if (bytes.length > maxSize) {
      if (mounted) {
        context.showSnackBar(
          'File too large (max ${AppConstants.maxAttachmentSizeMB}MB)',
          isError: true,
        );
      }
      return;
    }

    setState(() => _isUploading = true);

    try {
      final repo = ref.read(taskRepositoryProvider);
      final userId = SupabaseService.instance.currentUserId!;
      await repo.uploadAttachment(
        taskId: widget.taskId,
        userId: userId,
        fileBytes: bytes,
        fileName: fileName,
      );
      ref.invalidate(taskAttachmentsProvider(widget.taskId));
      if (mounted) {
        context.showSnackBar('File uploaded successfully');
      }
    } catch (e) {
      if (mounted) {
        context.showSnackBar('Upload failed: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _shareLocation() async {
    final addressController = TextEditingController();
    final linkController = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.location_on, color: AppColors.primary, size: 24),
              const SizedBox(width: 8),
              const Text('Share Location'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Address field
              TextField(
                controller: addressController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Location name or address',
                  prefixIcon: const Icon(Icons.place_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                ),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              // Link field
              TextField(
                controller: linkController,
                decoration: InputDecoration(
                  hintText: 'Google Maps link (optional)',
                  prefixIcon: const Icon(Icons.link),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                ),
                textInputAction: TextInputAction.done,
                onSubmitted: (_) {
                  final address = addressController.text.trim();
                  final link = linkController.text.trim();
                  if (address.isNotEmpty || link.isNotEmpty) {
                    Navigator.of(ctx).pop(_formatLocation(address, link));
                  }
                },
              ),
              const SizedBox(height: 12),
              // Quick actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        // Open Google Maps to get link
                        launchUrl(Uri.parse('https://www.google.com/maps'), mode: LaunchMode.externalApplication);
                      },
                      icon: const Icon(Icons.map_outlined, size: 16),
                      label: const Text('Open Maps', style: TextStyle(fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        // Use browser geolocation
                        _getCurrentLocation(ctx, addressController, linkController);
                      },
                      icon: const Icon(Icons.my_location, size: 16),
                      label: const Text('My Location', style: TextStyle(fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton.icon(
              onPressed: () {
                final address = addressController.text.trim();
                final link = linkController.text.trim();
                if (address.isNotEmpty || link.isNotEmpty) {
                  Navigator.of(ctx).pop(_formatLocation(address, link));
                }
              },
              icon: const Icon(Icons.send, size: 16),
              label: const Text('Share'),
            ),
          ],
        );
      },
    );

    if (result == null || result.isEmpty) return;

    // Post as a location comment
    try {
      final repo = ref.read(taskRepositoryProvider);
      final userId = SupabaseService.instance.currentUserId!;
      await repo.addComment(
        taskId: widget.taskId,
        userId: userId,
        content: result,
      );
      ref.invalidate(taskCommentsProvider(widget.taskId));
      if (mounted) {
        context.showSnackBar('Location shared');
      }
    } catch (e) {
      if (mounted) {
        context.showSnackBar('Failed to share location', isError: true);
      }
    }
  }

  String _formatLocation(String address, String link) {
    final buffer = StringBuffer('\u{1F4CD} ');
    if (address.isNotEmpty) buffer.write(address);
    if (link.isNotEmpty) {
      if (address.isNotEmpty) buffer.write('\n');
      buffer.write(link);
    }
    return buffer.toString();
  }

  void _getCurrentLocation(BuildContext dialogContext, TextEditingController addressCtrl, TextEditingController linkCtrl) {
    try {
      // Use dart:js_util for web geolocation
      _getWebGeolocation().then((coords) {
        if (coords != null) {
          final lat = coords['lat']!;
          final lng = coords['lng']!;
          addressCtrl.text = 'My Location ($lat, $lng)';
          linkCtrl.text = 'https://www.google.com/maps?q=$lat,$lng';
        }
      }).catchError((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not get location. Allow location access in browser.')),
          );
        }
      });
    } catch (_) {}
  }

  Future<Map<String, double>?> _getWebGeolocation() async {
    try {
      // ignore: avoid_dynamic_calls
      final dynamic js = await _jsGeolocation();
      if (js != null) return js;
    } catch (_) {}
    return null;
  }

  Future<Map<String, double>?> _jsGeolocation() async {
    // Use dart:js_util to call navigator.geolocation.getCurrentPosition
    final completer = Completer<Map<String, double>?>();
    try {
      final nav = js_util.getProperty(js_util.globalThis, 'navigator');
      final geo = js_util.getProperty(nav, 'geolocation');
      js_util.callMethod(geo, 'getCurrentPosition', [
        js_util.allowInterop((pos) {
          final coords = js_util.getProperty(pos, 'coords');
          final lat = js_util.getProperty<num>(coords, 'latitude').toDouble();
          final lng = js_util.getProperty<num>(coords, 'longitude').toDouble();
          completer.complete({'lat': lat, 'lng': lng});
        }),
        js_util.allowInterop((err) {
          completer.complete(null);
        }),
      ]);
    } catch (_) {
      completer.complete(null);
    }
    return completer.future;
  }

  void _showAddOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(ctx).dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Add Attachment',
                style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            AppSpacing.vGapMd,
            if (!kIsWeb)
              ListTile(
                leading: Icon(
                    PhosphorIcons.camera(PhosphorIconsStyle.regular)),
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImageFromCamera();
                },
              ),
            ListTile(
              leading:
                  Icon(PhosphorIcons.image(PhosphorIconsStyle.regular)),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImageFromGallery();
              },
            ),
            ListTile(
              leading:
                  Icon(PhosphorIcons.file(PhosphorIconsStyle.regular)),
              title: const Text('Upload Document'),
              subtitle: const Text('PDF, Word, Excel, TXT, CSV'),
              onTap: () {
                Navigator.pop(ctx);
                _pickDocument();
              },
            ),
            ListTile(
              leading: Icon(
                  PhosphorIcons.mapPin(PhosphorIconsStyle.regular)),
              title: const Text('Share Location'),
              onTap: () {
                Navigator.pop(ctx);
                _shareLocation();
              },
            ),
            AppSpacing.vGapMd,
          ],
        ),
      ),
    );
  }

  Future<void> _deleteAttachment(TaskAttachment attachment) async {
    try {
      final repo = ref.read(taskRepositoryProvider);
      await repo.deleteAttachment(attachment);
      ref.invalidate(taskAttachmentsProvider(widget.taskId));
      if (mounted) {
        context.showSnackBar('Attachment deleted');
      }
    } catch (e) {
      if (mounted) {
        context.showSnackBar('Failed to delete attachment', isError: true);
      }
    }
  }

  Future<void> _openAttachment(TaskAttachment attachment) async {
    if (attachment.isImage) {
      _showImageViewer(attachment);
    } else {
      // Open document via signed URL
      try {
        final uri = Uri.parse(attachment.fileUrl);
        final storagePath = uri.pathSegments
            .skipWhile((s) => s != 'object')
            .skip(2) // skip 'object' and 'public'/'sign'
            .join('/');

        // For public URLs, just launch directly
        final url = Uri.parse(attachment.fileUrl);
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        } else {
          if (mounted) {
            context.showSnackBar('Could not open file', isError: true);
          }
        }
      } catch (e) {
        if (mounted) {
          context.showSnackBar('Could not open file', isError: true);
        }
      }
    }
  }

  void _showImageViewer(TaskAttachment attachment) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog.fullscreen(
        child: Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            title: Text(
              attachment.fileName,
              style: const TextStyle(fontSize: 14, color: Colors.white70),
            ),
            leading: IconButton(
              onPressed: () => Navigator.pop(ctx),
              icon: const Icon(Icons.close, color: Colors.white),
            ),
          ),
          body: Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.network(
                attachment.fileUrl,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: progress.expectedTotalBytes != null
                          ? progress.cumulativeBytesLoaded /
                              progress.expectedTotalBytes!
                          : null,
                      color: Colors.white,
                    ),
                  );
                },
                errorBuilder: (_, __, ___) => const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.broken_image, color: Colors.white54, size: 64),
                    SizedBox(height: 16),
                    Text('Failed to load image',
                        style: TextStyle(color: Colors.white54)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Build ──

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final attachmentsAsync =
        ref.watch(taskAttachmentsProvider(widget.taskId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(
          children: [
            Icon(PhosphorIcons.paperclip(PhosphorIconsStyle.regular),
                size: 20),
            AppSpacing.hGapSm,
            Text('Attachments', style: theme.textTheme.titleSmall),
            attachmentsAsync.whenOrNull(
              data: (list) => list.isNotEmpty
                  ? Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${list.length}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    )
                  : null,
            ) ?? const SizedBox.shrink(),
            const Spacer(),
            if (_isUploading)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              IconButton(
                onPressed: _showAddOptions,
                icon: Icon(
                  PhosphorIcons.plus(PhosphorIconsStyle.bold),
                  size: 18,
                ),
                tooltip: 'Add attachment',
                padding: EdgeInsets.zero,
                constraints:
                    const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
          ],
        ),
        AppSpacing.vGapMd,

        attachmentsAsync.when(
          data: (attachments) {
            if (attachments.isEmpty) {
              return _EmptyAttachments(onAdd: _showAddOptions);
            }

            final images =
                attachments.where((a) => a.isImage).toList();
            final documents =
                attachments.where((a) => !a.isImage).toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Photo grid
                if (images.isNotEmpty) ...[
                  _PhotoGrid(
                    images: images,
                    onTap: _openAttachment,
                    onDelete: _deleteAttachment,
                  ),
                  if (documents.isNotEmpty) AppSpacing.vGapMd,
                ],

                // Document list
                if (documents.isNotEmpty)
                  _DocumentList(
                    documents: documents,
                    onTap: _openAttachment,
                    onDelete: _deleteAttachment,
                  ),
              ],
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
          error: (_, __) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Failed to load attachments',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.error,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Empty state ──

class _EmptyAttachments extends StatelessWidget {
  const _EmptyAttachments({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onAdd,
      borderRadius: AppSpacing.borderRadiusMd,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          border: Border.all(
            color: theme.dividerColor,
            style: BorderStyle.solid,
          ),
          borderRadius: AppSpacing.borderRadiusMd,
        ),
        child: Column(
          children: [
            Icon(
              PhosphorIcons.uploadSimple(PhosphorIconsStyle.regular),
              size: 32,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            AppSpacing.vGapSm,
            Text(
              'No attachments yet',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            AppSpacing.vGapXs,
            Text(
              'Tap to add photos, documents, or location',
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

// ── Photo grid ──

class _PhotoGrid extends StatelessWidget {
  const _PhotoGrid({
    required this.images,
    required this.onTap,
    required this.onDelete,
  });

  final List<TaskAttachment> images;
  final ValueChanged<TaskAttachment> onTap;
  final ValueChanged<TaskAttachment> onDelete;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: images.length,
      itemBuilder: (context, index) {
        final attachment = images[index];
        return _PhotoThumbnail(
          attachment: attachment,
          onTap: () => onTap(attachment),
          onDelete: () => onDelete(attachment),
        );
      },
    );
  }
}

class _PhotoThumbnail extends StatelessWidget {
  const _PhotoThumbnail({
    required this.attachment,
    required this.onTap,
    required this.onDelete,
  });

  final TaskAttachment attachment;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: AppSpacing.borderRadiusSm,
            child: Image.network(
              attachment.thumbnailUrl ?? attachment.fileUrl,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return Container(
                  color: theme.colorScheme.surfaceContainerHighest,
                  child: const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                );
              },
              errorBuilder: (_, __, ___) => Container(
                color: theme.colorScheme.surfaceContainerHighest,
                child: Icon(
                  PhosphorIcons.imageBroken(PhosphorIconsStyle.regular),
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
          // Delete button
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: onDelete,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  size: 14,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Document list ──

class _DocumentList extends StatelessWidget {
  const _DocumentList({
    required this.documents,
    required this.onTap,
    required this.onDelete,
  });

  final List<TaskAttachment> documents;
  final ValueChanged<TaskAttachment> onTap;
  final ValueChanged<TaskAttachment> onDelete;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: documents
          .map((doc) => _DocumentTile(
                attachment: doc,
                onTap: () => onTap(doc),
                onDelete: () => onDelete(doc),
              ))
          .toList(),
    );
  }
}

class _DocumentTile extends StatelessWidget {
  const _DocumentTile({
    required this.attachment,
    required this.onTap,
    required this.onDelete,
  });

  final TaskAttachment attachment;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  IconData _iconForExtension(String ext) {
    switch (ext.toLowerCase()) {
      case 'pdf':
        return PhosphorIcons.filePdf(PhosphorIconsStyle.regular);
      case 'doc':
      case 'docx':
        return PhosphorIcons.fileDoc(PhosphorIconsStyle.regular);
      case 'xls':
      case 'xlsx':
        return PhosphorIcons.fileXls(PhosphorIconsStyle.regular);
      case 'csv':
        return PhosphorIcons.fileCsv(PhosphorIconsStyle.regular);
      case 'txt':
        return PhosphorIcons.fileText(PhosphorIconsStyle.regular);
      default:
        return PhosphorIcons.file(PhosphorIconsStyle.regular);
    }
  }

  Color _colorForExtension(String ext) {
    switch (ext.toLowerCase()) {
      case 'pdf':
        return AppColors.error;
      case 'doc':
      case 'docx':
        return AppColors.info;
      case 'xls':
      case 'xlsx':
        return AppColors.success;
      default:
        return AppColors.secondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ext = attachment.fileExtension;

    return InkWell(
      onTap: onTap,
      borderRadius: AppSpacing.borderRadiusSm,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _colorForExtension(ext).withValues(alpha: 0.1),
                borderRadius: AppSpacing.borderRadiusSm,
              ),
              child: Icon(
                _iconForExtension(ext),
                size: 20,
                color: _colorForExtension(ext),
              ),
            ),
            AppSpacing.hGapMd,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    attachment.fileName,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (attachment.fileSizeFormatted.isNotEmpty)
                    Text(
                      '${ext.toUpperCase()} \u2022 ${attachment.fileSizeFormatted}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            IconButton(
              onPressed: onDelete,
              icon: Icon(
                PhosphorIcons.trash(PhosphorIconsStyle.regular),
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              padding: EdgeInsets.zero,
              constraints:
                  const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ],
        ),
      ),
    );
  }
}

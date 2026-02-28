import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/constants/api_constants.dart';
import '../../documents/providers/documents_provider.dart';
import '../providers/upload_provider.dart';

/// The Upload Document screen (PRD F-4).
///
/// Provides a form to pick a file, set a title and year, then upload the
/// document to the server. Shows progress during upload and a success
/// message upon completion.
class UploadScreen extends ConsumerStatefulWidget {
  const UploadScreen({super.key});

  @override
  ConsumerState<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends ConsumerState<UploadScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _yearController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _yearController = TextEditingController(text: DateTime.now().year.toString());

    // Reset upload state when the screen opens.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(uploadProvider.notifier).reset();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uploadState = ref.watch(uploadProvider);
    final notifier = ref.read(uploadProvider.notifier);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Sync title controller when file is picked (pre-populate).
    ref.listen<UploadState>(uploadProvider, (prev, next) {
      if (prev?.selectedFile != next.selectedFile && next.selectedFile != null) {
        _titleController.text = next.title;
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Document'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: uploadState.isUploading ? null : () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ---- File picker area ----
              _FilePickerArea(
                uploadState: uploadState,
                onTap: uploadState.isUploading ? null : () => notifier.pickFile(),
              ),
              const SizedBox(height: 24),

              // ---- Title field ----
              TextFormField(
                controller: _titleController,
                enabled: !uploadState.isUploading,
                decoration: const InputDecoration(
                  labelText: 'Document Title',
                  hintText: 'Enter a descriptive title',
                  border: OutlineInputBorder(),
                ),
                maxLength: ApiConstants.maxTitleLength,
                onChanged: notifier.setTitle,
                validator: (value) {
                  if (value == null || value.length < ApiConstants.minTitleLength) {
                    return 'Title must be at least ${ApiConstants.minTitleLength} characters.';
                  }
                  if (value.length > ApiConstants.maxTitleLength) {
                    return 'Title must be at most ${ApiConstants.maxTitleLength} characters.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // ---- Year field ----
              TextFormField(
                controller: _yearController,
                enabled: !uploadState.isUploading,
                decoration: const InputDecoration(
                  labelText: 'Year',
                  hintText: 'e.g. 2025',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                ],
                onChanged: (value) {
                  final parsed = int.tryParse(value);
                  if (parsed != null) notifier.setYear(parsed);
                },
                validator: (value) {
                  final year = int.tryParse(value ?? '');
                  if (year == null) return 'Please enter a valid year.';
                  if (year < ApiConstants.minYear || year > ApiConstants.maxYear) {
                    return 'Year must be between ${ApiConstants.minYear} and ${ApiConstants.maxYear}.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // ---- Upload error ----
              if (uploadState.error != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: colorScheme.onErrorContainer,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          uploadState.error!,
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onErrorContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // ---- Progress indicator ----
              if (uploadState.isUploading) ...[
                const LinearProgressIndicator(),
                const SizedBox(height: 16),
              ],

              // ---- Upload / Cancel buttons ----
              if (uploadState.isUploading)
                OutlinedButton(
                  onPressed: () {
                    // Cancel is best-effort; reset upload state.
                    notifier.reset();
                  },
                  child: const Text('Cancel'),
                )
              else
                FilledButton.icon(
                  onPressed: uploadState.isFormValid
                      ? () => _handleUpload(context, ref)
                      : null,
                  icon: const Icon(Icons.cloud_upload_outlined),
                  label: const Text('Upload'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleUpload(BuildContext context, WidgetRef ref) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);

    final result = await ref.read(uploadProvider.notifier).upload();
    if (result != null) {
      if (!mounted) return;
      ref.invalidate(documentsProvider);

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Document uploaded successfully (${result.chunksIndexed} sections)',
          ),
        ),
      );
      router.pop();
    }
  }
}

// ---------------------------------------------------------------------------
// File picker area widget
// ---------------------------------------------------------------------------

class _FilePickerArea extends StatelessWidget {
  final UploadState uploadState;
  final VoidCallback? onTap;

  const _FilePickerArea({
    required this.uploadState,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final hasFile = uploadState.selectedFile != null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: uploadState.fileError != null
                ? colorScheme.error
                : hasFile
                    ? colorScheme.primary
                    : colorScheme.outlineVariant,
            width: hasFile ? 2 : 1,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
          color: hasFile
              ? colorScheme.primaryContainer.withValues(alpha: 0.15)
              : colorScheme.surfaceContainerLow,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!hasFile) ...[
              Icon(
                Icons.upload_file_rounded,
                size: 48,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
              ),
              const SizedBox(height: 12),
              Text(
                'Tap to select a file',
                style: textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'PDF or TXT, max 50 MB',
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                ),
              ),
            ] else ...[
              Row(
                children: [
                  Icon(
                    uploadState.fileExtension == 'pdf'
                        ? Icons.picture_as_pdf_rounded
                        : Icons.description_rounded,
                    size: 36,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          uploadState.fileName ?? 'Unknown file',
                          style: textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            // File type badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.secondaryContainer,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                (uploadState.fileExtension ?? '').toUpperCase(),
                                style: textTheme.labelSmall?.copyWith(
                                  color: colorScheme.onSecondaryContainer,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              uploadState.fileSizeFormatted,
                              style: textTheme.labelSmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.check_circle_rounded,
                    color: colorScheme.primary,
                  ),
                ],
              ),
            ],

            // File validation error
            if (uploadState.fileError != null) ...[
              const SizedBox(height: 12),
              Text(
                uploadState.fileError!,
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.error,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

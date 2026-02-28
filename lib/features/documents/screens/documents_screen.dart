import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/api_exception.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/loading_shimmer.dart';
import '../providers/documents_provider.dart';
import '../widgets/document_card.dart';

/// The Documents screen (PRD F-3).
///
/// Displays a list of all uploaded documents with pull-to-refresh support.
/// Shows a FAB to navigate to the Upload screen. Each document card includes
/// a delete action that shows a confirmation dialog before proceeding.
class DocumentsScreen extends ConsumerWidget {
  const DocumentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final documentsAsync = ref.watch(documentsProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Documents'),
      ),
      body: documentsAsync.when(
        loading: () => const LoadingShimmer(),
        error: (error, stackTrace) {
          final message = error is ApiException
              ? error.message
              : 'Failed to load documents.';
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    size: 56,
                    color: colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () => ref.invalidate(documentsProvider),
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        },
        data: (documents) {
          if (documents.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.folder_open_rounded,
                      size: 72,
                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No documents yet.',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Upload your first document.',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(documentsProvider);
              // Wait for the provider to complete before ending the refresh
              // indicator animation.
              await ref.read(documentsProvider.future);
            },
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              itemCount: documents.length,
              itemBuilder: (context, index) {
                final doc = documents[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: DocumentCard(
                    document: doc,
                    onDelete: () => _handleDelete(context, ref, doc.id, doc.title),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/upload'),
        tooltip: 'Upload document',
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _handleDelete(
    BuildContext context,
    WidgetRef ref,
    String documentId,
    String documentTitle,
  ) async {
    final confirmed = await ConfirmDialog.show(
      context: context,
      title: 'Delete Document',
      message:
          'Are you sure you want to delete "$documentTitle"? This action cannot be undone.',
    );

    if (confirmed == true && context.mounted) {
      try {
        await ref.read(deleteDocumentProvider(documentId).future);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Document deleted.')),
          );
        }
      } on ApiException catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.message)),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to delete document.')),
          );
        }
      }
    }
  }
}

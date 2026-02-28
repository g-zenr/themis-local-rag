import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/models/document.dart';

/// A [Card] widget that displays a single [Document] with its title, year,
/// section count, created date, and a delete action button.
class DocumentCard extends StatelessWidget {
  /// The document to display.
  final Document document;

  /// Called when the user confirms deletion of this document.
  final VoidCallback onDelete;

  const DocumentCard({
    super.key,
    required this.document,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Document info (expands to fill available space).
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    document.title,
                    style: textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),

                  // Year badge and section count row.
                  Row(
                    children: [
                      // Year chip
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          document.year.toString(),
                          style: textTheme.labelSmall?.copyWith(
                            color: colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Section count
                      Text(
                        '${document.sectionCount} section${document.sectionCount == 1 ? '' : 's'}',
                        style: textTheme.labelMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Created date
                  Text(
                    DateFormat('MMM d, yyyy').format(document.createdAt),
                    style: textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),

            // Delete action
            IconButton(
              onPressed: onDelete,
              icon: Icon(
                Icons.delete_outline,
                color: colorScheme.error,
              ),
              tooltip: 'Delete document',
            ),
          ],
        ),
      ),
    );
  }
}

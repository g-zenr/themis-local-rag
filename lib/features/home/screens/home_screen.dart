import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/health_status.dart';
import '../../../shared/widgets/error_banner.dart';
import '../providers/health_provider.dart';

/// Home / Dashboard screen (PRD F-2).
///
/// Displays the current server status and provides quick-action shortcuts to
/// the main features of the app.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final healthAsync = ref.watch(healthStatusProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Athena'),
      ),
      body: Column(
        children: [
          // ------ Error banner when the server is unreachable ------
          if (healthAsync.hasError)
            ErrorBanner(
              message: _errorMessage(healthAsync.error),
              onRetry: () => ref.invalidate(healthStatusProvider),
            ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ------ Server Status Card ------
                  Text(
                    'Server Status',
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _ServerStatusCard(healthAsync: healthAsync),
                  const SizedBox(height: 32),

                  // ------ Quick Actions ------
                  Text(
                    'Quick Actions',
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _QuickActionCard(
                    icon: Icons.chat_bubble_outline_rounded,
                    label: 'Ask a Question',
                    subtitle: 'Query your documents using natural language',
                    color: colorScheme.primary,
                    onTap: () => context.go('/ask'),
                  ),
                  const SizedBox(height: 12),
                  _QuickActionCard(
                    icon: Icons.upload_file_rounded,
                    label: 'Upload Document',
                    subtitle: 'Add a PDF or text file to the knowledge base',
                    color: colorScheme.tertiary,
                    onTap: () => context.go('/upload'),
                  ),
                  const SizedBox(height: 12),
                  _QuickActionCard(
                    icon: Icons.folder_outlined,
                    label: 'View Documents',
                    subtitle: 'Browse and manage your uploaded documents',
                    color: colorScheme.secondary,
                    onTap: () => context.go('/documents'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _errorMessage(Object? error) {
    if (error == null) return 'Unable to reach the server.';
    return error.toString().replaceFirst('ApiException(null): ', '');
  }
}

// -----------------------------------------------------------------------------
// Server Status Card
// -----------------------------------------------------------------------------

class _ServerStatusCard extends StatelessWidget {
  final AsyncValue<HealthStatus> healthAsync;

  const _ServerStatusCard({required this.healthAsync});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: healthAsync.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (err, stack) => _buildOfflineStatus(colorScheme),
          data: (health) => _buildHealthDetails(health, colorScheme),
        ),
      ),
    );
  }

  Widget _buildOfflineStatus(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _StatusDot(color: Colors.red.shade600),
            const SizedBox(width: 10),
            Text(
              'Status: offline',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.red.shade600,
                fontSize: 15,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Unable to connect to the server. Check your settings.',
          style: TextStyle(
            color: colorScheme.onSurfaceVariant,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildHealthDetails(HealthStatus health, ColorScheme colorScheme) {
    final statusColor = _statusColor(health.status);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Status row
        Row(
          children: [
            _StatusDot(color: statusColor),
            const SizedBox(width: 10),
            Text(
              'Status: ${health.status}',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: statusColor,
                fontSize: 15,
              ),
            ),
          ],
        ),
        const Divider(height: 24),

        // Detail rows
        _DetailRow(
          icon: Icons.storage_rounded,
          label: 'Database',
          value: health.database,
          valueColor: health.database == 'connected'
              ? Colors.green.shade700
              : Colors.orange.shade700,
        ),
        const SizedBox(height: 8),
        _DetailRow(
          icon: Icons.psychology_rounded,
          label: 'Model',
          value: health.modelLoaded ? 'loaded' : 'not loaded',
          valueColor: health.modelLoaded
              ? Colors.green.shade700
              : Colors.orange.shade700,
        ),
        const SizedBox(height: 8),
        _DetailRow(
          icon: Icons.dataset_rounded,
          label: 'Chunks',
          value:
              '${health.totalChunks} total, ${health.indexedChunks} indexed',
        ),
      ],
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'ok':
        return Colors.green.shade700;
      case 'degraded':
        return Colors.orange.shade700;
      default:
        return Colors.red.shade600;
    }
  }
}

// -----------------------------------------------------------------------------
// Status dot indicator
// -----------------------------------------------------------------------------

class _StatusDot extends StatelessWidget {
  final Color color;

  const _StatusDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: 6,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Detail row
// -----------------------------------------------------------------------------

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Icon(icon, size: 18, color: colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: valueColor ?? colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// Quick Action Card
// -----------------------------------------------------------------------------

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

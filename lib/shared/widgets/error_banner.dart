import 'package:flutter/material.dart';

class ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const ErrorBanner({
    super.key,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return MaterialBanner(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      content: Row(
        children: [
          Icon(
            Icons.cloud_off_rounded,
            color: colorScheme.onErrorContainer,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: colorScheme.onErrorContainer,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: colorScheme.errorContainer,
      dividerColor: Colors.transparent,
      actions: [
        if (onRetry != null)
          TextButton.icon(
            onPressed: onRetry,
            icon: Icon(
              Icons.refresh_rounded,
              size: 18,
              color: colorScheme.onErrorContainer,
            ),
            label: Text(
              'Retry',
              style: TextStyle(color: colorScheme.onErrorContainer),
            ),
          )
        else
          const SizedBox.shrink(),
      ],
    );
  }
}

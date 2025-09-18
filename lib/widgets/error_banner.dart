import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../common/services/error_service.dart';
import '../common/services/connectivity_service.dart';

class ErrorBanner extends ConsumerWidget {
  const ErrorBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final errorState = ref.watch(errorProvider);
    final connectivityState = ref.watch(connectivityProvider);

    // Show offline banner if not connected
    if (!connectivityState.isOnline) {
      return _OfflineBanner();
    }

    // Show error banner if there's an error
    if (errorState.currentError != null) {
      return _ErrorBanner(error: errorState.currentError!);
    }

    return const SizedBox.shrink();
  }
}

class _OfflineBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Theme.of(context).colorScheme.errorContainer,
      child: Row(
        children: [
          Icon(
            Icons.wifi_off,
            color: Theme.of(context).colorScheme.onErrorContainer,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'You\'re offline. Some features may not be available.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onErrorContainer,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends ConsumerWidget {
  const _ErrorBanner({required this.error});

  final AppError error;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Theme.of(context).colorScheme.errorContainer,
      child: Row(
        children: [
          Icon(
            _getErrorIcon(),
            color: Theme.of(context).colorScheme.onErrorContainer,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              error.userFriendlyMessage,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onErrorContainer,
                fontSize: 14,
              ),
            ),
          ),
          if (error.action != null)
            TextButton(
              onPressed: () => _handleAction(context, ref),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
                minimumSize: const Size(0, 0),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
              child: Text(error.action!, style: const TextStyle(fontSize: 12)),
            ),
          IconButton(
            onPressed: () => ref.read(errorProvider.notifier).clearError(),
            icon: Icon(
              Icons.close,
              color: Theme.of(context).colorScheme.onErrorContainer,
              size: 18,
            ),
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  IconData _getErrorIcon() {
    switch (error.type) {
      case ErrorType.network:
        return Icons.wifi_off;
      case ErrorType.auth:
        return Icons.lock_outline;
      case ErrorType.validation:
        return Icons.warning_outlined;
      case ErrorType.server:
        return Icons.error_outline;
      case ErrorType.unknown:
        return Icons.help_outline;
    }
  }

  void _handleAction(BuildContext context, WidgetRef ref) {
    switch (error.type) {
      case ErrorType.network:
        // Could trigger a retry or refresh
        break;
      case ErrorType.auth:
        // Navigate to sign in
        // context.go('/signin');
        break;
      case ErrorType.validation:
        // Usually no action needed for validation errors
        break;
      case ErrorType.server:
        // Could trigger a retry
        break;
      case ErrorType.unknown:
        // Could trigger a retry
        break;
    }
    ref.read(errorProvider.notifier).clearError();
  }
}

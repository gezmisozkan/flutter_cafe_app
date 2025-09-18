import 'package:hooks_riverpod/hooks_riverpod.dart';

enum ErrorType { network, auth, validation, server, unknown }

class AppError {
  const AppError({
    required this.message,
    required this.type,
    this.details,
    this.action,
  });

  final String message;
  final ErrorType type;
  final String? details;
  final String? action;

  String get userFriendlyMessage {
    switch (type) {
      case ErrorType.network:
        return 'No internet connection. Please check your network and try again.';
      case ErrorType.auth:
        return 'Authentication failed. Please sign in again.';
      case ErrorType.validation:
        return message;
      case ErrorType.server:
        return 'Server error. Please try again later.';
      case ErrorType.unknown:
        return 'Something went wrong. Please try again.';
    }
  }
}

class ErrorState {
  const ErrorState({this.currentError, this.errorHistory = const []});

  final AppError? currentError;
  final List<AppError> errorHistory;

  ErrorState copyWith({AppError? currentError, List<AppError>? errorHistory}) {
    return ErrorState(
      currentError: currentError,
      errorHistory: errorHistory ?? this.errorHistory,
    );
  }
}

class ErrorNotifier extends StateNotifier<ErrorState> {
  ErrorNotifier() : super(const ErrorState());

  void showError(AppError error) {
    state = state.copyWith(
      currentError: error,
      errorHistory: [...state.errorHistory, error],
    );
  }

  void clearError() {
    state = state.copyWith(currentError: null);
  }

  void clearAllErrors() {
    state = const ErrorState();
  }
}

final errorProvider = StateNotifierProvider<ErrorNotifier, ErrorState>((ref) {
  return ErrorNotifier();
});

// Helper functions for common error scenarios
AppError createNetworkError() {
  return const AppError(
    message: 'Network error',
    type: ErrorType.network,
    action: 'Retry',
  );
}

AppError createAuthError(String message) {
  return AppError(message: message, type: ErrorType.auth, action: 'Sign In');
}

AppError createValidationError(String message) {
  return AppError(message: message, type: ErrorType.validation);
}

AppError createServerError(String message) {
  return AppError(message: message, type: ErrorType.server, action: 'Retry');
}

AppError createUnknownError(String message) {
  return AppError(message: message, type: ErrorType.unknown, action: 'Retry');
}

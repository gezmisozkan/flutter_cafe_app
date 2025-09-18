import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class ConnectivityState {
  const ConnectivityState({
    required this.isOnline,
    required this.connectionType,
  });

  final bool isOnline;
  final String connectionType;

  ConnectivityState copyWith({bool? isOnline, String? connectionType}) {
    return ConnectivityState(
      isOnline: isOnline ?? this.isOnline,
      connectionType: connectionType ?? this.connectionType,
    );
  }
}

class ConnectivityNotifier extends StateNotifier<ConnectivityState> {
  ConnectivityNotifier()
    : super(
        const ConnectivityState(isOnline: true, connectionType: 'unknown'),
      ) {
    _init();
  }

  late StreamSubscription<List<ConnectivityResult>> _subscription;

  void _init() {
    _subscription = Connectivity().onConnectivityChanged.listen(
      _updateConnectionStatus,
    );
    _checkInitialConnection();
  }

  Future<void> _checkInitialConnection() async {
    final result = await Connectivity().checkConnectivity();
    _updateConnectionStatus(result);
  }

  void _updateConnectionStatus(List<ConnectivityResult> results) {
    final isOnline = !results.contains(ConnectivityResult.none);
    final connectionType = results.isNotEmpty ? results.first.name : 'none';

    state = state.copyWith(isOnline: isOnline, connectionType: connectionType);
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

final connectivityProvider =
    StateNotifierProvider<ConnectivityNotifier, ConnectivityState>((ref) {
      return ConnectivityNotifier();
    });

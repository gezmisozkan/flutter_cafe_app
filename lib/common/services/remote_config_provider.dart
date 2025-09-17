import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class AppRemoteConfigState {
  const AppRemoteConfigState({required this.maintenance});
  final bool maintenance;
}

final appRemoteConfigProvider =
    StateNotifierProvider<AppRemoteConfigNotifier, AppRemoteConfigState>((ref) {
      return AppRemoteConfigNotifier();
    });

class AppRemoteConfigNotifier extends StateNotifier<AppRemoteConfigState> {
  AppRemoteConfigNotifier()
    : super(const AppRemoteConfigState(maintenance: false)) {
    _load();
  }

  Future<void> _load() async {
    try {
      final rc = FirebaseRemoteConfig.instance;
      final maintenance = rc.getBool('maintenance');
      state = AppRemoteConfigState(maintenance: maintenance);
    } catch (_) {
      state = const AppRemoteConfigState(maintenance: false);
    }
  }

  Future<void> refresh() async {
    try {
      await FirebaseRemoteConfig.instance.fetchAndActivate();
    } catch (_) {}
    await _load();
  }
}

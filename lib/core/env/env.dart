import 'package:hooks_riverpod/hooks_riverpod.dart';

class AppEnvConfig {
  const AppEnvConfig({
    required this.supabaseUrl,
    required this.supabaseAnonKey,
  });

  final String supabaseUrl;
  final String supabaseAnonKey;

  static const AppEnvConfig fromDartDefine = AppEnvConfig(
    supabaseUrl: String.fromEnvironment('SUPABASE_URL', defaultValue: ''),
    supabaseAnonKey: String.fromEnvironment(
      'SUPABASE_ANON_KEY',
      defaultValue: '',
    ),
  );

  bool get isConfigured => supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}

final appEnvProvider = Provider<AppEnvConfig>((ref) {
  return AppEnvConfig.fromDartDefine;
});

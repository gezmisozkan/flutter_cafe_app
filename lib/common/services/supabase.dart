import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/env/env.dart';

SupabaseClient? _cachedClient;

final supabaseClientProvider = Provider<SupabaseClient?>((ref) {
  return _cachedClient;
});

Future<void> initSupabaseIfConfigured(ProviderContainer container) async {
  final env = container.read(appEnvProvider);
  if (!env.isConfigured) return;
  // Always initialize here; avoid accessing Supabase.instance before init
  await Supabase.initialize(
    url: env.supabaseUrl,
    anonKey: env.supabaseAnonKey,
    debug: false,
  );
  _cachedClient = Supabase.instance.client;
}

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'app.dart';
import 'common/services/supabase.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final container = ProviderContainer();
  await initSupabaseIfConfigured(container);
  runApp(
    UncontrolledProviderScope(container: container, child: const CafeApp()),
  );
}

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'app.dart';
import 'common/services/supabase.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'common/services/firebase_bootstrap.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final container = ProviderContainer();
  await initSupabaseIfConfigured(container);
  // Firebase bootstrap (guarded)
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  await initFirebaseBootstrap(container);
  runApp(
    UncontrolledProviderScope(container: container, child: const CafeApp()),
  );
}

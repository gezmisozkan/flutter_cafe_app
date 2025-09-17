import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../common/services/supabase.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../../common/services/fcm_token_sync.dart';

class UserSession {
  UserSession({
    required this.userId,
    required this.email,
    required this.isAdmin,
  });

  final String userId;
  final String email;
  final bool isAdmin;
}

class AuthStore extends StateNotifier<UserSession?> {
  AuthStore(this._ref) : super(null);

  final Ref _ref;

  Future<bool> signIn({required String email, required String password}) async {
    if (email.isEmpty || password.isEmpty) return false;
    final client = _ref.read(supabaseClientProvider);
    if (client != null) {
      try {
        final AuthResponse res = await client.auth.signInWithPassword(
          email: email,
          password: password,
        );
        final user = res.user;
        if (user == null) return false;
        final String uid = user.id;
        final String mail = user.email ?? email;
        state = UserSession(userId: uid, email: mail, isAdmin: false);
        await _saveFcmToken(uid);
        return true;
      } catch (_) {
        return false;
      }
    }
    final isAdmin =
        email.toLowerCase() == 'admin@admin.com' && password == 'admin';
    state = UserSession(
      userId: 'user-${email.hashCode}',
      email: email,
      isAdmin: isAdmin,
    );
    await _saveFcmToken(state!.userId);
    return true;
  }

  Future<bool> signUp({required String email, required String password}) async {
    final client = _ref.read(supabaseClientProvider);
    if (client != null) {
      try {
        final AuthResponse res = await client.auth.signUp(
          email: email,
          password: password,
        );
        final user = res.user;
        if (user == null) return false;
        final String uid = user.id;
        final String mail = user.email ?? email;
        state = UserSession(userId: uid, email: mail, isAdmin: false);
        await _saveFcmToken(uid);
        return true;
      } catch (_) {
        return false;
      }
    }
    final ok = await signIn(email: email, password: password);
    return ok;
  }

  void signOut() {
    final client = _ref.read(supabaseClientProvider);
    final uid = state?.userId;
    if (client != null) {
      client.auth.signOut();
    }
    if (uid != null) {
      _removeFcmToken(uid);
    }
    state = null;
  }

  Future<void> _saveFcmToken(String uid) async {
    try {
      final service = FcmTokenSyncService(
        FirebaseFirestore.instance,
        FirebaseMessaging.instance,
      );
      await service.saveCurrentToken(uid);
    } catch (_) {}
  }

  Future<void> _removeFcmToken(String uid) async {
    try {
      final service = FcmTokenSyncService(
        FirebaseFirestore.instance,
        FirebaseMessaging.instance,
      );
      await service.removeCurrentToken(uid);
    } catch (_) {}
  }
}

final authStoreProvider = StateNotifierProvider<AuthStore, UserSession?>((ref) {
  return AuthStore(ref);
});

import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../common/services/supabase.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
        return true;
      } catch (_) {
        return false;
      }
    }
    return signIn(email: email, password: password);
  }

  void signOut() {
    final client = _ref.read(supabaseClientProvider);
    if (client != null) {
      client.auth.signOut();
    }
    state = null;
  }
}

final authStoreProvider = StateNotifierProvider<AuthStore, UserSession?>((ref) {
  return AuthStore(ref);
});

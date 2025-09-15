import 'package:hooks_riverpod/hooks_riverpod.dart';

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
  AuthStore() : super(null);

  Future<bool> signIn({required String email, required String password}) async {
    // Mock: accept any non-empty credentials
    if (email.isEmpty || password.isEmpty) return false;
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
    return signIn(email: email, password: password);
  }

  void signOut() {
    state = null;
  }
}

final authStoreProvider = StateNotifierProvider<AuthStore, UserSession?>((ref) {
  return AuthStore();
});

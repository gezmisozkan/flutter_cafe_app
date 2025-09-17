import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../common/services/supabase.dart';

class UserProfile {
  UserProfile({
    required this.userId,
    required this.email,
    this.name,
    this.phone,
    this.favoriteDrink,
  });

  final String userId;
  final String email;
  final String? name;
  final String? phone;
  final String? favoriteDrink;

  UserProfile copyWith({String? name, String? phone, String? favoriteDrink}) {
    return UserProfile(
      userId: userId,
      email: email,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      favoriteDrink: favoriteDrink ?? this.favoriteDrink,
    );
  }
}

class ProfileStore extends StateNotifier<UserProfile?> {
  ProfileStore(this._ref) : super(null);
  final Ref _ref;

  Future<void> loadFor(String userId, String email) async {
    final client = _ref.read(supabaseClientProvider);
    if (client == null) {
      state = UserProfile(userId: userId, email: email);
      return;
    }
    final rows = await client
        .from('profiles')
        .select('id, email, name, phone, favorite_drink')
        .eq('id', userId)
        .maybeSingle();
    if (rows == null) {
      await client.from('profiles').insert({'id': userId, 'email': email});
      state = UserProfile(userId: userId, email: email);
    } else {
      state = UserProfile(
        userId: rows['id'] as String,
        email: rows['email'] as String? ?? email,
        name: rows['name'] as String?,
        phone: rows['phone'] as String?,
        favoriteDrink: rows['favorite_drink'] as String?,
      );
    }
  }

  Future<void> update({
    String? name,
    String? phone,
    String? favoriteDrink,
  }) async {
    final current = state;
    if (current == null) return;
    final client = _ref.read(supabaseClientProvider);
    if (client != null) {
      await client.from('profiles').upsert({
        'id': current.userId,
        'email': current.email,
        if (name != null) 'name': name,
        if (phone != null) 'phone': phone,
        if (favoriteDrink != null) 'favorite_drink': favoriteDrink,
      });
    }
    state = current.copyWith(
      name: name,
      phone: phone,
      favoriteDrink: favoriteDrink,
    );
  }
}

final profileStoreProvider = StateNotifierProvider<ProfileStore, UserProfile?>((
  ref,
) {
  return ProfileStore(ref);
});

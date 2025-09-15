import 'package:hooks_riverpod/hooks_riverpod.dart';

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
  ProfileStore() : super(null);

  void loadFor(String userId, String email) {
    state = UserProfile(userId: userId, email: email);
  }

  void update({String? name, String? phone, String? favoriteDrink}) {
    final current = state;
    if (current == null) return;
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
  return ProfileStore();
});

import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../menu/domain/models.dart';
// Firebase imports disabled for UI testing
// import 'package:cloud_firestore/cloud_firestore.dart';
// import '../../auth/data/auth_store.dart';
import '../../loyalty/domain/models.dart';

class CartItem {
  CartItem({required this.item, required this.qty, this.note});

  final MenuItemModel item;
  final int qty;
  final String? note;

  int get lineTotalCents => item.priceCents * qty;
}

class CartState {
  const CartState({
    required this.items,
    this.appliedReward,
    this.promoCode,
    this.discountCents = 0,
  });

  final List<CartItem> items;
  final RewardItem? appliedReward;
  final String? promoCode;
  final int discountCents;

  int get subtotalCents => items.fold(0, (acc, e) => acc + e.lineTotalCents);

  int get totalCents {
    int total = subtotalCents;
    if (appliedReward != null) {
      total -= appliedReward!
          .costPoints; // Convert points to cents (1 point = 1 cent for simplicity)
    }
    total -= discountCents;
    return total.clamp(0, double.infinity).toInt();
  }

  CartState copyWith({
    List<CartItem>? items,
    RewardItem? appliedReward,
    String? promoCode,
    int? discountCents,
  }) {
    return CartState(
      items: items ?? this.items,
      appliedReward: appliedReward ?? this.appliedReward,
      promoCode: promoCode ?? this.promoCode,
      discountCents: discountCents ?? this.discountCents,
    );
  }
}

class CartStore extends StateNotifier<CartState> {
  CartStore(this._ref) : super(const CartState(items: [])) {
    // Attempt to load cart on startup
    Future.microtask(_loadFromFirestoreIfLoggedIn);
  }

  final Ref _ref;

  Future<void> add(MenuItemModel item, {String? note}) async {
    final idx = state.items.indexWhere(
      (e) => e.item.id == item.id && e.note == note,
    );
    if (idx >= 0) {
      final current = state.items[idx];
      final updated = CartItem(
        item: current.item,
        qty: current.qty + 1,
        note: current.note,
      );
      final next = [...state.items]..[idx] = updated;
      state = CartState(items: next);
    } else {
      state = CartState(
        items: [
          ...state.items,
          CartItem(item: item, qty: 1, note: note),
        ],
      );
    }
    await _saveToFirestoreIfLoggedIn();
  }

  Future<void> removeAt(int index) async {
    final next = [...state.items]..removeAt(index);
    state = CartState(items: next);
    await _saveToFirestoreIfLoggedIn();
  }

  Future<void> clear() async {
    state = const CartState(items: []);
    await _saveToFirestoreIfLoggedIn();
  }

  Future<void> applyReward(RewardItem reward) async {
    state = state.copyWith(appliedReward: reward);
    await _saveToFirestoreIfLoggedIn();
  }

  Future<void> removeReward() async {
    state = state.copyWith(appliedReward: null);
    await _saveToFirestoreIfLoggedIn();
  }

  Future<void> applyPromoCode(String code, int discountCents) async {
    state = state.copyWith(promoCode: code, discountCents: discountCents);
    await _saveToFirestoreIfLoggedIn();
  }

  Future<void> removePromoCode() async {
    state = state.copyWith(promoCode: null, discountCents: 0);
    await _saveToFirestoreIfLoggedIn();
  }

  Future<void> _saveToFirestoreIfLoggedIn() async {
    // Disabled for UI testing - cart data is only stored locally
    return;

    // Uncomment below to re-enable Firebase
    // final session = _ref.read(authStoreProvider);
    // final uid = session?.userId;
    // if (uid == null || uid.isEmpty) return;
    // final doc = FirebaseFirestore.instance.doc('carts/$uid');
    // await doc.set({
    //   'updated_at': FieldValue.serverTimestamp(),
    //   'items': [
    //     for (final it in state.items)
    //       {
    //         'menu_item_id': it.item.id,
    //         'name': it.item.name,
    //         'price_cents': it.item.priceCents,
    //         'qty': it.qty,
    //         'note': it.note,
    //       },
    //   ],
    //   'totals_cache': {
    //     'subtotal_cents': state.subtotalCents,
    //     'total_cents': state.totalCents,
    //   },
    //   if (state.appliedReward != null)
    //     'reward_applied': {
    //       'id': state.appliedReward!.id,
    //       'title': state.appliedReward!.title,
    //       'cost_points': state.appliedReward!.costPoints,
    //     },
    //   if (state.promoCode != null) 'promo_code': state.promoCode,
    //   'discount_cents': state.discountCents,
    // }, SetOptions(merge: true));
  }

  Future<void> _loadFromFirestoreIfLoggedIn() async {
    // Disabled for UI testing - cart starts empty
    return;

    // Uncomment below to re-enable Firebase
    // final session = _ref.read(authStoreProvider);
    // final uid = session?.userId;
    // if (uid == null || uid.isEmpty) return;
    // final doc = await FirebaseFirestore.instance.doc('carts/$uid').get();
    // if (!doc.exists) return;
    // final data = doc.data() as Map<String, dynamic>;
    // final items = <CartItem>[];
    // for (final m in (data['items'] as List? ?? const [])) {
    //   final map = (m as Map).cast<String, Object?>();
    //   items.add(
    //     CartItem(
    //       item: MenuItemModel(
    //         id: map['menu_item_id'] as String,
    //         categoryId: '',
    //         name: map['name'] as String? ?? 'Item',
    //         priceCents: (map['price_cents'] as num?)?.toInt() ?? 0,
    //       ),
    //       qty: (map['qty'] as num?)?.toInt() ?? 1,
    //       note: map['note'] as String?,
    //     ),
    //   );
    // }

    // // Load reward and promo data
    // RewardItem? appliedReward;
    // final rewardData = data['reward_applied'] as Map<String, dynamic>?;
    // if (rewardData != null) {
    //   appliedReward = RewardItem(
    //     id: rewardData['id'] as String,
    //     title: rewardData['title'] as String,
    //     costPoints: (rewardData['cost_points'] as num?)?.toInt() ?? 0,
    //   );
    // }

    // final promoCode = data['promo_code'] as String?;
    // final discountCents = (data['discount_cents'] as num?)?.toInt() ?? 0;

    // state = CartState(
    //   items: items,
    //   appliedReward: appliedReward,
    //   promoCode: promoCode,
    //   discountCents: discountCents,
    // );
  }
}

final cartStoreProvider = StateNotifierProvider<CartStore, CartState>((ref) {
  return CartStore(ref);
});

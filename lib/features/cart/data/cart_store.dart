import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../menu/domain/models.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../auth/data/auth_store.dart';

class CartItem {
  CartItem({required this.item, required this.qty, this.note});

  final MenuItemModel item;
  final int qty;
  final String? note;

  int get lineTotalCents => item.priceCents * qty;
}

class CartState {
  const CartState({required this.items});

  final List<CartItem> items;

  int get totalCents => items.fold(0, (acc, e) => acc + e.lineTotalCents);
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

  Future<void> _saveToFirestoreIfLoggedIn() async {
    final session = _ref.read(authStoreProvider);
    final uid = session?.userId;
    if (uid == null || uid.isEmpty) return;
    final doc = FirebaseFirestore.instance.doc('carts/$uid');
    await doc.set({
      'updated_at': FieldValue.serverTimestamp(),
      'items': [
        for (final it in state.items)
          {
            'menu_item_id': it.item.id,
            'name': it.item.name,
            'price_cents': it.item.priceCents,
            'qty': it.qty,
            'note': it.note,
          },
      ],
      'totals_cache': {'subtotal_cents': state.totalCents},
    }, SetOptions(merge: true));
  }

  Future<void> _loadFromFirestoreIfLoggedIn() async {
    final session = _ref.read(authStoreProvider);
    final uid = session?.userId;
    if (uid == null || uid.isEmpty) return;
    final doc = await FirebaseFirestore.instance.doc('carts/$uid').get();
    if (!doc.exists) return;
    final data = doc.data() as Map<String, dynamic>;
    final items = <CartItem>[];
    for (final m in (data['items'] as List? ?? const [])) {
      final map = (m as Map).cast<String, Object?>();
      items.add(
        CartItem(
          item: MenuItemModel(
            id: map['menu_item_id'] as String,
            categoryId: '',
            name: map['name'] as String? ?? 'Item',
            priceCents: (map['price_cents'] as num?)?.toInt() ?? 0,
          ),
          qty: (map['qty'] as num?)?.toInt() ?? 1,
          note: map['note'] as String?,
        ),
      );
    }
    state = CartState(items: items);
  }
}

final cartStoreProvider = StateNotifierProvider<CartStore, CartState>((ref) {
  return CartStore(ref);
});

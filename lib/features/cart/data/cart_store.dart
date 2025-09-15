import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../menu/domain/models.dart';

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
  CartStore() : super(const CartState(items: []));

  void add(MenuItemModel item, {String? note}) {
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
  }

  void removeAt(int index) {
    final next = [...state.items]..removeAt(index);
    state = CartState(items: next);
  }

  void clear() => state = const CartState(items: []);
}

final cartStoreProvider = StateNotifierProvider<CartStore, CartState>((ref) {
  return CartStore();
});

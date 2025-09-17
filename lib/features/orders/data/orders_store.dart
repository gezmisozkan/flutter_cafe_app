import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../cart/data/cart_store.dart';
import '../../../common/services/supabase.dart';

enum OrderStatus { pending, ready, completed, canceled }

class OrderItemSnapshot {
  OrderItemSnapshot({
    required this.menuItemId,
    required this.name,
    required this.qty,
    required this.priceCentsSnapshot,
    this.note,
  });

  final String menuItemId;
  final String name;
  final int qty;
  final int priceCentsSnapshot;
  final String? note;
}

class UserOrder {
  UserOrder({
    required this.id,
    required this.status,
    required this.pickupMinutesFromNow,
    required this.totalCents,
    required this.createdAt,
    required this.items,
  });

  final String id;
  final OrderStatus status;
  final int pickupMinutesFromNow; // 0 for ASAP, 10 for +10
  final int totalCents;
  final DateTime createdAt;
  final List<OrderItemSnapshot> items;
}

class OrdersState {
  const OrdersState({required this.orders});

  final List<UserOrder> orders;
}

class OrdersStore extends StateNotifier<OrdersState> {
  OrdersStore(this._ref) : super(const OrdersState(orders: []));
  final Ref _ref;

  Future<void> placeOrder(
    CartState cart, {
    required int pickupMinutesFromNow,
  }) async {
    if (cart.items.isEmpty) return;
    final items = [
      for (final ci in cart.items)
        OrderItemSnapshot(
          menuItemId: ci.item.id,
          name: ci.item.name,
          qty: ci.qty,
          priceCentsSnapshot: ci.item.priceCents,
          note: ci.note,
        ),
    ];
    final order = UserOrder(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      status: OrderStatus.pending,
      pickupMinutesFromNow: pickupMinutesFromNow,
      totalCents: cart.totalCents,
      createdAt: DateTime.now(),
      items: items,
    );
    state = OrdersState(orders: [...state.orders, order]);
    final client = _ref.read(supabaseClientProvider);
    if (client != null) {
      final inserted = await client
          .from('orders')
          .insert({
            'status': 'pending',
            'pickup_minutes_from_now': pickupMinutesFromNow,
            'total_cents': cart.totalCents,
          })
          .select('id, created_at')
          .single();
      final orderId = inserted['id'] as String;
      for (final it in items) {
        await client.from('order_items').insert({
          'order_id': orderId,
          'menu_item_id': it.menuItemId,
          'name': it.name,
          'qty': it.qty,
          'price_cents_snapshot': it.priceCentsSnapshot,
          'note': it.note,
        });
      }
    }
  }

  void updateStatus(String orderId, OrderStatus status) {
    final next = [
      for (final o in state.orders)
        if (o.id == orderId)
          UserOrder(
            id: o.id,
            status: status,
            pickupMinutesFromNow: o.pickupMinutesFromNow,
            totalCents: o.totalCents,
            createdAt: o.createdAt,
            items: o.items,
          )
        else
          o,
    ];
    state = OrdersState(orders: next);
  }
}

final ordersStoreProvider = StateNotifierProvider<OrdersStore, OrdersState>((
  ref,
) {
  return OrdersStore(ref);
});

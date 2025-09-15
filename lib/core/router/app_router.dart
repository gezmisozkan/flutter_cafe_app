import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../widgets/qr_box.dart';
import '../../features/loyalty/data/loyalty_store.dart';
import '../../features/menu/data/menu_store.dart';
import '../../features/cart/data/cart_store.dart';
import '../../features/orders/data/orders_store.dart';
import '../../features/menu/domain/models.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/home',
    routes: [
      ShellRoute(
        builder: (context, state, child) => _TabShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: _HomeScreen()),
          ),
          GoRoute(
            path: '/order',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: _OrderScreen()),
          ),
          GoRoute(
            path: '/card',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: _MyCardScreen()),
          ),
          GoRoute(
            path: '/store',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: _StoreScreen()),
          ),
          GoRoute(
            path: '/more',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: _MoreScreen()),
          ),
        ],
      ),
    ],
  );
});

class _TabShell extends StatelessWidget {
  const _TabShell({required this.child});

  final Widget child;

  static const _tabs = [
    ('/home', Icons.home, 'Home'),
    ('/order', Icons.shopping_bag_outlined, 'Order'),
    ('/card', Icons.credit_card, 'My Card'),
    ('/store', Icons.store_mall_directory_outlined, 'Store'),
    ('/more', Icons.more_horiz, 'More'),
  ];

  int _indexForLocation(BuildContext context) {
    final loc = GoRouterState.of(context).uri.toString();
    return _tabs
        .indexWhere((t) => loc.startsWith(t.$1))
        .clamp(0, _tabs.length - 1);
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _indexForLocation(context);
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (i) => context.go(_tabs[i].$1),
        destinations: [
          for (final t in _tabs)
            NavigationDestination(icon: Icon(t.$2), label: t.$3),
        ],
      ),
    );
  }
}

class _HomeScreen extends StatelessWidget {
  const _HomeScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: Center(
        child: Wrap(
          spacing: 12,
          children: [
            ElevatedButton(
              onPressed: () => context.go('/order'),
              child: const Text('Order'),
            ),
            ElevatedButton(
              onPressed: () => context.go('/card'),
              child: const Text('My Card'),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderScreen extends ConsumerWidget {
  const _OrderScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final menu = ref.watch(menuStoreProvider);
    final cart = ref.watch(cartStoreProvider);
    final currency = (int cents) => '₺ ${(cents / 100).toStringAsFixed(2)}';
    return Scaffold(
      appBar: AppBar(title: const Text('Order')),
      body: Column(
        children: [
          SizedBox(
            height: 56,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              scrollDirection: Axis.horizontal,
              itemCount: menu.categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final c = menu.categories[i];
                return Chip(label: Text(c.name));
              },
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                for (final c in menu.categories)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Text(
                          c.name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      for (final m
                          in (menu.itemsByCategory[c.id] ??
                              const <MenuItemModel>[]))
                        ListTile(
                          title: Text(m.name),
                          subtitle: Text(currency(m.priceCents)),
                          trailing: IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: () =>
                                ref.read(cartStoreProvider.notifier).add(m),
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: ListTile(
          title: const Text('Cart total'),
          subtitle: Text(currency(cart.totalCents)),
          trailing: ElevatedButton(
            onPressed: cart.items.isEmpty
                ? null
                : () => _showCartSheet(context, ref),
            child: const Text('View Cart'),
          ),
        ),
      ),
    );
  }
}

Future<void> _showCartSheet(BuildContext context, WidgetRef ref) async {
  final currency = (int cents) => '₺ ${(cents / 100).toStringAsFixed(2)}';
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) {
      final cart = ref.watch(cartStoreProvider);
      int pickup = 0; // 0 ASAP, 10 in 10m
      return StatefulBuilder(
        builder: (context, setState) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Cart',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: cart.items.length,
                      itemBuilder: (context, i) {
                        final ci = cart.items[i];
                        return ListTile(
                          title: Text('${ci.item.name} x${ci.qty}'),
                          subtitle: ci.note == null ? null : Text(ci.note!),
                          trailing: Text(currency(ci.lineTotalCents)),
                          leading: IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: () => ref
                                .read(cartStoreProvider.notifier)
                                .removeAt(i),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('Pickup time'),
                  const SizedBox(height: 8),
                  SegmentedButton<int>(
                    segments: const [
                      ButtonSegment<int>(value: 0, label: Text('ASAP')),
                      ButtonSegment<int>(value: 10, label: Text('+10 min')),
                    ],
                    selected: {pickup},
                    onSelectionChanged: (s) => setState(() => pickup = s.first),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total: ${currency(cart.totalCents)}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      ElevatedButton(
                        onPressed: cart.items.isEmpty
                            ? null
                            : () {
                                ref
                                    .read(ordersStoreProvider.notifier)
                                    .placeOrder(
                                      ref.read(cartStoreProvider),
                                      pickupMinutesFromNow: pickup,
                                    );
                                ref.read(cartStoreProvider.notifier).clear();
                                Navigator.of(context).pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Order placed')),
                                );
                              },
                        child: const Text('Place order'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

class _StoreScreen extends StatelessWidget {
  const _StoreScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Store')),
      body: const Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Address: 123 Coffee St'),
            SizedBox(height: 8),
            Text('Hours: 8:00 - 20:00'),
            SizedBox(height: 8),
            Text('Phone: +90 555 000 00 00'),
          ],
        ),
      ),
    );
  }
}

class _MoreScreen extends StatelessWidget {
  const _MoreScreen();

  @override
  Widget build(BuildContext context) {
    return const _OrdersHistoryScreen();
  }
}

class _OrdersHistoryScreen extends ConsumerWidget {
  const _OrdersHistoryScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(ordersStoreProvider).orders.reversed.toList();
    String statusLabel(OrderStatus s) {
      switch (s) {
        case OrderStatus.pending:
          return 'Pending';
        case OrderStatus.ready:
          return 'Ready';
        case OrderStatus.completed:
          return 'Completed';
        case OrderStatus.canceled:
          return 'Canceled';
      }
    }

    String currency(int cents) => '₺ ${(cents / 100).toStringAsFixed(2)}';

    return Scaffold(
      appBar: AppBar(title: const Text('Orders')),
      body: orders.isEmpty
          ? const Center(child: Text('No orders yet'))
          : ListView.builder(
              itemCount: orders.length,
              itemBuilder: (context, i) {
                final o = orders[i];
                return ExpansionTile(
                  title: Text('#${o.id} • ${statusLabel(o.status)}'),
                  subtitle: Text(
                    '${o.createdAt} • Total ${currency(o.totalCents)}',
                  ),
                  children: [
                    for (final it in o.items)
                      ListTile(
                        dense: true,
                        title: Text('${it.name} x${it.qty}'),
                        subtitle: it.note == null ? null : Text(it.note!),
                        trailing: Text(
                          currency(it.priceCentsSnapshot * it.qty),
                        ),
                      ),
                  ],
                );
              },
            ),
    );
  }
}

class _MyCardScreen extends ConsumerWidget {
  const _MyCardScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(fakeUserIdProvider);
    final loyalty = ref.watch(loyaltyStoreProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('My Card')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Points: ${loyalty.points}',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            SizedBox(height: 12),
            QrBox(data: userId),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () =>
                      ref.read(loyaltyStoreProvider.notifier).earn(10),
                  child: const Text('Earn +10'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () => _showRedeem(context, ref),
                  child: const Text('Redeem'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'History',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: loyalty.transactions.length,
                itemBuilder: (context, i) {
                  final tx =
                      loyalty.transactions[loyalty.transactions.length - 1 - i];
                  final isEarn = tx.delta > 0;
                  return ListTile(
                    leading: Icon(
                      isEarn ? Icons.add : Icons.remove,
                      color: isEarn ? Colors.green : Colors.red,
                    ),
                    title: Text(tx.reason),
                    trailing: Text('${tx.delta > 0 ? '+' : ''}${tx.delta}'),
                    subtitle: Text('${tx.createdAt}'),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final fakeUserIdProvider = Provider<String>((ref) => 'user-1234');

Future<void> _showRedeem(BuildContext context, WidgetRef ref) async {
  final store = ref.read(loyaltyStoreProvider);
  await showModalBottomSheet(
    context: context,
    showDragHandle: true,
    builder: (context) {
      return SafeArea(
        child: ListView(
          children: [
            for (final r in store.rewards)
              ListTile(
                title: Text(r.title),
                subtitle: Text('${r.costPoints} pts'),
                trailing: ElevatedButton(
                  onPressed: store.points >= r.costPoints
                      ? () {
                          final ok = ref
                              .read(loyaltyStoreProvider.notifier)
                              .redeem(r);
                          Navigator.of(context).pop();
                          if (!ok) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Not enough points'),
                              ),
                            );
                          }
                        }
                      : null,
                  child: const Text('Redeem'),
                ),
              ),
          ],
        ),
      );
    },
  );
}

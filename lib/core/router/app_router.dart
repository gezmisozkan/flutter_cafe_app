import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../widgets/qr_box.dart';
import '../../features/loyalty/data/loyalty_store.dart';
import '../../features/menu/data/menu_store.dart';
import '../../features/cart/data/cart_store.dart';
import '../../features/orders/data/orders_store.dart';
import '../../features/menu/domain/models.dart';
import '../../features/menu/ui/item_detail.dart';
import '../../features/auth/ui/auth_screens.dart';
import '../../features/auth/data/auth_store.dart';
import '../../features/menu/ui/admin_menu.dart';
import '../../features/admin/data/campaigns_store.dart';
import '../../widgets/empty_state.dart';
import '../../common/services/functions_client.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/home',
    routes: [
      GoRoute(
        path: '/signin',
        builder: (context, state) => const SignInScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      // Store selector (modal)
      GoRoute(
        path: '/store/select',
        pageBuilder: (context, state) =>
            DialogPage(child: _StoreSelectScreen()),
      ),
      // Product detail (alias old /item/:id)
      GoRoute(
        path: '/product/:id',
        builder: (context, state) {
          final menu = ref.read(menuStoreProvider);
          final id = state.pathParameters['id']!;
          final item = findItemById(menu, id);
          return ItemDetailScreen(item: item!);
        },
      ),
      // Checkout
      GoRoute(
        path: '/checkout',
        builder: (context, state) => const _CheckoutScreen(),
      ),
      // Order tracker
      GoRoute(
        path: '/order/:id/tracker',
        builder: (context, state) =>
            _OrderTrackerScreen(orderId: state.pathParameters['id']!),
      ),
      // Receipt
      GoRoute(
        path: '/receipt/:id',
        builder: (context, state) =>
            _ReceiptScreen(orderId: state.pathParameters['id']!),
      ),
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
            path: '/cart',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: _CartScreen()),
          ),
          GoRoute(
            path: '/loyalty',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: _MyCardScreen()),
          ),
          GoRoute(
            path: '/account',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: _MoreScreen()),
          ),
          // Back-compat existing paths
          GoRoute(
            path: '/item/:id',
            builder: (context, state) {
              final menu = ref.read(menuStoreProvider);
              final id = state.pathParameters['id']!;
              final item = findItemById(menu, id);
              return ItemDetailScreen(item: item!);
            },
          ),
          GoRoute(
            path: '/orders',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: _OrdersHistoryScreen()),
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
    ('/cart', Icons.shopping_cart_outlined, 'Cart'),
    ('/loyalty', Icons.card_membership_outlined, 'Loyalty'),
    ('/account', Icons.person_outline, 'Account'),
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
            NavigationDestination(
              key: ValueKey('tab-${t.$1}'),
              icon: Icon(t.$2),
              label: t.$3,
            ),
        ],
      ),
    );
  }
}

class _HomeScreen extends ConsumerWidget {
  const _HomeScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final campaigns = ref.watch(campaignsStoreProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            tooltip: 'Select store',
            icon: const Icon(Icons.store_mall_directory_outlined),
            onPressed: () => context.push('/store/select'),
          ),
          IconButton(
            tooltip: 'Refresh campaigns',
            icon: const Icon(Icons.refresh),
            onPressed: () {
              try {
                if (ref.read(campaignsStoreProvider).isEmpty) {
                  ref
                      .read(campaignsStoreProvider.notifier)
                      .add('Welcome', '10% off first order');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Campaigns refreshed')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Campaigns up to date')),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Failed to refresh campaigns'),
                    action: SnackBarAction(
                      label: 'Retry',
                      onPressed: () {
                        try {
                          ref
                              .read(campaignsStoreProvider.notifier)
                              .add('Welcome', '10% off first order');
                        } catch (_) {}
                      },
                    ),
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: ListView(
        children: [
          if (campaigns.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: EmptyState(
                message: 'No campaigns right now',
                icon: Icons.campaign_outlined,
              ),
            )
          else
            SizedBox(
              height: 140,
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                scrollDirection: Axis.horizontal,
                itemBuilder: (context, i) {
                  final c = campaigns[i];
                  return SizedBox(
                    width: 240,
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              c.title,
                              style: Theme.of(context).textTheme.titleMedium,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              c.body,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemCount: campaigns.length,
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => context.go('/order'),
                        child: const Text('Order'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => context.go('/loyalty'),
                        child: const Text('Loyalty'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => context.go('/account'),
                    child: const Text('Account'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Order again',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                _LastOrdersList(),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
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
      appBar: AppBar(
        title: const Text('Order'),
        actions: [
          IconButton(
            tooltip: 'Refresh Menu',
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              try {
                await ref.read(menuStoreProvider.notifier).refreshMenu();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Menu refreshed')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Failed to refresh menu'),
                      action: SnackBarAction(
                        label: 'Retry',
                        onPressed: () async {
                          try {
                            await ref
                                .read(menuStoreProvider.notifier)
                                .refreshMenu();
                          } catch (_) {}
                        },
                      ),
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
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
            child: menu.categories.isEmpty
                ? const EmptyState(message: 'No menu available')
                : ListView(
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
                                onTap: () => context.push('/product/${m.id}'),
                                title: Text(m.name),
                                subtitle: Text(currency(m.priceCents)),
                                trailing: IconButton(
                                  icon: const Icon(Icons.add_circle_outline),
                                  onPressed: () {
                                    try {
                                      ref
                                          .read(cartStoreProvider.notifier)
                                          .add(m);
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text('Added to cart'),
                                        ),
                                      );
                                    } catch (e) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: const Text(
                                            'Failed to add to cart',
                                          ),
                                          action: SnackBarAction(
                                            label: 'Retry',
                                            onPressed: () {
                                              try {
                                                ref
                                                    .read(
                                                      cartStoreProvider
                                                          .notifier,
                                                    )
                                                    .add(m);
                                              } catch (_) {}
                                            },
                                          ),
                                        ),
                                      );
                                    }
                                  },
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
            key: const ValueKey('btn-view-cart'),
            onPressed: cart.items.isEmpty ? null : () => context.go('/cart'),
            child: const Text('View Cart'),
          ),
        ),
      ),
    );
  }
}

class _CartScreen extends ConsumerWidget {
  const _CartScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartStoreProvider);
    final currency = (int cents) => '₺ ${(cents / 100).toStringAsFixed(2)}';
    int pickup = 0; // 0 ASAP, 10 in 10m
    return Scaffold(
      appBar: AppBar(title: const Text('Cart')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: cart.items.isEmpty
                  ? const EmptyState(message: 'Your cart is empty')
                  : ListView.builder(
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
            const Text('Pickup time'),
            const SizedBox(height: 8),
            StatefulBuilder(
              builder: (context, setState) {
                return SegmentedButton<int>(
                  segments: const [
                    ButtonSegment<int>(value: 0, label: Text('ASAP')),
                    ButtonSegment<int>(value: 10, label: Text('+10 min')),
                  ],
                  selected: {pickup},
                  onSelectionChanged: (s) => setState(() => pickup = s.first),
                );
              },
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
                  key: const ValueKey('btn-checkout'),
                  onPressed: cart.items.isEmpty
                      ? null
                      : () => context.push('/checkout'),
                  child: const Text('Checkout'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MoreScreen extends ConsumerWidget {
  const _MoreScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authStoreProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (session == null)
              ElevatedButton(
                onPressed: () => context.go('/signin'),
                child: const Text('Sign In'),
              )
            else ...[
              ElevatedButton(
                onPressed: () => context.go('/profile'),
                child: const Text('Profile'),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => context.go('/orders'),
                child: const Text('My Orders'),
              ),
              if (session.isAdmin) ...[
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => _showAdminPanel(context, ref),
                  child: const Text('Admin Panel'),
                ),
              ],
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => ref.read(authStoreProvider.notifier).signOut(),
                child: const Text('Logout'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

void _showAdminPanel(BuildContext context, WidgetRef ref) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) {
      final orders = ref.watch(ordersStoreProvider).orders;
      final pointsIssued = ref
          .watch(loyaltyStoreProvider)
          .transactions
          .where((t) => t.delta > 0)
          .fold<int>(0, (s, t) => s + t.delta);
      final pointsRedeemed = ref
          .watch(loyaltyStoreProvider)
          .transactions
          .where((t) => t.delta < 0)
          .fold<int>(0, (s, t) => s + t.delta.abs());
      return SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Admin Dashboard',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Orders today: ${orders.length}',
            ).applyDefaultTextStyle(context),
            Text(
              'Points issued today: $pointsIssued',
            ).applyDefaultTextStyle(context),
            Text(
              'Points redeemed today: $pointsRedeemed',
            ).applyDefaultTextStyle(context),
            const Divider(height: 24),
            const Text('Scan & Earn (enter user id then amount)'),
            const SizedBox(height: 8),
            _ScanEarnForm(),
            const Divider(height: 24),
            Text('Campaigns', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            _CampaignsForm(),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Orders Management'),
                TextButton(
                  onPressed: () => showModalBottomSheet<void>(
                    context: context,
                    showDragHandle: true,
                    builder: (_) => const AdminMenuSheet(),
                  ),
                  child: const Text('Menu CRUD'),
                ),
              ],
            ),
            for (final o in orders)
              ListTile(
                title: Text('#${o.id}'),
                subtitle: Text(o.status.name),
                trailing: Wrap(
                  spacing: 8,
                  children: [
                    ElevatedButton(
                      onPressed: o.status == OrderStatus.ready
                          ? null
                          : () {
                              try {
                                ref
                                    .read(ordersStoreProvider.notifier)
                                    .updateStatus(o.id, OrderStatus.ready);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Marked ready')),
                                );
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text(
                                      'Failed to update status',
                                    ),
                                    action: SnackBarAction(
                                      label: 'Retry',
                                      onPressed: () {
                                        try {
                                          ref
                                              .read(
                                                ordersStoreProvider.notifier,
                                              )
                                              .updateStatus(
                                                o.id,
                                                OrderStatus.ready,
                                              );
                                        } catch (_) {}
                                      },
                                    ),
                                  ),
                                );
                              }
                            },
                      child: const Text('Ready'),
                    ),
                    ElevatedButton(
                      onPressed: o.status == OrderStatus.completed
                          ? null
                          : () {
                              try {
                                ref
                                    .read(ordersStoreProvider.notifier)
                                    .updateStatus(o.id, OrderStatus.completed);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Marked completed'),
                                  ),
                                );
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text(
                                      'Failed to update status',
                                    ),
                                    action: SnackBarAction(
                                      label: 'Retry',
                                      onPressed: () {
                                        try {
                                          ref
                                              .read(
                                                ordersStoreProvider.notifier,
                                              )
                                              .updateStatus(
                                                o.id,
                                                OrderStatus.completed,
                                              );
                                        } catch (_) {}
                                      },
                                    ),
                                  ),
                                );
                              }
                            },
                      child: const Text('Complete'),
                    ),
                  ],
                ),
              ),
          ],
        ),
      );
    },
  );
}

class _ScanEarnForm extends ConsumerStatefulWidget {
  const _ScanEarnForm();
  @override
  ConsumerState<_ScanEarnForm> createState() => _ScanEarnFormState();
}

class _ScanEarnFormState extends ConsumerState<_ScanEarnForm> {
  final idCtrl = TextEditingController();
  final ptsCtrl = TextEditingController();

  @override
  void dispose() {
    idCtrl.dispose();
    ptsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: idCtrl,
            decoration: const InputDecoration(labelText: 'User ID'),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 100,
          child: TextField(
            controller: ptsCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Points'),
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: () {
            final userId = idCtrl.text.trim();
            final pts = int.tryParse(ptsCtrl.text) ?? 0;
            if (userId.isEmpty || pts <= 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Enter user and positive points')),
              );
              return;
            }
            try {
              ref
                  .read(loyaltyStoreProvider.notifier)
                  .earn(pts, reason: 'Admin manual earn');
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Points added')));
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Failed to add points'),
                  action: SnackBarAction(
                    label: 'Retry',
                    onPressed: () {
                      try {
                        ref
                            .read(loyaltyStoreProvider.notifier)
                            .earn(pts, reason: 'Admin manual earn');
                      } catch (_) {}
                    },
                  ),
                ),
              );
            }
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}

class _CampaignsForm extends ConsumerStatefulWidget {
  @override
  ConsumerState<_CampaignsForm> createState() => _CampaignsFormState();
}

class _CampaignsFormState extends ConsumerState<_CampaignsForm> {
  final titleCtrl = TextEditingController();
  final bodyCtrl = TextEditingController();

  @override
  void dispose() {
    titleCtrl.dispose();
    bodyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final campaigns = ref.watch(campaignsStoreProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final c in campaigns)
          ListTile(title: Text(c.title), subtitle: Text(c.body)),
        const SizedBox(height: 8),
        TextField(
          controller: titleCtrl,
          decoration: const InputDecoration(labelText: 'Title'),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: bodyCtrl,
          decoration: const InputDecoration(labelText: 'Body'),
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: () {
            if (titleCtrl.text.isEmpty || bodyCtrl.text.isEmpty) return;
            ref
                .read(campaignsStoreProvider.notifier)
                .add(titleCtrl.text.trim(), bodyCtrl.text.trim());
            titleCtrl.clear();
            bodyCtrl.clear();
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Campaign added')));
          },
          child: const Text('Add campaign'),
        ),
      ],
    );
  }
}

class _OrdersHistoryScreen extends ConsumerWidget {
  const _OrdersHistoryScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(ordersStoreProvider).orders;
    return Scaffold(
      appBar: AppBar(title: const Text('My Orders')),
      body: orders.isEmpty
          ? const EmptyState(message: 'No orders yet', icon: Icons.receipt_long)
          : ListView.builder(
              itemCount: orders.length,
              itemBuilder: (context, i) {
                final o = orders[orders.length - 1 - i];
                return ListTile(
                  title: Text(
                    '#${o.id.substring(o.id.length - 6)} • ${o.status.name}',
                  ),
                  subtitle: Text('${o.createdAt} • ${o.items.length} items'),
                  trailing: Text(
                    '₺ ${(o.totalCents / 100).toStringAsFixed(2)}',
                  ),
                  onTap: () => context.push('/order/${o.id}/tracker'),
                );
              },
            ),
    );
  }
}

class _CheckoutScreen extends ConsumerStatefulWidget {
  const _CheckoutScreen();
  @override
  ConsumerState<_CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<_CheckoutScreen> {
  bool _loading = false;
  String? _error;

  Future<void> _pay(BuildContext context) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final cart = ref.read(cartStoreProvider);
      if (cart.items.isEmpty) {
        setState(() => _error = 'Cart is empty');
        return;
      }
      final cartPayload = {
        'items': [
          for (final it in cart.items)
            {
              'id': it.item.id,
              'name': it.item.name,
              'qty': it.qty,
              'price_cents': it.item.priceCents,
              if (it.note != null) 'note': it.note,
            },
        ],
        'subtotal_cents': cart.totalCents,
      };
      final intent = await FunctionsClient.instance.createPaymentIntent({
        'cart': cartPayload,
        'store_id': 'default',
      });
      // Normally: handoff to provider SDK using client_secret/provider_params here
      final confirm = await FunctionsClient.instance.confirmCheckout({
        'intent_id': intent['client_secret'] ?? 'stub',
      });
      final orderId =
          (confirm['order_id'] as String?) ??
          DateTime.now().millisecondsSinceEpoch.toString();
      ref.read(cartStoreProvider.notifier).clear();
      if (mounted) {
        context.go('/order/$orderId/tracker');
      }
    } catch (e) {
      setState(() => _error = 'Checkout failed');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Payment method UI will be here (Stripe/iyzico).'),
            const SizedBox(height: 12),
            if (_error != null)
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _loading ? null : () => _pay(context),
              child: _loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Pay'),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderTrackerScreen extends StatelessWidget {
  const _OrderTrackerScreen({required this.orderId});
  final String orderId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Order Tracker')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Order: $orderId'),
            const SizedBox(height: 12),
            const ListTile(
              leading: Icon(Icons.looks_one),
              title: Text('Received'),
              subtitle: Text('Timestamp…'),
            ),
            const ListTile(
              leading: Icon(Icons.looks_two),
              title: Text('In prep'),
              subtitle: Text('Timestamp…'),
            ),
            const ListTile(
              leading: Icon(Icons.looks_3),
              title: Text('Ready'),
              subtitle: Text('Timestamp…'),
            ),
            const SizedBox(height: 12),
            const Text('Pickup code: 123456'),
          ],
        ),
      ),
    );
  }
}

class _ReceiptScreen extends StatelessWidget {
  const _ReceiptScreen({required this.orderId});
  final String orderId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Receipt')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Receipt for order $orderId'),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () {
                // Placeholder for Storage PDF open
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Open receipt PDF from Storage'),
                  ),
                );
              },
              child: const Text('Open PDF'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StoreSelectScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Store')),
      body: ListView(
        children: const [
          ListTile(title: Text('Nearest store • 0.5 km • Open now')),
          ListTile(title: Text('Downtown • 2.1 km • Closes 22:00')),
        ],
      ),
    );
  }
}

extension on Text {
  Text applyDefaultTextStyle(BuildContext context) =>
      Text(data ?? '', style: Theme.of(context).textTheme.bodyMedium);
}

/// A simple dialog-like page to present modal content.
class DialogPage extends CustomTransitionPage<void> {
  DialogPage({required Widget child})
    : super(
        child: child,
        fullscreenDialog: true,
        barrierDismissible: true,
        transitionDuration: const Duration(milliseconds: 260),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.08),
              end: Offset.zero,
            ).animate(curved),
            child: FadeTransition(opacity: curved, child: child),
          );
        },
      );
}

class _MyCardScreen extends ConsumerWidget {
  const _MyCardScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(fakeUserIdProvider);
    final loyalty = ref.watch(loyaltyStoreProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Loyalty')),
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
  await showModalBottomSheet<void>(
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
                      ? () async {
                          final ok = await ref
                              .read(loyaltyStoreProvider.notifier)
                              .redeem(r);
                          if (context.mounted) {
                            Navigator.of(context).pop();
                            if (!ok) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Not enough points'),
                                ),
                              );
                            }
                          }
                        }
                      : () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Not enough points')),
                          );
                        },
                  child: const Text('Redeem'),
                ),
              ),
          ],
        ),
      );
    },
  );
}

class _LastOrdersList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(ordersStoreProvider); // watch for updates
    final last = ref.read(ordersStoreProvider.notifier).lastOrders(limit: 3);
    if (last.isEmpty) {
      return const EmptyState(message: 'No recent orders');
    }
    String currency(int cents) => '₺ ${(cents / 100).toStringAsFixed(2)}';
    return Column(
      children: [
        for (final o in last)
          Card(
            child: ListTile(
              title: Text(
                '#${o.id.substring(o.id.length - 6)} • ${o.status.name}',
              ),
              subtitle: Text(
                '${o.items.length} items • ${currency(o.totalCents)}',
              ),
              trailing: TextButton(
                onPressed: () =>
                    ref.read(ordersStoreProvider.notifier).reorder(o),
                child: const Text('Reorder'),
              ),
            ),
          ),
      ],
    );
  }
}

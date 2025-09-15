import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../widgets/qr_box.dart';
import '../../features/loyalty/data/loyalty_store.dart';
import '../../features/menu/data/menu_store.dart';
import '../../features/cart/data/cart_store.dart';
import '../../features/orders/data/orders_store.dart';
import '../../features/menu/domain/models.dart';
import '../../features/menu/ui/item_detail.dart';
import '../../features/auth/ui/auth_screens.dart';
import '../../features/auth/data/auth_store.dart';
import '../../features/profile/data/profile_store.dart';
import '../../features/menu/ui/admin_menu.dart';
import '../../features/admin/data/campaigns_store.dart';
import '../../widgets/empty_state.dart';

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
            path: '/item/:id',
            builder: (context, state) {
              final menu = ref.read(menuStoreProvider);
              final id = state.pathParameters['id']!;
              final item = findItemById(menu, id);
              return ItemDetailScreen(item: item!);
            },
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
    ('/profile', Icons.person, 'Profile'),
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
    final campaigns = const [
      ('Welcome', '10% off first order'),
      ('New Beans', 'Try our seasonal roast'),
      ('Rewards', 'Redeem points for free coffee'),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: ListView(
        children: [
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
                            c.$1,
                            style: Theme.of(context).textTheme.titleMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            c.$2,
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
            child: Row(
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
                    onPressed: () => context.go('/card'),
                    child: const Text('My Card'),
                  ),
                ),
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
                                onTap: () => context.push('/item/${m.id}'),
                                title: Text(m.name),
                                subtitle: Text(currency(m.priceCents)),
                                trailing: IconButton(
                                  icon: const Icon(Icons.add_circle_outline),
                                  onPressed: () => ref
                                      .read(cartStoreProvider.notifier)
                                      .add(m),
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
    Future<void> callCafe() async {
      final uri = Uri(scheme: 'tel', path: '+905550000000');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    }

    Future<void> openMap() async {
      final uri = Uri.parse('https://maps.google.com/?q=123+Coffee+St');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Store')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Address: 123 Coffee St'),
            const SizedBox(height: 8),
            const Text('Hours: 8:00 - 20:00'),
            const SizedBox(height: 8),
            const Text('Phone: +90 555 000 00 00'),
            const SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton(onPressed: callCafe, child: const Text('Call')),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: openMap,
                  child: const Text('Open Map'),
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
      appBar: AppBar(title: const Text('More')),
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
                child: const Text('Sign Out'),
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
            Text('Orders today: ${orders.length}'),
            Text('Points issued today: $pointsIssued'),
            Text('Points redeemed today: $pointsRedeemed'),
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
                          : () => ref
                                .read(ordersStoreProvider.notifier)
                                .updateStatus(o.id, OrderStatus.ready),
                      child: const Text('Ready'),
                    ),
                    ElevatedButton(
                      onPressed: o.status == OrderStatus.completed
                          ? null
                          : () => ref
                                .read(ordersStoreProvider.notifier)
                                .updateStatus(o.id, OrderStatus.completed),
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
            final pts = int.tryParse(ptsCtrl.text) ?? 0;
            if (pts > 0) {
              ref
                  .read(loyaltyStoreProvider.notifier)
                  .earn(pts, reason: 'Admin manual earn');
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Points added')));
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
          ? const EmptyState(message: 'No orders yet', icon: Icons.receipt_long)
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

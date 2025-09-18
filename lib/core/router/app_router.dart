import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
// Firebase imports disabled for UI testing
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_storage/firebase_storage.dart';
// import 'package:url_launcher/url_launcher.dart';
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
import '../../features/profile/data/profile_store.dart';
import '../../widgets/empty_state.dart';
import '../../common/services/functions_client.dart';
import '../../common/services/store_service.dart';
import '../../common/models/store.dart';

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
    final storeState = ref.watch(storeProvider);
    final profile = ref.watch(profileStoreProvider);

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
          // Greeting section
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 600),
            tween: Tween(begin: 0.0, end: 1.0),
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getGreeting(profile?.name),
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'What would you like to order today?',
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),

          // Nearest store card
          if (storeState.nearestStore != null)
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 800),
              tween: Tween(begin: 0.0, end: 1.0),
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, 30 * (1 - value)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _NearestStoreCard(store: storeState.nearestStore!),
                    ),
                  ),
                );
              },
            ),

          const SizedBox(height: 16),

          // Promo banner
          if (campaigns.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _PromoBanner(campaigns: campaigns),
            ),

          const SizedBox(height: 16),

          // Action buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => context.go('/order'),
                        icon: const Icon(Icons.shopping_bag_outlined),
                        label: const Text('Order Now'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => context.go('/loyalty'),
                        icon: const Icon(Icons.card_membership_outlined),
                        label: const Text('Loyalty'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => context.go('/account'),
                    icon: const Icon(Icons.person_outline),
                    label: const Text('Account'),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Order again section
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

  String _getGreeting(String? name) {
    final hour = DateTime.now().hour;
    String timeGreeting;
    if (hour < 12) {
      timeGreeting = 'Good morning';
    } else if (hour < 17) {
      timeGreeting = 'Good afternoon';
    } else {
      timeGreeting = 'Good evening';
    }

    if (name != null && name.isNotEmpty) {
      return '$timeGreeting, $name!';
    }
    return '$timeGreeting!';
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
                : ListView.builder(
                    itemCount: menu.categories.length,
                    itemBuilder: (context, categoryIndex) {
                      final c = menu.categories[categoryIndex];
                      final items =
                          menu.itemsByCategory[c.id] ?? const <MenuItemModel>[];

                      return TweenAnimationBuilder<double>(
                        duration: Duration(
                          milliseconds: 600 + (categoryIndex * 100),
                        ),
                        tween: Tween(begin: 0.0, end: 1.0),
                        builder: (context, value, child) {
                          return Opacity(
                            opacity: value,
                            child: Transform.translate(
                              offset: Offset(0, 20 * (1 - value)),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    child: Text(
                                      c.name,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleMedium,
                                    ),
                                  ),
                                  for (
                                    int itemIndex = 0;
                                    itemIndex < items.length;
                                    itemIndex++
                                  )
                                    TweenAnimationBuilder<double>(
                                      duration: Duration(
                                        milliseconds:
                                            800 +
                                            (categoryIndex * 100) +
                                            (itemIndex * 50),
                                      ),
                                      tween: Tween(begin: 0.0, end: 1.0),
                                      builder: (context, itemValue, child) {
                                        final m = items[itemIndex];
                                        return Opacity(
                                          opacity: itemValue,
                                          child: Transform.translate(
                                            offset: Offset(
                                              0,
                                              10 * (1 - itemValue),
                                            ),
                                            child: ListTile(
                                              onTap: () => context.push(
                                                '/product/${m.id}',
                                              ),
                                              title: Text(m.name),
                                              subtitle: Text(
                                                currency(m.priceCents),
                                              ),
                                              trailing: IconButton(
                                                icon: const Icon(
                                                  Icons.add_circle_outline,
                                                ),
                                                onPressed: () {
                                                  try {
                                                    ref
                                                        .read(
                                                          cartStoreProvider
                                                              .notifier,
                                                        )
                                                        .add(m);
                                                    ScaffoldMessenger.of(
                                                      context,
                                                    ).showSnackBar(
                                                      const SnackBar(
                                                        content: Text(
                                                          'Added to cart',
                                                        ),
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
                                          ),
                                        );
                                      },
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
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

            // Rewards section
            if (cart.items.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Rewards'),
                  TextButton(
                    onPressed: () => _showRewardsDialog(context, ref),
                    child: const Text('Apply Reward'),
                  ),
                ],
              ),
              if (cart.appliedReward != null)
                Card(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: ListTile(
                    leading: Icon(
                      Icons.card_giftcard,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                    title: Text(
                      cart.appliedReward!.title,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                    subtitle: Text(
                      '${cart.appliedReward!.costPoints} points',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                    trailing: IconButton(
                      onPressed: () =>
                          ref.read(cartStoreProvider.notifier).removeReward(),
                      icon: Icon(
                        Icons.close,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 8),
            ],

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

            // Order summary
            if (cart.items.isNotEmpty) ...[
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Subtotal'),
                  Text(currency(cart.subtotalCents)),
                ],
              ),
              if (cart.appliedReward != null)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Reward: ${cart.appliedReward!.title}'),
                    Text('-${currency(cart.appliedReward!.costPoints)}'),
                  ],
                ),
              if (cart.discountCents > 0)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Discount: ${cart.promoCode ?? 'Promo'}'),
                    Text('-${currency(cart.discountCents)}'),
                  ],
                ),
              const Divider(),
            ],

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

Future<void> _showRewardsDialog(BuildContext context, WidgetRef ref) async {
  final loyalty = ref.read(loyaltyStoreProvider);
  final cart = ref.read(cartStoreProvider);

  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Available Rewards',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            if (loyalty.rewards.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('No rewards available'),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                itemCount: loyalty.rewards.length,
                itemBuilder: (context, index) {
                  final reward = loyalty.rewards[index];
                  final canAfford = loyalty.points >= reward.costPoints;
                  final isApplied = cart.appliedReward?.id == reward.id;

                  return ListTile(
                    leading: Icon(
                      isApplied ? Icons.check_circle : Icons.card_giftcard,
                      color: isApplied
                          ? Theme.of(context).colorScheme.primary
                          : canAfford
                          ? Theme.of(context).colorScheme.onSurface
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    title: Text(reward.title),
                    subtitle: Text('${reward.costPoints} points'),
                    trailing: isApplied
                        ? TextButton(
                            onPressed: () {
                              ref
                                  .read(cartStoreProvider.notifier)
                                  .removeReward();
                              Navigator.of(context).pop();
                            },
                            child: const Text('Remove'),
                          )
                        : TextButton(
                            onPressed: canAfford
                                ? () {
                                    ref
                                        .read(cartStoreProvider.notifier)
                                        .applyReward(reward);
                                    Navigator.of(context).pop();
                                  }
                                : null,
                            child: const Text('Apply'),
                          ),
                  );
                },
              ),
            const SizedBox(height: 16),
          ],
        ),
      );
    },
  );
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

class _OrderTrackerScreen extends ConsumerWidget {
  const _OrderTrackerScreen({required this.orderId});
  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Order Tracker')),
      body: _buildMockOrderTracker(context),
    );
  }

  Widget _buildMockOrderTracker(BuildContext context) {
    final now = DateTime.now();
    final createdAt = now.subtract(const Duration(minutes: 15));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order details card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order #${orderId.substring(orderId.length - 6)}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text('Total: ₺ 12.50'),
                  Text('Placed: ${_formatDateTime(createdAt)}'),
                  const SizedBox(height: 8),
                  Text(
                    'Pickup Code: 123456',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Order status steps
          Text('Order Status', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),

          _StatusStep(
            step: 1,
            title: 'Order Received',
            isCompleted: true,
            timestamp: createdAt,
          ),
          _StatusStep(
            step: 2,
            title: 'In Preparation',
            isCompleted: false,
            isActive: true,
          ),
          _StatusStep(
            step: 3,
            title: 'Ready for Pickup',
            isCompleted: false,
            isActive: false,
          ),

          const SizedBox(height: 24),

          // Order items
          Text('Order Items', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),

          ListTile(
            title: const Text('Espresso'),
            subtitle: const Text('Qty: 1'),
            trailing: const Text('₺ 4.50'),
          ),
          ListTile(
            title: const Text('Croissant'),
            subtitle: const Text('Qty: 2'),
            trailing: const Text('₺ 8.00'),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

class _StatusStep extends StatelessWidget {
  const _StatusStep({
    required this.step,
    required this.title,
    required this.isCompleted,
    this.isActive = false,
    this.timestamp,
  });

  final int step;
  final String title;
  final bool isCompleted;
  final bool isActive;
  final DateTime? timestamp;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isCompleted
                  ? Theme.of(context).colorScheme.primary
                  : isActive
                  ? Theme.of(context).colorScheme.primaryContainer
                  : Theme.of(context).colorScheme.surfaceVariant,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: isCompleted
                  ? const Icon(Icons.check, color: Colors.white, size: 20)
                  : Text(
                      step.toString(),
                      style: TextStyle(
                        color: isActive
                            ? Theme.of(context).colorScheme.onPrimaryContainer
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: isCompleted || isActive
                        ? Theme.of(context).colorScheme.onSurface
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: isActive ? FontWeight.bold : null,
                  ),
                ),
                if (timestamp != null)
                  Text(
                    _formatDateTime(timestamp!),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

class _ReceiptScreen extends ConsumerStatefulWidget {
  const _ReceiptScreen({required this.orderId});
  final String orderId;

  @override
  ConsumerState<_ReceiptScreen> createState() => _ReceiptScreenState();
}

class _ReceiptScreenState extends ConsumerState<_ReceiptScreen> {
  bool _loading = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Receipt')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Receipt for order #${widget.orderId.substring(widget.orderId.length - 6)}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Your receipt is ready for download',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            if (_loading)
              const CircularProgressIndicator()
            else if (_error != null)
              Column(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: Theme.of(context).colorScheme.error,
                    size: 48,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _downloadReceipt,
                    child: const Text('Retry'),
                  ),
                ],
              )
            else
              ElevatedButton.icon(
                onPressed: _downloadReceipt,
                icon: const Icon(Icons.download),
                label: const Text('Download PDF'),
              ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _downloadReceipt() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // Mock receipt for UI testing
      await Future<void>.delayed(const Duration(seconds: 1));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mock receipt opened successfully')),
        );
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to download receipt: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }

    // Uncomment below to re-enable Firebase Storage
    // try {
    //   final storage = FirebaseStorage.instance;
    //   final receiptRef = storage.ref('receipts/${widget.orderId}.pdf');

    //   // Get download URL
    //   final downloadUrl = await receiptRef.getDownloadURL();

    //   // Open the PDF using url_launcher
    //   final uri = Uri.parse(downloadUrl);
    //   if (await canLaunchUrl(uri)) {
    //     await launchUrl(uri, mode: LaunchMode.externalApplication);
    //     if (mounted) {
    //       ScaffoldMessenger.of(context).showSnackBar(
    //         const SnackBar(content: Text('Receipt opened successfully')),
    //       );
    //     }
    //   } else {
    //     throw Exception('Could not open PDF');
    //   }
    // } catch (e) {
    //   setState(() {
    //     _error = 'Failed to download receipt: ${e.toString()}';
    //   });
    // } finally {
    //   if (mounted) {
    //     setState(() {
    //       _loading = false;
    //     });
    //   }
    // }
  }
}

class _StoreSelectScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storeState = ref.watch(storeProvider);
    final userLocation = storeState.userLocation;

    return Scaffold(
      appBar: AppBar(title: const Text('Select Store')),
      body: storeState.stores.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: storeState.stores.length,
              itemBuilder: (context, index) {
                final store = storeState.stores[index];
                final distance = userLocation != null
                    ? store.distanceFrom(
                        userLocation.latitude,
                        userLocation.longitude,
                      )
                    : null;

                return ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: store.isOpen
                          ? Theme.of(context).colorScheme.primaryContainer
                          : Theme.of(context).colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.store_mall_directory_outlined,
                      color: store.isOpen
                          ? Theme.of(context).colorScheme.onPrimaryContainer
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  title: Text(store.name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(store.address),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          if (distance != null) ...[
                            Text('${distance.toStringAsFixed(1)} km'),
                            const Text(' • '),
                          ],
                          Text(store.statusText),
                        ],
                      ),
                    ],
                  ),
                  trailing: storeState.selectedStoreId == store.id
                      ? Icon(
                          Icons.check_circle,
                          color: Theme.of(context).colorScheme.primary,
                        )
                      : null,
                  onTap: () {
                    ref.read(storeProvider.notifier).selectStore(store.id);
                    Navigator.of(context).pop();
                  },
                );
              },
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

class _NearestStoreCard extends StatelessWidget {
  const _NearestStoreCard({required this.store});

  final Store store;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: store.isOpen
                    ? Theme.of(context).colorScheme.primaryContainer
                    : Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.store_mall_directory_outlined,
                color: store.isOpen
                    ? Theme.of(context).colorScheme.onPrimaryContainer
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    store.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    store.address,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    store.statusText,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: store.isOpen
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.error,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => context.push('/store/select'),
              icon: const Icon(Icons.arrow_forward_ios),
            ),
          ],
        ),
      ),
    );
  }
}

class _PromoBanner extends StatelessWidget {
  const _PromoBanner({required this.campaigns});

  final List<Campaign> campaigns;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primaryContainer,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: PageView.builder(
        itemCount: campaigns.length,
        itemBuilder: (context, index) {
          final campaign = campaigns[index];
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  campaign.title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  campaign.body,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const Spacer(),
                Align(
                  alignment: Alignment.bottomRight,
                  child: TextButton(
                    onPressed: () => context.go('/order'),
                    style: TextButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    ),
                    child: const Text('Order Now'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
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

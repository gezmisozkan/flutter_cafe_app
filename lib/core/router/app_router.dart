import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../widgets/qr_box.dart';

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

class _OrderScreen extends StatelessWidget {
  const _OrderScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Order')),
      body: const Center(child: Text('Menu coming soon')),
    );
  }
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
    return Scaffold(
      appBar: AppBar(title: const Text('More')),
      body: const Center(child: Text('Settings & Admin soon')),
    );
  }
}

class _MyCardScreen extends ConsumerWidget {
  const _MyCardScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(fakeUserIdProvider);
    final points = ref.watch(loyaltyPointsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('My Card')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Points: $points',
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
                      ref.read(loyaltyPointsProvider.notifier).earn(10),
                  child: const Text('Earn +10'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () =>
                      ref.read(loyaltyPointsProvider.notifier).redeem(10),
                  child: const Text('Redeem -10'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

final fakeUserIdProvider = Provider<String>((ref) => 'user-1234');

class LoyaltyPointsNotifier extends StateNotifier<int> {
  LoyaltyPointsNotifier() : super(0);

  void earn(int delta) => state += delta;
  void redeem(int delta) => state = (state - delta).clamp(0, 1 << 31);
}

final loyaltyPointsProvider = StateNotifierProvider<LoyaltyPointsNotifier, int>(
  (ref) {
    return LoyaltyPointsNotifier();
  },
);

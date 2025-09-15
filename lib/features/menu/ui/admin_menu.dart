import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../menu/data/menu_store.dart';
import '../../menu/domain/models.dart';

class AdminMenuSheet extends ConsumerWidget {
  const AdminMenuSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final menu = ref.watch(menuStoreProvider);
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Menu Items', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          for (final c in menu.categories)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c.name, style: Theme.of(context).textTheme.titleMedium),
                for (final m
                    in menu.itemsByCategory[c.id] ?? const <MenuItemModel>[])
                  ListTile(
                    title: Text(m.name),
                    subtitle: Text(
                      '₺ ${(m.priceCents / 100).toStringAsFixed(2)}',
                    ),
                    trailing: const Icon(Icons.edit),
                  ),
                const Divider(),
              ],
            ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Add/Edit not implemented in mock'),
                ),
              );
            },
            child: const Text('Add new item'),
          ),
        ],
      ),
    );
  }
}

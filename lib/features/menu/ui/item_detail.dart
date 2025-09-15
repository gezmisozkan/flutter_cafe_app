import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../menu/data/menu_store.dart';
import '../../menu/domain/models.dart';
import '../../cart/data/cart_store.dart';

class ItemDetailScreen extends ConsumerStatefulWidget {
  const ItemDetailScreen({super.key, required this.item});

  final MenuItemModel item;

  @override
  ConsumerState<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends ConsumerState<ItemDetailScreen> {
  final TextEditingController _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  String currency(int cents) => '₺ ${(cents / 100).toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.item.name)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Container(
                color: Colors.brown.shade50,
                child: const Icon(Icons.local_cafe, size: 64),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              currency(widget.item.priceCents),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _noteController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Notes (milk/sugar, etc.)',
                border: OutlineInputBorder(),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  void add() {
                    ref
                        .read(cartStoreProvider.notifier)
                        .add(
                          widget.item,
                          note: _noteController.text.isEmpty
                              ? null
                              : _noteController.text,
                        );
                  }

                  try {
                    add();
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Added to cart')),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Failed to add to cart'),
                        action: SnackBarAction(
                          label: 'Retry',
                          onPressed: () {
                            try {
                              add();
                              Navigator.of(context).pop();
                            } catch (_) {}
                          },
                        ),
                      ),
                    );
                  }
                },
                child: const Text('Add to cart'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

MenuItemModel? findItemById(MenuState menu, String id) {
  for (final list in menu.itemsByCategory.values) {
    for (final m in list) {
      if (m.id == id) return m;
    }
  }
  return null;
}

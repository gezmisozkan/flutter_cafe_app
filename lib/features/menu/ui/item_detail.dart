import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

  // Modifiers state
  List<_ModGroup> _groups = const [];
  final Map<String, String> _singleSelected = {}; // groupId -> optionId
  final Map<String, Set<String>> _multiSelected = {}; // groupId -> optionIds

  @override
  void initState() {
    super.initState();
    _loadModifiers();
  }

  Future<void> _loadModifiers() async {
    try {
      final base = FirebaseFirestore.instance
          .collection('products')
          .doc(widget.item.id)
          .collection('modifiers');
      final groupsSnap = await base.orderBy('sort').get();
      final groups = <_ModGroup>[];
      for (final g in groupsSnap.docs) {
        final data = g.data();
        final optionsSnap = await base
            .doc(g.id)
            .collection('options')
            .orderBy('sort')
            .get();
        final options = <_ModOption>[];
        for (final o in optionsSnap.docs) {
          final od = o.data();
          options.add(
            _ModOption(
              id: o.id,
              name: (od['name'] as String?) ?? 'Option',
              priceDeltaCents: (od['price_delta'] as num?)?.toInt() ?? 0,
            ),
          );
        }
        groups.add(
          _ModGroup(
            id: g.id,
            name: (data['name'] as String?) ?? 'Choose',
            type: (data['type'] as String?) == 'multi'
                ? _GroupType.multi
                : _GroupType.single,
            required: (data['required'] as bool?) ?? false,
            options: options,
          ),
        );
      }
      if (mounted) setState(() => _groups = groups);
    } catch (_) {
      // keep no modifiers on failure
    }
  }

  int _priceWithMods() {
    int total = widget.item.priceCents;
    for (final g in _groups) {
      if (g.type == _GroupType.single) {
        final optId = _singleSelected[g.id];
        if (optId != null) {
          final opt = g.options.firstWhere(
            (o) => o.id == optId,
            orElse: () => _ModOption(id: '', name: '', priceDeltaCents: 0),
          );
          total += opt.priceDeltaCents;
        }
      } else {
        final set = _multiSelected[g.id] ?? {};
        for (final opt in g.options) {
          if (set.contains(opt.id)) total += opt.priceDeltaCents;
        }
      }
    }
    return total;
  }

  bool get _allRequiredChosen {
    for (final g in _groups) {
      if (g.required &&
          g.type == _GroupType.single &&
          _singleSelected[g.id] == null) {
        return false;
      }
    }
    return true;
  }

  String _modsSummaryNote() {
    final parts = <String>[];
    for (final g in _groups) {
      if (g.type == _GroupType.single) {
        final optId = _singleSelected[g.id];
        if (optId != null) {
          final opt = g.options.firstWhere((o) => o.id == optId);
          parts.add('${g.name}: ${opt.name}');
        }
      } else {
        final set = _multiSelected[g.id] ?? {};
        if (set.isNotEmpty) {
          final names = g.options
              .where((o) => set.contains(o.id))
              .map((o) => o.name)
              .join(', ');
          parts.add('${g.name}: $names');
        }
      }
    }
    if (_noteController.text.trim().isNotEmpty) {
      parts.add('Note: ${_noteController.text.trim()}');
    }
    return parts.join(' • ');
  }

  @override
  Widget build(BuildContext context) {
    final price = _priceWithMods();
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
              currency(price),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            if (_groups.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: _groups.length,
                  itemBuilder: (context, i) {
                    final g = _groups[i];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 8, bottom: 4),
                          child: Text(
                            g.required ? '${g.name} *' : g.name,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        if (g.type == _GroupType.single)
                          for (final o in g.options)
                            RadioListTile<String>(
                              value: o.id,
                              groupValue: _singleSelected[g.id],
                              onChanged: (v) =>
                                  setState(() => _singleSelected[g.id] = v!),
                              title: Text(o.name),
                              subtitle: o.priceDeltaCents == 0
                                  ? null
                                  : Text('+ ${currency(o.priceDeltaCents)}'),
                            )
                        else
                          for (final o in g.options)
                            CheckboxListTile(
                              value: (_multiSelected[g.id] ?? {}).contains(
                                o.id,
                              ),
                              onChanged: (v) {
                                setState(() {
                                  final set =
                                      _multiSelected[g.id] ?? <String>{};
                                  if (v == true) {
                                    set.add(o.id);
                                  } else {
                                    set.remove(o.id);
                                  }
                                  _multiSelected[g.id] = set;
                                });
                              },
                              title: Text(o.name),
                              subtitle: o.priceDeltaCents == 0
                                  ? null
                                  : Text('+ ${currency(o.priceDeltaCents)}'),
                            ),
                      ],
                    );
                  },
                ),
              )
            else
              TextField(
                controller: _noteController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Notes (milk/sugar, etc.)',
                  border: OutlineInputBorder(),
                ),
              ),
            if (_groups.isNotEmpty) const SizedBox(height: 8),
            if (_groups.isNotEmpty)
              TextField(
                controller: _noteController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: !_allRequiredChosen
                    ? null
                    : () {
                        void add() {
                          final note = _modsSummaryNote();
                          ref
                              .read(cartStoreProvider.notifier)
                              .add(
                                widget.item.copyWith(priceCents: price),
                                note: note.isEmpty ? null : note,
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

class _ModGroup {
  const _ModGroup({
    required this.id,
    required this.name,
    required this.type,
    required this.required,
    required this.options,
  });
  final String id;
  final String name;
  final _GroupType type;
  final bool required;
  final List<_ModOption> options;
}

class _ModOption {
  const _ModOption({
    required this.id,
    required this.name,
    required this.priceDeltaCents,
  });
  final String id;
  final String name;
  final int priceDeltaCents;
}

enum _GroupType { single, multi }

extension on MenuItemModel {
  MenuItemModel copyWith({
    String? id,
    String? categoryId,
    String? name,
    int? priceCents,
    String? imageUrl,
    bool? isActive,
  }) {
    return MenuItemModel(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      name: name ?? this.name,
      priceCents: priceCents ?? this.priceCents,
      imageUrl: imageUrl ?? this.imageUrl,
      isActive: isActive ?? this.isActive,
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

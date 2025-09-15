import 'dart:convert';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/models.dart';

class MenuState {
  const MenuState({required this.categories, required this.itemsByCategory});

  final List<MenuCategory> categories;
  final Map<String, List<MenuItemModel>> itemsByCategory;
}

class MenuStore extends StateNotifier<MenuState> {
  MenuStore() : super(_seed()) {
    // Load cached menu on startup; if none, persist the seed
    Future.microtask(() async {
      await _loadFromCacheOrPersistSeed();
    });
  }

  static const _prefsKey = 'menu_cache_v1';

  static MenuState _seed() {
    return MenuState(
      categories: [
        MenuCategory(id: 'c1', name: 'Coffee', sortOrder: 1),
        MenuCategory(id: 'c2', name: 'Tea', sortOrder: 2),
        MenuCategory(id: 'c3', name: 'Snacks', sortOrder: 3),
      ],
      itemsByCategory: {
        'c1': [
          MenuItemModel(
            id: 'm1',
            categoryId: 'c1',
            name: 'Espresso',
            priceCents: 4500,
          ),
          MenuItemModel(
            id: 'm2',
            categoryId: 'c1',
            name: 'Latte',
            priceCents: 6500,
          ),
          MenuItemModel(
            id: 'm3',
            categoryId: 'c1',
            name: 'Cappuccino',
            priceCents: 6000,
          ),
        ],
        'c2': [
          MenuItemModel(
            id: 'm4',
            categoryId: 'c2',
            name: 'Black Tea',
            priceCents: 3000,
          ),
          MenuItemModel(
            id: 'm5',
            categoryId: 'c2',
            name: 'Green Tea',
            priceCents: 3500,
          ),
        ],
        'c3': [
          MenuItemModel(
            id: 'm6',
            categoryId: 'c3',
            name: 'Croissant',
            priceCents: 4000,
          ),
          MenuItemModel(
            id: 'm7',
            categoryId: 'c3',
            name: 'Brownie',
            priceCents: 4500,
          ),
        ],
      },
    );
  }

  Future<void> _loadFromCacheOrPersistSeed() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_prefsKey);
      if (jsonStr == null) {
        await _persist(state);
        return;
      }
      final decoded = json.decode(jsonStr) as Map<String, dynamic>;
      state = _fromJson(decoded);
    } catch (_) {
      // keep seed on failure
    }
  }

  Future<void> refreshMenu() async {
    // Simulate a remote refresh: reset to seed and persist
    state = _seed();
    await _persist(state);
  }

  Future<void> _persist(MenuState s) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = json.encode(_toJson(s));
    await prefs.setString(_prefsKey, jsonStr);
  }

  Map<String, dynamic> _toJson(MenuState s) {
    return {
      'categories': [
        for (final c in s.categories)
          {'id': c.id, 'name': c.name, 'sortOrder': c.sortOrder},
      ],
      'itemsByCategory': {
        for (final entry in s.itemsByCategory.entries)
          entry.key: [
            for (final m in entry.value)
              {
                'id': m.id,
                'categoryId': m.categoryId,
                'name': m.name,
                'priceCents': m.priceCents,
                'imageUrl': m.imageUrl,
                'isActive': m.isActive,
              },
          ],
      },
    };
  }

  MenuState _fromJson(Map<String, dynamic> map) {
    final categories = <MenuCategory>[];
    final rawCats = (map['categories'] as List?) ?? [];
    for (final c in rawCats) {
      categories.add(
        MenuCategory(
          id: c['id'] as String,
          name: c['name'] as String,
          sortOrder: (c['sortOrder'] as num?)?.toInt() ?? 0,
        ),
      );
    }
    final itemsByCategory = <String, List<MenuItemModel>>{};
    final rawItems = (map['itemsByCategory'] as Map?) ?? {};
    for (final entry in rawItems.entries) {
      final list = <MenuItemModel>[];
      for (final m in (entry.value as List? ?? [])) {
        list.add(
          MenuItemModel(
            id: m['id'] as String,
            categoryId: m['categoryId'] as String,
            name: m['name'] as String,
            priceCents: (m['priceCents'] as num).toInt(),
            imageUrl: m['imageUrl'] as String?,
            isActive: (m['isActive'] as bool?) ?? true,
          ),
        );
      }
      itemsByCategory[entry.key as String] = list;
    }
    return MenuState(categories: categories, itemsByCategory: itemsByCategory);
  }
}

final menuStoreProvider = StateNotifierProvider<MenuStore, MenuState>((ref) {
  return MenuStore();
});

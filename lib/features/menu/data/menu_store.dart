import 'dart:convert';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/models.dart';
import '../../../common/services/supabase.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MenuState {
  const MenuState({required this.categories, required this.itemsByCategory});

  final List<MenuCategory> categories;
  final Map<String, List<MenuItemModel>> itemsByCategory;
}

class MenuStore extends StateNotifier<MenuState> {
  MenuStore(this._ref) : super(_seed()) {
    // Load cached menu on startup; if none, persist the seed
    Future.microtask(() async {
      await _loadFromCacheOrPersistSeed();
      await _maybeLoadFromFirestore();
      await _maybeLoadFromSupabase();
    });
  }
  final Ref _ref;

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
    // Prefer Firestore if available
    final fs = FirebaseFirestore.instance;
    try {
      await _loadFromFirestore(fs);
      return;
    } catch (_) {}

    final client = _ref.read(supabaseClientProvider);
    if (client != null) {
      await _maybeLoadFromSupabase();
      return;
    }
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

  Future<void> _maybeLoadFromFirestore() async {
    try {
      await _loadFromFirestore(FirebaseFirestore.instance);
    } catch (_) {
      // ignore
    }
  }

  Future<void> _loadFromFirestore(FirebaseFirestore fs) async {
    // For MVP, read public categories/products, active only, order by sort
    final catsSnap = await fs
        .collection('categories')
        .orderBy('sort')
        .where('active', isEqualTo: true)
        .get(const GetOptions(source: Source.serverAndCache));
    final categories = <MenuCategory>[];
    for (final d in catsSnap.docs) {
      final data = d.data();
      categories.add(
        MenuCategory(
          id: d.id,
          name: (data['name'] as String?) ?? 'Category',
          sortOrder: (data['sort'] as num?)?.toInt() ?? 0,
        ),
      );
    }
    final itemsByCategory = <String, List<MenuItemModel>>{};
    // Read all active products; filter by active and category
    final prodSnap = await fs
        .collection('products')
        .where('active', isEqualTo: true)
        .get(const GetOptions(source: Source.serverAndCache));
    for (final d in prodSnap.docs) {
      final data = d.data();
      final categoryId = (data['categoryId'] as String?) ?? '';
      if (categoryId.isEmpty) continue;
      final item = MenuItemModel(
        id: d.id,
        categoryId: categoryId,
        name: (data['name'] as String?) ?? 'Item',
        priceCents: (data['base_price'] as num?)?.toInt() ?? 0,
        imageUrl: data['image_url'] as String?,
        isActive: (data['active'] as bool?) ?? true,
      );
      (itemsByCategory[categoryId] ??= []).add(item);
    }
    state = MenuState(categories: categories, itemsByCategory: itemsByCategory);
    await _persist(state);
  }

  Future<void> _maybeLoadFromSupabase() async {
    final client = _ref.read(supabaseClientProvider);
    if (client == null) return;
    try {
      final cats = await client
          .from('menu_categories')
          .select('id, name, sort_order')
          .order('sort_order');
      final items = await client
          .from('menu_items')
          .select('id, category_id, name, price_cents, image_url, is_active')
          .eq('is_active', true);
      final categories = [
        for (final c in (cats as List))
          MenuCategory(
            id: c['id'] as String,
            name: c['name'] as String,
            sortOrder: (c['sort_order'] as num?)?.toInt() ?? 0,
          ),
      ];
      final itemsByCategory = <String, List<MenuItemModel>>{};
      for (final m in (items as List)) {
        final item = MenuItemModel(
          id: m['id'] as String,
          categoryId: m['category_id'] as String,
          name: m['name'] as String,
          priceCents: (m['price_cents'] as num).toInt(),
          imageUrl: m['image_url'] as String?,
          isActive: (m['is_active'] as bool?) ?? true,
        );
        (itemsByCategory[item.categoryId] ??= []).add(item);
      }
      state = MenuState(
        categories: categories,
        itemsByCategory: itemsByCategory,
      );
      await _persist(state);
    } catch (_) {
      // ignore and keep cache/seed
    }
  }
}

final menuStoreProvider = StateNotifierProvider<MenuStore, MenuState>((ref) {
  return MenuStore(ref);
});

import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../domain/models.dart';

class MenuState {
  const MenuState({required this.categories, required this.itemsByCategory});

  final List<MenuCategory> categories;
  final Map<String, List<MenuItemModel>> itemsByCategory;
}

class MenuStore extends StateNotifier<MenuState> {
  MenuStore()
    : super(
        MenuState(
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
        ),
      );
}

final menuStoreProvider = StateNotifierProvider<MenuStore, MenuState>((ref) {
  return MenuStore();
});

class MenuCategory {
  MenuCategory({required this.id, required this.name, this.sortOrder = 0});

  final String id;
  final String name;
  final int sortOrder;
}

class MenuItemModel {
  MenuItemModel({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.priceCents,
    this.imageUrl,
    this.isActive = true,
  });

  final String id;
  final String categoryId;
  final String name;
  final int priceCents;
  final String? imageUrl;
  final bool isActive;
}

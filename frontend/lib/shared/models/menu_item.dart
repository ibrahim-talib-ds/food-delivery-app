class MenuItem {
  final int id;
  final int restaurantId;
  final int? categoryId;
  final String name;
  final String? description;
  final double price;
  final String currency;
  final String? imageUrl;
  final bool available;

  MenuItem({
    required this.id,
    required this.restaurantId,
    this.categoryId,
    required this.name,
    this.description,
    required this.price,
    required this.currency,
    this.imageUrl,
    required this.available,
  });

  factory MenuItem.fromJson(Map<String, dynamic> j) => MenuItem(
        id: j['id'],
        restaurantId: j['restaurant_id'],
        categoryId: j['category_id'],
        name: j['name'],
        description: j['description'],
        price: double.parse(j['price'].toString()),
        currency: j['currency'],
        imageUrl: j['image_url'],
        available: j['available'] ?? true,
      );
}

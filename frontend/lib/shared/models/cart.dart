class CartItem {
  final int id;
  final int menuItemId;
  final int quantity;
  final String menuItemName;
  final double unitPrice;
  final double lineTotal;

  CartItem({
    required this.id,
    required this.menuItemId,
    required this.quantity,
    required this.menuItemName,
    required this.unitPrice,
    required this.lineTotal,
  });

  factory CartItem.fromJson(Map<String, dynamic> j) => CartItem(
        id: j['id'],
        menuItemId: j['menu_item_id'],
        quantity: j['quantity'],
        menuItemName: j['menu_item_name'],
        unitPrice: double.parse(j['unit_price'].toString()),
        lineTotal: double.parse(j['line_total'].toString()),
      );
}

class Cart {
  final int? id;
  final int? restaurantId;
  final List<CartItem> items;
  final double subtotal;
  final double deliveryFee;
  final double total;
  final String currency;

  Cart({
    this.id,
    this.restaurantId,
    required this.items,
    required this.subtotal,
    required this.deliveryFee,
    required this.total,
    required this.currency,
  });

  factory Cart.fromJson(Map<String, dynamic> j) => Cart(
        id: j['id'],
        restaurantId: j['restaurant_id'],
        items: (j['items'] as List? ?? [])
            .map((e) => CartItem.fromJson(e))
            .toList(),
        subtotal: double.parse(j['subtotal'].toString()),
        deliveryFee: double.parse(j['delivery_fee'].toString()),
        total: double.parse(j['total'].toString()),
        currency: j['currency'] ?? 'USD',
      );

  bool get isEmpty => items.isEmpty;
  int get itemCount => items.fold(0, (s, i) => s + i.quantity);
}

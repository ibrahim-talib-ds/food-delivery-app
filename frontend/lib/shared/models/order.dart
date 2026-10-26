class OrderItem {
  final int id;
  final String nameSnapshot;
  final double priceSnapshot;
  final int quantity;
  OrderItem(
      {required this.id,
      required this.nameSnapshot,
      required this.priceSnapshot,
      required this.quantity});
  factory OrderItem.fromJson(Map<String, dynamic> j) => OrderItem(
        id: j['id'],
        nameSnapshot: j['name_snapshot'],
        priceSnapshot: double.parse(j['price_snapshot'].toString()),
        quantity: j['quantity'],
      );
}

class StatusHistory {
  final String status;
  final String? note;
  final DateTime createdAt;
  StatusHistory({required this.status, this.note, required this.createdAt});
  factory StatusHistory.fromJson(Map<String, dynamic> j) => StatusHistory(
        status: j['status'],
        note: j['note'],
        createdAt: DateTime.parse(j['created_at']),
      );
}

class Order {
  final int id;
  final int customerId;
  final int restaurantId;
  final int? riderId;
  final String status;
  final double subtotal;
  final double deliveryFee;
  final double total;
  final String currency;
  final String address;
  final String? city;
  final String? country;
  final String? note;
  final DateTime createdAt;
  final List<OrderItem> items;
  final List<StatusHistory> statusHistory;

  Order({
    required this.id,
    required this.customerId,
    required this.restaurantId,
    this.riderId,
    required this.status,
    required this.subtotal,
    required this.deliveryFee,
    required this.total,
    required this.currency,
    required this.address,
    this.city,
    this.country,
    this.note,
    required this.createdAt,
    required this.items,
    required this.statusHistory,
  });

  factory Order.fromJson(Map<String, dynamic> j) => Order(
        id: j['id'],
        customerId: j['customer_id'],
        restaurantId: j['restaurant_id'],
        riderId: j['rider_id'],
        status: j['status'],
        subtotal: double.parse(j['subtotal'].toString()),
        deliveryFee: double.parse(j['delivery_fee'].toString()),
        total: double.parse(j['total'].toString()),
        currency: j['currency'],
        address: j['address'],
        city: j['city'],
        country: j['country'],
        note: j['note'],
        createdAt: DateTime.parse(j['created_at']),
        items: (j['items'] as List? ?? [])
            .map((e) => OrderItem.fromJson(e))
            .toList(),
        statusHistory: (j['status_history'] as List? ?? [])
            .map((e) => StatusHistory.fromJson(e))
            .toList(),
      );
}

class Restaurant {
  final int id;
  final int ownerId;
  final String name;
  final String? description;
  final String? imageUrl;
  final String? city;
  final String? country;
  final String? address;
  final double deliveryFee;
  final String currency;
  final String status;

  Restaurant({
    required this.id,
    required this.ownerId,
    required this.name,
    this.description,
    this.imageUrl,
    this.city,
    this.country,
    this.address,
    required this.deliveryFee,
    required this.currency,
    required this.status,
  });

  factory Restaurant.fromJson(Map<String, dynamic> j) => Restaurant(
        id: j['id'],
        ownerId: j['owner_id'],
        name: j['name'],
        description: j['description'],
        imageUrl: j['image_url'],
        city: j['city'],
        country: j['country'],
        address: j['address'],
        deliveryFee: double.parse(j['delivery_fee'].toString()),
        currency: j['currency'],
        status: j['status'],
      );
}

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:latlong2/latlong.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../shared/models/order.dart';
import '../../shared/services/api_client.dart';
import '../../shared/screens/chat_screen.dart';

class OrderTrackingScreen extends StatefulWidget {
  final int orderId;
  const OrderTrackingScreen({super.key, required this.orderId});

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  Order? _order;
  WebSocketChannel? _channel;
  StreamSubscription? _wsSub;
  bool _loading = true;
  final MapController _mapController = MapController();
  Map<String, dynamic>? _contacts;

  static const darkGreen = Color(0xFF0D2B1A);
  static const gold = Color(0xFFD4AF37);

  final LatLng _restaurantLoc = const LatLng(40.7128, -74.0060);
  final LatLng _customerLoc = const LatLng(40.7306, -73.9352);

  @override
  void initState() {
    super.initState();
    _loadOrder();
    _loadContacts();
    _connectWebSocket();
  }

  Future<void> _loadOrder() async {
    try {
      final data = await ApiClient.get('/orders/${widget.orderId}');
      setState(() {
        _order = Order.fromJson(data);
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadContacts() async {
    try {
      final data = await ApiClient.get('/order-contacts/${widget.orderId}');
      if (mounted) setState(() => _contacts = data);
    } catch (e) {
      debugPrint('Contacts error: $e');
    }
  }

  Future<void> _call(String phone) async {
    final url = Uri.parse('tel:$phone');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  void _openChat(int receiverId, String name, String role) {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => ChatScreen(
                  orderId: widget.orderId,
                  receiverId: receiverId,
                  receiverName: name,
                  receiverRole: role,
                )));
  }

  void _connectWebSocket() {
    final token = ApiClient.token;
    if (token == null) return;
    final url = ApiClient.wsUrl('/ws/orders/${widget.orderId}', token);
    _channel = WebSocketChannel.connect(Uri.parse(url));
    _wsSub = _channel!.stream.listen((message) {
      final data = jsonDecode(message);
      if (data['event'] == 'status_changed') {
        _loadOrder();
        _loadContacts();
      }
    });
  }

  @override
  void dispose() {
    _wsSub?.cancel();
    _channel?.sink.close();
    super.dispose();
  }

  LatLng _getBikeLocation(String status) {
    switch (status) {
      case 'pending':
      case 'accepted':
      case 'preparing':
      case 'ready':
        return _restaurantLoc;
      case 'picked_up':
        return LatLng(
          (_restaurantLoc.latitude + _customerLoc.latitude) / 2,
          (_restaurantLoc.longitude + _customerLoc.longitude) / 2,
        );
      case 'delivered':
        return _customerLoc;
      default:
        return _restaurantLoc;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator(color: darkGreen)));
    }
    if (_order == null) {
      return const Scaffold(body: Center(child: Text('Order not found.')));
    }

    final status = _order!.status;
    final bikeLoc = _getBikeLocation(status);
    final statuses = [
      'pending',
      'accepted',
      'preparing',
      'ready',
      'picked_up',
      'delivered'
    ];
    final currentIndex = statuses.indexOf(status);

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: darkGreen,
        elevation: 0,
        title: Text('Order #${_order!.id}',
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(
              height: 280,
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _restaurantLoc,
                      initialZoom: 13.0,
                      interactionOptions: const InteractionOptions(
                          flags: InteractiveFlag.all & ~InteractiveFlag.rotate),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.food_delivery_tz',
                        tileProvider: CancellableNetworkTileProvider(),
                      ),
                      PolylineLayer(polylines: [
                        Polyline(
                            points: [_restaurantLoc, _customerLoc],
                            strokeWidth: 4,
                            color: darkGreen)
                      ]),
                      MarkerLayer(markers: [
                        Marker(
                            point: _restaurantLoc,
                            width: 40,
                            height: 40,
                            child: const Icon(Icons.storefront,
                                color: darkGreen, size: 35)),
                        Marker(
                            point: _customerLoc,
                            width: 40,
                            height: 40,
                            child: const Icon(Icons.home,
                                color: darkGreen, size: 35)),
                        Marker(
                            point: bikeLoc,
                            width: 60,
                            height: 60,
                            child: Image.asset(
                                'assets/images/delivery_bike.png',
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(Icons.delivery_dining,
                                        color: gold, size: 40))),
                      ]),
                    ],
                  ),
                  Positioned(
                    top: 16,
                    left: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 10)
                          ]),
                      child: const Row(children: [
                        Icon(Icons.access_time, color: darkGreen),
                        SizedBox(width: 12),
                        Text('Estimated Arrival: 15 - 25 min',
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.black87)),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Order Status',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: darkGreen)),
                  const SizedBox(height: 16),
                  ...List.generate(statuses.length, (index) {
                    final isDone = index <= currentIndex;
                    final isCurrent = index == currentIndex;
                    final label =
                        statuses[index].replaceAll('_', ' ').toUpperCase();
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color:
                                    isDone ? darkGreen : Colors.grey.shade300),
                            child: isDone
                                ? const Icon(Icons.check,
                                    size: 14, color: Colors.white)
                                : null,
                          ),
                          if (index < statuses.length - 1)
                            Container(
                                width: 2,
                                height: 40,
                                color:
                                    isDone ? darkGreen : Colors.grey.shade300),
                        ]),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(label,
                                    style: TextStyle(
                                        fontWeight: isCurrent
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                        color: isDone
                                            ? Colors.black87
                                            : Colors.grey,
                                        fontSize: 14)),
                                if (isCurrent)
                                  const Text('Currently in this stage',
                                      style: TextStyle(
                                          color: darkGreen,
                                          fontSize: 12,
                                          fontStyle: FontStyle.italic)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  }),

                  // ─── CONTACTS (Call/Chat) ───
                  if (_contacts != null) ...[
                    const SizedBox(height: 24),
                    const Text('Contact',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87)),
                    const SizedBox(height: 12),
                    if (_contacts!['restaurant'] != null)
                      _contactTile(
                          'Restaurant',
                          _contacts!['restaurant']['name'],
                          _contacts!['restaurant']['phone'],
                          _contacts!['restaurant']['id'],
                          'restaurant'),
                    if (_contacts!['rider'] != null)
                      _contactTile(
                          'Rider',
                          _contacts!['rider']['name'],
                          _contacts!['rider']['phone'],
                          _contacts!['rider']['id'],
                          'rider'),
                  ],

                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Order Summary',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.black87)),
                        const Divider(),
                        ..._order!.items.map((i) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('${i.quantity}x ${i.nameSnapshot}',
                                      style: const TextStyle(
                                          color: Colors.black54)),
                                  Text(
                                      '\$${i.priceSnapshot.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                          color: Colors.black87)),
                                ],
                              ),
                            )),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.black87)),
                            Text('\$${_order!.total.toStringAsFixed(2)}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: darkGreen)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _contactTile(
      String role, String name, String phone, int userId, String userRole) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: const Color(0xFFE8F0EA),
            child: Icon(
                userRole == 'rider' ? Icons.delivery_dining : Icons.storefront,
                color: darkGreen,
                size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(role,
                    style:
                        const TextStyle(color: Colors.black54, fontSize: 11)),
                Text(name,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        fontSize: 14)),
              ],
            ),
          ),
          IconButton(
              icon: const Icon(Icons.call, color: Colors.green),
              onPressed: () => _call(phone)),
          IconButton(
              icon: const Icon(Icons.chat_bubble_outline, color: Colors.blue),
              onPressed: () => _openChat(userId, name, role)),
        ],
      ),
    );
  }
}

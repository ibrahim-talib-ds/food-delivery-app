import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../shared/models/order.dart';
import '../../shared/services/api_client.dart';
import '../../shared/screens/chat_screen.dart';

class OrdersTab extends StatefulWidget {
  const OrdersTab({super.key});
  @override
  State<OrdersTab> createState() => _OrdersTabState();
}

class _OrdersTabState extends State<OrdersTab> {
  List<Order>? _orders;
  List<dynamic> _allContacts = [];
  bool _loading = true;
  Timer? _timer;

  static const darkGreen = Color(0xFF0D2B1A);
  static const gold = Color(0xFFD4AF37);

  @override
  void initState() {
    super.initState();
    _load();
    _timer = Timer.periodic(const Duration(seconds: 5), (t) {
      if (mounted && !_loading) _load();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await ApiClient.get('/orders');
      final orders = (data as List).map((j) => Order.fromJson(j)).toList();
      orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      // Fetch contact info for each order that has a rider
      final contacts = <dynamic>[];
      for (final o in orders) {
        if (o.riderId != null) {
          try {
            final c = await ApiClient.get('/order-contacts/${o.id}');
            contacts.add(c);
          } catch (_) {
            contacts.add(null);
          }
        } else {
          contacts.add(null);
        }
      }

      setState(() {
        _orders = orders;
        _allContacts = contacts;
      });
    } catch (e) {
      debugPrint('Error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _updateStatus(int orderId, String newStatus) async {
    try {
      await ApiClient.patch('/orders/$orderId/status', {'status': newStatus});
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _callRider(String phone) async {
    final url = Uri.parse('tel:$phone');
    if (await canLaunchUrl(url)) await launchUrl(url);
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.blue;
      case 'preparing':
        return gold;
      case 'ready':
        return Colors.green;
      case 'picked_up':
        return Colors.purple;
      case 'delivered':
        return darkGreen;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'PENDING';
      case 'accepted':
        return 'ACCEPTED';
      case 'preparing':
        return 'PREPARING';
      case 'ready':
        return 'READY';
      case 'picked_up':
        return 'OUT FOR DELIVERY';
      case 'delivered':
        return 'DELIVERED';
      case 'cancelled':
        return 'CANCELLED';
      default:
        return status.toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: darkGreen,
        elevation: 0,
        title: const Text('Incoming Orders',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: _loading && _orders == null
          ? const Center(child: CircularProgressIndicator(color: darkGreen))
          : _orders == null || _orders!.isEmpty
              ? const Center(
                  child: Text('No orders yet.',
                      style: TextStyle(color: Colors.black54)))
              : RefreshIndicator(
                  onRefresh: _load,
                  color: darkGreen,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _orders!.length,
                    itemBuilder: (context, index) {
                      final o = _orders![index];
                      final contact = index < _allContacts.length
                          ? _allContacts[index]
                          : null;
                      final riderInfo = contact?['rider'];

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 4)),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: _statusColor(o.status)
                                    .withValues(alpha: 0.1),
                                borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(20)),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Order #${o.id}',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: Colors.black87)),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                        color: _statusColor(o.status),
                                        borderRadius: BorderRadius.circular(8)),
                                    child: Text(_statusLabel(o.status),
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                            ),

                            // Items
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ...o.items.map((i) => Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 4),
                                        child: Row(
                                          children: [
                                            Text('${i.quantity}x ',
                                                style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: darkGreen)),
                                            Expanded(
                                                child: Text(i.nameSnapshot,
                                                    style: const TextStyle(
                                                        color:
                                                            Colors.black87))),
                                          ],
                                        ),
                                      )),
                                  const Divider(height: 24),
                                  Row(
                                    children: [
                                      const Icon(Icons.location_on,
                                          size: 16, color: Colors.black54),
                                      const SizedBox(width: 4),
                                      Expanded(
                                          child: Text(o.address,
                                              style: const TextStyle(
                                                  color: Colors.black54,
                                                  fontSize: 13))),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(Icons.attach_money,
                                          size: 16, color: darkGreen),
                                      Text(
                                          'Total: \$${o.total.toStringAsFixed(2)}',
                                          style: const TextStyle(
                                              color: darkGreen,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14)),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // Rider Contact (if assigned)
                            if (riderInfo != null) ...[
                              Container(
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                    color: const Color(0xFFE8F0EA),
                                    borderRadius: BorderRadius.circular(12)),
                                child: Row(
                                  children: [
                                    const CircleAvatar(
                                      radius: 18,
                                      backgroundColor: darkGreen,
                                      child: Icon(Icons.delivery_dining,
                                          color: gold, size: 18),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(riderInfo['name'] ?? 'Rider',
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: darkGreen,
                                                  fontSize: 14)),
                                          const Text('Rider assigned',
                                              style: TextStyle(
                                                  color: Colors.black54,
                                                  fontSize: 11)),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.call,
                                          color: Colors.green),
                                      onPressed: () =>
                                          _callRider(riderInfo['phone'] ?? ''),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                          Icons.chat_bubble_outline,
                                          color: Colors.blue),
                                      onPressed: () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (_) => ChatScreen(
                                                    orderId: o.id,
                                                    receiverId: riderInfo['id'],
                                                    receiverName:
                                                        riderInfo['name'] ??
                                                            'Rider',
                                                    receiverRole: 'rider',
                                                    receiverPhone:
                                                        riderInfo['phone'],
                                                  ))),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],

                            // Actions
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  if (o.status == 'pending')
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                          backgroundColor: darkGreen,
                                          minimumSize: const Size(120, 44),
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(20))),
                                      onPressed: () =>
                                          _updateStatus(o.id, 'accepted'),
                                      child: const Text('Accept Order',
                                          style: TextStyle(
                                              color: gold,
                                              fontWeight: FontWeight.bold)),
                                    ),
                                  if (o.status == 'accepted')
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                          backgroundColor: darkGreen,
                                          minimumSize: const Size(140, 44),
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(20))),
                                      onPressed: () =>
                                          _updateStatus(o.id, 'preparing'),
                                      child: const Text('Start Preparing',
                                          style: TextStyle(
                                              color: gold,
                                              fontWeight: FontWeight.bold)),
                                    ),
                                  if (o.status == 'preparing')
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                          backgroundColor: darkGreen,
                                          minimumSize: const Size(120, 44),
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(20))),
                                      onPressed: () =>
                                          _updateStatus(o.id, 'ready'),
                                      child: const Text('Mark as Ready',
                                          style: TextStyle(
                                              color: gold,
                                              fontWeight: FontWeight.bold)),
                                    ),
                                  if (o.status == 'ready')
                                    const Padding(
                                      padding: EdgeInsets.only(right: 8),
                                      child: Text('Waiting for rider...',
                                          style: TextStyle(
                                              color: Colors.orange,
                                              fontStyle: FontStyle.italic)),
                                    ),
                                  if (o.status == 'picked_up')
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                          color: Colors.purple
                                              .withValues(alpha: 0.1),
                                          borderRadius:
                                              BorderRadius.circular(8)),
                                      child: const Row(
                                        children: [
                                          Icon(Icons.delivery_dining,
                                              color: Colors.purple, size: 18),
                                          SizedBox(width: 6),
                                          Text('Rider is on the way',
                                              style: TextStyle(
                                                  color: Colors.purple,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13)),
                                        ],
                                      ),
                                    ),
                                  if (o.status == 'delivered')
                                    const Padding(
                                      padding: EdgeInsets.only(right: 8),
                                      child: Row(
                                        children: [
                                          Icon(Icons.check_circle,
                                              color: Colors.green, size: 18),
                                          SizedBox(width: 6),
                                          Text('Delivered',
                                              style: TextStyle(
                                                  color: Colors.green,
                                                  fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

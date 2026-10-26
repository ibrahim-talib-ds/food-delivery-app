import 'package:flutter/material.dart';
import '../../shared/models/order.dart';
import '../../shared/services/api_client.dart';
import '../../shared/utils/food_images.dart';
import 'order_tracking_screen.dart';

class OrderHistoryTab extends StatefulWidget {
  const OrderHistoryTab({super.key});
  @override
  State<OrderHistoryTab> createState() => _OrderHistoryTabState();
}

class _OrderHistoryTabState extends State<OrderHistoryTab>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  List<Order>? _orders;
  bool _loading = true;

  static const darkGreen = Color(0xFF0D2B1A);
  static const gold = Color(0xFFD4AF37);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await ApiClient.get('/orders');
      setState(() {
        _orders = (data as List).map((j) => Order.fromJson(j)).toList();
        _orders!.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      });
    } catch (e) {
      debugPrint('Error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: darkGreen,
        title: const Text('My Orders',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: gold,
          labelColor: gold,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Active'),
            Tab(text: 'Past'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: darkGreen))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOrderList(true),
                _buildOrderList(false),
              ],
            ),
    );
  }

  Widget _buildOrderList(bool isActive) {
    final filtered = _orders?.where((o) {
          final activeStatuses = [
            'pending',
            'accepted',
            'preparing',
            'ready',
            'picked_up'
          ];
          final isOActive = activeStatuses.contains(o.status);
          return isActive ? isOActive : !isOActive;
        }).toList() ??
        [];

    if (filtered.isEmpty) {
      return Center(
          child: Text('No ${isActive ? 'active' : 'past'} orders.',
              style: const TextStyle(color: Colors.grey)));
    }

    return RefreshIndicator(
      onRefresh: _load,
      color: darkGreen,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filtered.length,
        itemBuilder: (context, index) {
          final order = filtered[index];
          final imageUrl = order.items.isNotEmpty
              ? FoodImages.getImage(order.items.first.nameSnapshot)
              : 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=400&q=80';

          return GestureDetector(
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => OrderTrackingScreen(orderId: order.id))),
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4))
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left Side
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                    color: Color(0xFFE8F0EA),
                                    shape: BoxShape.circle),
                                child: const Icon(Icons.receipt_long,
                                    color: darkGreen, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Order #${order.id}',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: Colors.black87)),
                                  Text(order.status.toUpperCase(),
                                      style: TextStyle(
                                          color: order.status == 'pending'
                                              ? Colors.orange
                                              : darkGreen,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(imageUrl,
                                height: 100,
                                width: double.infinity,
                                fit: BoxFit.cover),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            order.items.map((e) => e.nameSnapshot).join(', '),
                            style: const TextStyle(
                                color: Colors.black54, fontSize: 13),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Right Side (Timeline)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('\$${order.total.toStringAsFixed(2)}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: darkGreen)),
                        const SizedBox(height: 16),
                        _buildTimelineItem(
                            'Confirmed', order.status != 'cancelled'),
                        _buildTimelineItem(
                            'Prepared',
                            [
                              'accepted',
                              'preparing',
                              'ready',
                              'picked_up',
                              'delivered'
                            ].contains(order.status)),
                        _buildTimelineItem('Dispatched',
                            ['picked_up', 'delivered'].contains(order.status)),
                        _buildTimelineItem(
                            'Delivered', order.status == 'delivered',
                            isLast: true),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTimelineItem(String label, bool isDone, {bool isLast = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDone ? darkGreen : Colors.grey.shade300,
              ),
            ),
            if (!isLast)
              Container(
                  width: 2,
                  height: 20,
                  color: isDone ? darkGreen : Colors.grey.shade300),
          ],
        ),
        const SizedBox(width: 8),
        Text(label,
            style: TextStyle(
                fontSize: 12,
                color: isDone ? Colors.black87 : Colors.grey,
                fontWeight: isDone ? FontWeight.w600 : FontWeight.normal)),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'dart:async';
import '../../shared/models/order.dart';
import '../../shared/services/api_client.dart';

class RiderOverviewTab extends StatefulWidget {
  const RiderOverviewTab({super.key});
  @override
  State<RiderOverviewTab> createState() => _RiderOverviewTabState();
}

class _RiderOverviewTabState extends State<RiderOverviewTab> {
  String _status = 'offline';
  Map<String, dynamic>? _activeDelivery;
  Order? _activeOrder;
  bool _loading = true;
  Timer? _timer;

  static const darkGreen = Color(0xFF0D2B1A);
  static const gold = Color(0xFFD4AF37);

  @override
  void initState() {
    super.initState();
    _load();
    // Auto-refresh every 5 seconds so active delivery appears instantly
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
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
      // 1. Try to get profile
      var profile = await ApiClient.get('/riders/me');
      _status = profile['current_status'] ?? 'offline';

      // 2. Get earnings & active delivery
      final earnData = await ApiClient.get('/riders/earnings');
      final deliveries = (earnData['deliveries'] as List)
          .map((d) => Map<String, dynamic>.from(d))
          .toList();
      final activeList =
          deliveries.where((d) => d['dropoff_time'] == null).toList();

      if (activeList.isNotEmpty) {
        _activeDelivery = activeList.first;
        final oData =
            await ApiClient.get('/orders/${_activeDelivery!['order_id']}');
        _activeOrder = Order.fromJson(oData);
      } else {
        _activeDelivery = null;
        _activeOrder = null;
      }
    } catch (e) {
      // 3. If profile doesn't exist, CREATE IT, then reload
      if (e.toString().contains('404') ||
          e.toString().contains('not created') ||
          e.toString().contains('400')) {
        await ApiClient.post('/riders/me', {'vehicle_type': 'motorcycle'});
        await _load(); // Retry
        return;
      }
      debugPrint('Load error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleStatus(bool value) async {
    final newStatus = value ? 'available' : 'offline';
    setState(() => _status = newStatus); // Instant UI response
    try {
      await ApiClient.patch('/riders/me', {'current_status': newStatus});
      if (mounted) _load();
    } catch (e) {
      if (mounted) {
        setState(
            () => _status = value ? 'offline' : 'available'); // Revert if fails
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _completeJob(int orderId) async {
    try {
      await ApiClient.patch('/riders/deliveries/$orderId/complete', {});
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Delivery Completed!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAvailable = _status == 'available';
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: darkGreen,
        title: const Text('Rider Dashboard',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: darkGreen))
          : RefreshIndicator(
              onRefresh: _load,
              color: darkGreen,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // Status Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10)
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                              color: isAvailable
                                  ? const Color(0xFFE8F0EA)
                                  : Colors.grey.shade200,
                              shape: BoxShape.circle),
                          child: Icon(
                              isAvailable
                                  ? Icons.delivery_dining
                                  : Icons.nightlight_round,
                              color: isAvailable ? darkGreen : Colors.grey,
                              size: 28),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                  isAvailable
                                      ? 'You are Online'
                                      : 'You are Offline',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      color: Colors.black87)),
                              Text(
                                  isAvailable
                                      ? 'Waiting for jobs...'
                                      : 'Go online to start earning.',
                                  style: const TextStyle(
                                      color: Colors.black54, fontSize: 13)),
                            ],
                          ),
                        ),
                        Switch(
                          value: isAvailable,
                          activeThumbColor: darkGreen,
                          activeTrackColor: darkGreen.withValues(alpha: 0.5),
                          onChanged: _toggleStatus,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Active Delivery
                  if (_activeDelivery != null && _activeOrder != null) ...[
                    const Text('Active Delivery',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.black87)),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: gold, width: 2),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Order #${_activeOrder!.id}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16)),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                    color: gold,
                                    borderRadius: BorderRadius.circular(8)),
                                child: const Text('IN PROGRESS',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          const Row(children: [
                            Icon(Icons.location_on,
                                size: 16, color: Colors.black54),
                            SizedBox(width: 8),
                            Expanded(
                                child: Text('Deliver to customer location',
                                    style: TextStyle(color: Colors.black54)))
                          ]),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: () => _completeJob(_activeOrder!.id),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: darkGreen,
                                minimumSize: const Size.fromHeight(50),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30))),
                            child: const Text('Mark as Delivered',
                                style: TextStyle(
                                    color: gold, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20)),
                      child: const Column(
                        children: [
                          Icon(Icons.delivery_dining,
                              size: 64, color: Color(0xFFE8F0EA)),
                          SizedBox(height: 16),
                          Text('No active delivery',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.black54)),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}

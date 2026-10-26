import 'dart:async';
import 'package:flutter/material.dart';
import '../../shared/services/api_client.dart';

class RiderEarningsTab extends StatefulWidget {
  const RiderEarningsTab({super.key});
  @override
  State<RiderEarningsTab> createState() => _RiderEarningsTabState();
}

class _RiderEarningsTabState extends State<RiderEarningsTab> {
  double _total = 0.0;
  List<Map<String, dynamic>> _deliveries = [];
  bool _loading = true;
  Timer? _timer;

  static const darkGreen = Color(0xFF0D2B1A);
  static const gold = Color(0xFFD4AF37);

  @override
  void initState() {
    super.initState();
    _load();
    // Auto-refresh every 5 seconds
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
      final data = await ApiClient.get('/riders/earnings');
      setState(() {
        _total = double.parse(data['total_earnings'].toString());
        _deliveries = (data['deliveries'] as List)
            .map((d) => Map<String, dynamic>.from(d))
            .toList();
      });
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
        title: const Text('My Earnings',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _loading && _deliveries.isEmpty
          ? const Center(child: CircularProgressIndicator(color: darkGreen))
          : Column(
              children: [
                Container(
                  margin: const EdgeInsets.all(20),
                  padding: const EdgeInsets.all(24),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [darkGreen, Color(0xFF1B4332)]),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                          color: darkGreen.withValues(alpha: 0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 8))
                    ],
                  ),
                  child: Column(
                    children: [
                      const Text('Total Earnings',
                          style:
                              TextStyle(color: Colors.white70, fontSize: 14)),
                      const SizedBox(height: 8),
                      Text('\$${_total.toStringAsFixed(2)}',
                          style: const TextStyle(
                              color: gold,
                              fontSize: 36,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                Expanded(
                  child: _deliveries.isEmpty
                      ? const Center(
                          child: Text('No earnings yet.',
                              style: TextStyle(color: Colors.black54)))
                      : RefreshIndicator(
                          onRefresh: _load,
                          color: darkGreen,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: _deliveries.length,
                            itemBuilder: (context, index) {
                              final e = _deliveries[index];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                          color: Colors.black
                                              .withValues(alpha: 0.04),
                                          blurRadius: 10)
                                    ]),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: const BoxDecoration(
                                          color: Color(0xFFE8F0EA),
                                          shape: BoxShape.circle),
                                      child: const Icon(Icons.receipt_long,
                                          color: darkGreen, size: 20),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text('Order #${e['order_id']}',
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.black87)),
                                          Text(
                                              e['dropoff_time'] != null
                                                  ? 'Delivered'
                                                  : 'In Progress',
                                              style: const TextStyle(
                                                  color: Colors.black54,
                                                  fontSize: 12)),
                                        ],
                                      ),
                                    ),
                                    Text('+\$${e['earnings']}',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green,
                                            fontSize: 15)),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }
}

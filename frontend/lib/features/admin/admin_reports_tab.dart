import 'package:flutter/material.dart';
import '../../shared/services/api_client.dart';

class AdminReportsTab extends StatefulWidget {
  final Function(int) onNavigateToTab;
  const AdminReportsTab({super.key, required this.onNavigateToTab});
  @override
  State<AdminReportsTab> createState() => _AdminReportsTabState();
}

class _AdminReportsTabState extends State<AdminReportsTab> {
  Map<String, dynamic>? _reports;
  bool _loading = true;
  static const darkGreen = Color(0xFF0D2B1A);
  static const gold = Color(0xFFD4AF37);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final rep = await ApiClient.get('/admin/reports');
      setState(() => _reports = rep);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: darkGreen));
    }
    if (_reports == null) return const Center(child: Text('No data'));

    return RefreshIndicator(
      onRefresh: _load,
      color: darkGreen,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient:
                  const LinearGradient(colors: [darkGreen, Color(0xFF1B4332)]),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                    color: darkGreen.withValues(alpha: 0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8))
              ],
            ),
            child: Column(
              children: [
                const Text('Total Platform Revenue',
                    style: TextStyle(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 8),
                Text('\$${_reports!['total_revenue']}',
                    style: const TextStyle(
                        color: gold,
                        fontSize: 36,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(children: [
            _statCard('Total Orders', '${_reports!['total_orders']}',
                Icons.receipt_long,
                onTap: () {}),
            const SizedBox(width: 12),
            _statCard('Delivered', '${_reports!['total_delivered']}',
                Icons.check_circle,
                onTap: () {}),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            _statCard(
                'Customers', '${_reports!['total_customers']}', Icons.people,
                onTap: () => widget.onNavigateToTab(2)),
            const SizedBox(width: 12),
            _statCard('Restaurants', '${_reports!['total_restaurants']}',
                Icons.storefront,
                onTap: () => widget.onNavigateToTab(1)),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            _statCard(
                'Riders', '${_reports!['total_riders']}', Icons.delivery_dining,
                onTap: () => widget.onNavigateToTab(2)),
            const SizedBox(width: 12),
            _statCard('Pending Restaurants',
                '${_reports!['pending_restaurants']}', Icons.pending_actions,
                color: Colors.orange, onTap: () => widget.onNavigateToTab(1)),
          ]),
        ],
      ),
    );
  }

  Widget _statCard(String title, String value, IconData icon,
      {Color? color, required VoidCallback onTap}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04), blurRadius: 10)
              ]),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color ?? darkGreen, size: 24),
              const SizedBox(height: 12),
              Text(value,
                  style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87)),
              Text(title,
                  style: const TextStyle(fontSize: 12, color: Colors.black54)),
            ],
          ),
        ),
      ),
    );
  }
}

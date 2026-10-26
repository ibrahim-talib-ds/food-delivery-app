import 'package:flutter/material.dart';
import '../../shared/screens/chat_screen.dart';
import 'dart:async';
import '../../shared/services/api_client.dart';

class RiderJobsTab extends StatefulWidget {
  const RiderJobsTab({super.key});
  @override
  State<RiderJobsTab> createState() => _RiderJobsTabState();
}

class _RiderJobsTabState extends State<RiderJobsTab> {
  List<Map<String, dynamic>> _jobs = [];
  bool _loading = true;
  Timer? _timer;
  static const darkGreen = Color(0xFF0D2B1A);

  @override
  void initState() {
    super.initState();
    _load();
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted && !_loading) _load();
    });
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await ApiClient.get('/riders/available');
      setState(() {
        _jobs =
            (data as List).map((j) => Map<String, dynamic>.from(j)).toList();
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _acceptJob(int orderId) async {
    try {
      await ApiClient.post('/riders/accept/$orderId', {});
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Job Accepted! Check Overview.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: darkGreen,
        title: const Text('Available Jobs',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: darkGreen))
          : _jobs.isEmpty
              ? const Center(
                  child: Text('No jobs available right now.',
                      style: TextStyle(color: Colors.black54)))
              : RefreshIndicator(
                  onRefresh: _load,
                  color: darkGreen,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _jobs.length,
                    itemBuilder: (context, index) {
                      final job = _jobs[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 10)
                            ]),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Order #${job['order_id']}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.black87)),
                            const SizedBox(height: 8),
                            Row(children: [
                              const Icon(Icons.restaurant,
                                  size: 16, color: Colors.black54),
                              const SizedBox(width: 4),
                              Text(job['restaurant_name'] ?? '',
                                  style: const TextStyle(
                                      fontSize: 13, color: Colors.black54))
                            ]),
                            const SizedBox(height: 4),
                            Row(children: [
                              const Icon(Icons.location_on,
                                  size: 16, color: Colors.black54),
                              const SizedBox(width: 4),
                              Expanded(
                                  child: Text(job['address'] ?? '',
                                      style: const TextStyle(
                                          fontSize: 13, color: Colors.black54)))
                            ]),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('\$${job['total']}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: darkGreen,
                                        fontSize: 16)),
                                Row(
                                  children: [
                                    IconButton(
                                        icon: const Icon(
                                            Icons.chat_bubble_outline,
                                            color: Colors.blue,
                                            size: 20),
                                        onPressed: () => Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (_) => ChatScreen(
                                                    orderId: job['order_id'],
                                                    receiverId: 1,
                                                    receiverName: 'Customer',
                                                    receiverRole:
                                                        'customer')))),
                                    ElevatedButton(
                                      onPressed: () =>
                                          _acceptJob(job['order_id']),
                                      style: ElevatedButton.styleFrom(
                                          minimumSize: const Size(100, 40),
                                          backgroundColor: darkGreen,
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(20))),
                                      child: const Text('Accept',
                                          style:
                                              TextStyle(color: Colors.white)),
                                    ),
                                  ],
                                ),
                              ],
                            )
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../shared/services/api_client.dart';
import 'order_tracking_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<dynamic> _notifications = [];
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
      final data = await ApiClient.get('/notifications');
      setState(() => _notifications = data);
    } catch (e) {
      debugPrint('Error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _handleTap(dynamic n) async {
    // Mark as read in background
    ApiClient.post('/notifications/${n['id']}/read', {});

    if (n['type'] == 'order' && n['reference_id'] != null) {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => OrderTrackingScreen(orderId: n['reference_id'])));
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(n['title'])));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: darkGreen,
        title: const Text('Notifications',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: darkGreen))
          : _notifications.isEmpty
              ? const Center(
                  child: Text('No notifications yet.',
                      style: TextStyle(color: Colors.black54)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _notifications.length,
                  itemBuilder: (context, index) {
                    final n = _notifications[index];
                    final isUnread = n['is_read'] == false;

                    return GestureDetector(
                      onTap: () => _handleTap(n),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isUnread ? Colors.white : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 10)
                          ],
                          border: isUnread
                              ? Border.all(color: darkGreen, width: 1)
                              : null,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                  color: gold.withValues(alpha: 0.15),
                                  shape: BoxShape.circle),
                              child: Icon(
                                  n['type'] == 'order'
                                      ? Icons.receipt_long
                                      : Icons.local_offer,
                                  color: darkGreen,
                                  size: 22),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(n['title'],
                                      style: TextStyle(
                                          fontWeight: isUnread
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                          fontSize: 15,
                                          color: Colors.black87)),
                                  const SizedBox(height: 4),
                                  Text(n['body'],
                                      style: const TextStyle(
                                          color: Colors.black54, fontSize: 13)),
                                  const SizedBox(height: 8),
                                  const Text('Tap to view',
                                      style: TextStyle(
                                          color: darkGreen,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                            if (isUnread)
                              Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

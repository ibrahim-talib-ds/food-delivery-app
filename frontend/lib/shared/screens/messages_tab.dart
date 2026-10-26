import 'dart:async';
import 'package:flutter/material.dart';
import '../../shared/services/api_client.dart';
import 'chat_screen.dart';

class MessagesTab extends StatefulWidget {
  const MessagesTab({super.key});
  @override
  State<MessagesTab> createState() => _MessagesTabState();
}

class _MessagesTabState extends State<MessagesTab> {
  List<dynamic> _conversations = [];
  bool _loading = true;
  Timer? _timer;
  static const darkGreen = Color(0xFF0D2B1A);

  @override
  void initState() {
    super.initState();
    _load();
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted) _load(silent: true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) setState(() => _loading = true);
    try {
      final data = await ApiClient.get('/conversations');
      setState(() => _conversations = data);
    } catch (e) {
      debugPrint('Conversations error: $e');
    } finally {
      if (!silent && mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: darkGreen,
        title: const Text(
          'Messages',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: darkGreen))
          : _conversations.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.chat_bubble_outline,
                          size: 80, color: Colors.black26),
                      SizedBox(height: 16),
                      Text(
                        'No messages yet',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black54),
                      ),
                      Text('Start a conversation from any order',
                          style: TextStyle(color: Colors.black38)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  color: darkGreen,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _conversations.length,
                    itemBuilder: (context, index) {
                      final c = _conversations[index];
                      final unread = c['unread'] ?? 0;
                      return GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatScreen(
                              orderId: c['order_id'],
                              receiverId: c['user_id'],
                              receiverName: c['full_name'],
                              receiverRole: c['role'],
                              receiverPhone: c['phone'],
                            ),
                          ),
                        ),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: unread > 0
                                ? Border.all(color: darkGreen, width: 1.5)
                                : null,
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: const Color(0xFFE8F0EA),
                                child: Text(
                                  c['full_name'].isNotEmpty
                                      ? c['full_name'][0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                    color: darkGreen,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            c['full_name'],
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                              color: Colors.black87,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          '#${c['order_id']}',
                                          style: const TextStyle(
                                              color: Colors.black38,
                                              fontSize: 11),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      c['role'].toString().toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.black54,
                                        fontSize: 10,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      c['last_message'],
                                      style: TextStyle(
                                        color: unread > 0
                                            ? Colors.black87
                                            : Colors.black54,
                                        fontWeight: unread > 0
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                        fontSize: 13,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              if (unread > 0)
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle),
                                  child: Text(
                                    '$unread',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

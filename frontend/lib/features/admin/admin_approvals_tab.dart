import 'package:flutter/material.dart';
import '../../shared/services/api_client.dart';

class AdminApprovalsTab extends StatefulWidget {
  const AdminApprovalsTab({super.key});
  @override
  State<AdminApprovalsTab> createState() => _AdminApprovalsTabState();
}

class _AdminApprovalsTabState extends State<AdminApprovalsTab> {
  List<dynamic> _restaurants = [];
  bool _loading = true;
  static const darkGreen = Color(0xFF0D2B1A);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final pending = await ApiClient.get('/admin/restaurants/pending');
      setState(() => _restaurants = pending);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _action(int id, String action) async {
    try {
      if (action == 'delete') {
        await ApiClient.delete('/admin/restaurants/$id');
      } else {
        await ApiClient.patch('/admin/restaurants/$id/$action', {});
      }
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: darkGreen));
    }
    if (_restaurants.isEmpty) {
      return const Center(
          child: Text('No pending approvals.',
              style: TextStyle(color: Colors.black54)));
    }

    return RefreshIndicator(
      onRefresh: _load,
      color: darkGreen,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _restaurants.length,
        itemBuilder: (context, index) {
          final r = _restaurants[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10)
                ]),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r['name'],
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.black87)),
                Text('${r['city'] ?? 'No city'} • Owner ID: ${r['owner_id']}',
                    style:
                        const TextStyle(color: Colors.black54, fontSize: 13)),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                        onPressed: () => _action(r['id'], 'suspend'),
                        child: const Text('Reject',
                            style: TextStyle(color: Colors.red))),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => _action(r['id'], 'approve'),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: darkGreen,
                          minimumSize: const Size(100, 40),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20))),
                      child: const Text('Approve',
                          style: TextStyle(color: Colors.white)),
                    ),
                  ],
                )
              ],
            ),
          );
        },
      ),
    );
  }
}

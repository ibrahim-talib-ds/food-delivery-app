import 'package:flutter/material.dart';
import '../../shared/services/api_client.dart';

class AdminRestaurantsTab extends StatefulWidget {
  const AdminRestaurantsTab({super.key});
  @override
  State<AdminRestaurantsTab> createState() => _AdminRestaurantsTabState();
}

class _AdminRestaurantsTabState extends State<AdminRestaurantsTab> {
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
      final data = await ApiClient.get('/admin/restaurants');
      setState(() => _restaurants = data);
    } catch (e) {
      debugPrint('Error: $e');
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

    return RefreshIndicator(
      onRefresh: _load,
      color: darkGreen,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _restaurants.length,
        itemBuilder: (context, index) {
          final r = _restaurants[index];
          final status = r['status'];

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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(r['name'],
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.black87)),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: status == 'approved'
                            ? Colors.green
                            : (status == 'pending'
                                ? Colors.orange
                                : Colors.red),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(status.toUpperCase(),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold)),
                    )
                  ],
                ),
                Text('${r['city'] ?? 'No city'} • Owner ID: ${r['owner_id']}',
                    style:
                        const TextStyle(color: Colors.black54, fontSize: 13)),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (status != 'approved')
                      TextButton(
                          onPressed: () => _action(r['id'], 'approve'),
                          child: const Text('Approve',
                              style: TextStyle(color: Colors.green))),
                    if (status == 'approved')
                      TextButton(
                          onPressed: () => _action(r['id'], 'suspend'),
                          child: const Text('Suspend',
                              style: TextStyle(color: Colors.orange))),
                    TextButton(
                        onPressed: () => _action(r['id'], 'delete'),
                        child: const Text('Delete',
                            style: TextStyle(color: Colors.red))),
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

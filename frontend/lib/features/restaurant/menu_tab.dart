import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../shared/models/menu_item.dart';
import '../../shared/models/restaurant.dart';
import '../../shared/services/api_client.dart';
import '../auth/auth_state.dart';
import 'add_item_sheet.dart';

class MenuTab extends StatefulWidget {
  const MenuTab({super.key});
  @override
  State<MenuTab> createState() => _MenuTabState();
}

class _MenuTabState extends State<MenuTab> {
  List<MenuItem>? _items;
  Restaurant? _myRestaurant;
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
      final auth = context.read<AuthState>();
      final rsList = await ApiClient.get('/restaurants') as List;
      final myRsList =
          rsList.where((r) => r['owner_id'] == auth.user!.id).toList();
      if (myRsList.isEmpty) {
        // Auto-create restaurant for new owners
        final newRs = await ApiClient.post('/restaurants', {
          'name': 'My New Restaurant',
          'description': 'Welcome!',
          'delivery_fee': '2.50',
          'currency': 'USD'
        });
        _myRestaurant = Restaurant.fromJson(newRs);
      } else {
        _myRestaurant = Restaurant.fromJson(myRsList.first);
      }

      final data =
          await ApiClient.get('/menu/restaurants/${_myRestaurant!.id}/items');
      setState(() {
        _items = (data as List).map((j) => MenuItem.fromJson(j)).toList();
      });
    } catch (e) {
      debugPrint('Menu load error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleAvailability(MenuItem item) async {
    try {
      await ApiClient.patch(
          '/menu/items/${item.id}', {'available': !item.available});
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _deleteItem(MenuItem item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Item?'),
        content: Text('Are you sure you want to delete "${item.name}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (confirm == true) {
      await ApiClient.delete('/menu/items/${item.id}');
      await _load();
    }
  }

  void _openAddSheet({MenuItem? item}) async {
    if (_myRestaurant == null) return;
    final refresh = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) =>
          AddItemSheet(restaurantId: _myRestaurant!.id, existingItem: item),
    );
    if (refresh == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: darkGreen,
        elevation: 0,
        title: const Text('Manage Menu',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: darkGreen,
        onPressed: () => _openAddSheet(),
        icon: const Icon(Icons.add, color: gold),
        label: const Text('Add Item',
            style: TextStyle(color: gold, fontWeight: FontWeight.bold)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: darkGreen))
          : _myRestaurant == null
              ? const Center(
                  child: Text('Restaurant profile not found.',
                      style: TextStyle(color: Colors.black54)))
              : RefreshIndicator(
                  onRefresh: _load,
                  color: darkGreen,
                  child: _items == null || _items!.isEmpty
                      ? ListView(children: const [
                          SizedBox(height: 100),
                          Center(
                              child: Text('No items yet.',
                                  style: TextStyle(color: Colors.black54)))
                        ])
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _items!.length,
                          itemBuilder: (context, index) {
                            final item = _items![index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                        color: Colors.black
                                            .withValues(alpha: 0.04),
                                        blurRadius: 10)
                                  ]),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(12),
                                title: Text(item.name,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Colors.black87)),
                                subtitle: Text(
                                    '\$${item.price.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                        color: darkGreen,
                                        fontWeight: FontWeight.bold)),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Switch(
                                      value: item.available,
                                      activeThumbColor: darkGreen,
                                      activeTrackColor:
                                          darkGreen.withValues(alpha: 0.5),
                                      onChanged: (_) =>
                                          _toggleAvailability(item),
                                    ),
                                    IconButton(
                                        icon: const Icon(Icons.edit,
                                            color: Colors.black54),
                                        onPressed: () =>
                                            _openAddSheet(item: item)),
                                    IconButton(
                                        icon: const Icon(Icons.delete_outline,
                                            color: Colors.red),
                                        onPressed: () => _deleteItem(item)),
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

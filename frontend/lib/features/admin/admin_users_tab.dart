import 'package:flutter/material.dart';
import '../../shared/services/api_client.dart';

class AdminUsersTab extends StatefulWidget {
  const AdminUsersTab({super.key});
  @override
  State<AdminUsersTab> createState() => _AdminUsersTabState();
}

class _AdminUsersTabState extends State<AdminUsersTab> {
  List<dynamic> _users = [];
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
      final data = await ApiClient.get('/admin/users');
      setState(() => _users = data);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleBlock(int id, bool isActive) async {
    if (isActive) {
      await ApiClient.patch('/admin/users/$id/deactivate', {});
    } else {
      await ApiClient.patch('/admin/users/$id/activate', {});
    }
    await _load();
  }

  Future<void> _delete(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete User?'),
        content: const Text('This action cannot be undone.'),
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
      await ApiClient.delete('/admin/users/$id');
      await _load();
    }
  }

  void _createUser() {
    showDialog(
      context: context,
      builder: (ctx) {
        final name = TextEditingController();
        final phone = TextEditingController();
        final pass = TextEditingController();
        String role = 'restaurant_owner';

        return StatefulBuilder(builder: (ctx, setState) {
          return AlertDialog(
            title: const Text('Create New User'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                    controller: name,
                    decoration: const InputDecoration(labelText: 'Full Name')),
                const SizedBox(height: 8),
                TextField(
                    controller: phone,
                    decoration:
                        const InputDecoration(labelText: 'Phone Number')),
                const SizedBox(height: 8),
                TextField(
                    controller: pass,
                    decoration: const InputDecoration(labelText: 'Password')),
                const SizedBox(height: 16),
                DropdownButton<String>(
                  value: role,
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(
                        value: 'restaurant_owner',
                        child: Text('Restaurant Owner')),
                    DropdownMenuItem(value: 'rider', child: Text('Rider')),
                    DropdownMenuItem(
                        value: 'customer', child: Text('Customer')),
                  ],
                  onChanged: (v) => setState(() => role = v!),
                ),
              ],
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () async {
                  try {
                    await ApiClient.post('/admin/users', {
                      'full_name': name.text,
                      'phone': phone.text,
                      'password': pass.text,
                      'role': role,
                    });
                    if (ctx.mounted) Navigator.pop(ctx);
                    _load();
                  } catch (e) {
                    if (ctx.mounted) {
                      ScaffoldMessenger.of(ctx)
                          .showSnackBar(SnackBar(content: Text('Error: $e')));
                    }
                  }
                },
                child: const Text('Create'),
              )
            ],
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: darkGreen));
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: darkGreen,
        onPressed: _createUser,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add User', style: TextStyle(color: Colors.white)),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        color: darkGreen,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _users.length,
          itemBuilder: (context, index) {
            final u = _users[index];
            final isActive = u['is_active'] ?? true;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 5)
                  ]),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor:
                      isActive ? const Color(0xFFE8F0EA) : Colors.grey.shade300,
                  child: Text(u['full_name'][0].toUpperCase(),
                      style: TextStyle(
                          color: isActive ? darkGreen : Colors.grey,
                          fontWeight: FontWeight.bold)),
                ),
                title: Text(u['full_name'],
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, color: Colors.black87)),
                subtitle: Text('${u['role']} • ${u['phone']}',
                    style:
                        const TextStyle(fontSize: 12, color: Colors.black54)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(isActive ? Icons.block : Icons.check_circle,
                          color: isActive ? Colors.orange : Colors.green),
                      onPressed: () => _toggleBlock(u['id'], isActive),
                    ),
                    IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _delete(u['id'])),
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

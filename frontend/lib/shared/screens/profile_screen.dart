import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../features/auth/auth_state.dart';
import '../../shared/models/user.dart';
import '../../features/restaurant/restaurant_shell.dart';
import '../../features/rider/rider_shell.dart';
import '../../features/admin/admin_shell.dart';
import '../../features/auth/welcome_screen.dart';
import '../../shared/screens/settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _editing = false;
  bool _saving = false;

  static const darkGreen = Color(0xFF0D2B1A);
  static const gold = Color(0xFFD4AF37);

  late TextEditingController _name;
  late TextEditingController _city;
  late TextEditingController _country;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthState>().user;
    _name = TextEditingController(text: user?.fullName ?? '');
    _city = TextEditingController(text: user?.city ?? '');
    _country = TextEditingController(text: user?.country ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _city.dispose();
    _country.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await context.read<AuthState>().updateProfile({
        'full_name': _name.text.trim(),
        'city': _city.text.trim().isEmpty ? null : _city.text.trim(),
        'country': _country.text.trim().isEmpty ? null : _country.text.trim(),
      });
      if (mounted) {
        setState(() => _editing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    final user = auth.user;

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: darkGreen)),
      );
    }

    final initials = user.fullName.trim().isEmpty
        ? '?'
        : user.fullName
            .trim()
            .split(' ')
            .map((e) => e[0])
            .take(2)
            .join()
            .toUpperCase();

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header with Avatar
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: darkGreen,
                    borderRadius:
                        BorderRadius.vertical(bottom: Radius.circular(30)),
                  ),
                ),
                Positioned(
                  bottom: -50,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 55,
                      backgroundColor: darkGreen,
                      child: Text(
                        initials,
                        style: const TextStyle(
                          fontSize: 38,
                          fontWeight: FontWeight.bold,
                          color: gold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 60),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _editing ? _buildEditForm() : _buildViewMode(user),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildEditForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Edit Details',
          style: TextStyle(
              fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        const SizedBox(height: 20),
        _textField('Full Name', _name),
        const SizedBox(height: 16),
        _textField('City', _city),
        const SizedBox(height: 16),
        _textField('Country', _country),
        const SizedBox(height: 32),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => _editing = false),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(54),
                  side: const BorderSide(color: Colors.grey),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                ),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.black54, fontSize: 16),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: darkGreen,
                  minimumSize: const Size.fromHeight(54),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                ),
                child: _saving
                    ? const CircularProgressIndicator(
                        color: gold, strokeWidth: 2)
                    : const Text(
                        'Save',
                        style: TextStyle(
                            color: gold,
                            fontSize: 16,
                            fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _textField(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.black87),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.black54),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: darkGreen, width: 2),
        ),
      ),
    );
  }

  Widget _buildViewMode(AppUser user) {
    return Column(
      children: [
        Text(
          user.fullName,
          style: const TextStyle(
              fontSize: 26, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        const SizedBox(height: 8),
        Text(
          user.phone,
          style: const TextStyle(color: Colors.black54, fontSize: 15),
        ),
        const SizedBox(height: 8),
        Text(
          '${user.city ?? 'Not set'}${user.country != null ? ', ${user.country}' : ''}',
          style: const TextStyle(color: Colors.black54, fontSize: 14),
        ),
        const SizedBox(height: 32),

        // Role Dashboard Tiles
        if (user.role == 'admin') ...[
          _dashboardTile(
            'Admin Dashboard',
            'Manage revenue, users, and approvals',
            Icons.admin_panel_settings,
            Colors.purple,
            () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => const AdminShell())),
          ),
        ] else if (user.role == 'restaurant_owner') ...[
          _dashboardTile(
            'Restaurant Dashboard',
            'Manage your orders and menu',
            Icons.storefront,
            Colors.orange,
            () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const RestaurantShell())),
          ),
        ] else if (user.role == 'rider') ...[
          _dashboardTile(
            'Rider Dashboard',
            'View jobs, earnings, and go online',
            Icons.delivery_dining,
            Colors.blue,
            () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => const RiderShell())),
          ),
        ],

        const SizedBox(height: 16),
        const Divider(color: Colors.black12),

        // Menu Items
        Material(
          color: Colors.transparent,
          child: Column(
            children: [
              _listTile('Profile details', Icons.person_outline,
                  () => setState(() => _editing = true)),
              _listTile('Settings', Icons.tune, () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen()));
              }),
              _listTile('About This App', Icons.info_outline, () {
                showAboutDialog(
                  context: context,
                  applicationName: 'Food Delivery',
                  applicationVersion: '1.0.0',
                  applicationIcon: const Icon(Icons.delivery_dining,
                      size: 40, color: darkGreen),
                  children: [
                    const Text(
                      'A premium food delivery app. Order from the best restaurants, delivered to your door.\n\nSupport: support@fooddelivery.app',
                    ),
                  ],
                );
              }),
              _listTile('Log out', Icons.logout, () async {
                final navigator = Navigator.of(context);
                await context.read<AuthState>().logout();
                navigator.pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                  (route) => false,
                );
              }, isDanger: true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _dashboardTile(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: color),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: color),
          ],
        ),
      ),
    );
  }

  Widget _listTile(String title, IconData icon, VoidCallback onTap,
      {bool isDanger = false}) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: isDanger ? Colors.red : Colors.black87),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 16,
          color: isDanger ? Colors.red : Colors.black87,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.black38),
      onTap: onTap,
    );
  }
}

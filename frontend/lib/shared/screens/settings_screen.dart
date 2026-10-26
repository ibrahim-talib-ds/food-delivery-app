import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const darkGreen = Color(0xFF0D2B1A);

  bool _notificationsEnabled = true;
  bool _emailNotifications = true;
  bool _smsNotifications = false;
  bool _promoNotifications = true;
  String _language = 'English';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notif_enabled') ?? true;
      _emailNotifications = prefs.getBool('email_notif') ?? true;
      _smsNotifications = prefs.getBool('sms_notif') ?? false;
      _promoNotifications = prefs.getBool('promo_notif') ?? true;
      _language = prefs.getString('language') ?? 'English';
    });
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) await prefs.setBool(key, value);
    if (value is String) await prefs.setString(key, value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: darkGreen,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Settings',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionHeader('Notifications'),
          _toggleTile(
            'Push Notifications',
            'Receive alerts for your orders',
            Icons.notifications,
            _notificationsEnabled,
            (v) {
              setState(() => _notificationsEnabled = v);
              _saveSetting('notif_enabled', v);
            },
          ),
          _toggleTile(
            'Email Notifications',
            'Get order updates via email',
            Icons.email,
            _emailNotifications,
            (v) {
              setState(() => _emailNotifications = v);
              _saveSetting('email_notif', v);
            },
          ),
          _toggleTile(
            'SMS Notifications',
            'Receive texts about deliveries',
            Icons.sms,
            _smsNotifications,
            (v) {
              setState(() => _smsNotifications = v);
              _saveSetting('sms_notif', v);
            },
          ),
          _toggleTile(
            'Promotions',
            'Get deals and special offers',
            Icons.local_offer,
            _promoNotifications,
            (v) {
              setState(() => _promoNotifications = v);
              _saveSetting('promo_notif', v);
            },
          ),
          const SizedBox(height: 24),
          _sectionHeader('Preferences'),
          _languageTile(),
          _optionTile(
            'Currency',
            'USD (\$)',
            Icons.attach_money,
            () => _showCurrencyPicker(),
          ),
          _optionTile(
            'Theme',
            'Light Mode',
            Icons.palette,
            () => _showThemePicker(),
          ),
          const SizedBox(height: 24),
          _sectionHeader('Account'),
          _optionTile(
            'Change Password',
            'Update your password',
            Icons.lock,
            () => _showChangePassword(),
          ),
          _optionTile(
            'Privacy Policy',
            'Read our privacy policy',
            Icons.privacy_tip,
            () => _showPrivacyPolicy(),
          ),
          _optionTile(
            'Terms of Service',
            'Read our terms',
            Icons.description,
            () => _showTerms(),
          ),
          const SizedBox(height: 24),
          _sectionHeader('Support'),
          _optionTile(
            'Help Center',
            'FAQs and troubleshooting',
            Icons.help,
            () => _showHelp(),
          ),
          _optionTile(
            'Contact Support',
            'support@fooddelivery.app',
            Icons.support_agent,
            () => _showContactSupport(),
          ),
          _optionTile(
            'Report a Bug',
            'Let us know what went wrong',
            Icons.bug_report,
            () => _showBugReport(),
          ),
          const SizedBox(height: 24),
          _sectionHeader('Danger Zone'),
          _optionTile(
            'Delete Account',
            'Permanently delete your account',
            Icons.delete_forever,
            () => _confirmDelete(),
            isDanger: true,
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _sectionHeader(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.black54,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _toggleTile(String title, String subtitle, IconData icon, bool value,
      ValueChanged<bool> onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Icon(icon, color: darkGreen),
        title: Text(title,
            style: const TextStyle(
                fontWeight: FontWeight.w500, color: Colors.black87)),
        subtitle: Text(subtitle,
            style: const TextStyle(fontSize: 12, color: Colors.black54)),
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: darkGreen,
          activeTrackColor: darkGreen.withValues(alpha: 0.5),
        ),
      ),
    );
  }

  Widget _optionTile(
      String title, String subtitle, IconData icon, VoidCallback onTap,
      {bool isDanger = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Icon(icon, color: isDanger ? Colors.red : darkGreen),
        title: Text(title,
            style: TextStyle(
                fontWeight: FontWeight.w500,
                color: isDanger ? Colors.red : Colors.black87)),
        subtitle: Text(subtitle,
            style: const TextStyle(fontSize: 12, color: Colors.black54)),
        trailing: const Icon(Icons.chevron_right, color: Colors.black38),
        onTap: onTap,
      ),
    );
  }

  Widget _languageTile() {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: const Icon(Icons.language, color: darkGreen),
        title: const Text('Language',
            style:
                TextStyle(fontWeight: FontWeight.w500, color: Colors.black87)),
        subtitle: Text(_language,
            style: const TextStyle(fontSize: 12, color: Colors.black54)),
        trailing: const Icon(Icons.chevron_right, color: Colors.black38),
        onTap: () async {
          final selected = await showModalBottomSheet<String>(
            context: context,
            backgroundColor: Colors.white,
            shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
            builder: (ctx) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 16),
                const Text('Select Language',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 8),
                ...['English', 'Swahili', 'French', 'Spanish', 'Arabic']
                    .map((lang) => ListTile(
                          title: Text(lang),
                          trailing: _language == lang
                              ? const Icon(Icons.check, color: darkGreen)
                              : null,
                          onTap: () => Navigator.pop(ctx, lang),
                        )),
                const SizedBox(height: 24),
              ],
            ),
          );
          if (selected != null) {
            setState(() => _language = selected);
            _saveSetting('language', selected);
          }
        },
      ),
    );
  }

  void _showCurrencyPicker() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Currency: USD (\$) - Coming soon')),
    );
  }

  void _showThemePicker() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Theme selection coming soon')),
    );
  }

  void _showChangePassword() {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: currentCtrl,
                obscureText: true,
                decoration:
                    const InputDecoration(labelText: 'Current Password')),
            const SizedBox(height: 12),
            TextField(
                controller: newCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'New Password')),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Password change coming soon')),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: const SingleChildScrollView(
          child: Text(
            'We value your privacy.\n\n'
            '1. We collect your name, phone, email, and delivery addresses.\n'
            '2. We use this data to process your orders and deliver them.\n'
            '3. We never sell your data to third parties.\n'
            '4. Your payment information is encrypted.\n'
            '5. You can delete your account at any time.\n\n'
            'For questions: privacy@fooddelivery.app',
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  void _showTerms() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Terms of Service'),
        content: const SingleChildScrollView(
          child: Text(
            'By using this app, you agree to:\n\n'
            '1. Provide accurate information.\n'
            '2. Pay for orders you place.\n'
            '3. Treat delivery riders with respect.\n'
            '4. Not misuse the platform.\n'
            '5. Follow local laws and regulations.\n\n'
            'We reserve the right to suspend accounts that violate these terms.',
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  void _showHelp() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Help Center'),
        content: const SingleChildScrollView(
          child: Text(
            'Common Questions:\n\n'
            'Q: How do I place an order?\n'
            'A: Browse restaurants, add items to cart, and checkout.\n\n'
            'Q: How do I track my order?\n'
            'A: Go to Orders tab and tap your active order.\n\n'
            'Q: How do I cancel an order?\n'
            'A: Contact the restaurant or support.\n\n'
            'Q: How do I report a problem?\n'
            'A: Use the "Report a Bug" option in Settings.',
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  void _showContactSupport() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Contact Support'),
        content: const Text(
          'Email: support@fooddelivery.app\n'
          'Phone: +1-800-FOOD-APP\n'
          'Hours: 24/7',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  void _showBugReport() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Report a Bug'),
        content: TextField(
          controller: ctrl,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Describe the issue...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Thank you! Bug report submitted.')),
              );
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Account?'),
        content: const Text(
            'This will permanently delete your account and all your data. This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Account deletion requires email verification'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

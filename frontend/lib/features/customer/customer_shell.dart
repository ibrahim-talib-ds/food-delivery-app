import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'cart_state.dart';
import 'home_tab.dart';
import 'order_history_tab.dart';
import 'cart_tab.dart';
import '../../shared/screens/profile_screen.dart';
import '../../shared/screens/messages_tab.dart';
import '../../shared/services/api_client.dart';

class CustomerShell extends StatefulWidget {
  const CustomerShell({super.key});
  @override
  State<CustomerShell> createState() => _CustomerShellState();
}

class _CustomerShellState extends State<CustomerShell> {
  int _index = 0;
  int _unreadCount = 0;
  Timer? _timer;

  final List<Widget> _tabs = const [
    HomeTab(),
    OrderHistoryTab(),
    CartTab(),
    MessagesTab(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CartState>().fetchCart();
      _fetchUnread();
    });
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _fetchUnread());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchUnread() async {
    try {
      final res = await ApiClient.get('/conversations');
      int total = 0;
      for (var c in (res as List)) {
        total += (c['unread'] ?? 0) as int;
      }
      if (mounted) setState(() => _unreadCount = total);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartState>();
    final cartCount = cart.cart?.itemCount ?? 0;
    final isDesktop = MediaQuery.of(context).size.width >= 800;
    const darkGreen = Color(0xFF0D2B1A);
    const gold = Color(0xFFD4AF37);

    final navItems = [
      const BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Home'),
      const BottomNavigationBarItem(
          icon: Icon(Icons.receipt_long_outlined),
          activeIcon: Icon(Icons.receipt_long),
          label: 'Orders'),
      BottomNavigationBarItem(
        icon: Badge(
          isLabelVisible: cartCount > 0,
          label: Text('$cartCount'),
          child: const Icon(Icons.shopping_bag_outlined),
        ),
        activeIcon: Badge(
          isLabelVisible: cartCount > 0,
          label: Text('$cartCount'),
          child: const Icon(Icons.shopping_bag),
        ),
        label: 'Cart',
      ),
      BottomNavigationBarItem(
        icon: _unreadCount > 0
            ? Badge(
                label: Text('$_unreadCount'),
                child: const Icon(Icons.chat_bubble_outline))
            : const Icon(Icons.chat_bubble_outline),
        activeIcon: _unreadCount > 0
            ? Badge(
                label: Text('$_unreadCount'),
                child: const Icon(Icons.chat_bubble))
            : const Icon(Icons.chat_bubble),
        label: 'Chat',
      ),
      const BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: 'Profile'),
    ];

    if (isDesktop) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _index,
              onDestinationSelected: (i) => setState(() => _index = i),
              extended: MediaQuery.of(context).size.width >= 1100,
              backgroundColor: darkGreen,
              indicatorColor: gold.withValues(alpha: 0.2),
              selectedIconTheme: const IconThemeData(color: gold),
              unselectedIconTheme: const IconThemeData(color: Colors.white54),
              selectedLabelTextStyle:
                  const TextStyle(color: gold, fontWeight: FontWeight.bold),
              unselectedLabelTextStyle: const TextStyle(color: Colors.white54),
              leading: const Padding(
                padding: EdgeInsets.all(16.0),
                child: Icon(Icons.delivery_dining, color: gold, size: 32),
              ),
              destinations: navItems
                  .map((item) => NavigationRailDestination(
                        icon: item.icon,
                        selectedIcon: item.activeIcon,
                        label: Text(item.label ?? ''),
                      ))
                  .toList(),
            ),
            Expanded(child: _tabs[_index]),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: darkGreen,
      body: _tabs[_index],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Colors.white12, width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _index,
          onTap: (i) => setState(() => _index = i),
          backgroundColor: darkGreen,
          selectedItemColor: gold,
          unselectedItemColor: Colors.white54,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          items: navItems,
        ),
      ),
    );
  }
}

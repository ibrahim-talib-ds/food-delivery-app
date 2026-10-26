import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../shared/screens/profile_screen.dart';
import 'rider_overview_tab.dart';
import 'rider_jobs_tab.dart';
import 'rider_earnings_tab.dart';
import '../../shared/screens/messages_tab.dart';

class RiderShell extends StatefulWidget {
  const RiderShell({super.key});
  @override
  State<RiderShell> createState() => _RiderShellState();
}

class _RiderShellState extends State<RiderShell> {
  int _index = 0;
  final List<Widget> _tabs = const [
    RiderOverviewTab(),
    RiderJobsTab(),
    RiderEarningsTab(),
    MessagesTab()
  ];

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 800;
    final navItems = [
      const BottomNavigationBarItem(
          icon: Icon(Icons.dashboard_outlined),
          activeIcon: Icon(Icons.dashboard),
          label: 'Overview'),
      const BottomNavigationBarItem(
          icon: Icon(Icons.delivery_dining_outlined),
          activeIcon: Icon(Icons.delivery_dining),
          label: 'Jobs'),
      const BottomNavigationBarItem(
          icon: Icon(Icons.account_balance_wallet_outlined),
          activeIcon: Icon(Icons.account_balance_wallet),
          label: 'Earnings'),
      const BottomNavigationBarItem(
          icon: Icon(Icons.chat_bubble_outline),
          activeIcon: Icon(Icons.chat_bubble),
          label: 'Chat'),
    ];

    if (isDesktop) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _index,
              onDestinationSelected: (i) => setState(() => _index = i),
              extended: MediaQuery.of(context).size.width >= 1100,
              backgroundColor: Colors.white,
              indicatorColor: AppColors.mint,
              leading: const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Icon(Icons.delivery_dining,
                      color: AppColors.primary, size: 32)),
              destinations: navItems
                  .map((item) => NavigationRailDestination(
                      icon: item.icon,
                      selectedIcon: item.activeIcon,
                      label: Text(item.label ?? '')))
                  .toList(),
              trailing: Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const Divider(),
                    IconButton(
                        icon: const Icon(Icons.person_outline,
                            color: AppColors.primary),
                        onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const ProfileScreen()))),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            const VerticalDivider(width: 1, color: Colors.black12),
            Expanded(child: _tabs[_index]),
          ],
        ),
      );
    }

    return Scaffold(
      body: _tabs[_index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textMuted,
        type: BottomNavigationBarType.fixed,
        items: navItems,
      ),
    );
  }
}

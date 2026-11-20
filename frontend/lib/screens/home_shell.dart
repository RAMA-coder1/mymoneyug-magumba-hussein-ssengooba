import 'package:flutter/material.dart';
import '../lucide_icons.dart';
import 'package:provider/provider.dart';

import '../services/auth_controller.dart';
import '../widgets/async_view.dart';
import 'accounts_screen.dart';
import 'categories_screen.dart';
import 'dashboard_screen.dart';
import 'transactions_screen.dart';

/// Consistent navigation (NFR-02): four tabs plus logout.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const _titles = ['Dashboard', 'Transactions', 'Accounts', 'Categories'];

  Future<void> _logout() async {
    final ok = await confirm(
        context, 'Log out?', 'You will need to log in again to see your records.',
        action: 'Log out');
    if (ok && mounted) await context.read<AuthController>().logout();
  }

  @override
  Widget build(BuildContext context) {
    // Tabs are rebuilt on switch so figures are always re-fetched.
    final pages = <Widget>[
      DashboardScreen(onSeeAll: () => setState(() => _index = 1)),
      const TransactionsScreen(),
      const AccountsScreen(),
      const CategoriesScreen(),
    ];
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_index]),
        actions: [
          IconButton(
            tooltip: 'Log out',
            icon: const Icon(LucideIcons.logOut),
            onPressed: _logout,
          ),
        ],
      ),
      body: KeyedSubtree(key: ValueKey(_index), child: pages[_index]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(LucideIcons.layoutDashboard),
              selectedIcon: Icon(LucideIcons.layoutDashboard),
              label: 'Dashboard'),
          NavigationDestination(
              icon: Icon(LucideIcons.receipt),
              selectedIcon: Icon(LucideIcons.receipt),
              label: 'Transactions'),
          NavigationDestination(
              icon: Icon(LucideIcons.wallet),
              selectedIcon: Icon(LucideIcons.wallet),
              label: 'Accounts'),
          NavigationDestination(
              icon: Icon(LucideIcons.tag),
              selectedIcon: Icon(LucideIcons.tag),
              label: 'Categories'),
        ],
      ),
    );
  }
}

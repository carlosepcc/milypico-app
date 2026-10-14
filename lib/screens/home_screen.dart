import 'package:flutter/material.dart';
import 'pos_screen.dart';
import 'sessions_screen.dart';
import 'catalog_screen.dart';
import 'currencies_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    POSScreen(),
    SessionsScreen(),
    CatalogScreen(),
    CurrenciesScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        backgroundColor: const Color(0xFF0F172A),
        indicatorColor: const Color(0xFF10B981).withValues(alpha: 0.25),
        elevation: 8,
        onDestinationSelected: (idx) {
          setState(() {
            _currentIndex = idx;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.point_of_sale_outlined, color: Colors.white70),
            selectedIcon: Icon(Icons.point_of_sale, color: Color(0xFF34D399)),
            label: 'POS',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_toggle_off, color: Colors.white70),
            selectedIcon: Icon(Icons.history_toggle_off, color: Color(0xFF34D399)),
            label: 'Sesiones',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined, color: Colors.white70),
            selectedIcon: Icon(Icons.inventory_2, color: Color(0xFF34D399)),
            label: 'Catálogo',
          ),
          NavigationDestination(
            icon: Icon(Icons.currency_exchange, color: Colors.white70),
            selectedIcon: Icon(Icons.currency_exchange, color: Color(0xFF34D399)),
            label: 'Divisas',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined, color: Colors.white70),
            selectedIcon: Icon(Icons.settings, color: Color(0xFF34D399)),
            label: 'Ajustes',
          ),
        ],
      ),
    );
  }
}

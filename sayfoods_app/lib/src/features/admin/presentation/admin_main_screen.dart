import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:sayfoods_app/src/features/admin/presentation/admin_dashboard_screen.dart';
import 'package:sayfoods_app/src/features/admin/presentation/admin_riders_hub_screen.dart';
import 'package:sayfoods_app/src/features/admin/presentation/admin_settings_screen.dart';

class AdminMainScreen extends StatefulWidget {
  const AdminMainScreen({super.key});

  @override
  State<AdminMainScreen> createState() => _AdminMainScreenState();
}

class _AdminMainScreenState extends State<AdminMainScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    const purple = Color(0xFF5B1380);

    final List<Widget> pages = [
      const AdminDashboardScreen(),
      const AdminRidersHubScreen(),
      const AdminSettingsScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: pages,
      ),
      bottomNavigationBar: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.88),
              border: Border(
                top: BorderSide(
                  color: Colors.white.withValues(alpha: 0.5),
                  width: 0.5,
                ),
              ),
            ),
            child: NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (i) =>
                  setState(() => _selectedIndex = i),
              backgroundColor: Colors.transparent,
              elevation: 0,
              indicatorColor: const Color(0x1A5B1380),
              labelBehavior:
                  NavigationDestinationLabelBehavior.alwaysShow,
              animationDuration: const Duration(milliseconds: 300),
              destinations: const [
                NavigationDestination(
                    icon: Icon(Icons.layers_outlined),
                    selectedIcon:
                        Icon(Icons.layers, color: purple),
                    label: 'Dashboard'),
                NavigationDestination(
                    icon: Icon(Icons.local_shipping_outlined),
                    selectedIcon: Icon(Icons.local_shipping,
                        color: purple),
                    label: 'Riders'),
                NavigationDestination(
                    icon: Icon(Icons.settings_outlined),
                    selectedIcon:
                        Icon(Icons.settings, color: purple),
                    label: 'Settings'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

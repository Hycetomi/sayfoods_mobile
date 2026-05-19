import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sayfoods_app/src/features/chat/application/chat_provider.dart';
import 'package:sayfoods_app/src/features/chat/presentation/chat_screen.dart';
import 'package:sayfoods_app/src/features/rider/application/rider_location_service.dart';
import 'package:sayfoods_app/src/features/rider/presentation/rider_home_screen.dart';
import 'package:sayfoods_app/src/features/rider/presentation/active_delivery_screen.dart';
import 'package:sayfoods_app/src/features/rider/presentation/rider_earnings_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RiderMainScreen extends ConsumerStatefulWidget {
  const RiderMainScreen({super.key});

  @override
  ConsumerState<RiderMainScreen> createState() => _RiderMainScreenState();
}

class _RiderMainScreenState extends ConsumerState<RiderMainScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(riderLocationServiceProvider).requestPermission();
    });
  }

  @override
  Widget build(BuildContext context) {
    final riderId = Supabase.instance.client.auth.currentUser?.id ?? '';

    final List<Widget> pages = [
      const RiderHomeScreen(),
      const ActiveDeliveryScreen(),
      const RiderEarningsScreen(),
      ChatScreen(
        params: ChatChannelParams(
          channelType: 'admin_rider',
          riderId: riderId,
        ),
        title: 'Dispatch',
        subtitle: 'Admin Communication Line',
      ),
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
              indicatorColor: const Color(0x1AF28F2A),
              labelBehavior:
                  NavigationDestinationLabelBehavior.alwaysShow,
              animationDuration: const Duration(milliseconds: 300),
              destinations: const [
                NavigationDestination(
                    icon: Icon(Icons.home_outlined),
                    selectedIcon:
                        Icon(Icons.home, color: Colors.orange),
                    label: 'Pool'),
                NavigationDestination(
                    icon: Icon(Icons.delivery_dining_outlined),
                    selectedIcon: Icon(Icons.delivery_dining,
                        color: Colors.orange),
                    label: 'Active'),
                NavigationDestination(
                    icon: Icon(Icons.account_balance_wallet_outlined),
                    selectedIcon: Icon(Icons.account_balance_wallet,
                        color: Colors.orange),
                    label: 'Earnings'),
                NavigationDestination(
                    icon: Icon(Icons.headset_mic_outlined),
                    selectedIcon: Icon(Icons.headset_mic_rounded,
                        color: Colors.orange),
                    label: 'Dispatch'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

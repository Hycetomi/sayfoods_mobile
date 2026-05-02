import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sayfoods_app/src/features/chat/application/chat_provider.dart';
import 'package:sayfoods_app/src/features/chat/presentation/chat_screen.dart';
import 'package:sayfoods_app/src/features/rider/presentation/rider_home_screen.dart';
import 'package:sayfoods_app/src/features/rider/presentation/active_delivery_screen.dart';
import 'package:sayfoods_app/src/features/rider/presentation/rider_earnings_screen.dart';

class RiderMainScreen extends StatefulWidget {
  const RiderMainScreen({super.key});

  @override
  State<RiderMainScreen> createState() => _RiderMainScreenState();
}

class _RiderMainScreenState extends State<RiderMainScreen> {
  int _selectedIndex = 0;

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
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          selectedItemColor: Colors.orange,
          unselectedItemColor: Colors.black54,
          backgroundColor: Colors.white,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
                icon: Icon(Icons.home), label: 'Pool'),
            BottomNavigationBarItem(
                icon: Icon(Icons.delivery_dining), label: 'Active'),
            BottomNavigationBarItem(
                icon: Icon(Icons.account_balance_wallet), label: 'Earnings'),
            BottomNavigationBarItem(
                icon: Icon(Icons.headset_mic_rounded), label: 'Dispatch'),
          ],
        ),
      ),
    );
  }
}

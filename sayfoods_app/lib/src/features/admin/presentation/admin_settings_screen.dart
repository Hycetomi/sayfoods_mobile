import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sayfoods_app/src/features/admin/presentation/manage_products_screen.dart';
import 'package:sayfoods_app/src/features/admin/presentation/manage_categories_screen.dart';
import 'package:sayfoods_app/src/features/admin/presentation/order_goals_screen.dart';
import 'package:sayfoods_app/src/features/admin/presentation/order_history_screen.dart';
import 'package:sayfoods_app/src/features/admin/presentation/manage_users_screen.dart';
import 'package:sayfoods_app/src/features/admin/presentation/edit_admin_profile_screen.dart';

class AdminSettingsScreen extends StatelessWidget {
  const AdminSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const colorPurple = Color(0xFF5B1380);
    const colorOrange = Color(0xFFF28F2A);
    const bgColor = Color(0xFFFCFCFC);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header
              const Text(
                'Settings',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 32),

              // 2. Settings Items
              _buildSettingsTile(
                context,
                title: 'Manage Products',
                icon: Icons.inventory_2,
                color: colorPurple,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ManageProductsScreen()),
                ),
              ),
              _buildSettingsTile(
                context,
                title: 'Manage Categories',
                icon: Icons.category,
                color: colorPurple,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ManageCategoriesScreen()),
                ),
              ),
              _buildSettingsTile(
                context,
                title: 'Order Goals',
                icon: Icons.track_changes,
                color: colorOrange,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const OrderGoalsScreen()),
                ),
              ),
              _buildSettingsTile(
                context,
                title: 'Order History',
                icon: Icons.history,
                color: colorOrange,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const OrderHistoryScreen()),
                ),
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              
              _buildSettingsTile(
                context,
                title: 'Manage Users',
                icon: Icons.people,
                color: Colors.black87,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ManageUsersScreen()),
                ),
              ),
              _buildSettingsTile(
                context,
                title: 'Edit Admin Profile',
                icon: Icons.admin_panel_settings,
                color: Colors.black87,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EditAdminProfileScreen()),
                ),
              ),
              const SizedBox(height: 32),
              
              // 3. Logout Button
              InkWell(
                onTap: () async {
                  await Supabase.instance.client.auth.signOut();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.logout, color: Colors.red),
                      SizedBox(width: 8),
                      Text(
                        'SIGN OUT',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04), // Ultra soft shadow
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }
}

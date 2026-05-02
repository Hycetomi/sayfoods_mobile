import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sayfoods_app/src/features/rider/application/rider_duty_provider.dart';
import 'package:sayfoods_app/src/shared/widgets/sayfoods_app_bar.dart';
import 'package:sayfoods_app/src/shared/widgets/sayfoods_modal.dart';
import 'package:sayfoods_app/src/features/admin/application/system_settings_provider.dart';
import 'package:sayfoods_app/src/features/rider/application/live_order_stream_provider.dart';

class RiderHomeScreen extends ConsumerWidget {
  const RiderHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dutyState = ref.watch(riderDutyProvider);
    final liveOrders = ref.watch(liveOrderStreamProvider);
    final settingsState = ref.watch(systemSettingsProvider);
    double commPercentage = 60.0;
    if (settingsState is AsyncData) {
      commPercentage = (settingsState.value?['commission_percentage'] as num?)?.toDouble() ?? 60.0;
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: SayfoodsAppBar(
        title: 'Dispatch Pool',
        showBackButton: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
            tooltip: 'Sign Out',
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  title: const Text('Sign Out',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  content:
                      const Text('Are you sure you want to sign out?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Sign Out',
                          style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
              if (confirmed == true) {
                await Supabase.instance.client.auth.signOut();
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Duty Toggle Section
          Container(
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Duty Status',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                dutyState.when(
                  data: (isOnline) => Switch(
                    value: isOnline,
                    activeColor: Colors.green,
                    onChanged: (val) async {
                      try {
                        await ref.read(riderDutyProvider.notifier).toggleDutyStatus(val);
                      } catch (e) {
                        if (context.mounted) {
                          SayfoodsModal.show(
                            context: context,
                            type: SayfoodsModalType.error,
                            title: 'Status Update Failed',
                            subtitle: e.toString(),
                          );
                        }
                      }
                    },
                  ),
                  loading: () => const CircularProgressIndicator(),
                  error: (err, _) => const Icon(Icons.error, color: Colors.red),
                ),
              ],
            ),
          ),
          
          // Pool Section
          Expanded(
            child: dutyState.maybeWhen(
              data: (isOnline) {
                if (!isOnline) {
                  return const Center(
                    child: Text(
                      'Go Online to view the dispatch pool.',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  );
                }
                
                return liveOrders.when(
                  data: (orders) {
                    if (orders.isEmpty) {
                      return const Center(
                        child: Text(
                          'No orders ready for pickup.',
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      );
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: orders.length,
                      itemBuilder: (context, index) {
                        final order = orders[index];
                        double rawCommission = order.deliveryFee * (commPercentage / 100);
                        final commission = rawCommission < 500 ? 500 : rawCommission;
                        
                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Order #${order.id.substring(0, 8)}',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                    Text(
                                      'Est. Earn: ₦${commission.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                        color: Colors.green,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text('Drop-off: ${order.deliveryAddress}', style: const TextStyle(fontSize: 14)),
                                const SizedBox(height: 16),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.orange,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    onPressed: () async {
                                      try {
                                        final supabase = Supabase.instance.client;
                                        final user = supabase.auth.currentUser;
                                        if (user == null) throw Exception("Not authenticated");
                                        
                                        await supabase.from('orders').update({
                                          'rider_id': user.id,
                                          'status': 'delivering'
                                        }).eq('id', order.id);
                                        
                                        if (context.mounted) {
                                          SayfoodsModal.show(
                                            context: context,
                                            type: SayfoodsModalType.success,
                                            title: 'Order Accepted',
                                            subtitle: 'You are now delivering Order #${order.id.substring(0, 8)}',
                                          );
                                        }
                                      } catch (e) {
                                        if (context.mounted) {
                                          SayfoodsModal.show(
                                            context: context,
                                            type: SayfoodsModalType.error,
                                            title: 'Failed to Accept Order',
                                            subtitle: e.toString(),
                                          );
                                        }
                                      }
                                    },
                                    child: const Text('Accept Delivery', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, _) => Center(child: Text('Error: $err')),
                );
              },
              orElse: () => const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }
}

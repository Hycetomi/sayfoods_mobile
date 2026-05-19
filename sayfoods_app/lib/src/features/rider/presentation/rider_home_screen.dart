import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sayfoods_app/src/features/rider/application/rider_duty_provider.dart';
import 'package:sayfoods_app/src/shared/widgets/sayfoods_app_bar.dart';
import 'package:sayfoods_app/src/shared/widgets/sayfoods_modal.dart';
import 'package:sayfoods_app/src/features/admin/application/system_settings_provider.dart';
import 'package:sayfoods_app/src/features/rider/application/live_order_stream_provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:sayfoods_app/src/shared/theme/app_colors.dart';
import 'package:sayfoods_app/src/shared/utils/error_handler.dart';

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
      backgroundColor: AppColors.background,
      appBar: SayfoodsAppBar(
        title: 'Dispatch Pool',
        showBackButton: false,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.logOut, color: AppColors.textPrimary),
            tooltip: 'Sign Out',
            onPressed: () async {
              bool confirmed = false;
              await SayfoodsModal.show(
                context: context,
                type: SayfoodsModalType.warning,
                title: 'Sign Out',
                subtitle: 'Are you sure you want to sign out?',
                primaryButtonText: 'Sign Out',
                onPrimaryPressed: () {
                  confirmed = true;
                  Navigator.pop(context);
                },
                secondaryButtonText: 'Cancel',
                onSecondaryPressed: () => Navigator.pop(context),
              );
              if (confirmed) {
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
              color: AppColors.surface,
              border: const Border(
                bottom: BorderSide(color: AppColors.border, width: 1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Duty Status',
                  style: TextStyle(
                    fontSize: 18,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                dutyState.when(
                  data: (isOnline) => Switch(
                    value: isOnline,
                    activeColor: AppColors.success,
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
                  loading: () => const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
                  error: (err, _) => const Icon(LucideIcons.alertTriangle, color: AppColors.error),
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
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
                    ),
                  );
                }
                
                return liveOrders.when(
                  data: (orders) {
                    if (orders.isEmpty) {
                      return const Center(
                        child: Text(
                          'No orders ready for pickup.',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
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
                          elevation: 0,
                          color: AppColors.surface,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: const BorderSide(color: AppColors.border),
                          ),
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
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
                                    ),
                                    Text(
                                      'Est. Earn: ₦${commission.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                        color: AppColors.success,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text('Drop-off: ${order.deliveryAddress}', style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                                const SizedBox(height: 16),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    onPressed: () async {
                                      try {
                                        final supabase = Supabase.instance.client;
                                        final user = supabase.auth.currentUser;
                                        if (user == null) throw Exception("Not authenticated");
                                        
                                        await supabase.from('orders').update({
                                          'rider_id': user.id,
                                          'status': 'out_for_delivery'
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
                                            subtitle: ErrorHelper.getErrorMessage(e),
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
                  loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                  error: (err, _) => Center(child: Text('Error: $err', style: const TextStyle(color: AppColors.error))),
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

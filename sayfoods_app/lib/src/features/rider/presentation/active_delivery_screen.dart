import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sayfoods_app/src/features/orders/domain/order_model.dart';
import 'package:sayfoods_app/src/shared/widgets/sayfoods_app_bar.dart';
import 'package:sayfoods_app/src/shared/widgets/sayfoods_modal.dart';
import 'package:sayfoods_app/src/features/admin/application/system_settings_provider.dart';
import 'package:sayfoods_app/src/features/chat/application/chat_provider.dart';
import 'package:sayfoods_app/src/features/chat/presentation/chat_screen.dart';

// Watches orders assigned to this rider that are still in-progress (all 3 active statuses).
// Supabase .stream() only supports a single .eq() server filter, so we scope by rider_id
// and apply the three-status gate client-side — consistent with the pattern used elsewhere.
final activeDeliveriesProvider = StreamProvider<List<OrderModel>>((ref) {
  final supabase = Supabase.instance.client;
  final user = supabase.auth.currentUser;

  if (user == null) return Stream.value([]);

  return supabase
      .from('orders')
      .stream(primaryKey: ['id'])
      .eq('rider_id', user.id)
      .map((data) => data
          .map((json) => OrderModel.fromJson(json))
          .where((order) =>
              order.status == 'delivering' ||
              order.status == 'out_for_delivery' ||
              order.status == 'delivered')
          .toList());
});

class ActiveDeliveryScreen extends ConsumerStatefulWidget {
  const ActiveDeliveryScreen({super.key});

  @override
  ConsumerState<ActiveDeliveryScreen> createState() =>
      _ActiveDeliveryScreenState();
}

class _ActiveDeliveryScreenState extends ConsumerState<ActiveDeliveryScreen> {
  static const _purple = Color(0xFF5B1380);

  // Tracks which order IDs have an in-flight Supabase request — prevents double-tap.
  final Set<String> _loadingOrders = {};

  Future<void> _progressStatus(
      BuildContext context, OrderModel order, String nextStatus) async {
    if (_loadingOrders.contains(order.id)) return;
    setState(() => _loadingOrders.add(order.id));
    try {
      final supabase = Supabase.instance.client;
      final Map<String, dynamic> updates = {'status': nextStatus};

      if (nextStatus == 'completed') {
        final settingsState = ref.read(systemSettingsProvider);
        double commPercentage = 60.0;
        if (settingsState is AsyncData) {
          commPercentage =
              (settingsState.value?['commission_percentage'] as num?)
                  ?.toDouble() ??
              60.0;
        }
        final double rawCommission =
            order.deliveryFee * (commPercentage / 100);
        final double finalCommission =
            rawCommission < 500 ? 500 : rawCommission;

        updates['completed_at'] = DateTime.now().toUtc().toIso8601String();
        updates['commission_earned'] = finalCommission;
      }

      await supabase.from('orders').update(updates).eq('id', order.id);

      if (context.mounted) {
        SayfoodsModal.show(
          context: context,
          type: SayfoodsModalType.success,
          title: _successTitle(nextStatus),
          subtitle: _successSubtitle(nextStatus, order),
        );
      }
    } catch (e) {
      if (context.mounted) {
        SayfoodsModal.show(
          context: context,
          type: SayfoodsModalType.error,
          title: 'Error',
          subtitle: e.toString(),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingOrders.remove(order.id));
    }
  }

  String _successTitle(String status) {
    switch (status) {
      case 'out_for_delivery':
        return 'Picked Up';
      case 'delivered':
        return 'Arrived';
      case 'completed':
        return 'Order Completed';
      default:
        return 'Updated';
    }
  }

  String _successSubtitle(String status, OrderModel order) {
    final id = order.id.substring(0, 8).toUpperCase();
    switch (status) {
      case 'out_for_delivery':
        return 'Order #$id picked up. Head to the drop-off.';
      case 'delivered':
        return 'Marked as arrived at delivery location.';
      case 'completed':
        final fmt = NumberFormat.currency(symbol: '₦', decimalDigits: 0);
        final settingsState = ref.read(systemSettingsProvider);
        double commPercentage = 60.0;
        if (settingsState is AsyncData) {
          commPercentage =
              (settingsState.value?['commission_percentage'] as num?)
                  ?.toDouble() ??
              60.0;
        }
        final double raw = order.deliveryFee * (commPercentage / 100);
        final double earned = raw < 500 ? 500 : raw;
        return 'Order #$id completed. You earned ${fmt.format(earned)}.';
      default:
        return '';
    }
  }

  Widget _stepChip(String status) {
    final Map<String, _StepMeta> meta = {
      'delivering': _StepMeta('Step 1 of 3 • Pick Up', Colors.orange),
      'out_for_delivery': _StepMeta('Step 2 of 3 • En Route', Colors.blue),
      'delivered': _StepMeta('Step 3 of 3 • Arrived', Colors.teal),
    };
    final m = meta[status] ?? _StepMeta(status, Colors.grey);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: m.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: m.color.withValues(alpha: 0.3)),
      ),
      child: Text(
        m.label,
        style: TextStyle(
            color: m.color, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, OrderModel order) {
    final isLoading = _loadingOrders.contains(order.id);
    final spinner = const SizedBox(
      width: 18,
      height: 18,
      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
    );

    switch (order.status) {
      case 'delivering':
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _purple,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: isLoading
                ? null
                : () => _progressStatus(context, order, 'out_for_delivery'),
            child: isLoading
                ? spinner
                : const Text('Picked Up',
                    style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        );

      case 'out_for_delivery':
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: isLoading
                ? null
                : () => _progressStatus(context, order, 'delivered'),
            child: isLoading
                ? spinner
                : const Text('Arrived at Location',
                    style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        );

      case 'delivered':
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: isLoading
                ? null
                : () => _progressStatus(context, order, 'completed'),
            child: isLoading
                ? spinner
                : const Text('Mark as Completed',
                    style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        );

      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeOrders = ref.watch(activeDeliveriesProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: const SayfoodsAppBar(
        title: 'Active Deliveries',
        showBackButton: false,
      ),
      body: activeOrders.when(
        data: (orders) {
          if (orders.isEmpty) {
            return const Center(
              child: Text(
                'No active deliveries.',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Order #${order.id.substring(0, 8).toUpperCase()}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          _stepChip(order.status),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Drop-off: ${order.deliveryAddress}',
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        icon: const Icon(
                            Icons.chat_bubble_outline_rounded,
                            size: 16),
                        label: const Text('Chat with Customer'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _purple,
                          side: const BorderSide(color: _purple),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          minimumSize: const Size(double.infinity, 44),
                        ),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatScreen(
                              params: ChatChannelParams(
                                channelType: 'rider_client',
                                orderId: order.id,
                              ),
                              title: 'Customer',
                              subtitle:
                                  'Order #${order.id.substring(0, 8).toUpperCase()}',
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildActionButton(context, order),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }
}

class _StepMeta {
  final String label;
  final Color color;
  const _StepMeta(this.label, this.color);
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sayfoods_app/src/features/chat/application/chat_provider.dart';
import 'package:sayfoods_app/src/features/chat/presentation/chat_screen.dart';
import 'package:sayfoods_app/src/features/orders/domain/order_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sayfoods_app/src/shared/widgets/sayfoods_modal.dart';

// ── Provider: fetch full riders list (profiles with role = 'rider') ──────────
final ridersListProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final response = await Supabase.instance.client
      .from('profiles')
      .select('id, full_name')
      .eq('role', 'rider')
      .order('full_name');
  return List<Map<String, dynamic>>.from(response as List);
});

// ── Notifier: update order status / rider ────────────────────────────────────
class OrderDetailNotifier extends StateNotifier<AsyncValue<void>> {
  OrderDetailNotifier() : super(const AsyncValue.data(null));

  Future<void> updateStatus(String orderId, String newStatus) async {
    state = const AsyncValue.loading();
    try {
      final res = await Supabase.instance.client
          .from('orders')
          .update({'status': newStatus})
          .eq('id', orderId)
          .select();
      if (res.isEmpty) throw Exception('Update rejected. Check RLS policies on orders table.');
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> assignRider(String orderId, String riderId) async {
    state = const AsyncValue.loading();
    try {
      final res = await Supabase.instance.client
          .from('orders')
          .update({'rider_id': riderId})
          .eq('id', orderId)
          .select();
      if (res.isEmpty) throw Exception('Rider assignment rejected. Check RLS policies on orders table.');
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> adjustCommission(String orderId, double amount) async {
    state = const AsyncValue.loading();
    try {
      final res = await Supabase.instance.client
          .from('orders')
          .update({'commission_earned': amount})
          .eq('id', orderId)
          .select();
      if (res.isEmpty) throw Exception('Commission update rejected. Check RLS policies.');
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final orderDetailNotifierProvider =
    StateNotifierProvider<OrderDetailNotifier, AsyncValue<void>>(
  (ref) => OrderDetailNotifier(),
);

// ── Screen ───────────────────────────────────────────────────────────────────
class AdminOrderDetailScreen extends ConsumerStatefulWidget {
  final OrderModel order;
  const AdminOrderDetailScreen({super.key, required this.order});

  @override
  ConsumerState<AdminOrderDetailScreen> createState() =>
      _AdminOrderDetailScreenState();
}

class _AdminOrderDetailScreenState
    extends ConsumerState<AdminOrderDetailScreen> {
  static const _purple = Color(0xFF5B1380);
  static const _orange = Color(0xFFF28F2A);
  static const _bg = Color(0xFFFCFCFC);

  late String _currentStatus;
  String? _selectedRiderId;
  String? _selectedRiderName;

  // Exactly matches the Supabase `order_status` enum
  final _statuses = [
    'pending',
    'accepted',
    'sourcing',
    'ready_for_pickup',
    'out_for_delivery',
    'delivering',
    'delivered',
    'completed',
    'cancelled',
  ];

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.order.status;
    _selectedRiderId = widget.order.riderId;
    _selectedRiderName = widget.order.riderName;
    _commissionController = TextEditingController(
        text: widget.order.commissionEarned.toStringAsFixed(2));
  }

  @override
  void dispose() {
    _commissionController.dispose();
    super.dispose();
  }

  Color _statusColor(String s) {
    switch (s.toLowerCase()) {
      case 'delivered':
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.blue;
      case 'sourcing':
        return Colors.deepPurple;
      case 'ready_for_pickup':
        return Colors.indigo;
      case 'out_for_delivery':
      case 'delivering':
        return Colors.teal;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _labelOf(String s) =>
      s.replaceAll('_', ' ')[0].toUpperCase() +
      s.replaceAll('_', ' ').substring(1);

  Future<void> _saveStatus() async {
    final notifier = ref.read(orderDetailNotifierProvider.notifier);
    try {
      await notifier.updateStatus(widget.order.id, _currentStatus);
      if (mounted) {
        SayfoodsModal.show(
          context: context,
          type: SayfoodsModalType.success,
          title: 'Success',
          subtitle: 'Order status updated!',
        );
        Navigator.pop(context, true); // signal refresh
      }
    } catch (e) {
      if (mounted) {
        SayfoodsModal.show(
          context: context,
          type: SayfoodsModalType.error,
          title: 'Error',
          subtitle: e.toString(),
        );
      }
    }
  }

  Future<void> _saveRider() async {
    if (_selectedRiderId == null) return;
    final notifier = ref.read(orderDetailNotifierProvider.notifier);
    try {
      await notifier.assignRider(widget.order.id, _selectedRiderId!);
      if (mounted) {
        SayfoodsModal.show(
          context: context,
          type: SayfoodsModalType.success,
          title: 'Success',
          subtitle: '$_selectedRiderName assigned!',
        );
      }
    } catch (e) {
      if (mounted) {
        SayfoodsModal.show(
          context: context,
          type: SayfoodsModalType.error,
          title: 'Error',
          subtitle: e.toString(),
        );
      }
    }
  }

  bool _isRevoking = false;
  bool _isAdjusting = false;
  late TextEditingController _commissionController;

  Future<void> _revokeCommission() async {
    setState(() => _isRevoking = true);
    try {
      await Supabase.instance.client
          .from('orders')
          .update({'commission_earned': 0})
          .eq('id', widget.order.id);
      if (mounted) {
        SayfoodsModal.show(
          context: context,
          type: SayfoodsModalType.success,
          title: 'Commission Revoked',
          subtitle: 'The commission for this order has been set to ₦0.',
        );
        Navigator.pop(context, true); // signal refresh
      }
    } catch (e) {
      if (mounted) {
        SayfoodsModal.show(
          context: context,
          type: SayfoodsModalType.error,
          title: 'Error',
          subtitle: 'Failed to revoke: $e',
        );
      }
    } finally {
      if (mounted) setState(() => _isRevoking = false);
    }
  }

  Future<void> _adjustCommission() async {
    final raw = _commissionController.text.trim();
    final amount = double.tryParse(raw);
    if (amount == null || amount < 0) {
      SayfoodsModal.show(
        context: context,
        type: SayfoodsModalType.error,
        title: 'Invalid Amount',
        subtitle: 'Please enter a valid non-negative number.',
      );
      return;
    }
    setState(() => _isAdjusting = true);
    try {
      await ref
          .read(orderDetailNotifierProvider.notifier)
          .adjustCommission(widget.order.id, amount);
      if (mounted) {
        final fmt = NumberFormat.currency(symbol: '₦', decimalDigits: 2);
        SayfoodsModal.show(
          context: context,
          type: SayfoodsModalType.success,
          title: 'Commission Adjusted',
          subtitle: 'Commission updated to ${fmt.format(amount)}.',
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        SayfoodsModal.show(
          context: context,
          type: SayfoodsModalType.error,
          title: 'Error',
          subtitle: 'Failed to adjust: $e',
        );
      }
    } finally {
      if (mounted) setState(() => _isAdjusting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final fmt = NumberFormat.currency(symbol: '₦', decimalDigits: 2);
    final ridersAsync = ref.watch(ridersListProvider);
    final isSaving =
        ref.watch(orderDetailNotifierProvider).isLoading;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: Text(
          '#${order.id.substring(0, 8).toUpperCase()}',
          style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace'),
        ),
        backgroundColor: _bg,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          // Message (dummy) button
          Tooltip(
            message: 'Message Customer',
            child: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _orange.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.chat_bubble_outline_rounded,
                    color: _orange, size: 20),
              ),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatScreen(
                    params: ChatChannelParams(
                      channelType: 'admin_client',
                      orderId: order.id,
                    ),
                    title: order.clientName ?? 'Customer',
                    subtitle:
                        'Order #${order.id.substring(0, 8).toUpperCase()}',
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
        children: [
          // ── Status Badge Row ───────────────────────────────────────────
          Row(
            children: [
              _statusBadge(_currentStatus),
              const Spacer(),
              Text(
                DateFormat('d MMM yyyy • h:mm a').format(order.createdAt),
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Customer & Rider Row ───────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _infoCard(
                  icon: Icons.person_rounded,
                  label: 'Customer',
                  value: order.clientName ?? 'Unknown',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _infoCard(
                  icon: Icons.delivery_dining_rounded,
                  label: 'Rider',
                  value: _selectedRiderName ?? 'Unassigned',
                  valueColor:
                      _selectedRiderName != null ? _purple : Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Delivery address
          _infoCard(
            icon: Icons.location_on_rounded,
            label: 'Delivery Address',
            value: order.deliveryAddress.isNotEmpty
                ? order.deliveryAddress
                : 'Not specified',
          ),
          const SizedBox(height: 24),

          // ── Update Status ─────────────────────────────────────────────
          _sectionHeader('Update Order Status'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _statuses.map((s) {
              final isSelected = _currentStatus == s;
              final color = _statusColor(s);
              return ChoiceChip(
                label: Text(_labelOf(s)),
                selected: isSelected,
                onSelected: (_) => setState(() => _currentStatus = s),
                selectedColor: color.withValues(alpha: 0.15),
                labelStyle: TextStyle(
                  color: isSelected ? color : Colors.grey.shade700,
                  fontWeight:
                      isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                side: BorderSide(
                    color: isSelected ? color : Colors.grey.shade200),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isSaving ? null : _saveStatus,
              style: ElevatedButton.styleFrom(
                backgroundColor: _purple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Text('Save Status',
                      style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 28),

          // ── Assign Rider ─────────────────────────────────────────────
          _sectionHeader('Assign Delivery Rider'),
          const SizedBox(height: 12),
          ridersAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text('Could not load riders: $e',
                style: const TextStyle(color: Colors.red)),
            data: (riders) {
              if (riders.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Text(
                    'No riders found. Make sure rider profiles have role = "rider".',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                );
              }
              return Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        hint: const Text('Select a rider'),
                        value: _selectedRiderId,
                        items: riders.map((r) {
                          return DropdownMenuItem<String>(
                            value: r['id'].toString(),
                            child: Text(r['full_name'] ?? 'Unnamed Rider'),
                          );
                        }).toList(),
                        onChanged: (val) {
                          final match =
                              riders.firstWhere((r) => r['id'] == val);
                          setState(() {
                            _selectedRiderId = val;
                            _selectedRiderName =
                                match['full_name']?.toString();
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: isSaving ? null : _saveRider,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _purple,
                        side: const BorderSide(color: _purple),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Assign Rider',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 28),

          // ── Logistics & Commission ───────────────────────────────────
          if (order.status == 'completed' && order.riderId != null) ...[
            _sectionHeader('Logistics & Commission'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _finRow('Commission Earned', fmt.format(order.commissionEarned)),
                  if (order.completedAt != null) ...[
                    const SizedBox(height: 8),
                    _finRow('Completed At', DateFormat('MMM d, h:mm a').format(order.completedAt!)),
                  ],
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 16),
                  Text(
                    'Adjust Commission',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _commissionController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      prefixText: '₦ ',
                      hintText: '0.00',
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            BorderSide(color: Colors.grey.shade200),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: _purple),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isAdjusting ? null : _adjustCommission,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _purple,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                      child: _isAdjusting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : const Text('Save Adjustment',
                              style:
                                  TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  if (order.commissionEarned > 0) ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _isRevoking ? null : _revokeCommission,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isRevoking
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    color: Colors.red, strokeWidth: 2))
                            : const Text('Revoke Commission'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 28),
          ],

          // ── Items Ordered ─────────────────────────────────────────────
          _sectionHeader('Items Ordered (${order.items.length})'),
          const SizedBox(height: 12),
          ...order.items.map((item) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade100),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _purple.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.fastfood_rounded,
                          color: _purple, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.product?.name ?? 'Unknown item',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 14)),
                          if (item.product?.categoryName != null)
                            Text(item.product!.categoryName!,
                                style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 11)),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('x${item.quantity}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 13)),
                        Text(fmt.format(item.priceAtPurchase),
                            style: TextStyle(
                                color: Colors.grey.shade500, fontSize: 11)),
                      ],
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 24),

          // ── Payment Summary ───────────────────────────────────────────
          _sectionHeader('Payment Summary'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: Column(
              children: [
                _finRow('Subtotal', fmt.format(order.subtotal)),
                const SizedBox(height: 10),
                _finRow('Delivery Fee', fmt.format(order.deliveryFee)),
                const Divider(height: 20),
                _finRow('Total', fmt.format(order.totalAmount),
                    isTotal: true),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Payment Status',
                        style: TextStyle(
                            color: Colors.grey.shade600, fontSize: 14)),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: order.paymentStatus.toLowerCase() == 'paid'
                            ? Colors.green.shade50
                            : Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        order.paymentStatus.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color:
                              order.paymentStatus.toLowerCase() == 'paid'
                                  ? Colors.green
                                  : Colors.orange,
                        ),
                      ),
                    )
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String status) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              width: 7,
              height: 7,
              decoration:
                  BoxDecoration(shape: BoxShape.circle, color: color)),
          const SizedBox(width: 6),
          Text(_labelOf(status),
              style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 13)),
        ],
      ),
    );
  }

  Widget _infoCard(
      {required IconData icon,
      required String label,
      required String value,
      Color? valueColor}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade600),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 10, color: Colors.grey.shade500)),
                const SizedBox(height: 2),
                Text(value,
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: valueColor ?? Colors.black87),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) => Text(title,
      style: const TextStyle(
          fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87));

  Widget _finRow(String label, String value, {bool isTotal = false}) =>
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  color: isTotal ? Colors.black : Colors.grey.shade600,
                  fontSize: isTotal ? 16 : 14,
                  fontWeight:
                      isTotal ? FontWeight.bold : FontWeight.normal)),
          Text(value,
              style: TextStyle(
                  color: isTotal ? _purple : Colors.black87,
                  fontSize: isTotal ? 16 : 14,
                  fontWeight:
                      isTotal ? FontWeight.w900 : FontWeight.w600)),
        ],
      );
}

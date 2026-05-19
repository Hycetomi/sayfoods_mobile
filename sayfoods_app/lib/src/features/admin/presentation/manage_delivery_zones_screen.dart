import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sayfoods_app/src/shared/widgets/sayfoods_app_bar.dart';
import 'package:sayfoods_app/src/shared/widgets/sayfoods_modal.dart';
import 'package:sayfoods_app/src/shared/utils/error_handler.dart';

final _deliveryZonesProvider =
    StreamProvider<List<Map<String, dynamic>>>((ref) {
  return Supabase.instance.client
      .from('delivery_zones')
      .stream(primaryKey: ['id'])
      .order('name', ascending: true)
      .map((data) => List<Map<String, dynamic>>.from(data));
});

class ManageDeliveryZonesScreen extends ConsumerWidget {
  const ManageDeliveryZonesScreen({super.key});

  static const _purple = Color(0xFF5B1380);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final zonesAsync = ref.watch(_deliveryZonesProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: const SayfoodsAppBar(
        title: 'Delivery Zones',
        showBackButton: true,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: _purple,
        child: const Icon(Icons.add_rounded, color: Colors.white),
        onPressed: () => _showAddDialog(context),
      ),
      body: zonesAsync.when(
        data: (zones) {
          if (zones.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.delivery_dining_rounded,
                      size: 56, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    'No delivery zones yet.\nTap + to add one.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.grey.shade400, fontSize: 15),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: zones.length,
            itemBuilder: (context, index) {
              final zone = zones[index];
              final name = zone['name'] as String? ?? 'Unknown';
              final fee = (zone['price'] as num?)?.toDouble() ?? 0.0;
              final id = zone['id'] as String;

              return Dismissible(
                key: Key(id),
                direction: DismissDirection.endToStart,
                confirmDismiss: (_) =>
                    _confirmDelete(context, name),
                onDismissed: (_) => _delete(context, id),
                background: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade400,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  child: const Icon(Icons.delete_rounded,
                      color: Colors.white),
                ),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade100),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color: _purple.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                            Icons.location_on_rounded,
                            color: _purple,
                            size: 20),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(name,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15)),
                      ),
                      Text(
                        '₦${fee.toStringAsFixed(0)}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: _purple),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () => _showEditDialog(context, zone),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(Icons.edit_rounded,
                              size: 18, color: Colors.grey.shade400),
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
        error: (e, _) => Center(
            child: Text('Error: $e',
                style: const TextStyle(color: Colors.red))),
      ),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context, String name) async {
    bool? result;
    await SayfoodsModal.show(
      context: context,
      type: SayfoodsModalType.warning,
      title: 'Delete Zone',
      subtitle: 'Remove "$name"? Orders using this zone may be affected.',
      primaryButtonText: 'Delete',
      onPrimaryPressed: () {
        result = true;
        Navigator.pop(context);
      },
      secondaryButtonText: 'Cancel',
      onSecondaryPressed: () {
        result = false;
        Navigator.pop(context);
      },
    );
    return result;
  }

  Future<void> _delete(BuildContext context, String id) async {
    try {
      await Supabase.instance.client
          .from('delivery_zones')
          .delete()
          .eq('id', id);
    } catch (e) {
      if (context.mounted) {
        SayfoodsModal.show(
          context: context,
          type: SayfoodsModalType.error,
          title: 'Error',
          subtitle: ErrorHelper.getErrorMessage(e),
        );
      }
    }
  }

  Future<void> _showAddDialog(BuildContext context) async {
    final nameCtrl = TextEditingController();
    final feeCtrl = TextEditingController();

    await SayfoodsModal.show(
      context: context,
      type: SayfoodsModalType.custom,
      customIcon: Icons.add_location_alt_rounded,
      customIconColor: const Color(0xFF5B1380),
      title: 'Add Delivery Zone',
      customContent: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: nameCtrl,
            decoration: InputDecoration(
              labelText: 'Zone name',
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: feeCtrl,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Delivery fee (₦)',
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
      primaryButtonText: 'Add',
      onPrimaryPressed: () async {
        final name = nameCtrl.text.trim();
        final fee = double.tryParse(feeCtrl.text.trim());
        if (name.isEmpty || fee == null) return;
        try {
          await Supabase.instance.client
              .from('delivery_zones')
              .insert({'name': name, 'price': fee});
          if (context.mounted) Navigator.pop(context);
        } catch (e) {
          if (context.mounted) {
            SayfoodsModal.show(
              context: context,
              type: SayfoodsModalType.error,
              title: 'Error',
              subtitle: ErrorHelper.getErrorMessage(e),
            );
          }
        }
      },
      secondaryButtonText: 'Cancel',
      onSecondaryPressed: () => Navigator.pop(context),
    );

    nameCtrl.dispose();
    feeCtrl.dispose();
  }

  Future<void> _showEditDialog(
      BuildContext context, Map<String, dynamic> zone) async {
    final nameCtrl =
        TextEditingController(text: zone['name'] as String? ?? '');
    final feeCtrl = TextEditingController(
        text: ((zone['price'] as num?)?.toDouble() ?? 0.0)
            .toStringAsFixed(0));
    final id = zone['id'] as String;

    await SayfoodsModal.show(
      context: context,
      type: SayfoodsModalType.custom,
      customIcon: Icons.edit_location_alt_rounded,
      customIconColor: const Color(0xFF5B1380),
      title: 'Edit Delivery Zone',
      customContent: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: nameCtrl,
            decoration: InputDecoration(
              labelText: 'Zone name',
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: feeCtrl,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Delivery fee (₦)',
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
      primaryButtonText: 'Save',
      onPrimaryPressed: () async {
        final name = nameCtrl.text.trim();
        final fee = double.tryParse(feeCtrl.text.trim());
        if (name.isEmpty || fee == null) return;
        try {
          await Supabase.instance.client
              .from('delivery_zones')
              .update({'name': name, 'price': fee})
              .eq('id', id);
          if (context.mounted) Navigator.pop(context);
        } catch (e) {
          if (context.mounted) {
            SayfoodsModal.show(
              context: context,
              type: SayfoodsModalType.error,
              title: 'Error',
              subtitle: ErrorHelper.getErrorMessage(e),
            );
          }
        }
      },
      secondaryButtonText: 'Cancel',
      onSecondaryPressed: () => Navigator.pop(context),
    );
    nameCtrl.dispose();
    feeCtrl.dispose();
  }
}

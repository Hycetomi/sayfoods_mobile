import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Providers
import 'package:sayfoods_app/src/features/profile/application/address_provider.dart';
import 'package:sayfoods_app/src/features/profile/application/delivery_zone_provider.dart';

class AddAddressSheet extends ConsumerStatefulWidget {
  const AddAddressSheet({super.key});

  @override
  ConsumerState<AddAddressSheet> createState() => _AddAddressSheetState();
}

class _AddAddressSheetState extends ConsumerState<AddAddressSheet> {
  final _streetController = TextEditingController();
  String? _selectedZoneId;
  final Color _primaryPurple = const Color(0xFF5A189A);

  @override
  void dispose() {
    _streetController.dispose();
    super.dispose();
  }

  void _saveAddress() {
    if (_streetController.text.trim().isEmpty || _selectedZoneId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter an address and select a zone.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Push to Supabase via our Address Provider!
    ref
        .read(addressProvider.notifier)
        .addAddress(
          street: _streetController.text.trim(),
          zoneId: _selectedZoneId!,
        );

    Navigator.pop(context); // Close the sheet
  }

  @override
  Widget build(BuildContext context) {
    // Watch the dynamic zones from Supabase
    final zonesAsyncValue = ref.watch(deliveryZoneProvider);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Add New Address',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),

          // Street Address Input
          TextFormField(
            controller: _streetController,
            decoration: InputDecoration(
              labelText: 'Street Address',
              hintText: 'e.g. 9, Oladosu street...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Dynamic Delivery Zone Dropdown
          zonesAsyncValue.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Text(
              'Error loading zones: $error',
              style: const TextStyle(color: Colors.red),
            ),
            data: (zones) {
              return DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Delivery Zone',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                value: _selectedZoneId,
                // Maps our dynamic list to DropdownMenuItems!
                items: zones.map((zone) {
                  return DropdownMenuItem(
                    value: zone.id,
                    child: Text(
                      '${zone.name} (₦${zone.price.toStringAsFixed(0)})',
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedZoneId = value);
                },
              );
            },
          ),
          const SizedBox(height: 32),

          // Save Button
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryPurple,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              onPressed: _saveAddress,
              child: const Text(
                'Save Address',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

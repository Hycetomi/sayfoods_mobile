import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sayfoods_app/src/features/profile/application/address_provider.dart';
import 'package:sayfoods_app/src/features/profile/application/delivery_zone_provider.dart';
import 'package:sayfoods_app/src/features/profile/application/geocoding_service.dart';
import 'package:sayfoods_app/src/shared/widgets/sayfoods_modal.dart';
import 'package:sayfoods_app/src/shared/utils/error_handler.dart';

class AddAddressSheet extends ConsumerStatefulWidget {
  const AddAddressSheet({super.key});

  @override
  ConsumerState<AddAddressSheet> createState() => _AddAddressSheetState();
}

class _AddAddressSheetState extends ConsumerState<AddAddressSheet> {
  final _streetController = TextEditingController();
  final _geocodingService = GeocodingService();

  String? _selectedZoneId;
  List<GeocodingResult> _suggestions = [];
  double? _selectedLat;
  double? _selectedLng;
  bool _isSaving = false;

  static const _purple = Color(0xFF5B1380);

  @override
  void dispose() {
    _streetController.dispose();
    _geocodingService.dispose();
    super.dispose();
  }

  void _onStreetChanged(String value) {
    // Clear previously selected coordinates when user edits text
    setState(() {
      _selectedLat = null;
      _selectedLng = null;
    });
    _geocodingService.search(
      query: value,
      onResults: (results) {
        if (mounted) setState(() => _suggestions = results);
      },
    );
  }

  void _selectSuggestion(GeocodingResult result) {
    _streetController.text = result.placeName;
    setState(() {
      _selectedLat = result.latitude;
      _selectedLng = result.longitude;
      _suggestions = [];
    });
    FocusScope.of(context).unfocus();
  }

  Future<void> _saveAddress() async {
    if (_streetController.text.trim().isEmpty || _selectedZoneId == null) {
      SayfoodsModal.show(
        context: context,
        type: SayfoodsModalType.warning,
        title: 'Missing Info',
        subtitle: 'Please enter an address and select a zone.',
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await ref.read(addressProvider.notifier).addAddress(
            street: _streetController.text.trim(),
            zoneId: _selectedZoneId!,
            latitude: _selectedLat,
            longitude: _selectedLng,
          );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        SayfoodsModal.show(
          context: context,
          type: SayfoodsModalType.error,
          title: 'Error',
          subtitle: ErrorHelper.getErrorMessage(e),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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

          // Street Address with Mapbox autocomplete
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _streetController,
                onChanged: _onStreetChanged,
                decoration: InputDecoration(
                  labelText: 'Street Address',
                  hintText: 'Start typing your address…',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _selectedLat != null
                      ? const Icon(Icons.check_circle_rounded,
                          color: Colors.green)
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _purple),
                  ),
                ),
              ),
              // Suggestions dropdown
              if (_suggestions.isNotEmpty)
                Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(12),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    itemCount: _suggestions.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final s = _suggestions[index];
                      return ListTile(
                        leading: const Icon(Icons.location_on_rounded,
                            color: _purple, size: 20),
                        title: Text(
                          s.placeName,
                          style: const TextStyle(fontSize: 13),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () => _selectSuggestion(s),
                        dense: true,
                      );
                    },
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Delivery Zone Dropdown
          zonesAsyncValue.when(
            loading: () =>
                const Center(child: CircularProgressIndicator()),
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
                initialValue: _selectedZoneId,
                items: zones.map((zone) {
                  return DropdownMenuItem(
                    value: zone.id,
                    child: Text(
                        '${zone.name} (₦${zone.price.toStringAsFixed(0)})'),
                  );
                }).toList(),
                onChanged: (value) =>
                    setState(() => _selectedZoneId = value),
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
                backgroundColor: _purple,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              onPressed: _isSaving ? null : _saveAddress,
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : const Text(
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

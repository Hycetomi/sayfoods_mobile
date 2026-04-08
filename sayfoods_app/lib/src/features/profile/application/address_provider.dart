import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sayfoods_app/src/features/profile/domain/address_model.dart';

class AddressNotifier extends AsyncNotifier<List<AddressModel>> {
  final _supabase = Supabase.instance.client;

  @override
  Future<List<AddressModel>> build() async {
    return _fetchAddresses();
  }

  // --- FETCH ADDRESSES ---
  Future<List<AddressModel>> _fetchAddresses() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await _supabase
        .from('user_addresses') // Updated table name
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return response.map((json) => AddressModel.fromJson(json)).toList();
  }

  // --- ADD NEW ADDRESS ---
  Future<void> addAddress({
    required String street,
    required String zoneId,
    String label = 'Home', // Defaulting to 'Home'
    String city = 'Lagos', // Defaulting to 'Lagos' based on your UI
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not logged in');

    state = const AsyncValue.loading();

    try {
      await _supabase.from('user_addresses').insert({
        'user_id': userId,
        'street_address': street,
        'zone_id': zoneId, // Matches your schema
        'label': label,
        'city': city,
        'is_default': false, // Can be updated later if needed
      });

      state = await AsyncValue.guard(() => _fetchAddresses());
    } catch (e) {
      state = await AsyncValue.guard(() => _fetchAddresses());
      rethrow;
    }
  }

  // --- DELETE ADDRESS ---
  Future<void> deleteAddress(String addressId) async {
    try {
      await _supabase.from('user_addresses').delete().eq('id', addressId);
      state = await AsyncValue.guard(() => _fetchAddresses());
    } catch (e) {
      rethrow;
    }
  }
}

final addressProvider =
    AsyncNotifierProvider<AddressNotifier, List<AddressModel>>(() {
      return AddressNotifier();
    });

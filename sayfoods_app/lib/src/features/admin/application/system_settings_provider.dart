import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SystemSettingsNotifier extends StateNotifier<AsyncValue<Map<String, dynamic>>> {
  SystemSettingsNotifier() : super(const AsyncValue.loading()) {
    _loadSettings();
  }

  final _supabase = Supabase.instance.client;

  Future<void> _loadSettings() async {
    try {
      final data = await _supabase.from('system_settings').select().limit(1).maybeSingle();
      if (data == null) {
        state = const AsyncValue.data({'commission_percentage': 60.0});
      } else {
        final Map<String, dynamic> processed = Map<String, dynamic>.from(data);
        if (processed['commission_percentage'] is num) {
          processed['commission_percentage'] = (processed['commission_percentage'] as num).toDouble();
        }
        state = AsyncValue.data(processed);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateCommissionPercentage(double newPercentage) async {
    final currentState = state;
    if (currentState is! AsyncData) return;

    state = const AsyncValue.loading();
    try {
      final res = await _supabase.from('system_settings').upsert({
        'id': 1,
        'commission_percentage': newPercentage,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).select().single();
      
      final Map<String, dynamic> processed = Map<String, dynamic>.from(res);
      if (processed['commission_percentage'] is num) {
        processed['commission_percentage'] = (processed['commission_percentage'] as num).toDouble();
      }
      state = AsyncValue.data(processed);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      _loadSettings();
      rethrow;
    }
  }
}

final systemSettingsProvider = StateNotifierProvider<SystemSettingsNotifier, AsyncValue<Map<String, dynamic>>>((ref) {
  return SystemSettingsNotifier();
});

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RiderLocationService {
  Timer? _timer;
  bool _running = false;

  Future<void> requestPermission() async {
    final status = await Permission.locationWhenInUse.request();
    if (status.isPermanentlyDenied) {
      await openAppSettings();
    }
  }

  Future<void> start({required String userId}) async {
    if (_running) return;
    _running = true;

    // Immediate first broadcast
    await _broadcast(userId);

    _timer = Timer.periodic(const Duration(seconds: 10), (_) async {
      if (_running) await _broadcast(userId);
    });
  }

  void stop() {
    _running = false;
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _broadcast(String userId) async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      );
      await Supabase.instance.client.from('profiles').update({
        'latitude': position.latitude,
        'longitude': position.longitude,
        'last_location_update': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', userId);
    } catch (_) {
      // Silently ignore — poor GPS or network; next tick will retry
    }
  }
}

final riderLocationServiceProvider = Provider<RiderLocationService>((ref) {
  final service = RiderLocationService();
  ref.onDispose(service.stop);
  return service;
});

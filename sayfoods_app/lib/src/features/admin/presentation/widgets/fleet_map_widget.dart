import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:sayfoods_app/src/features/admin/application/fleet_map_provider.dart';

class FleetMapWidget extends ConsumerStatefulWidget {
  const FleetMapWidget({super.key});

  @override
  ConsumerState<FleetMapWidget> createState() => _FleetMapWidgetState();
}

class _FleetMapWidgetState extends ConsumerState<FleetMapWidget> {
  static const _purple = Color(0xFF5B1380);

  PointAnnotationManager? _annotationManager;

  // Lagos centre as default camera position
  static const _defaultLat = 6.5244;
  static const _defaultLng = 3.3792;

  @override
  Widget build(BuildContext context) {
    final ridersAsync = ref.watch(onlineRidersStreamProvider);

    ridersAsync.whenData((riders) => _refreshPins(riders));

    final riderCount = ridersAsync.maybeWhen(
      data: (r) => r.length,
      orElse: () => 0,
    );

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      height: 240,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            ridersAsync.maybeWhen(
              data: (riders) => riders.isEmpty
                  ? _emptyState()
                  : MapWidget(
                      styleUri: MapboxStyles.MAPBOX_STREETS,
                      onMapCreated: _onMapCreated,
                    ),
              orElse: () => MapWidget(
                styleUri: MapboxStyles.MAPBOX_STREETS,
                onMapCreated: _onMapCreated,
              ),
            ),
            // Online rider count badge
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _purple,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: Colors.greenAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '$riderCount online',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onMapCreated(MapboxMap mapboxMap) async {
    await mapboxMap.setCamera(
      CameraOptions(
        center: Point(
            coordinates: Position(_defaultLng, _defaultLat)),
        zoom: 11.0,
      ),
    );
    _annotationManager =
        await mapboxMap.annotations.createPointAnnotationManager();
  }

  Future<void> _refreshPins(List<Map<String, dynamic>> riders) async {
    if (_annotationManager == null) return;
    await _annotationManager!.deleteAll();

    for (final rider in riders) {
      final lat = (rider['latitude'] as num?)?.toDouble();
      final lng = (rider['longitude'] as num?)?.toDouble();
      if (lat == null || lng == null) continue;

      await _annotationManager!.create(
        PointAnnotationOptions(
          geometry: Point(coordinates: Position(lng, lat)),
          iconSize: 1.5,
          iconColor: _purple.toARGB32(),
          textField: rider['full_name'] as String? ?? 'Rider',
          textSize: 10.0,
          textOffset: [0.0, 2.0],
          textColor: Colors.black87.toARGB32(),
        ),
      );
    }
  }

  Widget _emptyState() {
    return Container(
      color: Colors.grey.shade50,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.delivery_dining_rounded,
                size: 40, color: Colors.grey.shade300),
            const SizedBox(height: 8),
            Text(
              'No riders currently online',
              style: TextStyle(
                  color: Colors.grey.shade400, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

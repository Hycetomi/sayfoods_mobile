import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:sayfoods_app/src/features/orders/application/rider_location_provider.dart';
import 'package:sayfoods_app/src/features/orders/domain/order_model.dart';

// ── Shared helpers ────────────────────────────────────────────────────────────

Future<void> _geocodeAddress(
    String rawAddress, void Function(double lat, double lng) onResult) async {
  if (rawAddress.trim().isEmpty) return;
  try {
    final token = dotenv.env['MAPBOX_ACCESS_TOKEN'] ?? '';
    // Strip any "Label: " prefix the checkout adds (e.g. "Home: 9 Main St")
    final address = rawAddress.contains(': ')
        ? rawAddress.substring(rawAddress.indexOf(': ') + 2)
        : rawAddress;
    final uri = Uri.parse(
      'https://api.mapbox.com/geocoding/v5/mapbox.places/'
      '${Uri.encodeComponent(address.trim())}.json'
      '?country=NG&types=address,place,locality,neighborhood'
      '&limit=1&access_token=$token',
    );
    final res = await http.get(uri);
    if (res.statusCode == 200) {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final features = body['features'] as List<dynamic>;
      if (features.isNotEmpty) {
        final c = features.first['geometry']['coordinates'] as List<dynamic>;
        onResult((c[1] as num).toDouble(), (c[0] as num).toDouble());
      }
    }
  } catch (_) {}
}

Future<PolylineAnnotation?> _fetchAndDrawRoute({
  required PolylineAnnotationManager manager,
  required PolylineAnnotation? existing,
  required double rLat,
  required double rLng,
  required double dLat,
  required double dLng,
  required int lineColor,
}) async {
  try {
    final token = dotenv.env['MAPBOX_ACCESS_TOKEN'] ?? '';
    final uri = Uri.parse(
      'https://api.mapbox.com/directions/v5/mapbox/driving'
      '/$rLng,$rLat;$dLng,$dLat'
      '?geometries=geojson&overview=full&access_token=$token',
    );
    final res = await http.get(uri);
    if (res.statusCode != 200) return existing;
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final routes = body['routes'] as List<dynamic>;
    if (routes.isEmpty) return existing;
    final coords =
        (routes.first['geometry']['coordinates'] as List<dynamic>)
            .map((c) => Position(
                  (c[0] as num).toDouble(),
                  (c[1] as num).toDouble(),
                ))
            .toList();
    if (existing != null) {
      await manager.delete(existing);
    }
    return await manager.create(
      PolylineAnnotationOptions(
        geometry: LineString(coordinates: coords),
        lineColor: lineColor,
        lineWidth: 4.5,
        lineOpacity: 0.9,
      ),
    );
  } catch (_) {
    return existing;
  }
}

// ── Compact card widget ───────────────────────────────────────────────────────

class LiveDeliveryMap extends ConsumerStatefulWidget {
  final OrderModel order;
  const LiveDeliveryMap({super.key, required this.order});

  @override
  ConsumerState<LiveDeliveryMap> createState() => _LiveDeliveryMapState();
}

class _LiveDeliveryMapState extends ConsumerState<LiveDeliveryMap> {
  static const _orange = Color(0xFFF28F2A);
  static const _purple = Color(0xFF5B1380);

  MapboxMap? _map;
  CircleAnnotationManager? _circleManager;
  PolylineAnnotationManager? _polylineManager;

  CircleAnnotation? _riderCircle;
  PolylineAnnotation? _routeLine;

  double? _destLat;
  double? _destLng;
  double? _lastRiderLat;
  double? _lastRiderLng;
  bool? _geocodeResult; // null=pending, true=ok, false=failed

  bool get _hasRider => widget.order.riderId != null;
  bool get _hasDestination => _destLat != null && _destLng != null;

  @override
  void initState() {
    super.initState();
    _destLat = widget.order.deliveryLatitude;
    _destLng = widget.order.deliveryLongitude;
    if (_hasDestination) _geocodeResult = true;
  }

  Future<void> _geocodeIfNeeded() async {
    if (_hasDestination) return;
    if (widget.order.deliveryAddress.trim().isEmpty) {
      if (mounted) setState(() => _geocodeResult = false);
      return;
    }
    await _geocodeAddress(widget.order.deliveryAddress, (lat, lng) {
      _destLat = lat;
      _destLng = lng;
    });
    if (mounted) setState(() => _geocodeResult = _hasDestination ? true : false);
  }

  Future<void> _onRiderUpdate(Map<String, dynamic> profile) async {
    final lat = (profile['latitude'] as num?)?.toDouble();
    final lng = (profile['longitude'] as num?)?.toDouble();
    if (lat == null || lng == null) return;

    _lastRiderLat = lat;
    _lastRiderLng = lng;

    if (_circleManager == null) return; // map not ready yet

    // Update rider circle (orange)
    if (_riderCircle != null) await _circleManager!.delete(_riderCircle!);
    _riderCircle = await _circleManager!.create(
      CircleAnnotationOptions(
        geometry: Point(coordinates: Position(lng, lat)),
        circleRadius: 10.0,
        circleColor: _orange.toARGB32(),
        circleStrokeWidth: 3.0,
        circleStrokeColor: Colors.white.toARGB32(),
      ),
    );

    // Smoothly follow rider
    await _map?.flyTo(
      CameraOptions(
          center: Point(coordinates: Position(lng, lat)), zoom: 14.0),
      MapAnimationOptions(duration: 800),
    );

    // Redraw road route
    if (_hasDestination && _polylineManager != null) {
      _routeLine = await _fetchAndDrawRoute(
        manager: _polylineManager!,
        existing: _routeLine,
        rLat: lat, rLng: lng,
        dLat: _destLat!, dLng: _destLng!,
        lineColor: _orange.toARGB32(),
      );
    }
  }

  Future<void> _onMapCreated(MapboxMap mapboxMap) async {
    _map = mapboxMap;

    await _geocodeIfNeeded();

    final camLat = _destLat ?? 6.5244;
    final camLng = _destLng ?? 3.3792;
    await mapboxMap.setCamera(
      CameraOptions(
          center: Point(coordinates: Position(camLng, camLat)), zoom: 13.0),
    );

    _circleManager =
        await mapboxMap.annotations.createCircleAnnotationManager();
    _polylineManager =
        await mapboxMap.annotations.createPolylineAnnotationManager();

    // Static destination circle (purple)
    if (_hasDestination) {
      await _circleManager!.create(
        CircleAnnotationOptions(
          geometry: Point(coordinates: Position(_destLng!, _destLat!)),
          circleRadius: 12.0,
          circleColor: _purple.toARGB32(),
          circleStrokeWidth: 3.0,
          circleStrokeColor: Colors.white.toARGB32(),
        ),
      );
    }

    // Sync with rider location that fired before map was ready
    if (_lastRiderLat != null && _lastRiderLng != null) {
      await _onRiderUpdate({
        'latitude': _lastRiderLat,
        'longitude': _lastRiderLng,
      });
    } else if (_hasRider) {
      final current = ref
          .read(riderLocationStreamProvider(widget.order.riderId!))
          .valueOrNull;
      if (current != null) await _onRiderUpdate(current);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasRider) return _placeholder('Live tracking unavailable');

    ref.listen(riderLocationStreamProvider(widget.order.riderId!), (_, next) {
      next.whenData((profile) {
        if (profile != null) _onRiderUpdate(profile);
      });
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                height: 250,
                child: MapWidget(
                  styleUri: MapboxStyles.MAPBOX_STREETS,
                  onMapCreated: _onMapCreated,
                  gestureRecognizers: {
                    Factory<EagerGestureRecognizer>(
                        EagerGestureRecognizer.new),
                  },
                ),
              ),
            ),
            // Fullscreen expand button
            Positioned(
              top: 10,
              right: 10,
              child: GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        _FullscreenMapScreen(order: widget.order),
                  ),
                ),
                child: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.fullscreen_rounded,
                      size: 20, color: Colors.black87),
                ),
              ),
            ),
          ],
        ),
        if (_geocodeResult == false)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded,
                    size: 13, color: Colors.grey.shade400),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    'Destination pin unavailable — address could not be geocoded',
                    style:
                        TextStyle(fontSize: 11, color: Colors.grey.shade400),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _placeholder(String message) {
    return Container(
      height: 250,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.location_off_rounded,
                size: 40, color: Colors.grey.shade400),
            const SizedBox(height: 8),
            Text(message,
                style:
                    TextStyle(color: Colors.grey.shade500, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

// ── Full-screen map ───────────────────────────────────────────────────────────

class _FullscreenMapScreen extends ConsumerStatefulWidget {
  final OrderModel order;
  const _FullscreenMapScreen({required this.order});

  @override
  ConsumerState<_FullscreenMapScreen> createState() =>
      _FullscreenMapScreenState();
}

class _FullscreenMapScreenState
    extends ConsumerState<_FullscreenMapScreen> {
  static const _orange = Color(0xFFF28F2A);
  static const _purple = Color(0xFF5B1380);

  CircleAnnotationManager? _circleManager;
  PolylineAnnotationManager? _polylineManager;
  CircleAnnotation? _riderCircle;
  PolylineAnnotation? _routeLine;

  double? _destLat;
  double? _destLng;

  bool get _hasRider => widget.order.riderId != null;
  bool get _hasDestination => _destLat != null && _destLng != null;

  @override
  void initState() {
    super.initState();
    _destLat = widget.order.deliveryLatitude;
    _destLng = widget.order.deliveryLongitude;
  }

  Future<void> _onRiderUpdate(Map<String, dynamic> profile) async {
    final lat = (profile['latitude'] as num?)?.toDouble();
    final lng = (profile['longitude'] as num?)?.toDouble();
    if (lat == null || lng == null || _circleManager == null) return;

    if (_riderCircle != null) await _circleManager!.delete(_riderCircle!);
    _riderCircle = await _circleManager!.create(
      CircleAnnotationOptions(
        geometry: Point(coordinates: Position(lng, lat)),
        circleRadius: 12.0,
        circleColor: _orange.toARGB32(),
        circleStrokeWidth: 3.0,
        circleStrokeColor: Colors.white.toARGB32(),
      ),
    );

    if (_hasDestination && _polylineManager != null) {
      _routeLine = await _fetchAndDrawRoute(
        manager: _polylineManager!,
        existing: _routeLine,
        rLat: lat, rLng: lng,
        dLat: _destLat!, dLng: _destLng!,
        lineColor: _orange.toARGB32(),
      );
    }
  }

  Future<void> _onMapCreated(MapboxMap mapboxMap) async {
    await _geocodeAddress(widget.order.deliveryAddress, (lat, lng) {
      _destLat = lat;
      _destLng = lng;
    });

    final camLat = _destLat ?? 6.5244;
    final camLng = _destLng ?? 3.3792;
    await mapboxMap.setCamera(
      CameraOptions(
          center: Point(coordinates: Position(camLng, camLat)), zoom: 14.0),
    );

    _circleManager =
        await mapboxMap.annotations.createCircleAnnotationManager();
    _polylineManager =
        await mapboxMap.annotations.createPolylineAnnotationManager();

    if (_hasDestination) {
      await _circleManager!.create(
        CircleAnnotationOptions(
          geometry: Point(coordinates: Position(_destLng!, _destLat!)),
          circleRadius: 14.0,
          circleColor: _purple.toARGB32(),
          circleStrokeWidth: 3.0,
          circleStrokeColor: Colors.white.toARGB32(),
        ),
      );
    }

    if (_hasRider) {
      final current = ref
          .read(riderLocationStreamProvider(widget.order.riderId!))
          .valueOrNull;
      if (current != null) await _onRiderUpdate(current);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hasRider) {
      ref.listen(riderLocationStreamProvider(widget.order.riderId!),
          (_, next) {
        next.whenData((p) {
          if (p != null) _onRiderUpdate(p);
        });
      });
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 6,
                ),
              ],
            ),
            child: const Icon(Icons.arrow_back_rounded,
                color: Colors.black87),
          ),
        ),
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 6,
              ),
            ],
          ),
          child: Text(
            widget.order.deliveryAddress.isNotEmpty
                ? widget.order.deliveryAddress
                : 'Live Tracking',
            style: const TextStyle(
                color: Colors.black87,
                fontSize: 13,
                fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
      body: MapWidget(
        styleUri: MapboxStyles.MAPBOX_STREETS,
        onMapCreated: _onMapCreated,
      ),
    );
  }
}

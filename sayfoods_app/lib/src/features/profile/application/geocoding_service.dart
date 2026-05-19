import 'dart:async';
import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class GeocodingResult {
  final String placeName;
  final double latitude;
  final double longitude;

  const GeocodingResult({
    required this.placeName,
    required this.latitude,
    required this.longitude,
  });
}

class GeocodingService {
  static const _baseUrl =
      'https://api.mapbox.com/geocoding/v5/mapbox.places';

  Timer? _debounce;

  // Debounced address search. Results are delivered via [onResults] callback.
  // Clears results when query is shorter than 3 characters.
  void search({
    required String query,
    required void Function(List<GeocodingResult>) onResults,
  }) {
    _debounce?.cancel();
    if (query.trim().length < 3) {
      onResults([]);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      final token = dotenv.env['MAPBOX_ACCESS_TOKEN'] ?? '';
      final encoded = Uri.encodeComponent(query.trim());
      final uri = Uri.parse(
        '$_baseUrl/$encoded.json'
        '?country=NG&types=address,place&access_token=$token',
      );
      try {
        final response = await http.get(uri);
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          final features = data['features'] as List<dynamic>;
          onResults(features.map((f) {
            final coords = f['geometry']['coordinates'] as List<dynamic>;
            return GeocodingResult(
              placeName: f['place_name'] as String,
              latitude: (coords[1] as num).toDouble(),
              longitude: (coords[0] as num).toDouble(),
            );
          }).toList());
        } else {
          onResults([]);
        }
      } catch (_) {
        onResults([]);
      }
    });
  }

  void dispose() => _debounce?.cancel();
}

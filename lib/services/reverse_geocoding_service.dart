// Turns map coordinates into a readable address.
import 'dart:convert';

import 'package:http/http.dart' as http;

// Requests place names for latitude and longitude values.
class ReverseGeocodingService {
  ReverseGeocodingService({http.Client? client})
      : _client = client ?? http.Client();

  final http.Client _client;

  // Looks up a place name and uses coordinates as a fallback.
  Future<String> addressFor({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final uri = Uri.https(
        'api.bigdatacloud.net',
        '/data/reverse-geocode-client',
        {
          'latitude': latitude.toString(),
          'longitude': longitude.toString(),
          'localityLanguage': 'en',
        },
      );

      final response = await _client.get(uri).timeout(
            const Duration(seconds: 8),
          );

      if (response.statusCode != 200) {
        return formatCoordinates(latitude, longitude);
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        return formatCoordinates(latitude, longitude);
      }

      return formatPlaceAddress(decoded) ??
          formatCoordinates(latitude, longitude);
    } catch (_) {
      return formatCoordinates(latitude, longitude);
    }
  }
}

// Displays coordinates with five decimal places.
String formatCoordinates(double latitude, double longitude) {
  return '${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)}';
}

// Combines available place names and skips duplicates.
String? formatPlaceAddress(Map<String, dynamic> data) {
  final parts = <String>[];

  for (final key in ['locality', 'city', 'principalSubdivision', 'countryName']) {
    final value = data[key];
    if (value is! String) continue;

    final trimmed = value.trim();
    if (trimmed.isEmpty || parts.contains(trimmed)) continue;
    parts.add(trimmed);
  }

  if (parts.isEmpty) return null;
  return parts.join(', ');
}

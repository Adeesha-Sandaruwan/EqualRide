import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'report_geo_resolver.dart';

/// Turns "6.93, 79.86" style labels into place names such as "Maradana,
/// Colombo". Uses the free BigDataCloud client endpoint (no key) and caches
/// answers on the device. Falls back to the original text when offline.
class PlaceNameResolver extends ChangeNotifier {
  PlaceNameResolver({http.Client? client}) : _client = client ?? http.Client();

  static const _cacheKey = 'insights_place_names_v1';

  final http.Client _client;
  final Map<String, String> _names = {};
  final Set<String> _pending = {};
  final Set<String> _failed = {};
  Future<void>? _loading;
  bool _disposed = false;

  /// Rounded to ~11 m so nearby reports share one lookup.
  static String? keyFor(String label) {
    final point = ReportGeoResolver.parseCoordinates(label);
    if (point == null) return null;
    return '${point.latitude.toStringAsFixed(4)},'
        '${point.longitude.toStringAsFixed(4)}';
  }

  /// The place name when known, otherwise the original label.
  String display(String label) {
    final key = keyFor(label);
    if (key == null) return label;
    return _names[key] ?? label;
  }

  /// True while [label] is coordinates that have no name yet.
  bool isUnnamed(String label) {
    final key = keyFor(label);
    return key != null && !_names.containsKey(key);
  }

  /// Looks up names for every coordinate label in [labels].
  Future<void> resolve(Iterable<String> labels) async {
    await (_loading ??= _loadCache());

    final todo = <String>[];
    for (final label in labels) {
      final key = keyFor(label);
      if (key == null ||
          _names.containsKey(key) ||
          _pending.contains(key) ||
          _failed.contains(key)) {
        continue;
      }
      _pending.add(key);
      todo.add(key);
    }

    var changed = false;
    for (final key in todo) {
      final name = await _lookup(key);
      _pending.remove(key);
      if (name == null) {
        _failed.add(key);
        continue;
      }
      _names[key] = name;
      changed = true;
    }

    if (changed) {
      await _saveCache();
      if (!_disposed) notifyListeners();
    }
  }

  Future<String?> _lookup(String key) async {
    final parts = key.split(',');
    try {
      final uri = Uri.https(
        'api.bigdatacloud.net',
        '/data/reverse-geocode-client',
        {
          'latitude': parts[0],
          'longitude': parts[1],
          'localityLanguage': 'en',
        },
      );
      final response = await _client.get(uri).timeout(
            const Duration(seconds: 8),
          );
      if (response.statusCode != 200) return null;

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) return null;
      return formatPlaceName(decoded);
    } catch (_) {
      return null;
    }
  }

  /// "Locality, City", dropping blanks and duplicates. Never includes the
  /// province or country so rows stay short.
  static String? formatPlaceName(Map<String, dynamic> data) {
    final parts = <String>[];
    for (final field in ['locality', 'city']) {
      final value = data[field];
      if (value is! String) continue;
      final trimmed = value.trim();
      if (trimmed.isEmpty || parts.contains(trimmed)) continue;
      parts.add(trimmed);
    }
    if (parts.isEmpty) {
      final fallback = data['principalSubdivision'];
      if (fallback is String && fallback.trim().isNotEmpty) {
        return fallback.trim();
      }
      return null;
    }
    return parts.join(', ');
  }

  Future<void> _loadCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cacheKey);
      if (raw == null) return;
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        decoded.forEach((key, value) {
          if (value is String) _names[key] = value;
        });
      }
    } catch (_) {
      // A corrupt cache is simply ignored.
    }
  }

  Future<void> _saveCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, jsonEncode(_names));
    } catch (_) {
      // Caching is best effort.
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

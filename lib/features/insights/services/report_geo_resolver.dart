// File: report_geo_resolver.dart
//
// Finds a map point for each report: parses coordinates in the text, then the
// landmark gazetteer, then free forward geocoding (cached). Reports that
// cannot be placed are counted as unmapped.

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../models/community_report.dart';
import '../models/geo_report.dart';
import 'landmark_gazetteer.dart';

/// Turns the free-text location of a report into map coordinates.
///
/// Reports only store a text location, so this tries, in order:
///   1. a "lat, lng" pair written by the map picker,
///   2. the bundled landmark list (instant, offline),
///   3. OpenStreetMap Nominatim, queued to one request per second and cached.
/// Reports that cannot be placed are kept and marked as unresolved.
class ReportGeoResolver {
  ReportGeoResolver({
    http.Client? client,
    this._requestGap = const Duration(milliseconds: 1100),
  }) : _client = client ?? http.Client();

  static const _cacheKey = 'insights_geo_cache_v1';
  static const _userAgent = 'EqualRide/1.0 (accessibility insights)';

  final http.Client _client;
  final Duration _requestGap;

  /// Location text -> [lat, lng], or null when Nominatim found nothing.
  Map<String, List<double>?>? _cache;
  DateTime? _lastRequestAt;

  static final _coordinatePattern = RegExp(
    r'(-?\d{1,2}\.\d+)\s*,\s*(-?\d{1,3}\.\d+)',
  );

  /// Parses a "6.93500, 79.85000" style location, or returns null.
  static GeoPoint? parseCoordinates(String location) {
    final match = _coordinatePattern.firstMatch(location);
    if (match == null) return null;

    final latitude = double.tryParse(match.group(1)!);
    final longitude = double.tryParse(match.group(2)!);
    if (latitude == null ||
        longitude == null ||
        latitude < -90 ||
        latitude > 90 ||
        longitude < -180 ||
        longitude > 180) {
      return null;
    }
    return GeoPoint(latitude, longitude);
  }

  /// Steps 1 and 2 only. Instant and never touches the network.
  GeoReport resolveLocal(CommunityReport report) {
    final coordinates = parseCoordinates(report.location);
    if (coordinates != null) {
      return GeoReport(
        report: report,
        point: coordinates,
        source: GeoSource.coordinates,
      );
    }

    final landmark = LandmarkGazetteer.lookup(report.location);
    if (landmark != null) {
      return GeoReport(
        report: report,
        point: landmark,
        source: GeoSource.gazetteer,
      );
    }

    return GeoReport(report: report, point: null, source: GeoSource.unresolved);
  }

  /// Resolves every report. Each distinct unresolved location is looked up
  /// at most once, and previous answers are reused from the cache.
  Future<List<GeoReport>> resolveAll(
    List<CommunityReport> reports, {
    bool useNetwork = true,
  }) async {
    final results = reports.map(resolveLocal).toList();
    if (!useNetwork) {
      return _applyCache(results, await _loadCache());
    }

    final cache = await _loadCache();
    final lookups = <String, GeoPoint?>{};

    for (final result in results) {
      if (result.isMapped) continue;

      final key = _normalise(result.report.location);
      if (key.isEmpty || lookups.containsKey(key)) continue;

      if (cache.containsKey(key)) {
        lookups[key] = _toPoint(cache[key]);
        continue;
      }

      final lookup = await _geocode(key);
      if (lookup.failed) continue;

      cache[key] = lookup.point == null
          ? null
          : [lookup.point!.latitude, lookup.point!.longitude];
      lookups[key] = lookup.point;
    }

    await _saveCache(cache);
    return _applyCache(results, cache);
  }

  List<GeoReport> _applyCache(
    List<GeoReport> results,
    Map<String, List<double>?> cache,
  ) {
    return results.map((result) {
      if (result.isMapped) return result;

      final point = _toPoint(cache[_normalise(result.report.location)]);
      if (point == null) return result;

      return GeoReport(
        report: result.report,
        point: point,
        source: GeoSource.geocoded,
      );
    }).toList();
  }

  static GeoPoint? _toPoint(List<double>? value) =>
      value == null ? null : GeoPoint(value[0], value[1]);

  /// Keeps only the place part of "Bus Stop - University of Moratuwa".
  static String _normalise(String location) {
    final text = location.trim();
    final dash = text.lastIndexOf(' - ');
    return (dash >= 0 ? text.substring(dash + 3) : text).trim();
  }

  Future<_GeocodeResult> _geocode(String query) async {
    final wait = _lastRequestAt == null
        ? Duration.zero
        : _requestGap - DateTime.now().difference(_lastRequestAt!);
    if (wait > Duration.zero) await Future<void>.delayed(wait);
    _lastRequestAt = DateTime.now();

    try {
      final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
        'q': query,
        'format': 'json',
        'limit': '1',
        'countrycodes': 'lk',
      });

      final response = await _client
          .get(
            uri,
            headers: {'User-Agent': _userAgent, 'Accept-Language': 'en'},
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) return const _GeocodeResult.failed();

      final decoded = jsonDecode(response.body);
      if (decoded is! List) return const _GeocodeResult.failed();
      if (decoded.isEmpty) return const _GeocodeResult.notFound();

      final first = decoded.first;
      if (first is! Map<String, dynamic>) return const _GeocodeResult.failed();

      final latitude = double.tryParse('${first['lat']}');
      final longitude = double.tryParse('${first['lon']}');
      if (latitude == null || longitude == null) {
        return const _GeocodeResult.failed();
      }
      return _GeocodeResult.found(GeoPoint(latitude, longitude));
    } catch (_) {
      return const _GeocodeResult.failed();
    }
  }

  Future<Map<String, List<double>?>> _loadCache() async {
    final existing = _cache;
    if (existing != null) return existing;

    final loaded = <String, List<double>?>{};
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cacheKey);
      if (raw != null) {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          decoded.forEach((key, value) {
            if (value == null) {
              loaded[key] = null;
            } else if (value is List && value.length == 2) {
              loaded[key] = [
                (value[0] as num).toDouble(),
                (value[1] as num).toDouble(),
              ];
            }
          });
        }
      }
    } catch (_) {
      // A corrupt or unavailable cache only means lookups are repeated.
    }

    return _cache = loaded;
  }

  Future<void> _saveCache(Map<String, List<double>?> cache) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, jsonEncode(cache));
    } catch (_) {
      // Cache is best effort.
    }
  }
}

/// Outcome of one Nominatim request. A failed request is not cached so it is
/// retried later; a confirmed "not found" is cached to avoid repeat calls.
class _GeocodeResult {
  const _GeocodeResult.found(GeoPoint this.point) : failed = false;
  const _GeocodeResult.notFound() : point = null, failed = false;
  const _GeocodeResult.failed() : point = null, failed = true;

  final GeoPoint? point;
  final bool failed;
}

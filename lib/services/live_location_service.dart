import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import 'reverse_geocoding_service.dart';

/// Data class representing commuter's live location with metadata
class CommuterLocation {
  const CommuterLocation({
    required this.coordinates,
    required this.address,
    this.accuracyMeters = 5.0,
    required this.timestamp,
    required this.isRealGps,
    this.statusMessage = 'Active',
  });

  final LatLng coordinates;
  final String address;
  final double accuracyMeters;
  final DateTime timestamp;
  final bool isRealGps;
  final String statusMessage;

  String get shortCoordinates =>
      '${coordinates.latitude.toStringAsFixed(4)}, ${coordinates.longitude.toStringAsFixed(4)}';
}

/// Service to handle real-time GPS location fetching and live transit tracking
class LiveLocationService {
  LiveLocationService({ReverseGeocodingService? geocodingService})
    : _geocoding = geocodingService ?? ReverseGeocodingService();

  final ReverseGeocodingService _geocoding;

  // Default fallback reference coordinates (Kolonnawa / Colombo transit corridor)
  static const LatLng defaultColomboLocation = LatLng(6.9271, 79.8821);

  /// Approximate geographic locations for common demo transit landmarks in Colombo
  static LatLng resolveLocationCoordinates(String locationName) {
    final lower = locationName.toLowerCase();
    if (lower.contains('kolonnawa')) {
      return const LatLng(6.9271, 79.8821);
    } else if (lower.contains('colombo fort') ||
        lower.contains('fort station')) {
      return const LatLng(6.9344, 79.8428);
    } else if (lower.contains('pettah')) {
      return const LatLng(6.9360, 79.8510);
    } else if (lower.contains('borella')) {
      return const LatLng(6.9147, 79.8778);
    } else if (lower.contains('maradana')) {
      return const LatLng(6.9303, 79.8655);
    } else if (lower.contains('hospital') ||
        lower.contains('general hospital')) {
      return const LatLng(6.9180, 79.8700);
    } else if (lower.contains('dematagoda')) {
      return const LatLng(6.9320, 79.8760);
    } else if (lower.contains('kollupitiya')) {
      return const LatLng(6.9080, 79.8510);
    } else if (lower.contains('bambalapitiya')) {
      return const LatLng(6.8920, 79.8550);
    } else if (lower.contains('colombo')) {
      return const LatLng(6.9271, 79.8612);
    }
    return defaultColomboLocation;
  }

  /// Fetches real device/browser GPS coordinates if permitted, with intelligent fallback.
  Future<CommuterLocation> fetchCurrentLocation({
    LatLng? fallbackCoordinates,
    String? hintLocationName,
  }) async {
    final fallback =
        fallbackCoordinates ??
        (hintLocationName != null
            ? resolveLocationCoordinates(hintLocationName)
            : defaultColomboLocation);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        final address = await _geocoding.addressFor(
          latitude: fallback.latitude,
          longitude: fallback.longitude,
        );
        return CommuterLocation(
          coordinates: fallback,
          address: address.isNotEmpty
              ? address
              : (hintLocationName ?? 'Kolonnawa, Colombo'),
          accuracyMeters: 10.0,
          timestamp: DateTime.now(),
          isRealGps: false,
          statusMessage: 'Location service off. Using starting transit hub.',
        );
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          final address = await _geocoding.addressFor(
            latitude: fallback.latitude,
            longitude: fallback.longitude,
          );
          return CommuterLocation(
            coordinates: fallback,
            address: address.isNotEmpty
                ? address
                : (hintLocationName ?? 'Kolonnawa, Colombo'),
            accuracyMeters: 10.0,
            timestamp: DateTime.now(),
            isRealGps: false,
            statusMessage: 'Permission denied. Using transit origin location.',
          );
        }
      }

      if (permission == LocationPermission.deniedForever) {
        final address = await _geocoding.addressFor(
          latitude: fallback.latitude,
          longitude: fallback.longitude,
        );
        return CommuterLocation(
          coordinates: fallback,
          address: address.isNotEmpty
              ? address
              : (hintLocationName ?? 'Kolonnawa, Colombo'),
          accuracyMeters: 10.0,
          timestamp: DateTime.now(),
          isRealGps: false,
          statusMessage: 'GPS permission denied. Using transit origin.',
        );
      }

      // Live Position fetched from device/browser GPS
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 7),
        ),
      );

      final realCoord = LatLng(position.latitude, position.longitude);
      final address = await _geocoding.addressFor(
        latitude: realCoord.latitude,
        longitude: realCoord.longitude,
      );

      return CommuterLocation(
        coordinates: realCoord,
        address: address.isNotEmpty
            ? address
            : '${realCoord.latitude}, ${realCoord.longitude}',
        accuracyMeters: position.accuracy,
        timestamp: position.timestamp,
        isRealGps: true,
        statusMessage:
            'Live GPS Acquired (±${position.accuracy.toStringAsFixed(0)}m)',
      );
    } catch (e) {
      debugPrint('LiveLocationService: GPS fetch fallback due to: $e');
      final address = await _geocoding.addressFor(
        latitude: fallback.latitude,
        longitude: fallback.longitude,
      );
      return CommuterLocation(
        coordinates: fallback,
        address: address.isNotEmpty
            ? address
            : (hintLocationName ?? 'Transit Departure Point'),
        accuracyMeters: 8.0,
        timestamp: DateTime.now(),
        isRealGps: false,
        statusMessage: 'Live simulated position connected.',
      );
    }
  }

  /// Calculates real distance in meters between two coordinates
  double distanceBetween(LatLng from, LatLng to) {
    const Distance distance = Distance();
    return distance.as(LengthUnit.Meter, from, to);
  }

  /// Formats meters into human readable distance string (e.g. "350 m" or "1.4 km")
  String formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.round()} m';
    }
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }
}

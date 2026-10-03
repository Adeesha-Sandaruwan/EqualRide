import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/app_theme.dart';
import '../widgets/glass_panel.dart';

String formatMapCoordinates(LatLng point) =>
    '${point.latitude.toStringAsFixed(6)}, ${point.longitude.toStringAsFixed(6)}';

class AccessibilityMapLocationPickerPage extends StatefulWidget {
  const AccessibilityMapLocationPickerPage({super.key, this.initialLocation});

  final String? initialLocation;

  @override
  State<AccessibilityMapLocationPickerPage> createState() =>
      _AccessibilityMapLocationPickerPageState();
}

class _AccessibilityMapLocationPickerPageState
    extends State<AccessibilityMapLocationPickerPage> {
  static const _defaultCenter = LatLng(6.9271, 79.8612);
  static final _coordinatePattern = RegExp(
    r'(-?\d+(?:\.\d+)?)\s*,\s*(-?\d+(?:\.\d+)?)',
  );

  final MapController _mapController = MapController();
  LatLng? selectedPoint;
  bool _mapReady = false;

  LatLng? get savedCoordinates {
    final match = _coordinatePattern.firstMatch(widget.initialLocation ?? '');
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
    return LatLng(latitude, longitude);
  }

  LatLng get initialCenter => savedCoordinates ?? _defaultCenter;

  @override
  void initState() {
    super.initState();
    selectedPoint = savedCoordinates;
  }

  Future<void> openOpenStreetMapAttribution() async {
    final uri = Uri.https('www.openstreetmap.org', '/copyright');
    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open OpenStreetMap credits.'),
          ),
        );
      }
    } catch (error, stackTrace) {
      debugPrint('Unable to open OpenStreetMap attribution: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open map credits.')),
        );
      }
    }
  }

  void centerMap() {
    if (!_mapReady) return;
    _mapController.move(selectedPoint ?? initialCenter, 14);
  }

  @override
  Widget build(BuildContext context) {
    final hasSelectedPoint = selectedPoint != null;

    return Scaffold(
      backgroundColor: AppTheme.navy,
      appBar: AppBar(
        backgroundColor: AppTheme.navy,
        foregroundColor: AppTheme.textPrimary,
        titleSpacing: 4,
        title: const Text(
          'Pin the issue location',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: 'Center map',
            onPressed: _mapReady ? centerMap : null,
            icon: const Icon(Icons.my_location_rounded),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: initialCenter,
              initialZoom: 14,
              minZoom: 3,
              maxZoom: 18,
              onMapReady: () => setState(() => _mapReady = true),
              onTap: (_, point) => setState(() => selectedPoint = point),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.equal_drive',
              ),
              if (selectedPoint != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: selectedPoint!,
                      width: 52,
                      height: 58,
                      alignment: Alignment.topCenter,
                      child: const Icon(
                        Icons.location_on_rounded,
                        color: AppTheme.teal,
                        size: 52,
                        shadows: [
                          Shadow(
                            color: AppTheme.navy,
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
          Positioned(
            top: 12,
            left: 16,
            right: 16,
            child: IgnorePointer(
              child: GlassPanel(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 13,
                ),
                borderRadius: 18,
                child: Row(
                  children: [
                    Container(
                      height: 38,
                      width: 38,
                      decoration: BoxDecoration(
                        color: AppTheme.teal.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.touch_app_rounded,
                        color: AppTheme.teal,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            hasSelectedPoint
                                ? 'Pin placed'
                                : 'Tap to place your pin',
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            hasSelectedPoint
                                ? 'Tap another spot to adjust it.'
                                : 'Zoom and move the map, then tap the exact spot.',
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 8,
            child: SafeArea(
              top: false,
              child: GlassPanel(
                padding: const EdgeInsets.all(18),
                borderRadius: 24,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          height: 40,
                          width: 40,
                          decoration: BoxDecoration(
                            color: AppTheme.teal.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: const Icon(
                            Icons.location_on_rounded,
                            color: AppTheme.teal,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                hasSelectedPoint
                                    ? 'Selected location'
                                    : 'No location selected yet',
                                style: const TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                hasSelectedPoint
                                    ? formatMapCoordinates(selectedPoint!)
                                    : 'Tap anywhere on the map to drop a pin.',
                                style: const TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (hasSelectedPoint)
                          IconButton(
                            tooltip: 'Remove pin',
                            onPressed: () =>
                                setState(() => selectedPoint = null),
                            icon: const Icon(Icons.close_rounded),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'You can edit the location description after returning to your report.',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: openOpenStreetMapAttribution,
                        child: const Text('© OpenStreetMap contributors'),
                      ),
                    ),
                    const SizedBox(height: 4),
                    FilledButton.icon(
                      onPressed: hasSelectedPoint
                          ? () => Navigator.of(context).pop(selectedPoint)
                          : null,
                      icon: const Icon(Icons.check_rounded),
                      label: const Text('Use this location'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

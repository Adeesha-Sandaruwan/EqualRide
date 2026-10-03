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

  LatLng? selectedPoint;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.navy,
      appBar: AppBar(
        backgroundColor: AppTheme.navy,
        foregroundColor: AppTheme.textPrimary,
        title: const Text('Choose report location'),
      ),
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: initialCenter,
              initialZoom: 14,
              minZoom: 3,
              maxZoom: 18,
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
            top: 16,
            left: 16,
            right: 16,
            child: IgnorePointer(
              child: GlassPanel(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                borderRadius: 18,
                child: Row(
                  children: [
                    const Icon(Icons.touch_app_rounded, color: AppTheme.teal),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        selectedPoint == null
                            ? 'Tap the map to drop a pin at the issue location.'
                            : 'Drag the map or tap again to fine-tune the pin.',
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
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
            bottom: 20,
            child: GlassPanel(
              borderRadius: 24,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.location_searching_rounded,
                        color: AppTheme.teal,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Selected coordinates',
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              selectedPoint == null
                                  ? 'Tap the map to choose a point'
                                  : formatMapCoordinates(selectedPoint!),
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'The coordinates will be inserted into the report location field. You can edit them there.',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: openOpenStreetMapAttribution,
                      child: const Text('© OpenStreetMap contributors'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: selectedPoint == null
                        ? null
                        : () => Navigator.of(context).pop(selectedPoint),
                    icon: const Icon(Icons.check_circle_outline_rounded),
                    label: const Text('Use this location'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

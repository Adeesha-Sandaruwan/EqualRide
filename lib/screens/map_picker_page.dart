import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/picked_map_location.dart';
import '../services/reverse_geocoding_service.dart';
import '../theme/app_theme.dart';

const _colomboCenter = LatLng(6.9271, 79.8612);

Future<PickedMapLocation?> pickLocationOnMap(
  BuildContext context, {
  String title = 'Choose on map',
}) {
  return Navigator.of(context, rootNavigator: true).push<PickedMapLocation>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => MapPickerPage(title: title),
    ),
  );
}

class MapPickerPage extends StatefulWidget {
  const MapPickerPage({
    super.key,
    this.title = 'Choose on map',
  });

  final String title;

  @override
  State<MapPickerPage> createState() => _MapPickerPageState();
}

class _MapPickerPageState extends State<MapPickerPage> {
  final ReverseGeocodingService _geocoding = ReverseGeocodingService();

  LatLng? _selected;
  var _address = '';
  var _isLookingUp = false;
  var _lookupId = 0;

  Future<void> _selectPoint(LatLng point) async {
    final lookupId = ++_lookupId;

    setState(() {
      _selected = point;
      _isLookingUp = true;
      _address = 'Finding address...';
    });

    final address = await _geocoding.addressFor(
      latitude: point.latitude,
      longitude: point.longitude,
    );

    if (!mounted || lookupId != _lookupId) return;

    setState(() {
      _address = address;
      _isLookingUp = false;
    });
  }

  void _confirm() {
    final selected = _selected;
    if (selected == null || _isLookingUp || _address.isEmpty) return;

    Navigator.of(context).pop(
      PickedMapLocation(
        latitude: selected.latitude,
        longitude: selected.longitude,
        address: _address,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selected;
    final canConfirm = selected != null && !_isLookingUp && _address.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.navy,
        title: Text(widget.title),
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  options: MapOptions(
                    initialCenter: _colomboCenter,
                    initialZoom: 13,
                    onTap: (_, point) => _selectPoint(point),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://server.arcgisonline.com/ArcGIS/rest/services/World_Street_Map/MapServer/tile/{z}/{y}/{x}',
                      userAgentPackageName: 'com.example.equal_drive',
                    ),
                    SimpleAttributionWidget(
                      source: const Text('Esri, OpenStreetMap'),
                    ),
                    if (selected != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: selected,
                            width: 44,
                            height: 44,
                            alignment: Alignment.bottomCenter,
                            child: const Icon(
                              Icons.location_pin,
                              color: Color(0xFFE53935),
                              size: 44,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  right: 12,
                  child: Material(
                    color: AppTheme.navy.withValues(alpha: 0.88),
                    borderRadius: BorderRadius.circular(14),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      child: Text(
                        'Tap the map to drop a pin, then use that place.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppTheme.textPrimary),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    selected == null
                        ? 'No place selected yet'
                        : _address,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: canConfirm ? _confirm : null,
                    icon: _isLookingUp
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppTheme.navy,
                            ),
                          )
                        : const Icon(Icons.check_rounded),
                    label: Text(
                      _isLookingUp ? 'Finding address...' : 'Use this place',
                    ),
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

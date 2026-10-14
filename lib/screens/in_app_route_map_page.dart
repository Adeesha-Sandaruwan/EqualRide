import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/route_details.dart';
import '../services/live_location_service.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_panel.dart';
import 'live_journey_companion_page.dart';

class InAppRouteMapPage extends StatefulWidget {
  const InAppRouteMapPage({super.key, required this.routeDetails});

  final RouteDetails routeDetails;

  @override
  State<InAppRouteMapPage> createState() => _InAppRouteMapPageState();
}

class _InAppRouteMapPageState extends State<InAppRouteMapPage>
    with SingleTickerProviderStateMixin {
  final MapController _mapController = MapController();
  final LiveLocationService _locationService = LiveLocationService();

  late final LatLng _startCoords;
  late final LatLng _destCoords;
  late final List<LatLng> _routePoints;
  late final List<LatLng> _stopPoints;

  CommuterLocation? _userLocation;
  bool _isFetchingLocation = false;
  String _locationStatus = 'Tap to fetch live location';
  double? _distanceToStartMeters;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initRouteCoordinates();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.25).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Auto-fetch commuter live location on screen load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchLiveLocation(showFeedback: false);
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _initRouteCoordinates() {
    _startCoords = LiveLocationService.resolveLocationCoordinates(
      widget.routeDetails.startLocation,
    );
    _destCoords = LiveLocationService.resolveLocationCoordinates(
      widget.routeDetails.destination,
    );

    // Generate realistic intermediate corridor waypoints
    final midLat = (_startCoords.latitude + _destCoords.latitude) / 2;
    final midLng = (_startCoords.longitude + _destCoords.longitude) / 2;

    // Intermediate stops along Colombo transit corridor
    final waypoint1 = LatLng(
      _startCoords.latitude + (midLat - _startCoords.latitude) * 0.6 + 0.002,
      _startCoords.longitude + (midLng - _startCoords.longitude) * 0.5 - 0.003,
    );
    final waypoint2 = LatLng(
      midLat + (_destCoords.latitude - midLat) * 0.5 - 0.002,
      midLng + (_destCoords.longitude - midLng) * 0.6 + 0.002,
    );

    _stopPoints = [_startCoords, waypoint1, waypoint2, _destCoords];

    // Smooth route line connecting points
    _routePoints = [
      _startCoords,
      LatLng(_startCoords.latitude + 0.001, _startCoords.longitude - 0.001),
      waypoint1,
      LatLng(midLat, midLng),
      waypoint2,
      LatLng(_destCoords.latitude - 0.001, _destCoords.longitude + 0.001),
      _destCoords,
    ];
  }

  Future<void> _fetchLiveLocation({bool showFeedback = true}) async {
    setState(() {
      _isFetchingLocation = true;
      _locationStatus = 'Fetching GPS coordinates...';
    });

    try {
      final loc = await _locationService.fetchCurrentLocation(
        fallbackCoordinates: _startCoords,
        hintLocationName: widget.routeDetails.startLocation,
      );

      final distance = _locationService.distanceBetween(
        loc.coordinates,
        _startCoords,
      );

      if (!mounted) return;

      setState(() {
        _userLocation = loc;
        _isFetchingLocation = false;
        _distanceToStartMeters = distance;
        _locationStatus = loc.statusMessage;
      });

      // Smoothly animate map camera to user location
      _mapController.move(loc.coordinates, 14.5);

      if (showFeedback && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.navy,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: AppTheme.teal),
            ),
            content: Row(
              children: [
                const Icon(
                  Icons.my_location_rounded,
                  color: AppTheme.teal,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Live location fetched: ${loc.address}',
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isFetchingLocation = false;
        _locationStatus = 'Using origin transit hub';
      });
    }
  }

  void _recenterFullRoute() {
    final bounds = LatLngBounds.fromPoints(_routePoints);
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 80),
      ),
    );
  }

  Future<void> _openExternalGoogleMaps() async {
    final start = widget.routeDetails.startLocation.trim();
    final dest = widget.routeDetails.destination.trim();
    final Uri googleMapsUrl = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&origin=${Uri.encodeComponent(start)}&destination=${Uri.encodeComponent(dest)}&travelmode=transit',
    );

    try {
      await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open external Google Maps.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _userLocation;

    return Scaffold(
      backgroundColor: AppTheme.navy,
      body: Stack(
        children: [
          // 1. In-App Interactive Map powered by flutter_map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _startCoords,
              initialZoom: 13.5,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://server.arcgisonline.com/ArcGIS/rest/services/World_Street_Map/MapServer/tile/{z}/{y}/{x}',
                userAgentPackageName: 'com.example.equal_drive',
              ),
              // Route Polyline Glow Layer
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: _routePoints,
                    strokeWidth: 9.0,
                    color: AppTheme.teal.withValues(alpha: 0.35),
                  ),
                  Polyline(
                    points: _routePoints,
                    strokeWidth: 5.0,
                    color: AppTheme.aqua,
                  ),
                ],
              ),
              // Marker Layer (Origin, Intermediate Stops, Destination, and Live Commuter)
              MarkerLayer(
                markers: [
                  // Origin Marker
                  Marker(
                    point: _startCoords,
                    width: 50,
                    height: 50,
                    alignment: Alignment.center,
                    child: _buildStationMarker(
                      icon: Icons.trip_origin_rounded,
                      color: const Color(0xFF00E676),
                      label: 'Start',
                    ),
                  ),
                  // Intermediate Stop 1
                  Marker(
                    point: _stopPoints[1],
                    width: 38,
                    height: 38,
                    alignment: Alignment.center,
                    child: _buildWaypointMarker(number: '1'),
                  ),
                  // Intermediate Stop 2
                  Marker(
                    point: _stopPoints[2],
                    width: 38,
                    height: 38,
                    alignment: Alignment.center,
                    child: _buildWaypointMarker(number: '2'),
                  ),
                  // Destination Marker
                  Marker(
                    point: _destCoords,
                    width: 50,
                    height: 50,
                    alignment: Alignment.center,
                    child: _buildStationMarker(
                      icon: Icons.location_on_rounded,
                      color: const Color(0xFFFF5252),
                      label: 'End',
                    ),
                  ),
                  // Live Commuter GPS Marker
                  if (user != null)
                    Marker(
                      point: user.coordinates,
                      width: 64,
                      height: 64,
                      alignment: Alignment.center,
                      child: AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Stack(
                            alignment: Alignment.center,
                            children: [
                              // Pulsing outer radar circle
                              Container(
                                width: 50 * _pulseAnimation.value,
                                height: 50 * _pulseAnimation.value,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppTheme.aqua.withValues(
                                    alpha: 0.35 / _pulseAnimation.value,
                                  ),
                                ),
                              ),
                              // Core commuter badge
                              Container(
                                width: 26,
                                height: 26,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0xFF00E5FF),
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2.8,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.5,
                                      ),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.person_pin_circle_rounded,
                                  color: AppTheme.navy,
                                  size: 14,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                ],
              ),
            ],
          ),

          // 2. Top Navigation Bar & Live GPS Status Header
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppTheme.navy.withValues(alpha: 0.88),
                    radius: 22,
                    child: IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: AppTheme.textPrimary,
                        size: 18,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.navy.withValues(alpha: 0.88),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppTheme.teal.withValues(alpha: 0.4),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          _isFetchingLocation
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppTheme.teal,
                                  ),
                                )
                              : Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: user?.isRealGps == true
                                        ? const Color(0xFF00E676)
                                        : AppTheme.aqua,
                                    boxShadow: [
                                      BoxShadow(
                                        color:
                                            (user?.isRealGps == true
                                                    ? const Color(0xFF00E676)
                                                    : AppTheme.aqua)
                                                .withValues(alpha: 0.6),
                                        blurRadius: 6,
                                      ),
                                    ],
                                  ),
                                ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  widget.routeDetails.routeTitle,
                                  style: const TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  _locationStatus,
                                  style: TextStyle(
                                    color: AppTheme.textSecondary.withValues(
                                      alpha: 0.9,
                                    ),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. Floating Control Actions (Fetch Location, Center Route, Google Maps)
          Positioned(
            right: 16,
            top: 90,
            child: Column(
              children: [
                // Fetch Live Location Button
                _buildMapFloatingBtn(
                  icon: Icons.my_location_rounded,
                  tooltip: 'Fetch Live GPS Location',
                  color: AppTheme.teal,
                  iconColor: AppTheme.navy,
                  isLoading: _isFetchingLocation,
                  onTap: () => _fetchLiveLocation(showFeedback: true),
                ),
                const SizedBox(height: 10),
                // Recenter Full Route
                _buildMapFloatingBtn(
                  icon: Icons.crop_free_rounded,
                  tooltip: 'View Full Route Bounds',
                  color: AppTheme.navy.withValues(alpha: 0.9),
                  iconColor: AppTheme.aqua,
                  onTap: _recenterFullRoute,
                ),
                const SizedBox(height: 10),
                // External Google Maps
                _buildMapFloatingBtn(
                  icon: Icons.open_in_new_rounded,
                  tooltip: 'Open in Google Maps',
                  color: AppTheme.navy.withValues(alpha: 0.9),
                  iconColor: AppTheme.textSecondary,
                  onTap: _openExternalGoogleMaps,
                ),
              ],
            ),
          ),

          // 4. Bottom Interactive Route & Live Companion Card
          Positioned(
            left: 16,
            right: 16,
            bottom: 20,
            child: GlassPanel(
              padding: const EdgeInsets.all(18),
              borderRadius: 24,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.teal.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppTheme.teal.withValues(alpha: 0.45),
                          ),
                        ),
                        child: const Icon(
                          Icons.directions_bus_rounded,
                          color: AppTheme.teal,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.routeDetails.routeTitle,
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                Text(
                                  '${widget.routeDetails.durationMinutes} mins',
                                  style: const TextStyle(
                                    color: AppTheme.aqua,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const Text(
                                  ' • ',
                                  style: TextStyle(
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                                Text(
                                  'Score: ${widget.routeDetails.accessibilityScore}%',
                                  style: const TextStyle(
                                    color: Color(0xFF00E676),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Live Distance to Boarding Stop
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.navy.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.teal.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.accessibility_new_rounded,
                          color: AppTheme.teal,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _distanceToStartMeters != null
                                ? 'Distance to boarding stop: ${_locationService.formatDistance(_distanceToStartMeters!)}'
                                : 'Fetching distance to boarding stop...',
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (widget.routeDetails.isStepFree)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.teal.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              '♿ Step-Free',
                              style: TextStyle(
                                color: AppTheme.teal,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Start Live Journey Companion Button
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => LiveJourneyCompanionPage(
                              routeDetails: widget.routeDetails,
                              initialLocation: _userLocation,
                            ),
                          ),
                        );
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.teal,
                        foregroundColor: AppTheme.navy,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                      ),
                      icon: const Icon(
                        Icons.navigation_rounded,
                        size: 20,
                        color: AppTheme.navy,
                      ),
                      label: const Text(
                        'Start Live Journey Companion',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                        ),
                      ),
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

  Widget _buildStationMarker({
    required IconData icon,
    required Color color,
    required String label,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 16),
        ),
      ],
    );
  }

  Widget _buildWaypointMarker({required String number}) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.navy,
        shape: BoxShape.circle,
        border: Border.all(color: AppTheme.aqua, width: 2),
        boxShadow: [
          BoxShadow(color: AppTheme.aqua.withValues(alpha: 0.3), blurRadius: 4),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        number,
        style: const TextStyle(
          color: AppTheme.aqua,
          fontWeight: FontWeight.w800,
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _buildMapFloatingBtn({
    required IconData icon,
    required String tooltip,
    required Color color,
    required Color iconColor,
    required VoidCallback onTap,
    bool isLoading = false,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: AppTheme.teal.withValues(alpha: 0.4),
            width: 1.2,
          ),
        ),
        elevation: 4,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: isLoading ? null : onTap,
          child: Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            child: isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: AppTheme.navy,
                    ),
                  )
                : Icon(icon, color: iconColor, size: 20),
          ),
        ),
      ),
    );
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/route_details.dart';
import '../services/live_location_service.dart';
import '../services/voice_assistant_service.dart';
import '../theme/app_theme.dart';
import '../widgets/equal_ride_background.dart';
import '../widgets/glass_panel.dart';

class LiveJourneyCompanionPage extends StatefulWidget {
  const LiveJourneyCompanionPage({
    super.key,
    required this.routeDetails,
    this.initialLocation,
  });

  final RouteDetails routeDetails;
  final CommuterLocation? initialLocation;

  @override
  State<LiveJourneyCompanionPage> createState() =>
      _LiveJourneyCompanionPageState();
}

class _LiveJourneyCompanionPageState extends State<LiveJourneyCompanionPage>
    with SingleTickerProviderStateMixin {
  final LiveLocationService _locationService = LiveLocationService();

  int currentStepIndex = 0;
  bool isHighContrast = false;
  bool isAudioGuidanceEnabled = true;

  // Live Location & Real-Time Tracking State
  CommuterLocation? _currentLocation;
  bool _isLiveTrackingActive = true;
  bool _isFetchingLocation = false;
  double _distanceToCurrentStepMeters = 420.0;
  double _transitSpeedKmh = 26.0;
  Timer? _liveTransitTimer;
  bool _showMiniMap = false;

  late final LatLng _startCoords;
  late final LatLng _destCoords;
  late final List<LatLng> _routePoints;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initCoordinates();

    _currentLocation = widget.initialLocation;
    if (_currentLocation == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _fetchLiveLocation(showNotice: false);
      });
    }

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.25).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _startLiveTransitTimer();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _registerVoiceContext();
    });
  }

  void _registerVoiceContext() {
    VoiceAssistantService.instance.registerScreen(
      VoiceScreenContext(
        name: 'Live Journey Companion',
        summary:
            'In-transit navigation on ${widget.routeDetails.routeTitle} towards ${widget.routeDetails.destination}.',
        readContent: _buildCompanionVoiceSummary,
        onVoiceCommand: (cmd) async {
          if (cmd.contains('next stop') ||
              cmd.contains('how far') ||
              cmd.contains('current step') ||
              cmd.contains('where am i')) {
            await VoiceAssistantService.instance
                .speak(_buildCompanionVoiceSummary());
            return true;
          }
          if (cmd.contains('next step') || cmd.contains('step forward')) {
            if (currentStepIndex < widget.routeDetails.journeySteps.length - 1) {
              setState(() => currentStepIndex++);
              await VoiceAssistantService.instance.speak(
                'Advanced to step ${currentStepIndex + 1}: ${widget.routeDetails.journeySteps[currentStepIndex].title}',
              );
              return true;
            }
          }
          if (cmd.contains('previous step') || cmd.contains('step back')) {
            if (currentStepIndex > 0) {
              setState(() => currentStepIndex--);
              await VoiceAssistantService.instance.speak(
                'Moved back to step ${currentStepIndex + 1}: ${widget.routeDetails.journeySteps[currentStepIndex].title}',
              );
              return true;
            }
          }
          return false;
        },
      ),
      announceNow: true,
    );
  }

  String _buildCompanionVoiceSummary() {
    if (widget.routeDetails.journeySteps.isEmpty) {
      return 'Live journey companion for ${widget.routeDetails.routeTitle}. In transit to ${widget.routeDetails.destination}.';
    }
    final step = widget.routeDetails.journeySteps[currentStepIndex.clamp(0, widget.routeDetails.journeySteps.length - 1)];
    final distance = _distanceToCurrentStepMeters.round();
    final totalSteps = widget.routeDetails.journeySteps.length;
    return 'Live journey companion. You are at step ${currentStepIndex + 1} of $totalSteps: ${step.title}, ${step.subtitle}. Distance to next checkpoint is approximately $distance meters. Current speed is ${_transitSpeedKmh.round()} kilometers per hour.';
  }

  @override
  void dispose() {
    _liveTransitTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _initCoordinates() {
    _startCoords = LiveLocationService.resolveLocationCoordinates(
      widget.routeDetails.startLocation,
    );
    _destCoords = LiveLocationService.resolveLocationCoordinates(
      widget.routeDetails.destination,
    );

    final midLat = (_startCoords.latitude + _destCoords.latitude) / 2;
    final midLng = (_startCoords.longitude + _destCoords.longitude) / 2;

    _routePoints = [
      _startCoords,
      LatLng(
        _startCoords.latitude + (midLat - _startCoords.latitude) * 0.6 + 0.002,
        _startCoords.longitude +
            (midLng - _startCoords.longitude) * 0.5 -
            0.003,
      ),
      LatLng(midLat, midLng),
      LatLng(
        midLat + (_destCoords.latitude - midLat) * 0.5 - 0.002,
        midLng + (_destCoords.longitude - midLng) * 0.6 + 0.002,
      ),
      _destCoords,
    ];
  }

  void _startLiveTransitTimer() {
    _liveTransitTimer?.cancel();
    _liveTransitTimer = Timer.periodic(const Duration(milliseconds: 2400), (
      timer,
    ) {
      if (!_isLiveTrackingActive || !mounted) return;

      setState(() {
        _transitSpeedKmh =
            22.0 + ((_distanceToCurrentStepMeters.toInt() % 12).toDouble());
        if (_distanceToCurrentStepMeters > 40) {
          _distanceToCurrentStepMeters -= 38.0;
          if (_distanceToCurrentStepMeters < 40) {
            _distanceToCurrentStepMeters = 20.0;
            _onArrivedAtStepStop();
          }
        }
      });
    });
  }

  void _onArrivedAtStepStop() {
    final steps = widget.routeDetails.journeySteps;
    if (steps.isEmpty) return;
    final step = steps[currentStepIndex.clamp(0, steps.length - 1)];

    if (isAudioGuidanceEnabled && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 3),
          backgroundColor: const Color(0xFF00E676),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          content: Row(
            children: [
              const Icon(
                Icons.notifications_active_rounded,
                color: AppTheme.navy,
                size: 24,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Arriving at stop: ${step.title}! Prepare to disembark.',
                  style: const TextStyle(
                    color: AppTheme.navy,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  Future<void> _fetchLiveLocation({bool showNotice = true}) async {
    setState(() {
      _isFetchingLocation = true;
    });

    try {
      final loc = await _locationService.fetchCurrentLocation(
        fallbackCoordinates: _startCoords,
        hintLocationName: widget.routeDetails.startLocation,
      );

      if (!mounted) return;

      setState(() {
        _currentLocation = loc;
        _isFetchingLocation = false;
      });

      if (showNotice && mounted) {
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
                    'Live Location Fetched: ${loc.address}',
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _isFetchingLocation = false);
    }
  }

  void _nextStep() {
    if (currentStepIndex < widget.routeDetails.journeySteps.length - 1) {
      setState(() {
        currentStepIndex++;
        _distanceToCurrentStepMeters = 450.0;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 2),
          backgroundColor: AppTheme.teal,
          content: Text(
            'Proceeding to step ${currentStepIndex + 1}: ${widget.routeDetails.journeySteps[currentStepIndex].title}',
            style: const TextStyle(
              color: AppTheme.navy,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
    } else {
      _showArrivalDialog();
    }
  }

  void _previousStep() {
    if (currentStepIndex > 0) {
      setState(() {
        currentStepIndex--;
        _distanceToCurrentStepMeters = 400.0;
      });
    }
  }

  void _showArrivalDialog() {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF0F263E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: AppTheme.teal, size: 28),
            SizedBox(width: 10),
            Text(
              'Journey Complete!',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You have safely arrived at ${widget.routeDetails.destination}.',
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.teal.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.teal.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.eco_rounded, color: AppTheme.teal, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'SDG 11 Impact: You saved ${widget.routeDetails.carbonSavedKg} of CO₂ compared to a private car!',
                      style: const TextStyle(
                        color: AppTheme.teal,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Exit Live Companion
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.teal,
              foregroundColor: AppTheme.navy,
            ),
            child: const Text('Return to Route'),
          ),
        ],
      ),
    );
  }

  void _showAssistanceCard({required bool isPrioritySeat}) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: isHighContrast ? Colors.black : const Color(0xFF0D243B),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          border: Border.all(
            color: isPrioritySeat ? AppTheme.aqua : AppTheme.teal,
            width: 2.5,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(
                  isPrioritySeat
                      ? Icons.event_seat_rounded
                      : Icons.accessible_forward_rounded,
                  color: isPrioritySeat ? AppTheme.aqua : AppTheme.teal,
                  size: 38,
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, size: 28),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              isPrioritySeat
                  ? 'PLEASE OFFER PRIORITY SEAT'
                  : 'RAMP ASSISTANCE REQUESTED',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isPrioritySeat ? AppTheme.aqua : AppTheme.teal,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Show this card to fellow passengers or the transit crew.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
              ),
              child: Column(
                children: [
                  Text(
                    isPrioritySeat
                        ? 'I have mobility assistance needs and kindly require a designated priority seat.'
                        : 'I am using a mobility device and request ramp deployment for boarding/alighting.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isPrioritySeat
                        ? 'කරුණාකර ප්‍රමුඛ ආසනයක් ලබාදීමට සහය වන්න.'
                        : 'කරුණාකර රෝද පුටු රැම්ප් ආධාරකය සකසා දෙන්න.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isPrioritySeat ? AppTheme.aqua : AppTheme.teal,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => Navigator.pop(context),
              style: FilledButton.styleFrom(
                backgroundColor: isPrioritySeat ? AppTheme.aqua : AppTheme.teal,
                foregroundColor: AppTheme.navy,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Close Notice',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final steps = widget.routeDetails.journeySteps;
    final currentStep = steps.isNotEmpty
        ? steps[currentStepIndex.clamp(0, steps.length - 1)]
        : null;

    final progress = steps.isEmpty
        ? 1.0
        : (currentStepIndex + 1) / steps.length;

    final bgColor = isHighContrast ? Colors.black : const Color(0xFF0A1929);

    return Scaffold(
      backgroundColor: bgColor,
      body: EqualRideBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Top Bar with Contrast toggle and Audio toggle
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: 'Exit Navigation',
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded, size: 24),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'LIVE ACCESSIBLE COMPANION',
                            style: TextStyle(
                              color: AppTheme.aqua,
                              fontWeight: FontWeight.w900,
                              fontSize: 11,
                              letterSpacing: 0.6,
                            ),
                          ),
                          Text(
                            widget.routeDetails.routeTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: _showMiniMap ? 'Hide Map' : 'Show Map',
                      icon: Icon(
                        _showMiniMap ? Icons.map_rounded : Icons.map_outlined,
                        color: _showMiniMap
                            ? AppTheme.aqua
                            : AppTheme.textSecondary,
                      ),
                      onPressed: () {
                        setState(() => _showMiniMap = !_showMiniMap);
                      },
                    ),
                    IconButton(
                      tooltip: isHighContrast
                          ? 'Standard Mode'
                          : 'High Contrast Mode',
                      icon: Icon(
                        isHighContrast
                            ? Icons.contrast_rounded
                            : Icons.brightness_6_rounded,
                        color: isHighContrast ? Colors.yellow : AppTheme.teal,
                      ),
                      onPressed: () {
                        setState(() => isHighContrast = !isHighContrast);
                      },
                    ),
                    IconButton(
                      tooltip: isAudioGuidanceEnabled
                          ? 'Audio Cues Active'
                          : 'Audio Muted',
                      icon: Icon(
                        isAudioGuidanceEnabled
                            ? Icons.volume_up_rounded
                            : Icons.volume_off_rounded,
                        color: isAudioGuidanceEnabled
                            ? AppTheme.aqua
                            : AppTheme.textSecondary,
                      ),
                      onPressed: () {
                        setState(
                          () =>
                              isAudioGuidanceEnabled = !isAudioGuidanceEnabled,
                        );
                      },
                    ),
                  ],
                ),
              ),

              // Live Location & GPS Status Banner
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.navy.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppTheme.teal.withValues(alpha: 0.4),
                      width: 1.2,
                    ),
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
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFF00E676),
                                boxShadow: [
                                  BoxShadow(
                                    color: Color(0xFF00E676),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                            ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  'LIVE GPS ACTIVE',
                                  style: TextStyle(
                                    color: Color(0xFF00E676),
                                    fontWeight: FontWeight.w900,
                                    fontSize: 10,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                                const Text(
                                  ' • ',
                                  style: TextStyle(
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                                Text(
                                  'Speed: ${_transitSpeedKmh.toStringAsFixed(0)} km/h',
                                  style: const TextStyle(
                                    color: AppTheme.aqua,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              _currentLocation != null
                                  ? '${_currentLocation!.address} (${_currentLocation!.shortCoordinates})'
                                  : 'Fetching live location...',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        tooltip: _isLiveTrackingActive
                            ? 'Pause Live Tracking'
                            : 'Resume Live Tracking',
                        icon: Icon(
                          _isLiveTrackingActive
                              ? Icons.pause_circle_filled_rounded
                              : Icons.play_circle_fill_rounded,
                          color: _isLiveTrackingActive
                              ? const Color(0xFF00E676)
                              : AppTheme.aqua,
                          size: 20,
                        ),
                        onPressed: () {
                          setState(() {
                            _isLiveTrackingActive = !_isLiveTrackingActive;
                          });
                        },
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        tooltip: 'Refresh Live Location',
                        icon: const Icon(
                          Icons.refresh_rounded,
                          color: AppTheme.teal,
                          size: 20,
                        ),
                        onPressed: () => _fetchLiveLocation(showNotice: true),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 6),

              // Journey Progress Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Step ${currentStepIndex + 1} of ${steps.length}',
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          '${(progress * 100).toInt()}% Completed',
                          style: const TextStyle(
                            color: AppTheme.teal,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 7,
                        backgroundColor: Colors.white.withValues(alpha: 0.12),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppTheme.teal,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // Main Active Step Card & Live Map
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  children: [
                    // Embedded In-App Live Map when toggled
                    if (_showMiniMap) ...[
                      Container(
                        height: 180,
                        margin: const EdgeInsets.only(bottom: 14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppTheme.teal.withValues(alpha: 0.5),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.4),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Stack(
                          children: [
                            FlutterMap(
                              options: MapOptions(
                                initialCenter:
                                    _currentLocation?.coordinates ??
                                    _startCoords,
                                initialZoom: 14.0,
                              ),
                              children: [
                                TileLayer(
                                  urlTemplate:
                                      'https://server.arcgisonline.com/ArcGIS/rest/services/World_Street_Map/MapServer/tile/{z}/{y}/{x}',
                                  userAgentPackageName:
                                      'com.example.equal_drive',
                                ),
                                PolylineLayer(
                                  polylines: [
                                    Polyline(
                                      points: _routePoints,
                                      strokeWidth: 4.5,
                                      color: AppTheme.aqua,
                                    ),
                                  ],
                                ),
                                MarkerLayer(
                                  markers: [
                                    Marker(
                                      point:
                                          _currentLocation?.coordinates ??
                                          _startCoords,
                                      width: 40,
                                      height: 40,
                                      child: AnimatedBuilder(
                                        animation: _pulseAnimation,
                                        builder: (context, child) {
                                          return Container(
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: const Color(0xFF00E5FF),
                                              border: Border.all(
                                                color: Colors.white,
                                                width: 2.5,
                                              ),
                                            ),
                                            child: const Icon(
                                              Icons.navigation_rounded,
                                              color: AppTheme.navy,
                                              size: 16,
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    Marker(
                                      point: _destCoords,
                                      width: 32,
                                      height: 32,
                                      child: const Icon(
                                        Icons.location_on_rounded,
                                        color: Color(0xFFFF5252),
                                        size: 26,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.navy.withValues(alpha: 0.9),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'Live Transit HUD',
                                  style: TextStyle(
                                    color: AppTheme.aqua,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    if (currentStep != null) ...[
                      Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isHighContrast
                                ? [
                                    const Color(0xFF1E1E1E),
                                    const Color(0xFF121212),
                                  ]
                                : [
                                    const Color(
                                      0xFF134E5E,
                                    ).withValues(alpha: 0.65),
                                    const Color(
                                      0xFF1A365D,
                                    ).withValues(alpha: 0.65),
                                  ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(26),
                          border: Border.all(
                            color: isHighContrast
                                ? Colors.yellow
                                : AppTheme.teal,
                            width: 2.0,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.teal.withValues(alpha: 0.25),
                              blurRadius: 18,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.teal.withValues(
                                      alpha: 0.22,
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    currentStep.stepType.toUpperCase(),
                                    style: const TextStyle(
                                      color: AppTheme.teal,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.timer_rounded,
                                      size: 16,
                                      color: AppTheme.aqua,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      currentStep.durationOrWaitTime,
                                      style: const TextStyle(
                                        color: AppTheme.aqua,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              currentStep.title,
                              style: TextStyle(
                                color: isHighContrast
                                    ? Colors.yellow
                                    : AppTheme.textPrimary,
                                fontWeight: FontWeight.w900,
                                fontSize: isHighContrast ? 24 : 22,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              currentStep.subtitle,
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 15,
                                height: 1.35,
                              ),
                            ),

                            // Real-time live distance ticker to this step's station
                            const SizedBox(height: 14),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.navy.withValues(alpha: 0.7),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: AppTheme.teal.withValues(alpha: 0.35),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.near_me_rounded,
                                    color: AppTheme.teal,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      _distanceToCurrentStepMeters <= 30
                                          ? 'Arriving at destination stop!'
                                          : 'Approaching stop: ${_locationService.formatDistance(_distanceToCurrentStepMeters)} away',
                                      style: const TextStyle(
                                        color: AppTheme.textPrimary,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    _distanceToCurrentStepMeters <= 30
                                        ? '🔔 ARRIVED'
                                        : 'TRACKING',
                                    style: TextStyle(
                                      color: _distanceToCurrentStepMeters <= 30
                                          ? const Color(0xFF00E676)
                                          : AppTheme.aqua,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            if (currentStep.surfaceCondition != null) ...[
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.accessible_forward_rounded,
                                      size: 18,
                                      color: AppTheme.teal,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Surface: ${currentStep.surfaceCondition}',
                                        style: const TextStyle(
                                          color: AppTheme.textPrimary,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            if (currentStep.facilityNote != null) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppTheme.aqua.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.info_rounded,
                                      size: 18,
                                      color: AppTheme.aqua,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Feature: ${currentStep.facilityNote}',
                                        style: const TextStyle(
                                          color: AppTheme.aqua,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            if (currentStep.hazardAlert != null) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFFFF5252,
                                  ).withValues(alpha: 0.16),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(
                                      0xFFFF5252,
                                    ).withValues(alpha: 0.5),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.warning_amber_rounded,
                                      size: 18,
                                      color: Color(0xFFFF5252),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        currentStep.hazardAlert!,
                                        style: const TextStyle(
                                          color: Color(0xFFFF8B8B),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),

                    // Quick Assistance Display Cards (SDG 10 Inclusion Feature)
                    Text(
                      'Rider Assistance Cards (Tap to show conductor)',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () =>
                                _showAssistanceCard(isPrioritySeat: true),
                            child: Ink(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppTheme.aqua.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: AppTheme.aqua.withValues(alpha: 0.45),
                                ),
                              ),
                              child: const Column(
                                children: [
                                  Icon(
                                    Icons.event_seat_rounded,
                                    color: AppTheme.aqua,
                                    size: 28,
                                  ),
                                  SizedBox(height: 6),
                                  Text(
                                    'Priority Seat Card',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: AppTheme.aqua,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () =>
                                _showAssistanceCard(isPrioritySeat: false),
                            child: Ink(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppTheme.teal.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: AppTheme.teal.withValues(alpha: 0.45),
                                ),
                              ),
                              child: const Column(
                                children: [
                                  Icon(
                                    Icons.accessible_forward_rounded,
                                    color: AppTheme.teal,
                                    size: 28,
                                  ),
                                  SizedBox(height: 6),
                                  Text(
                                    'Ramp Support Card',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: AppTheme.teal,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    // Next Step Preview
                    if (currentStepIndex < steps.length - 1) ...[
                      Text(
                        'Up Next:',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      GlassPanel(
                        padding: const EdgeInsets.all(14),
                        borderRadius: 16,
                        child: Row(
                          children: [
                            const Icon(
                              Icons.arrow_forward_rounded,
                              color: AppTheme.teal,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                steps[currentStepIndex + 1].title,
                                style: const TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            Text(
                              steps[currentStepIndex + 1].durationOrWaitTime,
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Bottom Navigation Controls
              Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF0C1F33),
                  border: Border(
                    top: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                ),
                child: Row(
                  children: [
                    if (currentStepIndex > 0) ...[
                      OutlinedButton(
                        onPressed: _previousStep,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Icon(Icons.arrow_back_rounded, size: 20),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _nextStep,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.teal,
                          foregroundColor: AppTheme.navy,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        icon: Icon(
                          currentStepIndex == steps.length - 1
                              ? Icons.check_circle_rounded
                              : Icons.arrow_forward_rounded,
                          size: 20,
                        ),
                        label: Text(
                          currentStepIndex == steps.length - 1
                              ? 'Complete Journey'
                              : 'Next Step',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

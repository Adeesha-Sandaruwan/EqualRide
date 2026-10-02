import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/route_details.dart';
import '../theme/app_theme.dart';
import '../widgets/equal_ride_background.dart';

class RouteDetailsPage extends StatelessWidget {
  const RouteDetailsPage({
    super.key,
    required this.routeDetails,
  });

  final RouteDetails routeDetails;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: EqualRideBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Header with Back Button and Title
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 20, 16),
                child: Row(
                  children: [
                    _HoverBackButton(
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Route Details',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Accessibility & navigation breakdown',
                            style: TextStyle(
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

              // Main Scrollable Content
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                  children: [
                    // Start & Destination Summary Card with Hover effects
                    _RouteSummaryCard(routeDetails: routeDetails),

                    const SizedBox(height: 18),

                    // Accessibility Score Panel with Hover effects
                    _AccessibilityScorePanel(
                      score: routeDetails.accessibilityScore,
                      durationMinutes: routeDetails.durationMinutes,
                      transfers: routeDetails.transfers,
                    ),

                    const SizedBox(height: 24),

                    // Section Title: Accessibility & Facilities
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppTheme.teal.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.accessibility_new_rounded,
                            color: AppTheme.teal,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Accessibility & Facilities',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Accessibility Status Card
                    _AccessibilityStatusCard(routeDetails: routeDetails),

                    const SizedBox(height: 26),

                    // Section Title: Journey Steps
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppTheme.aqua.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.alt_route_rounded,
                            color: AppTheme.aqua,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Journey Steps',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Journey Timeline Container with Hover Card
                    _HoverGlassCard(
                      child: routeDetails.journeySteps.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.symmetric(vertical: 14),
                              child: Center(
                                child: Text(
                                  'No step details available for this route.',
                                  style:
                                      TextStyle(color: AppTheme.textSecondary),
                                ),
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: routeDetails.journeySteps.length,
                              itemBuilder: (context, index) {
                                final step = routeDetails.journeySteps[index];
                                final isLast = index ==
                                    routeDetails.journeySteps.length - 1;

                                return _JourneyTimelineItem(
                                  step: step,
                                  isLast: isLast,
                                );
                              },
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

/// Back button with glass hover animation
class _HoverBackButton extends StatefulWidget {
  const _HoverBackButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  State<_HoverBackButton> createState() => _HoverBackButtonState();
}

class _HoverBackButtonState extends State<_HoverBackButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: _isHovered
                ? AppTheme.teal.withValues(alpha: 0.20)
                : Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _isHovered
                  ? AppTheme.teal.withValues(alpha: 0.55)
                  : Colors.white.withValues(alpha: 0.16),
            ),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: AppTheme.teal.withValues(alpha: 0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: AnimatedScale(
            scale: _isHovered ? 1.08 : 1.0,
            duration: const Duration(milliseconds: 180),
            child: const Icon(
              Icons.arrow_back_rounded,
              color: AppTheme.textPrimary,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}

/// Interactive Glass Container with smooth hover lift and glowing border
class _HoverGlassCard extends StatefulWidget {
  const _HoverGlassCard({
    required this.child,
  });

  final Widget child;

  @override
  State<_HoverGlassCard> createState() => _HoverGlassCardState();
}

class _HoverGlassCardState extends State<_HoverGlassCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    const glow = AppTheme.teal;
    const borderRadius = 24.0;
    const padding = EdgeInsets.all(20);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(0, _isHovered ? -1.5 : 0, 0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: [
            BoxShadow(
              color: _isHovered
                  ? glow.withValues(alpha: 0.10)
                  : Colors.black.withValues(alpha: 0.16),
              blurRadius: _isHovered ? 20 : 16,
              offset: Offset(0, _isHovered ? 5 : 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: padding,
              decoration: BoxDecoration(
                color: _isHovered
                    ? Colors.white.withValues(alpha: 0.11)
                    : Colors.white.withValues(alpha: 0.09),
                borderRadius: BorderRadius.circular(borderRadius),
                border: Border.all(
                  color: _isHovered
                      ? glow.withValues(alpha: 0.32)
                      : Colors.white.withValues(alpha: 0.18),
                  width: 1.0,
                ),
              ),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}

/// Start & Destination summary card
class _RouteSummaryCard extends StatelessWidget {
  const _RouteSummaryCard({required this.routeDetails});

  final RouteDetails routeDetails;

  @override
  Widget build(BuildContext context) {
    return _HoverGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  color: AppTheme.teal.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppTheme.teal.withValues(alpha: 0.40),
                  ),
                ),
                child: const Icon(
                  Icons.directions_bus_rounded,
                  color: AppTheme.teal,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      routeDetails.routeTitle,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      'Verified Accessible Transit',
                      style: TextStyle(
                        color: AppTheme.teal,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      height: 20,
                      width: 20,
                      decoration: BoxDecoration(
                        color: AppTheme.teal.withValues(alpha: 0.22),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.teal, width: 2),
                      ),
                      child: Center(
                        child: Container(
                          height: 6,
                          width: 6,
                          decoration: const BoxDecoration(
                            color: AppTheme.teal,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                    Container(
                      width: 2,
                      height: 30,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppTheme.teal.withValues(alpha: 0.6),
                            AppTheme.aqua.withValues(alpha: 0.6),
                          ],
                        ),
                      ),
                    ),
                    Container(
                      height: 22,
                      width: 22,
                      decoration: BoxDecoration(
                        color: AppTheme.aqua.withValues(alpha: 0.22),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.location_on_rounded,
                        color: AppTheme.aqua,
                        size: 18,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Start: ${routeDetails.startLocation}',
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Destination: ${routeDetails.destination}',
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          // Interactive View in Map Button with rich hover animation
          _HoverMapButton(
            onPressed: () => _openGoogleMaps(context),
          ),
        ],
      ),
    );
  }

  Future<void> _openGoogleMaps(BuildContext context) async {
    final start = routeDetails.startLocation.trim();
    final dest = routeDetails.destination.trim();

    final isGenericStart = start.isEmpty ||
        start.toLowerCase() == 'home' ||
        start.toLowerCase() == 'current location';

    final Uri googleMapsUrl = isGenericStart
        ? Uri.parse(
            'https://www.google.com/maps/dir/?api=1&destination=${Uri.encodeComponent(dest)}&travelmode=transit',
          )
        : Uri.parse(
            'https://www.google.com/maps/dir/?api=1&origin=${Uri.encodeComponent(start)}&destination=${Uri.encodeComponent(dest)}&travelmode=transit',
          );

    try {
      final launched = await launchUrl(
        googleMapsUrl,
        mode: LaunchMode.externalApplication,
      );

      if (!launched && context.mounted) {
        await launchUrl(
          googleMapsUrl,
          mode: LaunchMode.platformDefault,
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open Google Maps.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }
}

/// View in Map button with responsive hover effects
class _HoverMapButton extends StatefulWidget {
  const _HoverMapButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  State<_HoverMapButton> createState() => _HoverMapButtonState();
}

class _HoverMapButtonState extends State<_HoverMapButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          transform: Matrix4.translationValues(0, _isHovered ? -1.0 : 0, 0),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          decoration: BoxDecoration(
            gradient: _isHovered
                ? const LinearGradient(
                    colors: [Color(0xFF38E5D8), AppTheme.teal],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : LinearGradient(
                    colors: [
                      AppTheme.teal.withValues(alpha: 0.16),
                      AppTheme.teal.withValues(alpha: 0.08),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isHovered
                  ? AppTheme.aqua
                  : AppTheme.teal.withValues(alpha: 0.55),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color:
                    AppTheme.teal.withValues(alpha: _isHovered ? 0.28 : 0.08),
                blurRadius: _isHovered ? 12 : 6,
                offset: Offset(0, _isHovered ? 3 : 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedScale(
                scale: _isHovered ? 1.08 : 1.0,
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  Icons.map_rounded,
                  size: 20,
                  color: _isHovered ? AppTheme.navy : AppTheme.aqua,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'View in Map',
                style: TextStyle(
                  color: _isHovered ? AppTheme.navy : AppTheme.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Reusable Accessibility Score Panel with Hover effects
class _AccessibilityScorePanel extends StatelessWidget {
  const _AccessibilityScorePanel({
    required this.score,
    required this.durationMinutes,
    required this.transfers,
  });

  final int score;
  final int durationMinutes;
  final int transfers;

  String get _ratingDescription {
    if (score >= 85) return 'Highly Accessible Route';
    if (score >= 65) return 'Moderate Accessibility';
    return 'Limited Accessibility';
  }

  @override
  Widget build(BuildContext context) {
    return _HoverGlassCard(
      child: Column(
        children: [
          Row(
            children: [
              Container(
                height: 54,
                width: 54,
                decoration: BoxDecoration(
                  color: AppTheme.teal.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppTheme.teal.withValues(alpha: 0.6),
                    width: 2.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.teal.withValues(alpha: 0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    '$score',
                    style: const TextStyle(
                      color: AppTheme.teal,
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Accessibility Score',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _ratingDescription,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              _StatusBadge(
                label: '$score/100',
                icon: Icons.verified_rounded,
                isWarning: score < 65,
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: Colors.white12),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _HoverMetricTile(
                  icon: Icons.schedule_rounded,
                  iconColor: AppTheme.aqua,
                  title: '$durationMinutes mins',
                  subtitle: 'Total duration',
                ),
              ),
              Container(
                width: 1,
                height: 32,
                color: Colors.white.withValues(alpha: 0.15),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _HoverMetricTile(
                  icon: Icons.swap_horiz_rounded,
                  iconColor: AppTheme.teal,
                  title: transfers == 0
                      ? '0 transfers (Direct)'
                      : '$transfers transfers',
                  subtitle: 'Transfers / switch',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Interactive Metric Tile inside Score Panel
class _HoverMetricTile extends StatefulWidget {
  const _HoverMetricTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;

  @override
  State<_HoverMetricTile> createState() => _HoverMetricTileState();
}

class _HoverMetricTileState extends State<_HoverMetricTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: _isHovered
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            AnimatedScale(
              scale: _isHovered ? 1.15 : 1.0,
              duration: const Duration(milliseconds: 180),
              child: Icon(
                widget.icon,
                color: widget.iconColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    widget.subtitle,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Reusable Accessibility Status Card containing all facility statuses
class _AccessibilityStatusCard extends StatelessWidget {
  const _AccessibilityStatusCard({required this.routeDetails});

  final RouteDetails routeDetails;

  bool _isAvailable(String value) {
    final lower = value.toLowerCase();
    return lower.contains('available') && !lower.contains('un');
  }

  @override
  Widget build(BuildContext context) {
    final isRampAvailable = _isAvailable(routeDetails.rampStatus);
    final isLiftAvailable = _isAvailable(routeDetails.liftStatus);
    final isLowCrowding = routeDetails.crowdingLevel.toLowerCase() == 'low';

    return _HoverGlassCard(
      child: Column(
        children: [
          // Step-Free
          _AccessibilityStatusTile(
            icon: Icons.accessible_forward_rounded,
            title: 'Step-free',
            statusText: routeDetails.isStepFree ? 'Available' : 'Unavailable',
            isWarning: !routeDetails.isStepFree,
          ),
          const Divider(height: 16, color: Colors.white12),

          // Wheelchair Access
          _AccessibilityStatusTile(
            icon: Icons.accessible_rounded,
            title: 'Wheelchair access',
            statusText:
                routeDetails.hasWheelchairAccess ? 'Available' : 'Unavailable',
            isWarning: !routeDetails.hasWheelchairAccess,
          ),
          const Divider(height: 16, color: Colors.white12),

          // Ramp
          _AccessibilityStatusTile(
            icon: Icons.ramp_right_rounded,
            title: 'Ramp',
            statusText: routeDetails.rampStatus,
            isWarning: !isRampAvailable,
          ),
          const Divider(height: 16, color: Colors.white12),

          // Lift
          _AccessibilityStatusTile(
            icon: Icons.elevator_rounded,
            title: 'Lift',
            statusText: routeDetails.liftStatus,
            isWarning: !isLiftAvailable,
          ),
          const Divider(height: 16, color: Colors.white12),

          // Crowding
          _AccessibilityStatusTile(
            icon: Icons.groups_rounded,
            title: 'Crowd level',
            statusText: routeDetails.crowdingLevel,
            isWarning: !isLowCrowding,
          ),
        ],
      ),
    );
  }
}

/// Reusable Tile for an individual accessibility facility with hover highlight
class _AccessibilityStatusTile extends StatefulWidget {
  const _AccessibilityStatusTile({
    required this.icon,
    required this.title,
    required this.statusText,
    required this.isWarning,
  });

  final IconData icon;
  final String title;
  final String statusText;
  final bool isWarning;

  @override
  State<_AccessibilityStatusTile> createState() =>
      _AccessibilityStatusTileState();
}

class _AccessibilityStatusTileState extends State<_AccessibilityStatusTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final statusColor =
        widget.isWarning ? const Color(0xFFFFB259) : AppTheme.teal;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: _isHovered
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              height: 38,
              width: 38,
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: _isHovered ? 0.25 : 0.14),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color:
                      statusColor.withValues(alpha: _isHovered ? 0.50 : 0.15),
                ),
              ),
              child: AnimatedScale(
                scale: _isHovered ? 1.10 : 1.0,
                duration: const Duration(milliseconds: 180),
                child: Icon(widget.icon, color: statusColor, size: 20),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                widget.title,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
            _StatusBadge(
              label: widget.statusText,
              icon: widget.isWarning
                  ? Icons.warning_amber_rounded
                  : Icons.check_circle_outline_rounded,
              isWarning: widget.isWarning,
              isHovered: _isHovered,
            ),
          ],
        ),
      ),
    );
  }
}

/// Reusable Status Badge with accessible iconography and explicit warning/success style
class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.label,
    required this.icon,
    this.isWarning = false,
    this.isHovered = false,
  });

  final String label;
  final IconData icon;
  final bool isWarning;
  final bool isHovered;

  @override
  Widget build(BuildContext context) {
    final badgeColor = isWarning ? const Color(0xFFFFB259) : AppTheme.teal;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: isHovered ? 0.22 : 0.14),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: badgeColor.withValues(alpha: isHovered ? 0.55 : 0.35),
          width: 1,
        ),
        boxShadow: isHovered
            ? [
                BoxShadow(
                  color: badgeColor.withValues(alpha: 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: badgeColor, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: badgeColor,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

/// Reusable Journey Timeline Step Item with interactive hover effect
class _JourneyTimelineItem extends StatefulWidget {
  const _JourneyTimelineItem({
    required this.step,
    required this.isLast,
  });

  final JourneyStep step;
  final bool isLast;

  @override
  State<_JourneyTimelineItem> createState() => _JourneyTimelineItemState();
}

class _JourneyTimelineItemState extends State<_JourneyTimelineItem> {
  bool _isHovered = false;

  IconData _resolveStepIcon(JourneyStep step) {
    if (step.iconName != null) {
      switch (step.iconName) {
        case 'directions_walk':
          return Icons.directions_walk_rounded;
        case 'directions_bus':
          return Icons.directions_bus_rounded;
        case 'directions_transit':
        case 'train':
          return Icons.train_rounded;
        case 'location_on':
          return Icons.location_on_rounded;
        case 'local_hospital':
          return Icons.local_hospital_rounded;
      }
    }

    switch (step.stepType.toLowerCase()) {
      case 'walk':
        return Icons.directions_walk_rounded;
      case 'transit':
      case 'bus':
        return Icons.directions_bus_rounded;
      case 'train':
      case 'rail':
        return Icons.train_rounded;
      case 'arrival':
      case 'destination':
        return Icons.location_on_rounded;
      default:
        return Icons.navigation_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final stepIcon = _resolveStepIcon(widget.step);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Timeline icon indicator & connecting line
            Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 40,
                  width: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.teal
                        .withValues(alpha: _isHovered ? 0.24 : 0.18),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTheme.teal
                          .withValues(alpha: _isHovered ? 0.65 : 0.45),
                      width: _isHovered ? 1.8 : 1.5,
                    ),
                    boxShadow: _isHovered
                        ? [
                            BoxShadow(
                              color: AppTheme.teal.withValues(alpha: 0.22),
                              blurRadius: 7,
                              offset: const Offset(0, 1),
                            ),
                          ]
                        : null,
                  ),
                  child: AnimatedScale(
                    scale: _isHovered ? 1.06 : 1.0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      stepIcon,
                      color: _isHovered ? AppTheme.aqua : AppTheme.teal,
                      size: 20,
                    ),
                  ),
                ),
                if (!widget.isLast)
                  Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: AppTheme.teal
                          .withValues(alpha: _isHovered ? 0.45 : 0.30),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 16),
            // Step content with interactive card
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(bottom: widget.isLast ? 0 : 20),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _isHovered
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _isHovered
                          ? AppTheme.teal.withValues(alpha: 0.24)
                          : Colors.transparent,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _isHovered
                                  ? AppTheme.aqua.withValues(alpha: 0.25)
                                  : AppTheme.aqua.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              widget.step.stepType.toUpperCase(),
                              style: const TextStyle(
                                color: AppTheme.aqua,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Row(
                            children: [
                              const Icon(
                                Icons.timer_outlined,
                                size: 14,
                                color: AppTheme.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                widget.step.durationOrWaitTime,
                                style: const TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.step.title,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.step.subtitle,
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

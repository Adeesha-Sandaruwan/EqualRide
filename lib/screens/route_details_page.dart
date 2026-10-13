import 'dart:ui';

import 'package:flutter/material.dart';

import '../models/community_report.dart';
import '../models/route_details.dart';
import '../services/voice_assistant_service.dart';
import '../theme/app_theme.dart';
import '../widgets/equal_ride_background.dart';
import 'accessibility_report_page.dart';
import 'in_app_route_map_page.dart';
import 'live_journey_companion_page.dart';

class RouteDetailsPage extends StatelessWidget {
  const RouteDetailsPage({super.key, required this.routeDetails});

  final RouteDetails routeDetails;

  String _buildDetailsVoiceSummary() {
    final buffer = StringBuffer();
    buffer.write(
      'Route Details for ${routeDetails.routeTitle}. From ${routeDetails.startLocation} to ${routeDetails.destination}. Total duration ${routeDetails.durationMinutes} minutes with ${routeDetails.journeySteps.length} transit steps. ',
    );
    for (var i = 0; i < routeDetails.journeySteps.length; i++) {
      final s = routeDetails.journeySteps[i];
      buffer.write('Step ${i + 1}: ${s.title}, ${s.subtitle}. ');
    }
    buffer.write('Say "Start journey" to begin real-time navigation.');
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      VoiceAssistantService.instance.registerScreen(
        VoiceScreenContext(
          name: 'Route Details',
          summary:
              'Route ${routeDetails.routeTitle} to ${routeDetails.destination}. Total duration is ${routeDetails.durationMinutes} minutes with ${routeDetails.journeySteps.length} steps.',
          readContent: _buildDetailsVoiceSummary,
          onVoiceCommand: (cmd) async {
            if (cmd.contains('start journey') ||
                cmd.contains('live companion') ||
                cmd.contains('start navigation')) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      LiveJourneyCompanionPage(routeDetails: routeDetails),
                ),
              );
              return true;
            }
            if (cmd.contains('map') || cmd.contains('view in map')) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      InAppRouteMapPage(routeDetails: routeDetails),
                ),
              );
              return true;
            }
            return false;
          },
        ),
        announceNow: false,
      );
    });

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
                    _HoverBackButton(onPressed: () => Navigator.pop(context)),
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
                    // Active Crowdsourced Hazard Banner (if any)
                    if (routeDetails.communityAlerts.isNotEmpty)
                      _CommunityHazardBanner(
                        alerts: routeDetails.communityAlerts,
                      ),

                    // Start & Destination Summary Card with Hover effects
                    _RouteSummaryCard(routeDetails: routeDetails),

                    const SizedBox(height: 18),

                    // Accessibility Score Panel with Granular Breakdown
                    _AccessibilityScorePanel(routeDetails: routeDetails),

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
                                  style: TextStyle(
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: routeDetails.journeySteps.length,
                              itemBuilder: (context, index) {
                                final step = routeDetails.journeySteps[index];
                                final isLast =
                                    index ==
                                    routeDetails.journeySteps.length - 1;

                                return _JourneyTimelineItem(
                                  step: step,
                                  isLast: isLast,
                                  routeTitle: routeDetails.routeTitle,
                                );
                              },
                            ),
                    ),

                    const SizedBox(height: 24),

                    // Active Navigation Companion & Quick Report Footer
                    _RouteActionFooter(routeDetails: routeDetails),
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

/// Clean static Back button without hover animations (easy and stable for elderly users)
class _HoverBackButton extends StatelessWidget {
  const _HoverBackButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.16),
          ),
        ),
        child: const Icon(
          Icons.arrow_back_rounded,
          color: AppTheme.textPrimary,
          size: 20,
        ),
      ),
    );
  }
}

/// Calm static Glass Container without hover lift or shifting borders (for elderly usability)
class _HoverGlassCard extends StatelessWidget {
  const _HoverGlassCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    const borderRadius = 24.0;
    const padding = EdgeInsets.all(20);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.18),
                width: 1.0,
              ),
            ),
            child: child,
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
          // Interactive In-App View in Map Button with live location fetch
          _HoverMapButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => InAppRouteMapPage(routeDetails: routeDetails),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// View in Map button (stable and static for elderly users)
class _HoverMapButton extends StatelessWidget {
  const _HoverMapButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.teal.withValues(alpha: 0.20),
              AppTheme.teal.withValues(alpha: 0.10),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.teal.withValues(alpha: 0.55),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.teal.withValues(alpha: 0.10),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.map_rounded,
              size: 20,
              color: AppTheme.aqua,
            ),
            SizedBox(width: 10),
            Text(
              'View in Map',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Reusable Accessibility Score Panel with Granular Sub-Scores Breakdown
class _AccessibilityScorePanel extends StatelessWidget {
  const _AccessibilityScorePanel({required this.routeDetails});

  final RouteDetails routeDetails;

  String get _ratingDescription {
    final score = routeDetails.accessibilityScore;
    if (score >= 85) return 'Highly Accessible Route';
    if (score >= 65) return 'Moderate Accessibility';
    return 'Limited Accessibility';
  }

  @override
  Widget build(BuildContext context) {
    final score = routeDetails.accessibilityScore;

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
                      'Overall Accessibility Score',
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
          const SizedBox(height: 16),
          // Sub-scores Granular Breakdown (SDG 10 Core Evaluation)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Column(
              children: [
                _SubScoreRow(
                  label: 'Boarding Access & Ramps',
                  score: routeDetails.boardingScore,
                  color: AppTheme.teal,
                  icon: Icons.accessible_forward_rounded,
                ),
                const SizedBox(height: 8),
                _SubScoreRow(
                  label: 'Pedestrian Path & Transfers',
                  score: routeDetails.pathwayScore,
                  color: AppTheme.aqua,
                  icon: Icons.directions_walk_rounded,
                ),
                const SizedBox(height: 8),
                _SubScoreRow(
                  label: 'Priority Seating & Space',
                  score: routeDetails.seatingScore,
                  color: const Color(0xFF64D2FF),
                  icon: Icons.event_seat_rounded,
                ),
              ],
            ),
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
                  title: '${routeDetails.durationMinutes} mins',
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
                  title: routeDetails.transfers == 0
                      ? '0 transfers (Direct)'
                      : '${routeDetails.transfers} transfers',
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

class _SubScoreRow extends StatelessWidget {
  const _SubScoreRow({
    required this.label,
    required this.score,
    required this.color,
    required this.icon,
  });

  final String label;
  final int score;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              '$score%',
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: (score / 100).clamp(0.0, 1.0),
            minHeight: 5,
            backgroundColor: Colors.white.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

/// Metric Tile inside Score Panel (clean and static for elderly users)
class _HoverMetricTile extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                Text(
                  subtitle,
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
            statusText: routeDetails.hasWheelchairAccess
                ? 'Available'
                : 'Unavailable',
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

/// Reusable Tile for an individual accessibility facility (clean static style for elderly usability)
class _AccessibilityStatusTile extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final statusColor = isWarning
        ? const Color(0xFFFFB259)
        : AppTheme.teal;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            height: 38,
            width: 38,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: statusColor.withValues(alpha: 0.20),
              ),
            ),
            child: Icon(icon, color: statusColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          _StatusBadge(
            label: statusText,
            icon: isWarning
                ? Icons.warning_amber_rounded
                : Icons.check_circle_outline_rounded,
            isWarning: isWarning,
          ),
        ],
      ),
    );
  }
}

/// Reusable Status Badge with accessible iconography (static without hover)
class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.label,
    required this.icon,
    this.isWarning = false,
  });

  final String label;
  final IconData icon;
  final bool isWarning;

  @override
  Widget build(BuildContext context) {
    final badgeColor = isWarning ? const Color(0xFFFFB259) : AppTheme.teal;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: badgeColor.withValues(alpha: 0.35),
          width: 1,
        ),
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

/// Reusable Journey Timeline Step Item (clean static design for elderly accessibility)
class _JourneyTimelineItem extends StatelessWidget {
  const _JourneyTimelineItem({
    required this.step,
    required this.isLast,
    this.routeTitle,
  });

  final JourneyStep step;
  final bool isLast;
  final String? routeTitle;

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

  void _reportAtStop(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AccessibilityReportPage(
          initialLocation: step.title,
          initialIssueType: 'Step-free access issue',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stepIcon = _resolveStepIcon(step);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline icon indicator & connecting line
          Column(
            children: [
              Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  color: AppTheme.teal.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppTheme.teal.withValues(alpha: 0.45),
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  stepIcon,
                  color: AppTheme.teal,
                  size: 20,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: AppTheme.teal.withValues(alpha: 0.30),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          // Step content
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
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
                            color: AppTheme.aqua.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            step.stepType.toUpperCase(),
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
                              step.durationOrWaitTime,
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
                      step.title,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      step.subtitle,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                    if (step.surfaceCondition != null) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.accessible_forward_rounded,
                              size: 15,
                              color: AppTheme.teal,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                step.surfaceCondition!,
                                style: const TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (step.facilityNote != null) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.aqua.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.info_outline_rounded,
                              size: 15,
                              color: AppTheme.aqua,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                step.facilityNote!,
                                style: const TextStyle(
                                  color: AppTheme.aqua,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (step.hazardAlert != null) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFFFF5252,
                          ).withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(
                              0xFFFF5252,
                            ).withValues(alpha: 0.4),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.warning_amber_rounded,
                              size: 15,
                              color: Color(0xFFFF5252),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                step.hazardAlert!,
                                style: const TextStyle(
                                  color: Color(0xFFFF8B8B),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    // Contextual Report Button (SDG 10 Commuter Reporting Loop)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () => _reportAtStop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          visualDensity: VisualDensity.compact,
                        ),
                        icon: const Icon(
                          Icons.flag_outlined,
                          size: 14,
                          color: AppTheme.aqua,
                        ),
                        label: const Text(
                          'Report issue here',
                          style: TextStyle(
                            color: AppTheme.aqua,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
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


/// Active Crowdsourced Hazard Alert Banner
class _CommunityHazardBanner extends StatelessWidget {
  const _CommunityHazardBanner({required this.alerts});

  final List<CommunityReport> alerts;

  @override
  Widget build(BuildContext context) {
    if (alerts.isEmpty) return const SizedBox.shrink();

    final hasCritical = alerts.any(
      (a) =>
          a.impactLevel == 'Critical' ||
          a.issueType.contains('Ramp') ||
          a.issueType.contains('Lift'),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: hasCritical
            ? const Color(0xFFFF5252).withValues(alpha: 0.18)
            : const Color(0xFFFFB300).withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: hasCritical
              ? const Color(0xFFFF5252).withValues(alpha: 0.55)
              : const Color(0xFFFFB300).withValues(alpha: 0.55),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: hasCritical
                    ? const Color(0xFFFF5252)
                    : const Color(0xFFFFB300),
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(
                'ACTIVE CROWDSOURCED HAZARD (${alerts.length})',
                style: TextStyle(
                  color: hasCritical
                      ? const Color(0xFFFF5252)
                      : const Color(0xFFFFB300),
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...alerts
              .take(2)
              .map(
                (alert) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    '• ${alert.issueType} reported at ${alert.location}: ${alert.description}',
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                ),
              ),
          const SizedBox(height: 4),
          const Text(
            'Transit accessibility volunteers reported this condition. Please plan extra time or ask staff for assistance.',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

/// Bottom Action Footer for Navigation & Crowdsourced Reporting
class _RouteActionFooter extends StatelessWidget {
  const _RouteActionFooter({required this.routeDetails});

  final RouteDetails routeDetails;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FilledButton.icon(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    LiveJourneyCompanionPage(routeDetails: routeDetails),
              ),
            );
          },
          style: FilledButton.styleFrom(
            backgroundColor: AppTheme.teal,
            foregroundColor: AppTheme.navy,
            minimumSize: const Size.fromHeight(56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            elevation: 4,
            shadowColor: AppTheme.teal.withValues(alpha: 0.35),
          ),
          icon: const Icon(Icons.navigation_rounded, size: 22),
          label: const Text(
            'Start Journey (Live Companion)',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => AccessibilityReportPage(
                  initialLocation: routeDetails.routeTitle,
                  initialIssueType: 'Ramp unavailable',
                ),
              ),
            );
          },
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: Colors.white.withValues(alpha: 0.25)),
            foregroundColor: AppTheme.textPrimary,
            minimumSize: const Size.fromHeight(50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          icon: const Icon(Icons.flag_outlined, size: 18, color: AppTheme.aqua),
          label: const Text(
            'Report an Issue on this Route',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

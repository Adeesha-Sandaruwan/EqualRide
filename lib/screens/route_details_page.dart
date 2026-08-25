import 'package:flutter/material.dart';

import '../models/route_details.dart';
import '../theme/app_theme.dart';
import '../widgets/equal_ride_background.dart';
import '../widgets/glass_panel.dart';

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
                padding: const EdgeInsets.fromLTRB(12, 8, 20, 12),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: 'Back',
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    Expanded(
                      child: Text(
                        'Route Details',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                  ],
                ),
              ),

              // Main Scrollable Content
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                  children: [
                    // Start & Destination Summary Card
                    _RouteSummaryCard(routeDetails: routeDetails),

                    const SizedBox(height: 16),

                    // Accessibility Score Panel
                    _AccessibilityScorePanel(
                      score: routeDetails.accessibilityScore,
                      durationMinutes: routeDetails.durationMinutes,
                      transfers: routeDetails.transfers,
                    ),

                    const SizedBox(height: 20),

                    // Section Title
                    Text(
                      'Accessibility & Facilities',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),

                    // Accessibility Status Card
                    _AccessibilityStatusCard(routeDetails: routeDetails),

                    const SizedBox(height: 24),

                    // Journey Steps Section
                    Text(
                      'Journey Steps',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),

                    // Journey Timeline Container
                    GlassPanel(
                      child: routeDetails.journeySteps.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.symmetric(vertical: 10),
                              child: Center(
                                child: Text(
                                  'No step details available for this route.',
                                  style: TextStyle(color: AppTheme.textSecondary),
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
                                    index == routeDetails.journeySteps.length - 1;

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

/// Start & Destination summary card
class _RouteSummaryCard extends StatelessWidget {
  const _RouteSummaryCard({required this.routeDetails});

  final RouteDetails routeDetails;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            routeDetails.routeTitle,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  const Icon(
                    Icons.trip_origin_rounded,
                    color: AppTheme.teal,
                    size: 20,
                  ),
                  Container(
                    width: 2,
                    height: 28,
                    color: AppTheme.teal.withValues(alpha: 0.35),
                  ),
                  const Icon(
                    Icons.location_on_rounded,
                    color: AppTheme.aqua,
                    size: 22,
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
                    const SizedBox(height: 22),
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
        ],
      ),
    );
  }
}

/// Reusable Accessibility Score Panel
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
    return GlassPanel(
      child: Column(
        children: [
          Row(
            children: [
              Container(
                height: 52,
                width: 52,
                decoration: BoxDecoration(
                  color: AppTheme.teal.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppTheme.teal.withValues(alpha: 0.5),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    '$score',
                    style: const TextStyle(
                      color: AppTheme.teal,
                      fontSize: 18,
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
                child: Row(
                  children: [
                    const Icon(
                      Icons.schedule_rounded,
                      color: AppTheme.aqua,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$durationMinutes mins',
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        const Text(
                          'Total duration',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 28,
                color: Colors.white.withValues(alpha: 0.15),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Row(
                  children: [
                    const Icon(
                      Icons.swap_horiz_rounded,
                      color: AppTheme.teal,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          transfers == 0 ? '0 transfers (Direct)' : '$transfers transfers',
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        const Text(
                          'Transfers / switch',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
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

    return GlassPanel(
      child: Column(
        children: [
          // Step-Free
          _AccessibilityStatusTile(
            icon: Icons.accessible_forward_rounded,
            title: 'Step-free',
            statusText: routeDetails.isStepFree ? 'Available' : 'Unavailable',
            isWarning: !routeDetails.isStepFree,
          ),
          const Divider(height: 18, color: Colors.white12),

          // Wheelchair Access
          _AccessibilityStatusTile(
            icon: Icons.accessible_rounded,
            title: 'Wheelchair access',
            statusText: routeDetails.hasWheelchairAccess ? 'Available' : 'Unavailable',
            isWarning: !routeDetails.hasWheelchairAccess,
          ),
          const Divider(height: 18, color: Colors.white12),

          // Ramp
          _AccessibilityStatusTile(
            icon: Icons.ramp_right_rounded,
            title: 'Ramp',
            statusText: routeDetails.rampStatus,
            isWarning: !isRampAvailable,
          ),
          const Divider(height: 18, color: Colors.white12),

          // Lift
          _AccessibilityStatusTile(
            icon: Icons.elevator_rounded,
            title: 'Lift',
            statusText: routeDetails.liftStatus,
            isWarning: !isLiftAvailable,
          ),
          const Divider(height: 18, color: Colors.white12),

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

/// Reusable Tile for an individual accessibility facility
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
    final statusColor = isWarning ? const Color(0xFFFFB259) : AppTheme.teal;

    return Row(
      children: [
        Container(
          height: 38,
          width: 38,
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(12),
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
          icon: isWarning ? Icons.warning_amber_rounded : Icons.check_circle_outline_rounded,
          isWarning: isWarning,
        ),
      ],
    );
  }
}

/// Reusable Status Badge with accessible iconography and explicit warning/success style
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

/// Reusable Journey Timeline Step Item
class _JourneyTimelineItem extends StatelessWidget {
  const _JourneyTimelineItem({
    required this.step,
    required this.isLast,
  });

  final JourneyStep step;
  final bool isLast;

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
    final stepIcon = _resolveStepIcon(step);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline icon indicator & connecting line
          Column(
            children: [
              Container(
                height: 38,
                width: 38,
                decoration: BoxDecoration(
                  color: AppTheme.teal.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppTheme.teal.withValues(alpha: 0.45),
                    width: 1.5,
                  ),
                ),
                child: Icon(stepIcon, color: AppTheme.teal, size: 20),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: AppTheme.teal.withValues(alpha: 0.3),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          // Step content
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
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
                  const SizedBox(height: 6),
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
                      height: 1.3,
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

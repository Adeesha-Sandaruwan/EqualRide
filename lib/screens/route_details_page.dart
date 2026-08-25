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
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  children: [
                    // Start & Destination Summary Card
                    GlassPanel(
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
                    ),

                    const SizedBox(height: 16),

                    // Metrics Card (Duration, Accessibility Score, Transfers)
                    GlassPanel(
                      child: Row(
                        children: [
                          Expanded(
                            child: _MetricItem(
                              icon: Icons.schedule_rounded,
                              label: 'Total Duration',
                              value: '${routeDetails.durationMinutes} min',
                              color: AppTheme.aqua,
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 48,
                            color: Colors.white.withValues(alpha: 0.15),
                          ),
                          Expanded(
                            child: _MetricItem(
                              icon: Icons.swap_horiz_rounded,
                              label: 'Transfers',
                              value: '${routeDetails.transfers} transfers',
                              color: AppTheme.teal,
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 48,
                            color: Colors.white.withValues(alpha: 0.15),
                          ),
                          Expanded(
                            child: _MetricItem(
                              icon: Icons.verified_rounded,
                              label: 'Score',
                              value: '${routeDetails.accessibilityScore}/100',
                              color: AppTheme.teal,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Accessibility & Facilities Section
                    Text(
                      'Accessibility & Facilities',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    GlassPanel(
                      child: Column(
                        children: [
                          _AccessibilityStatusTile(
                            icon: Icons.accessible_forward_rounded,
                            title: 'Step-Free Status',
                            statusText: routeDetails.isStepFree
                                ? 'Step-free access confirmed'
                                : 'Not fully step-free',
                            isPositive: routeDetails.isStepFree,
                          ),
                          const Divider(height: 20, color: Colors.white12),
                          _AccessibilityStatusTile(
                            icon: Icons.accessible_rounded,
                            title: 'Wheelchair Access',
                            statusText: routeDetails.hasWheelchairAccess
                                ? 'Wheelchair access available'
                                : 'Wheelchair access not available',
                            isPositive: routeDetails.hasWheelchairAccess,
                          ),
                          const Divider(height: 20, color: Colors.white12),
                          _AccessibilityStatusTile(
                            icon: Icons.ramp_right_rounded,
                            title: 'Ramp Status',
                            statusText: 'Ramp: ${routeDetails.rampStatus}',
                            isPositive: routeDetails.rampStatus.toLowerCase().contains('available'),
                          ),
                          const Divider(height: 20, color: Colors.white12),
                          _AccessibilityStatusTile(
                            icon: Icons.elevator_rounded,
                            title: 'Lift Status',
                            statusText: 'Lift: ${routeDetails.liftStatus}',
                            isPositive: routeDetails.liftStatus.toLowerCase().contains('available'),
                          ),
                          const Divider(height: 20, color: Colors.white12),
                          _AccessibilityStatusTile(
                            icon: Icons.groups_rounded,
                            title: 'Crowding Level',
                            statusText: 'Crowding: ${routeDetails.crowdingLevel}',
                            isPositive: routeDetails.crowdingLevel.toLowerCase() == 'low',
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Journey Steps Timeline Section
                    Text(
                      'Journey Steps',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    GlassPanel(
                      child: routeDetails.journeySteps.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                'No step details available for this route.',
                                style: TextStyle(color: AppTheme.textSecondary),
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: routeDetails.journeySteps.length,
                              itemBuilder: (context, index) {
                                final step = routeDetails.journeySteps[index];
                                final isLast = index == routeDetails.journeySteps.length - 1;
                                final stepIcon = _resolveStepIcon(step);

                                return _JourneyTimelineStep(
                                  step: step,
                                  icon: stepIcon,
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

class _MetricItem extends StatelessWidget {
  const _MetricItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 6),
        Text(
          value,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class _AccessibilityStatusTile extends StatelessWidget {
  const _AccessibilityStatusTile({
    required this.icon,
    required this.title,
    required this.statusText,
    required this.isPositive,
  });

  final IconData icon;
  final String title;
  final String statusText;
  final bool isPositive;

  @override
  Widget build(BuildContext context) {
    final statusColor = isPositive ? AppTheme.teal : const Color(0xFFFFC46B);
    final statusIcon = isPositive ? Icons.check_circle_outline_rounded : Icons.info_outline_rounded;

    return Row(
      children: [
        Container(
          height: 40,
          width: 40,
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: statusColor, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                statusText,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        Icon(statusIcon, color: statusColor, size: 20),
      ],
    );
  }
}

class _JourneyTimelineStep extends StatelessWidget {
  const _JourneyTimelineStep({
    required this.step,
    required this.icon,
    required this.isLast,
  });

  final JourneyStep step;
  final IconData icon;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline indicator & connecting line
          Column(
            children: [
              Container(
                height: 38,
                width: 38,
                decoration: BoxDecoration(
                  color: AppTheme.teal.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppTheme.teal.withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                ),
                child: Icon(icon, color: AppTheme.teal, size: 20),
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

/// Represents an individual step within a journey route.
class JourneyStep {
  const JourneyStep({
    required this.stepType,
    required this.title,
    required this.subtitle,
    required this.durationOrWaitTime,
    this.iconName,
  });

  final String stepType;
  final String title;
  final String subtitle;
  final String durationOrWaitTime;
  final String? iconName;
}

/// Represents detailed accessibility and navigation information for a transit route.
class RouteDetails {
  const RouteDetails({
    required this.routeId,
    required this.routeTitle,
    required this.startLocation,
    required this.destination,
    required this.durationMinutes,
    required this.transfers,
    required this.isStepFree,
    required this.hasWheelchairAccess,
    required this.rampStatus,
    required this.liftStatus,
    required this.crowdingLevel,
    required this.accessibilityScore,
    this.journeySteps = const [],
  });

  final String routeId;
  final String routeTitle;
  final String startLocation;
  final String destination;
  final int durationMinutes;
  final int transfers;
  final bool isStepFree;
  final bool hasWheelchairAccess;
  final String rampStatus;
  final String liftStatus;
  final String crowdingLevel;
  final int accessibilityScore;
  final List<JourneyStep> journeySteps;
}

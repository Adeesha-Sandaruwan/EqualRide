import 'community_report.dart';

/// Represents an individual step within a journey route.
class JourneyStep {
  const JourneyStep({
    required this.stepType,
    required this.title,
    required this.subtitle,
    required this.durationOrWaitTime,
    this.iconName,
    this.isAccessible = true,
    this.facilityNote,
    this.hazardAlert,
    this.surfaceCondition,
  });

  final String stepType;
  final String title;
  final String subtitle;
  final String durationOrWaitTime;
  final String? iconName;
  final bool isAccessible;
  final String? facilityNote;
  final String? hazardAlert;
  final String? surfaceCondition;
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
    this.communityAlerts = const [],
    this.boardingScore = 95,
    this.pathwayScore = 90,
    this.seatingScore = 88,
    this.carbonSavedKg = '1.8 kg',
    this.inclusivityRating = 'High',
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
  final List<CommunityReport> communityAlerts;
  final int boardingScore;
  final int pathwayScore;
  final int seatingScore;
  final String carbonSavedKg;
  final String inclusivityRating;
}

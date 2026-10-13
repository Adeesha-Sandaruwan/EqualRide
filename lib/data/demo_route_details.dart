import '../models/community_report.dart';
import '../models/route_details.dart';
import '../models/transport_route.dart';

/// Demo route details data enriched with accessibility attributes and community hazard reports.
class DemoRouteDetails {
  static const RouteDetails bus245Details = RouteDetails(
    routeId: 'bus-245',
    routeTitle: 'Bus 245 towards North Station',
    startLocation: 'Home',
    destination: 'City General Hospital',
    durationMinutes: 45,
    transfers: 0,
    isStepFree: true,
    hasWheelchairAccess: true,
    rampStatus: 'Available',
    liftStatus: 'Available',
    crowdingLevel: 'Low',
    accessibilityScore: 92,
    boardingScore: 95,
    pathwayScore: 92,
    seatingScore: 90,
    carbonSavedKg: '1.9 kg',
    inclusivityRating: 'Excellent',
    journeySteps: [
      JourneyStep(
        stepType: 'Walk',
        title: 'Walk to Elm Street Stop A',
        subtitle: 'Step-free, flat paved footpath with tactile paving to Elm Street Stop A',
        durationOrWaitTime: '5 mins',
        iconName: 'directions_walk',
        isAccessible: true,
        surfaceCondition: 'Smooth paved pavement, curb cuts present',
        facilityNote: 'Audible crossing signals active at Elm & 4th Ave',
      ),
      JourneyStep(
        stepType: 'Transit',
        title: 'Board Bus 245 towards North Station',
        subtitle: 'Low-floor boarding with motorized ramp deployment and dedicated wheelchair bay',
        durationOrWaitTime: '35 mins',
        iconName: 'directions_bus',
        isAccessible: true,
        surfaceCondition: 'Level threshold boarding',
        facilityNote: 'Priority seating and digital audio announcements active',
      ),
      JourneyStep(
        stepType: 'Arrival',
        title: 'Arrive at City General Hospital',
        subtitle: 'Direct sheltered level access to City General Hospital main entrance',
        durationOrWaitTime: '5 mins',
        iconName: 'location_on',
        isAccessible: true,
        surfaceCondition: 'Step-free automated entrance sliding doors',
        facilityNote: 'Staff assistance desk located 15m inside the lobby',
      ),
    ],
  );

  /// List of pre-configured demo route details.
  static const List<RouteDetails> all = [
    bus245Details,
  ];

  /// Returns existing details or generates dynamic details for any transport route.
  static RouteDetails getDetailsForRoute(
    TransportRoute route, {
    String? from,
    String? destination,
    List<CommunityReport>? activeReports,
  }) {
    final start = (from != null && from.isNotEmpty) ? from : 'Current Location';
    final dest =
        (destination != null && destination.isNotEmpty) ? destination : 'Destination';

    // Find any matching community reports for this route
    final matchingReports = (activeReports ?? []).where((report) {
      final routeNum = route.routeNumber.toLowerCase().trim();
      final busNum = report.busNumber?.toLowerCase().trim();
      if (busNum != null && busNum == routeNum) return true;
      final loc = report.location.toLowerCase();
      final desc = report.description.toLowerCase();
      return loc.contains('bus $routeNum') ||
          loc.contains('route $routeNum') ||
          desc.contains('bus $routeNum') ||
          desc.contains('route $routeNum');
    }).toList();

    // Check pre-configured details
    final existing = all.cast<RouteDetails?>().firstWhere(
          (details) => details?.routeId == route.id,
          orElse: () => null,
        );

    if (existing != null) {
      return RouteDetails(
        routeId: existing.routeId,
        routeTitle: existing.routeTitle,
        startLocation: start,
        destination: dest,
        durationMinutes: existing.durationMinutes,
        transfers: existing.transfers,
        isStepFree: existing.isStepFree,
        hasWheelchairAccess: existing.hasWheelchairAccess,
        rampStatus: existing.rampStatus,
        liftStatus: existing.liftStatus,
        crowdingLevel: existing.crowdingLevel,
        accessibilityScore: existing.accessibilityScore,
        boardingScore: existing.boardingScore,
        pathwayScore: existing.pathwayScore,
        seatingScore: existing.seatingScore,
        carbonSavedKg: existing.carbonSavedKg,
        inclusivityRating: existing.inclusivityRating,
        journeySteps: existing.journeySteps,
        communityAlerts: matchingReports,
      );
    }

    final transitMinutes = route.durationMinutes > 10
        ? route.durationMinutes - 10
        : route.durationMinutes;

    final hasCriticalHazard = matchingReports.any((r) =>
        r.impactLevel == 'Critical' ||
        r.issueType.contains('Ramp') ||
        r.issueType.contains('Lift'));

    // Dynamic calculation of sub-scores based on route attributes & live alerts
    int boardingScore = route.isStepFree ? 92 : 55;
    if (hasCriticalHazard) boardingScore = (boardingScore * 0.6).round();

    int pathwayScore = route.transfers == 0 ? 88 : 74;
    int seatingScore = route.hasPrioritySeating ? 90 : 50;
    if (route.crowding == 'High') seatingScore -= 20;

    final calculatedScore =
        ((boardingScore * 0.45) + (pathwayScore * 0.3) + (seatingScore * 0.25))
            .round()
            .clamp(20, 100);

    final carbonKg =
        (route.durationMinutes * 0.045).toStringAsFixed(1); // approximate savings vs car

    final inclusivity = calculatedScore >= 85
        ? 'Excellent'
        : calculatedScore >= 70
            ? 'Good'
            : 'Moderate';

    final hazardText = matchingReports.isNotEmpty
        ? '${matchingReports.first.issueType}: ${matchingReports.first.description}'
        : null;

    return RouteDetails(
      routeId: route.id,
      routeTitle: '${route.transportType} ${route.routeNumber} towards $dest',
      startLocation: start,
      destination: dest,
      durationMinutes: route.durationMinutes,
      transfers: route.transfers,
      isStepFree: route.isStepFree && !hasCriticalHazard,
      hasWheelchairAccess: route.isStepFree && !hasCriticalHazard,
      rampStatus: hasCriticalHazard
          ? 'Reported Issue'
          : route.isStepFree
              ? 'Available'
              : 'Unavailable',
      liftStatus: route.isStepFree ? 'Available' : 'Limited',
      crowdingLevel: route.crowding,
      accessibilityScore: calculatedScore,
      boardingScore: boardingScore,
      pathwayScore: pathwayScore,
      seatingScore: seatingScore,
      carbonSavedKg: '$carbonKg kg',
      inclusivityRating: inclusivity,
      communityAlerts: matchingReports,
      journeySteps: [
        JourneyStep(
          stepType: 'Walk',
          title: 'Walk to boarding stop',
          subtitle: route.isStepFree
              ? 'Step-free paved access with street crossing guidance'
              : 'Standard footpath towards the stop',
          durationOrWaitTime: '5 mins',
          iconName: 'directions_walk',
          isAccessible: route.isStepFree,
          surfaceCondition: route.isStepFree
              ? 'Smooth paved pedestrian pathway'
              : 'Standard street curb',
          facilityNote: 'Sheltered waiting area and bench seating',
        ),
        JourneyStep(
          stepType: 'Transit',
          title: 'Board ${route.transportType} ${route.routeNumber}',
          subtitle: route.description,
          durationOrWaitTime: '$transitMinutes mins',
          iconName: route.transportType == 'Train'
              ? 'directions_railway'
              : 'directions_bus',
          isAccessible: route.isStepFree && !hasCriticalHazard,
          surfaceCondition: route.isStepFree
              ? 'Low-floor boarding with accessible entry'
              : 'Standard high-step boarding',
          facilityNote: route.hasPrioritySeating
              ? 'Designated priority seats directly near doors'
              : 'Standard seating only',
          hazardAlert: hazardText,
        ),
        JourneyStep(
          stepType: 'Arrival',
          title: 'Arrive at $dest',
          subtitle: 'Direct accessible exit towards destination entrance',
          durationOrWaitTime: '5 mins',
          iconName: 'location_on',
          isAccessible: true,
          surfaceCondition: 'Continuous flat pathway',
          facilityNote: 'Accessible taxi pick-up and drop-off zone nearby',
        ),
      ],
    );
  }
}


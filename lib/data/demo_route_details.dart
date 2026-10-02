import '../models/route_details.dart';
import '../models/transport_route.dart';

/// Temporary demo route details data until a verified public-transport data source is integrated.
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
    journeySteps: [
      JourneyStep(
        stepType: 'Walk',
        title: 'Walk to bus stop',
        subtitle: 'Step-free, flat paved footpath to Elm Street Stop A',
        durationOrWaitTime: '5 mins',
        iconName: 'directions_walk',
      ),
      JourneyStep(
        stepType: 'Transit',
        title: 'Board Bus 245 towards North Station',
        subtitle: 'Low-floor boarding with ramp deployment and designated wheelchair bay',
        durationOrWaitTime: '35 mins',
        iconName: 'directions_bus',
      ),
      JourneyStep(
        stepType: 'Arrival',
        title: 'Arrive at destination',
        subtitle: 'Direct level access to City General Hospital main entrance',
        durationOrWaitTime: '5 mins',
        iconName: 'location_on',
      ),
    ],
  );

  /// List of available demo route details.
  static const List<RouteDetails> all = [
    bus245Details,
  ];

  /// Returns existing details or generates dynamic details for any transport route.
  static RouteDetails getDetailsForRoute(
    TransportRoute route, {
    String? from,
    String? destination,
  }) {
    final existing = all.cast<RouteDetails?>().firstWhere(
          (details) => details?.routeId == route.id,
          orElse: () => null,
        );
    if (existing != null) return existing;

    final start = (from != null && from.isNotEmpty) ? from : 'Current Location';
    final dest =
        (destination != null && destination.isNotEmpty) ? destination : 'Destination';
    final transitMinutes = route.durationMinutes > 10
        ? route.durationMinutes - 10
        : route.durationMinutes;

    return RouteDetails(
      routeId: route.id,
      routeTitle: '${route.transportType} ${route.routeNumber} towards $dest',
      startLocation: start,
      destination: dest,
      durationMinutes: route.durationMinutes,
      transfers: route.transfers,
      isStepFree: route.isStepFree,
      hasWheelchairAccess: route.isStepFree,
      rampStatus: route.isStepFree ? 'Available' : 'Unavailable',
      liftStatus: route.isStepFree ? 'Available' : 'Limited',
      crowdingLevel: route.crowding,
      accessibilityScore: route.accessibilityScore,
      journeySteps: [
        JourneyStep(
          stepType: 'Walk',
          title: 'Walk to boarding stop',
          subtitle: route.isStepFree
              ? 'Step-free paved access to the stop'
              : 'Standard footpath to the stop',
          durationOrWaitTime: '5 mins',
          iconName: 'directions_walk',
        ),
        JourneyStep(
          stepType: 'Transit',
          title: 'Board ${route.transportType} ${route.routeNumber}',
          subtitle: route.description,
          durationOrWaitTime: '$transitMinutes mins',
          iconName: route.transportType == 'Train'
              ? 'directions_railway'
              : 'directions_bus',
        ),
        JourneyStep(
          stepType: 'Arrival',
          title: 'Arrive at $dest',
          subtitle: 'Direct accessible exit towards destination',
          durationOrWaitTime: '5 mins',
          iconName: 'location_on',
        ),
      ],
    );
  }
}


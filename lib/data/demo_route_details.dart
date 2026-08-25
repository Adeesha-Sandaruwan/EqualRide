import '../models/route_details.dart';

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
}

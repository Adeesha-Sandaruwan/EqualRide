import '../models/transport_route.dart';

class DemoRoutes {
  static const routes = [
    TransportRoute(
      id: 'bus-245',
      routeNumber: '245',
      transportType: 'Bus',
      durationMinutes: 45,
      transfers: 0,
      isStepFree: true,
      crowding: 'Low',
      accessibilityScore: 92,
      description: 'Low-floor bus with wheelchair access and ramp support.',
    ),
    TransportRoute(
      id: 'train-a',
      routeNumber: 'Line A',
      transportType: 'Train',
      durationMinutes: 30,
      transfers: 1,
      isStepFree: true,
      crowding: 'High',
      accessibilityScore: 78,
      description: 'Step-free rail route with one accessible transfer.',
    ),
    TransportRoute(
      id: 'bus-138',
      routeNumber: '138',
      transportType: 'Bus',
      durationMinutes: 52,
      transfers: 1,
      isStepFree: false,
      crowding: 'Medium',
      accessibilityScore: 61,
      description: 'Standard bus route with limited accessibility data.',
    ),
  ];
}
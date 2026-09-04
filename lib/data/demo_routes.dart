import '../models/transport_route.dart';

class DemoRoutes {
  static final List<TransportRoute> routes = List.unmodifiable([
    const TransportRoute(
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
    const TransportRoute(
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
    const TransportRoute(
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

    ...List.generate(150, _buildDemoBusRoute),
  ]);

  static TransportRoute _buildDemoBusRoute(int index) {
    final routeNumber = 100 + index;
    final isStepFree = index % 4 != 0;

    final crowding = switch (index % 3) {
      0 => 'Low',
      1 => 'Medium',
      _ => 'High',
    };

    final transfers = index % 4;
    final duration = 25 + ((index * 7) % 55);

    var score = 55;

    if (isStepFree) {
      score += 20;
    }

    if (crowding == 'Low') {
      score += 12;
    } else if (crowding == 'High') {
      score -= 8;
    }

    if (transfers == 0) {
      score += 10;
    } else if (transfers >= 2) {
      score -= 8;
    }

    return TransportRoute(
      id: 'demo-bus-$routeNumber',
      routeNumber: '$routeNumber',
      transportType: 'Bus',
      durationMinutes: duration,
      transfers: transfers,
      isStepFree: isStepFree,
      crowding: crowding,
      accessibilityScore: score.clamp(0, 100).toInt(),
      description: isStepFree
          ? 'Demo low-floor bus route with recorded accessibility information.'
          : 'Demo bus route with limited accessibility information.',
    );
  }
}
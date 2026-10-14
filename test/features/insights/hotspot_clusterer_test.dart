import 'package:equal_drive/features/insights/models/geo_report.dart';
import 'package:equal_drive/features/insights/services/hotspot_clusterer.dart';
import 'package:equal_drive/models/community_report.dart';
import 'package:flutter_test/flutter_test.dart';

CommunityReport _report(
  String id, {
  String impact = 'High',
  String status = 'Pending',
  String? bus,
  Duration age = const Duration(hours: 2),
  required DateTime now,
}) {
  return CommunityReport(
    id: id,
    issueType: 'Ramp unavailable',
    description: 'x',
    location: 'Fort',
    authorId: 'u',
    createdAt: now.subtract(age),
    status: status,
    busNumber: bus,
    impactLevel: impact,
  );
}

GeoReport _at(CommunityReport r, double lat, double lng) =>
    GeoReport(report: r, point: GeoPoint(lat, lng), source: GeoSource.gazetteer);

void main() {
  final now = DateTime(2026, 5, 1, 12);

  test('groups nearby reports into one cluster and ranks by severity', () {
    final clusters = HotspotClusterer.cluster(
      [
        _at(_report('a', now: now), 6.9301, 79.8501),
        _at(_report('b', impact: 'Critical', now: now), 6.9305, 79.8505),
        _at(_report('c', impact: 'Low', now: now), 7.2901, 80.6301),
      ],
      filter: const MapFilter(),
      now: now,
    );

    expect(clusters, hasLength(2));
    expect(clusters.first.count, 2);
    expect(clusters.first.openSeverity, 7);
    expect(clusters.first.maxWeight, 4);
  });

  test('skips unmapped reports', () {
    final r = _report('a', now: now);
    final clusters = HotspotClusterer.cluster(
      [GeoReport(report: r, point: null, source: GeoSource.unresolved)],
      filter: const MapFilter(),
      now: now,
    );
    expect(clusters, isEmpty);
  });

  test('filters by window, scope, resolved and critical', () {
    final old = _report('old', age: const Duration(days: 3), now: now);
    final bus = _report('bus', bus: '138', now: now);
    final done = _report('done', status: 'Resolved', now: now);
    final crit = _report('crit', impact: 'Critical', now: now);

    expect(const MapFilter(window: MapWindow.last24h).accepts(old, now), isFalse);
    expect(const MapFilter(window: MapWindow.last7d).accepts(old, now), isTrue);
    expect(const MapFilter(scope: MapScope.road).accepts(bus, now), isFalse);
    expect(const MapFilter(scope: MapScope.bus).accepts(bus, now), isTrue);
    expect(const MapFilter().accepts(done, now), isFalse);
    expect(const MapFilter(includeResolved: true).accepts(done, now), isTrue);
    expect(const MapFilter(criticalOnly: true).accepts(bus, now), isFalse);
    expect(const MapFilter(criticalOnly: true).accepts(crit, now), isTrue);
  });

  test('cluster label prefers bus number and top issue is most common', () {
    final clusters = HotspotClusterer.cluster(
      [_at(_report('a', bus: '138', now: now), 6.93, 79.85)],
      filter: const MapFilter(),
      now: now,
    );
    expect(clusters.single.label, 'Bus 138');
    expect(clusters.single.topIssue, 'Ramp unavailable');
  });
}

import '../../../models/community_report.dart';
import '../models/geo_report.dart';
import 'insights_calculator.dart';

enum MapScope { all, bus, road }

enum MapWindow {
  last24h(Duration(hours: 24)),
  last7d(Duration(days: 7)),
  last30d(Duration(days: 30));

  const MapWindow(this.duration);

  final Duration duration;
}

/// Filters applied to the live hotspot map only.
class MapFilter {
  const MapFilter({
    this.scope = MapScope.all,
    this.window = MapWindow.last7d,
    this.criticalOnly = false,
    this.includeResolved = false,
  });

  final MapScope scope;
  final MapWindow window;
  final bool criticalOnly;
  final bool includeResolved;

  MapFilter copyWith({
    MapScope? scope,
    MapWindow? window,
    bool? criticalOnly,
    bool? includeResolved,
  }) {
    return MapFilter(
      scope: scope ?? this.scope,
      window: window ?? this.window,
      criticalOnly: criticalOnly ?? this.criticalOnly,
      includeResolved: includeResolved ?? this.includeResolved,
    );
  }

  bool accepts(CommunityReport report, DateTime now) {
    final created = report.createdAt;
    if (created == null || now.difference(created) > window.duration) {
      return false;
    }

    final hasBus = (report.busNumber ?? '').trim().isNotEmpty;
    if (scope == MapScope.bus && !hasBus) return false;
    if (scope == MapScope.road && hasBus) return false;

    if (!includeResolved &&
        InsightsCalculator.bucketOf(report.status) == ReportBucket.resolved) {
      return false;
    }
    if (criticalOnly && report.impactLevel != 'Critical') return false;
    return true;
  }
}

/// Reports that fall in the same map grid cell.
class HotspotCluster {
  HotspotCluster({
    required this.latitude,
    required this.longitude,
    required this.reports,
  });

  final double latitude;
  final double longitude;
  final List<CommunityReport> reports;

  int get count => reports.length;

  /// Sum of severity weights of the cluster's unresolved reports.
  int get openSeverity => reports
      .where(
        (r) => InsightsCalculator.bucketOf(r.status) != ReportBucket.resolved,
      )
      .fold(0, (sum, r) => sum + InsightsCalculator.severityWeight(r.impactLevel));

  int get maxWeight => reports.fold(
        0,
        (max, r) {
          final w = InsightsCalculator.severityWeight(r.impactLevel);
          return w > max ? w : max;
        },
      );

  /// Most common issue type in this cluster.
  String get topIssue {
    final counts = <String, int>{};
    for (final r in reports) {
      counts[r.issueType] = (counts[r.issueType] ?? 0) + 1;
    }
    return (counts.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value)))
        .first
        .key;
  }

  /// Best human-readable name for the place.
  String get label {
    final counts = <String, int>{};
    for (final r in reports) {
      final name = (r.busNumber ?? '').trim().isNotEmpty
          ? 'Bus ${r.busNumber!.trim()}'
          : r.location.trim();
      if (name.isNotEmpty) counts[name] = (counts[name] ?? 0) + 1;
    }
    if (counts.isEmpty) return 'Unnamed place';
    return (counts.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value)))
        .first
        .key;
  }

  DateTime? get latest {
    DateTime? result;
    for (final r in reports) {
      final c = r.createdAt;
      if (c != null && (result == null || c.isAfter(result))) result = c;
    }
    return result;
  }
}

/// Groups mapped reports into grid cells so nearby problems form one hotspot.
class HotspotClusterer {
  const HotspotClusterer._();

  /// Roughly 1.1 km at Sri Lankan latitudes.
  static const double cellDegrees = 0.01;

  static List<HotspotCluster> cluster(
    Iterable<GeoReport> reports, {
    required MapFilter filter,
    required DateTime now,
  }) {
    final cells = <String, List<GeoReport>>{};
    for (final item in reports) {
      final point = item.point;
      if (point == null || !filter.accepts(item.report, now)) continue;

      final row = (point.latitude / cellDegrees).floor();
      final col = (point.longitude / cellDegrees).floor();
      cells.putIfAbsent('$row:$col', () => []).add(item);
    }

    final clusters = cells.values.map((items) {
      final lat = items.fold(0.0, (s, i) => s + i.point!.latitude) /
          items.length;
      final lng = items.fold(0.0, (s, i) => s + i.point!.longitude) /
          items.length;
      return HotspotCluster(
        latitude: lat,
        longitude: lng,
        reports: items.map((i) => i.report).toList(),
      );
    }).toList()
      ..sort((a, b) => b.openSeverity.compareTo(a.openSeverity));
    return clusters;
  }
}

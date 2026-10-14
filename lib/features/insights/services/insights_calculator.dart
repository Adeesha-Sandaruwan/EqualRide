import '../../../models/community_report.dart';
import '../models/insight_summary.dart';

/// Pure aggregation of community reports. It only reads reports and never
/// writes, so it is safe to run alongside the Community Reports screens.
class InsightsCalculator {
  const InsightsCalculator._();

  static const _impactWeights = {
    'Low': 1,
    'Moderate': 2,
    'High': 3,
    'Critical': 4,
  };

  static const _maxEntries = 5;

  static int severityWeight(String impactLevel) =>
      _impactWeights[impactLevel] ?? _impactWeights['Moderate']!;

  /// Normalises the free-text status to one of three buckets.
  static ReportBucket bucketOf(String status) {
    switch (status.trim().toLowerCase()) {
      case 'resolved':
        return ReportBucket.resolved;
      case 'in progress':
        return ReportBucket.inProgress;
      default:
        return ReportBucket.pending;
    }
  }

  static InsightSummary summarize(
    List<CommunityReport> reports, {
    InsightRange range = InsightRange.days30,
    DateTime? now,
  }) {
    final current = now ?? DateTime.now();
    final today = DateTime(current.year, current.month, current.day);
    final start = DateTime(today.year, today.month, today.day - (range.days - 1));

    var pending = 0;
    var inProgress = 0;
    var resolved = 0;
    var criticalOpen = 0;
    var bus = 0;
    var road = 0;
    DateTime? oldestOpen;

    final issueAcc = <String, _Accumulator>{};
    final hotspotAcc = <String, _Accumulator>{};
    final perDay = <DateTime, int>{};

    for (final report in reports) {
      // A report with a pending server timestamp has no createdAt yet.
      final created = (report.createdAt ?? current).toLocal();
      final bucket = bucketOf(report.status);
      final isOpen = bucket != ReportBucket.resolved;

      if (isOpen && (oldestOpen == null || created.isBefore(oldestOpen))) {
        oldestOpen = created;
      }

      var day = DateTime(created.year, created.month, created.day);
      if (day.isAfter(today)) day = today;
      if (day.isBefore(start)) continue;

      perDay[day] = (perDay[day] ?? 0) + 1;

      switch (bucket) {
        case ReportBucket.pending:
          pending++;
        case ReportBucket.inProgress:
          inProgress++;
        case ReportBucket.resolved:
          resolved++;
      }

      if (report.category == 'road') {
        road++;
      } else {
        bus++;
      }

      final weight = severityWeight(report.impactLevel);
      if (isOpen && report.impactLevel == 'Critical') criticalOpen++;

      issueAcc
          .putIfAbsent(report.issueType, _Accumulator.new)
          .add(isOpen: isOpen, weight: weight);
      hotspotAcc
          .putIfAbsent(_hotspotLabel(report), _Accumulator.new)
          .add(isOpen: isOpen, weight: weight);
    }

    final total = pending + inProgress + resolved;
    if (total == 0) {
      return InsightSummary(
        range: range,
        totalReports: 0,
        pendingCount: 0,
        inProgressCount: 0,
        resolvedCount: 0,
        criticalOpenCount: 0,
        busCount: 0,
        roadCount: 0,
        topIssueTypes: const [],
        topHotspots: const [],
        trend: _trend(start, range.days, perDay),
        oldestOpenAt: oldestOpen,
      );
    }

    return InsightSummary(
      range: range,
      totalReports: total,
      pendingCount: pending,
      inProgressCount: inProgress,
      resolvedCount: resolved,
      criticalOpenCount: criticalOpen,
      busCount: bus,
      roadCount: road,
      topIssueTypes: _rank(
        issueAcc,
        (a, b) => b.count != a.count
            ? b.count.compareTo(a.count)
            : b.severityScore.compareTo(a.severityScore),
      ),
      topHotspots: _rank(
        hotspotAcc,
        (a, b) => b.severityScore != a.severityScore
            ? b.severityScore.compareTo(a.severityScore)
            : b.count.compareTo(a.count),
        onlyOpen: true,
      ),
      trend: _trend(start, range.days, perDay),
      oldestOpenAt: oldestOpen,
    );
  }

  /// Bus reports group by route number, station and road reports by place.
  static String _hotspotLabel(CommunityReport report) {
    final bus = report.busNumber?.trim() ?? '';
    if (bus.isNotEmpty) return 'Bus $bus';
    final location = report.location.trim();
    return location.isEmpty ? 'Unknown location' : location;
  }

  static List<InsightEntry> _rank(
    Map<String, _Accumulator> source,
    int Function(InsightEntry, InsightEntry) compare, {
    bool onlyOpen = false,
  }) {
    final entries = source.entries
        .where((e) => !onlyOpen || e.value.open > 0)
        .map(
          (e) => InsightEntry(
            label: e.key,
            count: e.value.count,
            openCount: e.value.open,
            severityScore: e.value.severity,
          ),
        )
        .toList()
      ..sort((a, b) {
        final result = compare(a, b);
        return result != 0 ? result : a.label.compareTo(b.label);
      });

    return entries.take(_maxEntries).toList();
  }

  static List<TrendPoint> _trend(
    DateTime start,
    int days,
    Map<DateTime, int> perDay,
  ) {
    return List.generate(days, (i) {
      final date = DateTime(start.year, start.month, start.day + i);
      return TrendPoint(date: date, count: perDay[date] ?? 0);
    });
  }
}

enum ReportBucket { pending, inProgress, resolved }

class _Accumulator {
  int count = 0;
  int open = 0;
  int severity = 0;

  void add({required bool isOpen, required int weight}) {
    count++;
    if (isOpen) {
      open++;
      severity += weight;
    }
  }
}

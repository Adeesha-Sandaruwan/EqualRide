/// Time window used by the insights dashboard.
enum InsightRange {
  days7(7),
  days30(30),
  days90(90);

  const InsightRange(this.days);

  final int days;
}

/// One ranked row, for example an issue type or a problem route.
class InsightEntry {
  const InsightEntry({
    required this.label,
    required this.count,
    required this.openCount,
    required this.severityScore,
  });

  final String label;

  /// All reports in the selected range.
  final int count;

  /// Reports in the range that are not resolved yet.
  final int openCount;

  /// Sum of impact weights of the open reports (Low 1 .. Critical 4).
  final int severityScore;
}

/// Reports created on a single calendar day.
class TrendPoint {
  const TrendPoint({required this.date, required this.count});

  final DateTime date;
  final int count;
}

/// Aggregated view of community reports for the insights dashboard.
class InsightSummary {
  const InsightSummary({
    required this.range,
    required this.totalReports,
    required this.pendingCount,
    required this.inProgressCount,
    required this.resolvedCount,
    required this.criticalOpenCount,
    required this.busCount,
    required this.roadCount,
    required this.topIssueTypes,
    required this.topHotspots,
    required this.trend,
    this.oldestOpenAt,
  });

  const InsightSummary.empty(this.range)
      : totalReports = 0,
        pendingCount = 0,
        inProgressCount = 0,
        resolvedCount = 0,
        criticalOpenCount = 0,
        busCount = 0,
        roadCount = 0,
        topIssueTypes = const [],
        topHotspots = const [],
        trend = const [],
        oldestOpenAt = null;

  final InsightRange range;
  final int totalReports;
  final int pendingCount;
  final int inProgressCount;
  final int resolvedCount;

  /// Critical-impact reports in the range that are still open.
  final int criticalOpenCount;

  /// On-bus reports in the range.
  final int busCount;

  /// Station and road reports in the range.
  final int roadCount;

  /// Issue types ranked by how often they are reported.
  final List<InsightEntry> topIssueTypes;

  /// Routes or places ranked by the severity of their open reports.
  final List<InsightEntry> topHotspots;

  /// One point per day across the range, oldest first.
  final List<TrendPoint> trend;

  /// Creation time of the oldest open report across all reports, not just
  /// the selected range, because an old backlog does not expire.
  final DateTime? oldestOpenAt;

  int get openCount => pendingCount + inProgressCount;

  bool get isEmpty => totalReports == 0;

  /// Share of reports in the range that are resolved, from 0 to 1.
  double get resolutionRate =>
      totalReports == 0 ? 0 : resolvedCount / totalReports;
}

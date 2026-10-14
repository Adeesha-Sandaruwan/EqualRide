import '../models/insight_summary.dart';

/// Builds the one-line plain-language takeaway shown at the top of the
/// dashboard.
String buildInsightHeadline(InsightSummary summary) {
  if (summary.isEmpty) {
    return 'No reports in the last ${summary.range.days} days yet.';
  }

  final parts = <String>[];

  final open = summary.openCount;
  parts.add(
    open == 0
        ? 'All ${summary.totalReports} reports are resolved.'
        : '$open of ${summary.totalReports} reports are still open.',
  );

  if (summary.criticalOpenCount > 0) {
    final n = summary.criticalOpenCount;
    parts.add('$n critical ${n == 1 ? 'issue needs' : 'issues need'} attention.');
  }

  if (summary.topIssueTypes.isNotEmpty) {
    parts.add('Most reported: ${summary.topIssueTypes.first.label}.');
  }

  return parts.join(' ');
}

/// Whole days since the oldest open report, or null when nothing is open.
int? oldestOpenDays(InsightSummary summary, {DateTime? now}) {
  final oldest = summary.oldestOpenAt;
  if (oldest == null) return null;
  final days = (now ?? DateTime.now()).difference(oldest).inDays;
  return days < 0 ? 0 : days;
}

// File: insights_service.dart
//
// Thin Firestore stream wrapper for Insights. Watches the existing reports
// collection read-only and maps each snapshot through InsightsCalculator.
// Does not add or change any report data.

import '../../../models/community_report.dart';
import '../../../services/accessibility_report_service.dart';
import '../models/insight_summary.dart';
import 'insights_calculator.dart';

/// Read-only access to community reports for the insights feature.
///
/// It listens to the existing real-time report stream and never writes, so
/// it does not change how Community Reports behaves.
class InsightsService {
  InsightsService({Stream<List<CommunityReport>> Function()? reportsSource})
    : _reportsSource =
          reportsSource ??
          (() => AccessibilityReportService().getReportsStream());

  final Stream<List<CommunityReport>> Function() _reportsSource;

  /// Live list of all reports. Each call opens one Firestore listener, so
  /// callers should subscribe once and share the result.
  Stream<List<CommunityReport>> watchReports() => _reportsSource();

  /// Live summary for [range], recomputed whenever reports change.
  Stream<InsightSummary> watchSummary(InsightRange range) {
    return watchReports().map(
      (reports) => InsightsCalculator.summarize(reports, range: range),
    );
  }
}

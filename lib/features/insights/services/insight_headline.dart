// File: insight_headline.dart
//
// Builds the one-line plain-language takeaway at the top of the dashboard,
// and the "oldest open report" age in days.

import '../../../models/accessibility_preferences.dart';
import '../models/insight_summary.dart';
import 'insights_strings.dart';

/// Builds the one-line plain-language takeaway shown at the top of the
/// dashboard.
String buildInsightHeadline(
  InsightSummary summary, {
  AppLanguage language = AppLanguage.english,
}) {
  String t(String key, [Map<String, Object> params = const {}]) =>
      InsightsStrings.text(language, key, params);

  if (summary.isEmpty) {
    return t('headlineNone', {'days': summary.range.days});
  }

  final parts = <String>[];

  final open = summary.openCount;
  parts.add(
    open == 0
        ? t('headlineAllResolved', {'total': summary.totalReports})
        : t('headlineOpen', {'open': open, 'total': summary.totalReports}),
  );

  final critical = summary.criticalOpenCount;
  if (critical > 0) {
    parts.add(
      critical == 1
          ? t('headlineCriticalOne')
          : t('headlineCriticalMany', {'n': critical}),
    );
  }

  if (summary.topIssueTypes.isNotEmpty) {
    parts.add(t('headlineMost', {'issue': summary.topIssueTypes.first.label}));
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

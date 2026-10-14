// File: share_summary.dart
//
// Builds the plain-text summary shared from the dashboard (Copy / WhatsApp /
// Email). Contains totals and ranked areas only, never individual reports or
// author details.

import '../../../models/accessibility_preferences.dart';
import '../models/insight_summary.dart';
import 'insights_strings.dart';

/// Builds the plain-text summary people can send through any app. It holds
/// totals and ranked areas only, never individual reports or author details.
String buildShareSummary(
  InsightSummary summary, {
  AppLanguage language = AppLanguage.english,
  String Function(String label)? nameOf,
}) {
  String name(String label) => nameOf?.call(label) ?? label;

  String t(String key, [Map<String, Object> params = const {}]) =>
      InsightsStrings.text(language, key, params);

  final lines = <String>[
    t('shareHeading', {'days': summary.range.days}),
    t('shareTotal', {
      'total': summary.totalReports,
      'open': summary.openCount,
      'resolved': summary.resolvedCount,
    }),
  ];

  if (summary.criticalOpenCount > 0) {
    lines.add(t('shareCritical', {'n': summary.criticalOpenCount}));
  }

  if (summary.topIssueTypes.isNotEmpty) {
    lines.add('');
    lines.add(t('shareTopIssues'));
    for (final e in summary.topIssueTypes.take(3)) {
      lines.add('• ${e.label} (${e.count})');
    }
  }

  if (summary.topHotspots.isNotEmpty) {
    lines.add('');
    lines.add(t('shareHotspots'));
    for (final e in summary.topHotspots.take(3)) {
      lines.add('• ${name(e.label)} (${e.openCount})');
    }
  }

  lines
    ..add('')
    ..add(t('shareFooter'));
  return lines.join('\n');
}

// File: insights_calculator_test.dart
//
// Tests for the Insights summary calculation (buckets, rankings, trend).

import 'package:equal_drive/features/insights/models/insight_summary.dart';
import 'package:equal_drive/features/insights/services/insights_calculator.dart';
import 'package:equal_drive/models/community_report.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 10, 14, 12);

  CommunityReport report({
    String id = 'r',
    String issueType = 'Ramp unavailable',
    String status = 'Pending',
    String impact = 'Moderate',
    String category = 'bus',
    String? busNumber,
    String location = 'Somewhere',
    DateTime? createdAt,
  }) {
    return CommunityReport(
      id: id,
      issueType: issueType,
      description: '',
      location: location,
      authorId: 'u',
      status: status,
      category: category,
      busNumber: busNumber,
      impactLevel: impact,
      createdAt: createdAt ?? now,
    );
  }

  test('empty input gives an empty summary with a full trend', () {
    final summary = InsightsCalculator.summarize([], now: now);

    expect(summary.isEmpty, isTrue);
    expect(summary.resolutionRate, 0);
    expect(summary.trend, hasLength(30));
    expect(summary.trend.every((p) => p.count == 0), isTrue);
  });

  test('counts statuses, resolution rate and bus/road split', () {
    final summary = InsightsCalculator.summarize([
      report(id: '1', status: 'Pending'),
      report(id: '2', status: 'in progress'),
      report(id: '3', status: 'Resolved', category: 'road'),
      report(id: '4', status: 'Something else'),
    ], now: now);

    expect(summary.totalReports, 4);
    expect(summary.pendingCount, 2);
    expect(summary.inProgressCount, 1);
    expect(summary.resolvedCount, 1);
    expect(summary.openCount, 3);
    expect(summary.resolutionRate, 0.25);
    expect(summary.busCount, 3);
    expect(summary.roadCount, 1);
  });

  test('only open critical reports count as critical open', () {
    final summary = InsightsCalculator.summarize([
      report(id: '1', impact: 'Critical'),
      report(id: '2', impact: 'Critical', status: 'Resolved'),
      report(id: '3', impact: 'High'),
    ], now: now);

    expect(summary.criticalOpenCount, 1);
  });

  test('range excludes older reports but oldest open ignores the range', () {
    final old = now.subtract(const Duration(days: 60));
    final summary = InsightsCalculator.summarize(
      [report(id: 'new'), report(id: 'old', createdAt: old)],
      range: InsightRange.days7,
      now: now,
    );

    expect(summary.totalReports, 1);
    expect(summary.oldestOpenAt, old);
  });

  test('report without a timestamp is treated as created now', () {
    final summary = InsightsCalculator.summarize([
      CommunityReport(
        id: 'x',
        issueType: 'Other',
        description: '',
        location: 'Y',
        authorId: 'u',
      ),
    ], now: now);

    expect(summary.totalReports, 1);
    expect(summary.trend.last.count, 1);
  });

  test('top issue types rank by count and cap at five', () {
    final reports = <CommunityReport>[
      for (var i = 0; i < 3; i++) report(id: 'a$i', issueType: 'A'),
      for (var i = 0; i < 2; i++) report(id: 'b$i', issueType: 'B'),
      for (final t in ['C', 'D', 'E', 'F']) report(id: t, issueType: t),
    ];

    final summary = InsightsCalculator.summarize(reports, now: now);

    expect(summary.topIssueTypes, hasLength(5));
    expect(summary.topIssueTypes.first.label, 'A');
    expect(summary.topIssueTypes[1].label, 'B');
  });

  test('hotspots rank by open severity and skip fully resolved places', () {
    final summary = InsightsCalculator.summarize([
      report(id: '1', busNumber: '138', impact: 'Critical'),
      report(id: '2', busNumber: '245', impact: 'Low'),
      report(id: '3', busNumber: '245', impact: 'Low'),
      report(id: '4', busNumber: '99', impact: 'Critical', status: 'Resolved'),
      report(id: '5', category: 'road', location: 'Maradana Station'),
    ], now: now);

    final labels = summary.topHotspots.map((e) => e.label).toList();
    expect(labels.first, 'Bus 138');
    expect(labels, isNot(contains('Bus 99')));
    expect(labels, contains('Maradana Station'));
    expect(summary.topHotspots.first.severityScore, 4);
  });

  test('trend buckets reports per day, oldest first', () {
    final summary = InsightsCalculator.summarize(
      [
        report(id: '1'),
        report(id: '2'),
        report(id: '3', createdAt: now.subtract(const Duration(days: 2))),
      ],
      range: InsightRange.days7,
      now: now,
    );

    expect(summary.trend, hasLength(7));
    expect(summary.trend.last.count, 2);
    expect(summary.trend[4].count, 1);
    expect(summary.trend.first.date.isBefore(summary.trend.last.date), isTrue);
  });

  test('unknown impact level falls back to moderate weight', () {
    expect(InsightsCalculator.severityWeight('Nonsense'), 2);
    expect(InsightsCalculator.severityWeight('Critical'), 4);
  });
}

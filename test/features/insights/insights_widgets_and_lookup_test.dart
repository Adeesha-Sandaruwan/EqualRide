// File: insights_widgets_and_lookup_test.dart
//
// Tests for the smaller Insights building blocks: the colour palette, the summary model and "oldest open" helper,
// and the dashboard widgets (range selector, KPI card, hotspot list, entry
// card and error state).

import 'package:equal_drive/features/insights/models/insight_summary.dart';
import 'package:equal_drive/features/insights/services/insight_headline.dart';
import 'package:equal_drive/features/insights/widgets/hotspot_list.dart';
import 'package:equal_drive/features/insights/widgets/insight_palette.dart';
import 'package:equal_drive/features/insights/widgets/insight_states.dart';
import 'package:equal_drive/features/insights/widgets/insights_entry_card.dart';
import 'package:equal_drive/features/insights/widgets/kpi_card.dart';
import 'package:equal_drive/features/insights/widgets/range_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child) => MaterialApp(
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

void main() {
  group('InsightPalette', () {
    test('severity share maps to the expected colours', () {
      expect(InsightPalette.forSeverityShare(0.9), InsightPalette.critical);
      expect(InsightPalette.forSeverityShare(0.6), InsightPalette.high);
      expect(InsightPalette.forSeverityShare(0.3), InsightPalette.moderate);
      expect(InsightPalette.forSeverityShare(0.1), InsightPalette.low);
    });
  });

  group('InsightSummary', () {
    test('empty summary reports no data and zero rates', () {
      const summary = InsightSummary.empty(InsightRange.days7);
      expect(summary.isEmpty, isTrue);
      expect(summary.openCount, 0);
      expect(summary.resolutionRate, 0);
    });

    test('oldestOpenDays is null when nothing is open', () {
      const summary = InsightSummary.empty(InsightRange.days30);
      expect(oldestOpenDays(summary), isNull);
    });

    test('oldestOpenDays counts whole days and never goes negative', () {
      final now = DateTime(2025, 6, 10);
      InsightSummary withOldest(DateTime date) => InsightSummary(
        range: InsightRange.days30,
        totalReports: 1,
        pendingCount: 1,
        inProgressCount: 0,
        resolvedCount: 0,
        criticalOpenCount: 0,
        busCount: 1,
        roadCount: 0,
        topIssueTypes: const [],
        topHotspots: const [],
        trend: const [],
        oldestOpenAt: date,
      );

      expect(oldestOpenDays(withOldest(DateTime(2025, 6, 3)), now: now), 7);
      expect(oldestOpenDays(withOldest(DateTime(2025, 6, 20)), now: now), 0);
    });
  });

  group('widgets', () {
    testWidgets('RangeSelector reports the tapped range', (tester) async {
      InsightRange? picked;
      await tester.pumpWidget(
        _host(
          RangeSelector(
            selected: InsightRange.days7,
            onChanged: (r) => picked = r,
          ),
        ),
      );

      expect(find.text('7 days'), findsOneWidget);
      await tester.tap(find.text('30 days'));
      expect(picked, InsightRange.days30);
    });

    testWidgets('KpiCard shows its label and final value', (tester) async {
      await tester.pumpWidget(
        _host(const KpiCard(icon: Icons.flag, label: 'Open', value: 12)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Open'), findsOneWidget);
      expect(find.text('12'), findsOneWidget);
    });

    testWidgets('HotspotList uses nameOf instead of the raw label', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          HotspotList(
            entries: const [
              InsightEntry(
                label: '6.9271, 79.8612',
                count: 3,
                openCount: 2,
                severityScore: 6,
              ),
            ],
            nameOf: (_) => 'Fort, Colombo',
          ),
        ),
      );

      expect(find.text('Fort, Colombo'), findsOneWidget);
      expect(find.text('6.9271, 79.8612'), findsNothing);
    });

    testWidgets('HotspotList shows a friendly message when empty', (
      tester,
    ) async {
      await tester.pumpWidget(_host(const HotspotList(entries: [])));
      expect(find.textContaining('No open problems'), findsOneWidget);
    });

    testWidgets('InsightsEntryCard renders as a button', (tester) async {
      await tester.pumpWidget(_host(const InsightsEntryCard()));
      expect(find.byType(InkWell), findsWidgets);
    });

    testWidgets('InsightsErrorState retry callback fires', (tester) async {
      var retried = false;
      await tester.pumpWidget(
        _host(
          InsightsErrorState(
            message: 'Could not load',
            onRetry: () => retried = true,
          ),
        ),
      );

      expect(find.text('Could not load'), findsOneWidget);
      await tester.tap(find.byType(FilledButton).first);
      expect(retried, isTrue);
    });
  });
}

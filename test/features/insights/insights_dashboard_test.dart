import 'dart:async';

import 'package:equal_drive/features/insights/screens/insights_dashboard_page.dart';
import 'package:equal_drive/features/insights/services/insight_headline.dart';
import 'package:equal_drive/features/insights/services/insights_calculator.dart';
import 'package:equal_drive/features/insights/services/insights_service.dart';
import 'package:equal_drive/models/community_report.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

CommunityReport _report(
  String id, {
  String status = 'Pending',
  String impact = 'Moderate',
  String issueType = 'Ramp unavailable',
}) {
  return CommunityReport(
    id: id,
    issueType: issueType,
    description: '',
    location: 'Maradana Station',
    authorId: 'u',
    status: status,
    impactLevel: impact,
    createdAt: DateTime.now(),
  );
}

Widget _app(Stream<List<CommunityReport>> stream) {
  return MaterialApp(
    home: InsightsDashboardPage(
      service: InsightsService(reportsSource: () => stream),
    ),
  );
}

void main() {
  group('buildInsightHeadline', () {
    test('handles no data', () {
      final summary = InsightsCalculator.summarize([]);
      expect(buildInsightHeadline(summary), contains('No reports'));
    });

    test('summarises open, critical and top issue', () {
      final summary = InsightsCalculator.summarize([
        _report('1', impact: 'Critical'),
        _report('2', status: 'Resolved'),
      ]);
      final text = buildInsightHeadline(summary);

      expect(text, contains('1 of 2 reports are still open'));
      expect(text, contains('1 critical issue needs attention'));
      expect(text, contains('Most reported: Ramp unavailable'));
    });

    test('celebrates when everything is resolved', () {
      final summary = InsightsCalculator.summarize([
        _report('1', status: 'Resolved'),
      ]);
      expect(buildInsightHeadline(summary), contains('All 1 reports'));
    });
  });

  group('oldestOpenDays', () {
    test('is null when nothing is open', () {
      final summary = InsightsCalculator.summarize([
        _report('1', status: 'Resolved'),
      ]);
      expect(oldestOpenDays(summary), isNull);
    });
  });

  group('InsightsDashboardPage', () {
    testWidgets('shows a skeleton, then the dashboard', (tester) async {
      final controller = StreamController<List<CommunityReport>>();
      addTearDown(controller.close);
      tester.view.physicalSize = const Size(800, 3000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_app(controller.stream));
      expect(find.bySemanticsLabel('Loading insights'), findsOneWidget);

      controller.add([_report('1'), _report('2', impact: 'Critical')]);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Overview'), findsOneWidget);
      expect(find.text('Total reports'), findsOneWidget);
      expect(find.text('Critical open'), findsOneWidget);
      expect(find.text('Most reported issues'), findsOneWidget);
    });

    testWidgets('shows the empty state with no reports', (tester) async {
      await tester.pumpWidget(_app(Stream.value(<CommunityReport>[])));
      await tester.pump();

      expect(find.text('No data to analyse yet'), findsOneWidget);
    });

    testWidgets('shows an error with retry', (tester) async {
      await tester.pumpWidget(
        _app(Stream<List<CommunityReport>>.error('Permission denied')),
      );
      await tester.pump();

      expect(find.text('Could not load insights'), findsOneWidget);
      expect(find.text('Permission denied'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
    });

    testWidgets('switching the range keeps showing data', (tester) async {
      await tester.pumpWidget(_app(Stream.value([_report('1')])));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      await tester.tap(find.text('7 days'));
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Total reports'), findsOneWidget);
    });
  });
}

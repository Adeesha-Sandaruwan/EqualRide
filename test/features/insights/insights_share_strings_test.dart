import 'package:equal_drive/features/insights/models/insight_summary.dart';
import 'package:equal_drive/features/insights/services/insight_headline.dart';
import 'package:equal_drive/features/insights/services/insights_calculator.dart';
import 'package:equal_drive/features/insights/services/insights_strings.dart';
import 'package:equal_drive/features/insights/services/share_summary.dart';
import 'package:equal_drive/features/insights/widgets/share_summary_sheet.dart';
import 'package:equal_drive/models/accessibility_preferences.dart';
import 'package:equal_drive/models/community_report.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

InsightSummary _summary() {
  final now = DateTime.now();
  return InsightsCalculator.summarize(
    [
      CommunityReport(
        id: '1',
        issueType: 'Ramp unavailable',
        description: 'secret description',
        location: 'Fort',
        authorId: 'secret-author',
        createdAt: now.subtract(const Duration(days: 1)),
        status: 'Pending',
        impactLevel: 'Critical',
      ),
    ],
    range: InsightRange.days30,
  );
}

void main() {
  test('every English key has a Sinhala translation', () {
    for (final key in InsightsStrings.englishKeys) {
      expect(
        InsightsStrings.text(AppLanguage.sinhala, key),
        isNot(InsightsStrings.text(AppLanguage.english, key)),
        reason: key,
      );
    }
  });

  test('replaces parameters and falls back to the key', () {
    expect(
      InsightsStrings.text(AppLanguage.english, 'headlineOpen',
          {'open': 2, 'total': 5}),
      '2 of 5 reports are still open.',
    );
    expect(InsightsStrings.text(AppLanguage.english, 'nope'), 'nope');
  });

  test('headline is localised', () {
    final english = buildInsightHeadline(_summary());
    final sinhala =
        buildInsightHeadline(_summary(), language: AppLanguage.sinhala);
    expect(english, contains('critical issue needs attention'));
    expect(sinhala, isNot(english));
  });

  test('share summary has totals and areas but no personal data', () {
    final text = buildShareSummary(_summary());
    expect(text, contains('Reports: 1 (1 open, 0 resolved)'));
    expect(text, contains('Critical open: 1'));
    expect(text, contains('Ramp unavailable'));
    expect(text, isNot(contains('secret')));
  });

  testWidgets('share sheet opens a WhatsApp link and reports failure',
      (tester) async {
    Uri? opened;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ShareSummarySheet(
            text: 'hello world',
            language: AppLanguage.english,
            launch: (uri) async {
              opened = uri;
              return false;
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('WhatsApp'));
    await tester.pumpAndSettle();

    expect(opened?.host, 'wa.me');
    expect(opened?.queryParameters['text'], 'hello world');
    expect(find.text(InsightsStrings.text(AppLanguage.english, 'shareFailed')),
        findsOneWidget);
  });
}

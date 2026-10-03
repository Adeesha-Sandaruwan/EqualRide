import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:equal_drive/models/community_report.dart';
import 'package:equal_drive/services/accessibility_report_draft_service.dart';
import 'package:equal_drive/widgets/impact_level_selector.dart';

void main() {
  test('saves and restores the selected access impact in a draft', () {
    const draft = AccessibilityReportDraft(
      issueType: 'Lift unavailable',
      description: 'The lift is out of service.',
      location: 'Central Station',
      impactLevel: 'Critical',
    );

    final restored = AccessibilityReportDraft.fromJson(draft.toJson());

    expect(restored.impactLevel, 'Critical');
  });

  test('defaults older drafts and reports to moderate impact', () {
    final draft = AccessibilityReportDraft.fromJson({
      'version': 1,
      'issueType': 'Lift unavailable',
      'description': 'The lift is out of service.',
      'location': 'Central Station',
    });
    const report = CommunityReport(
      id: 'report-1',
      issueType: 'Lift unavailable',
      description: 'The lift is out of service.',
      location: 'Central Station',
      authorId: 'user-1',
    );

    expect(draft.impactLevel, CommunityReport.defaultImpactLevel);
    expect(report.impactLevel, CommunityReport.defaultImpactLevel);
  });

  testWidgets('allows selecting an access impact level', (tester) async {
    String? selectedLevel;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ImpactLevelSelector(
            value: CommunityReport.defaultImpactLevel,
            onChanged: (value) => selectedLevel = value,
          ),
        ),
      ),
    );

    await tester.tap(find.widgetWithText(ChoiceChip, 'Critical'));

    expect(selectedLevel, 'Critical');
  });
}

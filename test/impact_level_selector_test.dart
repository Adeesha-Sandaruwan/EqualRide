// File: impact_level_selector_test.dart
//
// Tests for the access-impact selector used in report forms: every level has
// a distinct icon and colour, tapping a tile reports the level, and a disabled
// selector ignores taps.

import 'package:equal_drive/models/community_report.dart';
import 'package:equal_drive/widgets/impact_level_selector.dart';
import 'package:equal_drive/widgets/report_impact_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host({
  required String value,
  required ValueChanged<String> onChanged,
  bool enabled = true,
}) => MaterialApp(
  home: Scaffold(
    body: SingleChildScrollView(
      child: ImpactLevelSelector(
        value: value,
        onChanged: onChanged,
        enabled: enabled,
      ),
    ),
  ),
);

void main() {
  test('each level has its own icon and colour', () {
    final levels = CommunityReport.impactLevelDescriptions.keys.toList();
    expect(
      levels.map(ImpactLevelSelector.iconFor).toSet().length,
      levels.length,
    );
    expect(
      levels.map(ReportImpactBadge.colorFor).toSet().length,
      levels.length,
    );
  });

  testWidgets('shows all levels and the selected description', (tester) async {
    await tester.pumpWidget(_host(value: 'High', onChanged: (_) {}));

    for (final level in CommunityReport.impactLevelDescriptions.keys) {
      expect(find.text(level), findsOneWidget);
    }
    expect(
      find.text(CommunityReport.impactLevelDescriptions['High']!),
      findsOneWidget,
    );
  });

  testWidgets('tapping a tile reports that level', (tester) async {
    String? picked;
    await tester.pumpWidget(
      _host(value: 'Moderate', onChanged: (l) => picked = l),
    );

    await tester.tap(find.text('Critical'));
    expect(picked, 'Critical');
  });

  testWidgets('disabled selector ignores taps', (tester) async {
    String? picked;
    await tester.pumpWidget(
      _host(value: 'Moderate', onChanged: (l) => picked = l, enabled: false),
    );

    await tester.tap(find.text('Low'));
    expect(picked, isNull);
  });

  testWidgets('unknown value falls back to the default level', (tester) async {
    await tester.pumpWidget(_host(value: 'Bogus', onChanged: (_) {}));
    expect(
      find.text(
        CommunityReport.impactLevelDescriptions[CommunityReport
            .defaultImpactLevel]!,
      ),
      findsOneWidget,
    );
  });
}

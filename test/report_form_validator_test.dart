import 'package:flutter_test/flutter_test.dart';

import 'package:equal_drive/utils/report_form_validator.dart';

void main() {
  // ── issueType ─────────────────────────────────────────────────────────────
  group('ReportFormValidator.issueType', () {
    test('returns error for null', () {
      expect(ReportFormValidator.issueType(null), isNotNull);
    });

    test('returns error for empty string', () {
      expect(ReportFormValidator.issueType(''), isNotNull);
    });

    test('returns null for a valid value', () {
      expect(ReportFormValidator.issueType('Ramp unavailable'), isNull);
    });
  });

  // ── location ──────────────────────────────────────────────────────────────
  group('ReportFormValidator.location', () {
    test('returns error for null', () {
      expect(ReportFormValidator.location(null), isNotNull);
    });

    test('returns error for empty string', () {
      expect(ReportFormValidator.location(''), isNotNull);
    });

    test('returns error for string exceeding max length', () {
      final longString = 'A' * (ReportFormValidator.locationMaxLength + 1);
      expect(ReportFormValidator.location(longString), isNotNull);
    });

    test('returns error for numeric-only input', () {
      expect(ReportFormValidator.location('12345'), isNotNull);
    });

    test('returns null for a valid location', () {
      expect(ReportFormValidator.location('Colombo Fort Station'), isNull);
    });
  });

  // ── busNumber ─────────────────────────────────────────────────────────────
  group('ReportFormValidator.busNumber', () {
    test('returns null for empty (field is optional)', () {
      expect(ReportFormValidator.busNumber(''), isNull);
      expect(ReportFormValidator.busNumber(null), isNull);
    });

    test('returns error for string exceeding max length', () {
      final longString = '1' * (ReportFormValidator.busNumberMaxLength + 1);
      expect(ReportFormValidator.busNumber(longString), isNotNull);
    });

    test('returns error for special characters', () {
      expect(ReportFormValidator.busNumber('138!@#'), isNotNull);
    });

    test('returns null for valid bus number', () {
      expect(ReportFormValidator.busNumber('138'), isNull);
      expect(ReportFormValidator.busNumber('138A'), isNull);
      expect(ReportFormValidator.busNumber('100/2'), isNull);
    });
  });

  // ── description ───────────────────────────────────────────────────────────
  group('ReportFormValidator.description', () {
    test('returns error for null', () {
      expect(ReportFormValidator.description(null), isNotNull);
    });

    test('returns error for empty string', () {
      expect(ReportFormValidator.description(''), isNotNull);
    });

    test('returns error when too short', () {
      expect(ReportFormValidator.description('Too short'), isNotNull);
    });

    test('returns error when exceeding max length', () {
      final longText = 'A ' * (ReportFormValidator.descriptionMaxLength ~/ 2 + 1);
      expect(ReportFormValidator.description(longText), isNotNull);
    });

    test('returns error for repeated single characters (spam)', () {
      expect(ReportFormValidator.description('aaaaaaaaaaaaaaaaaaaaa'), isNotNull);
    });

    test('returns null for a valid description', () {
      expect(
        ReportFormValidator.description(
          'The wheelchair ramp on Bus 138 was broken and could not be deployed.',
        ),
        isNull,
      );
    });
  });

  // ── matchesSearch ─────────────────────────────────────────────────────────
  group('ReportFormValidator.matchesSearch', () {
    const issueType = 'Ramp unavailable';
    const location = 'Colombo Fort Station';
    const description = 'The ramp was completely broken.';

    test('returns true when query is empty', () {
      expect(
        ReportFormValidator.matchesSearch(
          issueType: issueType,
          location: location,
          description: description,
          query: '',
        ),
        isTrue,
      );
    });

    test('matches on issueType (case-insensitive)', () {
      expect(
        ReportFormValidator.matchesSearch(
          issueType: issueType,
          location: location,
          description: description,
          query: 'ramp',
        ),
        isTrue,
      );
    });

    test('matches on location', () {
      expect(
        ReportFormValidator.matchesSearch(
          issueType: issueType,
          location: location,
          description: description,
          query: 'Colombo',
        ),
        isTrue,
      );
    });

    test('matches on description', () {
      expect(
        ReportFormValidator.matchesSearch(
          issueType: issueType,
          location: location,
          description: description,
          query: 'broken',
        ),
        isTrue,
      );
    });

    test('returns false when no field matches', () {
      expect(
        ReportFormValidator.matchesSearch(
          issueType: issueType,
          location: location,
          description: description,
          query: 'elevator',
        ),
        isFalse,
      );
    });
  });
}

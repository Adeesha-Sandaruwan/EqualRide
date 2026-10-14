// File: incident_photo_test.dart
//
// Tests for the incident photo feature: base64 encoding and size limits, safe
// decoding, the CommunityReport photo field, and the photo picker widget.

import 'dart:convert';
import 'dart:typed_data';

import 'package:equal_drive/models/community_report.dart';
import 'package:equal_drive/services/incident_photo_service.dart';
import 'package:equal_drive/widgets/incident_photo_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('IncidentPhotoService', () {
    test('encodes bytes as plain base64', () {
      final photo = IncidentPhotoService.fromBytes(
        Uint8List.fromList([1, 2, 3, 4]),
      );
      expect(photo.base64, base64Encode([1, 2, 3, 4]));
      expect(photo.base64.startsWith('data:'), isFalse);
    });

    test('rejects empty and oversized photos', () {
      expect(
        () => IncidentPhotoService.fromBytes(Uint8List(0)),
        throwsA(isA<IncidentPhotoException>()),
      );
      expect(
        () => IncidentPhotoService.fromBytes(Uint8List(400000)),
        throwsA(isA<IncidentPhotoException>()),
      );
    });

    test('tryDecode round-trips and tolerates bad data', () {
      final encoded = base64Encode([9, 8, 7]);
      expect(IncidentPhotoService.tryDecode(encoded), [9, 8, 7]);
      expect(IncidentPhotoService.tryDecode(null), isNull);
      expect(IncidentPhotoService.tryDecode(''), isNull);
      expect(IncidentPhotoService.tryDecode('%%not base64%%'), isNull);
    });
  });

  group('CommunityReport photo field', () {
    CommunityReport build({String? photo}) => CommunityReport(
      id: 'r1',
      issueType: 'Broken Ramp',
      description: 'The ramp is broken at the station.',
      location: 'Central Station',
      authorId: 'u1',
      createdAt: DateTime(2025, 1, 1),
      incidentPhotoBase64: photo,
    );

    test('toMap includes the photo only when present', () {
      expect(build().toMap().containsKey('incidentPhotoBase64'), isFalse);
      expect(build(photo: 'abc').toMap()['incidentPhotoBase64'], 'abc');
    });

    test('copyWith keeps the photo', () {
      expect(build(photo: 'abc').copyWith().incidentPhotoBase64, 'abc');
    });
  });

  testWidgets('picker shows source buttons, then preview with remove', (
    tester,
  ) async {
    var removed = false;
    Widget host(Uint8List? bytes) => MaterialApp(
      home: Scaffold(
        body: IncidentPhotoPicker(
          photoBytes: bytes,
          enabled: true,
          isBusy: false,
          onCamera: () {},
          onGallery: () {},
          onRemove: () => removed = true,
        ),
      ),
    );

    await tester.pumpWidget(host(null));
    expect(find.text('Take photo'), findsOneWidget);
    expect(find.text('Choose photo'), findsOneWidget);

    await tester.pumpWidget(host(_pngBytes));
    expect(find.byType(Image), findsOneWidget);
    await tester.tap(find.text('Remove'));
    expect(removed, isTrue);
  });
}

final Uint8List _pngBytes = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
);

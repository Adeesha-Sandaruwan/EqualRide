import 'dart:convert';

import 'package:equal_drive/features/insights/models/geo_report.dart';
import 'package:equal_drive/features/insights/services/landmark_gazetteer.dart';
import 'package:equal_drive/features/insights/services/report_geo_resolver.dart';
import 'package:equal_drive/models/community_report.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  CommunityReport report(String location, {String id = 'r'}) {
    return CommunityReport(
      id: id,
      issueType: 'Other',
      description: '',
      location: location,
      authorId: 'u',
    );
  }

  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('parseCoordinates', () {
    test('reads the map picker format', () {
      expect(
        ReportGeoResolver.parseCoordinates('6.93500, 79.85000'),
        const GeoPoint(6.935, 79.85),
      );
    });

    test('rejects out of range and non-coordinate text', () {
      expect(ReportGeoResolver.parseCoordinates('95.0, 79.0'), isNull);
      expect(ReportGeoResolver.parseCoordinates('Bus 138, route 12'), isNull);
      expect(ReportGeoResolver.parseCoordinates('Maradana Station'), isNull);
    });
  });

  group('LandmarkGazetteer', () {
    test('prefers the longest matching name', () {
      final fort = LandmarkGazetteer.lookup(
        'Bus 138 - Colombo Fort to Kaduwela',
      );
      expect(fort, const GeoPoint(6.9335, 79.8500));
    });

    test('is case insensitive and returns null for unknown places', () {
      expect(LandmarkGazetteer.lookup('MARADANA RAILWAY STATION'), isNotNull);
      expect(LandmarkGazetteer.lookup('Atlantis'), isNull);
    });
  });

  group('resolveLocal', () {
    final resolver = ReportGeoResolver(client: MockClient((_) async {
      fail('resolveLocal must not use the network');
    }));

    test('reports the source of each match', () {
      expect(
        resolver.resolveLocal(report('6.9, 79.8')).source,
        GeoSource.coordinates,
      );
      expect(
        resolver.resolveLocal(report('Maradana')).source,
        GeoSource.gazetteer,
      );
      final unknown = resolver.resolveLocal(report('Atlantis'));
      expect(unknown.source, GeoSource.unresolved);
      expect(unknown.isMapped, isFalse);
    });
  });

  group('resolveAll', () {
    test('geocodes unknown places once and reuses the cache', () async {
      var calls = 0;
      final client = MockClient((request) async {
        calls++;
        expect(request.headers['User-Agent'], isNotEmpty);
        return http.Response(
          jsonEncode([
            {'lat': '7.5', 'lon': '80.5'},
          ]),
          200,
        );
      });
      final resolver = ReportGeoResolver(
        client: client,
        requestGap: Duration.zero,
      );

      final results = await resolver.resolveAll([
        report('Bus Stop - Atlantis', id: '1'),
        report('Atlantis', id: '2'),
        report('Maradana', id: '3'),
      ]);

      expect(calls, 1);
      expect(results[0].source, GeoSource.geocoded);
      expect(results[1].point, const GeoPoint(7.5, 80.5));
      expect(results[2].source, GeoSource.gazetteer);

      await resolver.resolveAll([report('Atlantis')]);
      expect(calls, 1);
    });

    test('keeps unresolved reports and does not cache network errors', () async {
      var calls = 0;
      final resolver = ReportGeoResolver(
        client: MockClient((_) async {
          calls++;
          return http.Response('error', 500);
        }),
        requestGap: Duration.zero,
      );

      final first = await resolver.resolveAll([report('Atlantis')]);
      expect(first.single.isMapped, isFalse);

      await resolver.resolveAll([report('Atlantis')]);
      expect(calls, 2);
    });

    test('caches a confirmed not-found result', () async {
      var calls = 0;
      final resolver = ReportGeoResolver(
        client: MockClient((_) async {
          calls++;
          return http.Response('[]', 200);
        }),
        requestGap: Duration.zero,
      );

      await resolver.resolveAll([report('Nowhere')]);
      await resolver.resolveAll([report('Nowhere')]);
      expect(calls, 1);
    });

    test('useNetwork false never calls the network', () async {
      final resolver = ReportGeoResolver(
        client: MockClient((_) async {
          fail('network must not be used');
        }),
      );

      final results = await resolver.resolveAll(
        [report('Atlantis')],
        useNetwork: false,
      );
      expect(results.single.isMapped, isFalse);
    });
  });
}

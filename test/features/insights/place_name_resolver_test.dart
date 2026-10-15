// File: place_name_resolver_test.dart
//
// Tests for turning coordinates into readable place names and caching them.

import 'dart:convert';

import 'package:equal_drive/features/insights/services/place_name_resolver.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('formats locality and city without province or country', () {
    expect(
      PlaceNameResolver.formatPlaceName({
        'locality': 'Maradana',
        'city': 'Colombo',
        'principalSubdivision': 'Western Province',
        'countryName': 'Sri Lanka',
      }),
      'Maradana, Colombo',
    );
    expect(
      PlaceNameResolver.formatPlaceName({'locality': 'Fort', 'city': 'Fort'}),
      'Fort',
    );
    expect(
      PlaceNameResolver.formatPlaceName({'principalSubdivision': 'Western'}),
      'Western',
    );
    expect(PlaceNameResolver.formatPlaceName({'locality': ' '}), isNull);
  });

  test(
    'replaces coordinate labels with names and leaves text labels alone',
    () async {
      var calls = 0;
      final resolver = PlaceNameResolver(
        client: MockClient((request) async {
          calls++;
          expect(request.url.queryParameters['latitude'], '6.9331');
          return http.Response(
            jsonEncode({'locality': 'Maradana', 'city': 'Colombo'}),
            200,
          );
        }),
      );

      const coords = '6.933066, 79.894205';
      expect(resolver.display(coords), coords);

      await resolver.resolve([coords, 'Bus 138', 'Fort Station']);
      expect(resolver.display(coords), 'Maradana, Colombo');
      expect(resolver.display('Bus 138'), 'Bus 138');
      expect(resolver.display('Fort Station'), 'Fort Station');
      expect(calls, 1);

      await resolver.resolve([coords]);
      expect(calls, 1);
    },
  );

  test('keeps coordinates when the lookup fails and does not retry', () async {
    var calls = 0;
    final resolver = PlaceNameResolver(
      client: MockClient((_) async {
        calls++;
        return http.Response('error', 500);
      }),
    );

    const coords = '6.909630, 79.971152';
    await resolver.resolve([coords]);
    await resolver.resolve([coords]);

    expect(resolver.display(coords), coords);
    expect(calls, 1);
  });

  test('reuses names saved from an earlier session', () async {
    final first = PlaceNameResolver(
      client: MockClient(
        (_) async => http.Response(jsonEncode({'locality': 'Borella'}), 200),
      ),
    );
    await first.resolve(['6.9120, 79.8770']);

    final second = PlaceNameResolver(
      client: MockClient((_) async => throw StateError('no network')),
    );
    await second.resolve(['6.9120, 79.8770']);
    expect(second.display('6.9120, 79.8770'), 'Borella');
  });
}

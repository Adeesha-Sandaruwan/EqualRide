import 'package:flutter_test/flutter_test.dart';

import 'package:equal_drive/services/reverse_geocoding_service.dart';

void main() {
  test('builds a readable address from reverse-geocode data', () {
    final address = formatPlaceAddress({
      'locality': 'Fort',
      'city': 'Colombo',
      'principalSubdivision': 'Western Province',
      'countryName': 'Sri Lanka',
    });

    expect(address, 'Fort, Colombo, Western Province, Sri Lanka');
  });

  test('skips blank and duplicate place names', () {
    final address = formatPlaceAddress({
      'locality': 'Colombo',
      'city': 'Colombo',
      'principalSubdivision': '',
      'countryName': 'Sri Lanka',
    });

    expect(address, 'Colombo, Sri Lanka');
  });

  test('formats coordinates when no place name is available', () {
    expect(formatPlaceAddress({}), isNull);
    expect(formatCoordinates(6.9271, 79.8612), '6.92710, 79.86120');
  });
}

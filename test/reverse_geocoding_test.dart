import 'package:flutter_test/flutter_test.dart';

import 'package:equal_drive/services/reverse_geocoding_service.dart';

void main() {
  // Place parts are joined from the most local name to the country.
  test('builds a readable address from reverse-geocode data', () {
    final address = formatPlaceAddress({
      'locality': 'Fort',
      'city': 'Colombo',
      'principalSubdivision': 'Western Province',
      'countryName': 'Sri Lanka',
    });

    expect(address, 'Fort, Colombo, Western Province, Sri Lanka');
  });

  // Empty and repeated names are left out of the result.
  test('skips blank and duplicate place names', () {
    final address = formatPlaceAddress({
      'locality': 'Colombo',
      'city': 'Colombo',
      'principalSubdivision': '',
      'countryName': 'Sri Lanka',
    });

    expect(address, 'Colombo, Sri Lanka');
  });

  // Coordinates are used when address details are missing.
  test('formats coordinates when no place name is available', () {
    expect(formatPlaceAddress({}), isNull);
    expect(formatCoordinates(6.9271, 79.8612), '6.92710, 79.86120');
  });

  // Extra spaces around names should not appear in the final address.
  test('trims spaces from place names', () {
    expect(formatPlaceAddress({'locality': '  Fort  ', 'countryName': ' Sri Lanka '}), 'Fort, Sri Lanka');
  });

  // Values that are not text should be skipped safely.
  test('skips place fields that are not strings', () {
    expect(formatPlaceAddress({'locality': 12, 'city': 'Colombo'}), 'Colombo');
  });

  // If no usable place names exist, the formatter reports no address.
  test('returns null when all place names are blank', () {
    expect(formatPlaceAddress({'locality': ' ', 'city': ''}), isNull);
  });
}

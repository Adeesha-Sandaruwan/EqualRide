import 'package:flutter_test/flutter_test.dart';

import 'package:equal_drive/models/saved_location.dart';

void main() {
  test('creates Firestore data without document id', () {
    const location = SavedLocation(
      id: 'location-1',
      name: 'Home',
      address: 'Colombo Fort Railway Station',
    );

    expect(location.toMap(), {
      'name': 'Home',
      'address': 'Colombo Fort Railway Station',
    });
  });

  test('restores a saved location from Firestore data', () {
    final location = SavedLocation.fromMap(
      id: 'location-2',
      map: {
        'name': 'Hospital',
        'address': 'National Hospital of Sri Lanka',
      },
    );

    expect(location.id, 'location-2');
    expect(location.name, 'Hospital');
    expect(location.address, 'National Hospital of Sri Lanka');
  });

  test('uses safe defaults for incomplete Firestore data', () {
    final location = SavedLocation.fromMap(
      id: 'location-3',
      map: {},
    );

    expect(location.name, 'Saved location');
    expect(location.address, '');
  });
}
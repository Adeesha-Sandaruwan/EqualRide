import 'package:flutter_test/flutter_test.dart';

import 'package:equal_drive/models/saved_location.dart';

void main() {
  // Firestore stores the fields while keeping the document ID separate.
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

  // A Firestore document can be restored with its document ID.
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

  // Missing fields are replaced with safe display values.
  test('uses safe defaults for incomplete Firestore data', () {
    final location = SavedLocation.fromMap(
      id: 'location-3',
      map: {},
    );

    expect(location.name, 'Saved location');
    expect(location.address, '');
  });

  // The document ID belongs to Firestore, so it is not included in saved fields.
  test('does not include the id when converting to a map', () {
    const location = SavedLocation(id: 'abc', name: 'Home', address: 'Colombo');

    expect(location.toMap().containsKey('id'), isFalse);
  });

  // Additional fields from Firestore do not affect the location model.
  test('ignores fields that are not part of a saved location', () {
    final location = SavedLocation.fromMap(id: 'location-4', map: {'name': 'Library', 'address': 'Colombo', 'extra': 'ignored'});

    expect(location.name, 'Library');
    expect(location.address, 'Colombo');
  });

  // Saved name and address values should be restored without changes.
  test('keeps saved name and address values', () {
    const location = SavedLocation(id: 'location-5', name: 'Work', address: 'Town Hall, Colombo');

    final restored = SavedLocation.fromMap(id: location.id, map: location.toMap());

    expect(restored.id, location.id);
    expect(restored.name, location.name);
    expect(restored.address, location.address);
  });
}

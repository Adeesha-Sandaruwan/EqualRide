import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/saved_location.dart';

class SavedLocationService {
  SavedLocationService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _locations(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('savedLocations');
  }

  Stream<List<SavedLocation>> watchLocations(String userId) {
    return _locations(userId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (document) => SavedLocation.fromMap(
                  id: document.id,
                  map: document.data(),
                ),
              )
              .toList(),
        );
  }

  Future<void> addLocation({
    required String userId,
    required String name,
    required String address,
  }) async {
    await _locations(userId).add({
      'name': name.trim(),
      'address': address.trim(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateLocation({
    required String userId,
    required SavedLocation location,
    required String name,
    required String address,
  }) async {
    await _locations(userId).doc(location.id).update({
      'name': name.trim(),
      'address': address.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteLocation({
    required String userId,
    required String locationId,
  }) {
    return _locations(userId).doc(locationId).delete();
  }
}
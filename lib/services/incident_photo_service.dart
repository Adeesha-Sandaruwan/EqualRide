// File: incident_photo_service.dart
//
// Picks an incident photo (camera or gallery), shrinks it, and base64-encodes
// it for Firestore. Rejects photos too large for a document and safely
// decodes stored photos for display.

import 'dart:convert';
import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

class IncidentPhotoException implements Exception {
  const IncidentPhotoException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// A compressed incident photo ready to be stored in Firestore.
class IncidentPhoto {
  IncidentPhoto(this.bytes) : base64 = base64Encode(bytes);

  final Uint8List bytes;

  /// Plain base64 (no "data:" prefix), the value saved in Firestore.
  final String base64;
}

/// Picks a photo, shrinks it, and encodes it as base64.
///
/// Firestore documents are limited to 1 MiB, so photos are resized and
/// recompressed by the picker and rejected if they are still too large.
class IncidentPhotoService {
  IncidentPhotoService({ImagePicker? picker})
      : _picker = picker ?? ImagePicker();

  /// Longest side in pixels after resizing.
  static const maxDimension = 1024.0;
  static const jpegQuality = 70;

  /// Maximum base64 length that is saved. About 300 KB of image data.
  static const maxBase64Length = 400000;

  final ImagePicker _picker;

  Future<IncidentPhoto?> pick(ImageSource source) async {
    final XFile? file;
    try {
      file = await _picker.pickImage(
        source: source,
        maxWidth: maxDimension,
        maxHeight: maxDimension,
        imageQuality: jpegQuality,
      );
    } catch (_) {
      throw const IncidentPhotoException(
        'Could not open the camera or gallery. Check app permissions.',
      );
    }
    if (file == null) return null;

    final bytes = await file.readAsBytes();
    return fromBytes(bytes);
  }

  /// Validates [bytes] and wraps them. Exposed for tests.
  static IncidentPhoto fromBytes(Uint8List bytes) {
    if (bytes.isEmpty) {
      throw const IncidentPhotoException('That photo could not be read.');
    }
    final photo = IncidentPhoto(bytes);
    if (photo.base64.length > maxBase64Length) {
      throw const IncidentPhotoException(
        'That photo is too large. Please choose a smaller one.',
      );
    }
    return photo;
  }

  /// Decodes a stored base64 string, or returns null when missing or corrupt.
  static Uint8List? tryDecode(String? value) {
    if (value == null || value.isEmpty) return null;
    try {
      final bytes = base64Decode(value);
      return bytes.isEmpty ? null : bytes;
    } catch (_) {
      return null;
    }
  }
}

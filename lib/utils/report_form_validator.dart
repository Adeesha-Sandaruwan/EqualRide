/// Validation rules for the community report submission form.
///
/// Extracted into a standalone class so the logic can be unit-tested
/// independently of any Flutter widget tree.
class ReportFormValidator {
  const ReportFormValidator._();

  // ── Constants ────────────────────────────────────────────────────────────

  /// Minimum characters required in the description field.
  static const int descriptionMinLength = 15;

  /// Maximum characters allowed in the description field.
  static const int descriptionMaxLength = 1000;

  /// Maximum characters allowed in the location field.
  static const int locationMaxLength = 200;

  /// Maximum characters allowed in the bus-number field.
  static const int busNumberMaxLength = 10;

  // ── Issue type ───────────────────────────────────────────────────────────

  /// Returns an error string if [value] is null, otherwise null.
  static String? issueType(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please select an issue type.';
    }
    return null;
  }

  // ── Location ─────────────────────────────────────────────────────────────

  /// Validates the location field.
  ///
  /// Rules:
  /// - Must not be empty.
  /// - Must be at most [locationMaxLength] characters.
  /// - Must contain at least one letter (rejects pure punctuation/numbers).
  static String? location(String? value) {
    final text = value?.trim() ?? '';

    if (text.isEmpty) {
      return 'Please enter the location where you observed the issue.';
    }

    if (text.length > locationMaxLength) {
      return 'Location is too long (max $locationMaxLength characters).';
    }

    // Must contain at least one alphabetic character.
    if (!RegExp(r'[a-zA-Z]').hasMatch(text)) {
      return 'Please enter a recognisable location name.';
    }

    return null;
  }

  // ── Bus number ────────────────────────────────────────────────────────────

  /// Validates the optional bus-number field.
  ///
  /// The field is optional — an empty value is always valid.
  /// If a value is provided it must be alphanumeric (e.g. "138", "138A").
  static String? busNumber(String? value) {
    final text = value?.trim() ?? '';

    if (text.isEmpty) return null; // optional field

    if (text.length > busNumberMaxLength) {
      return 'Bus number is too long (max $busNumberMaxLength characters).';
    }

    if (!RegExp(r'^[a-zA-Z0-9\s\-/]+$').hasMatch(text)) {
      return 'Bus number should only contain letters, numbers, hyphens or slashes.';
    }

    return null;
  }

  // ── Description ──────────────────────────────────────────────────────────

  /// Validates the description field.
  ///
  /// Rules:
  /// - Must not be empty.
  /// - Must be at least [descriptionMinLength] characters (encourages detail).
  /// - Must be at most [descriptionMaxLength] characters.
  /// - Must not be composed entirely of repeated single characters
  ///   (catches "aaaaaaa" spam).
  static String? description(String? value) {
    final text = value?.trim() ?? '';

    if (text.isEmpty) {
      return 'Please describe what you saw or experienced.';
    }

    if (text.length < descriptionMinLength) {
      return 'A bit more detail helps others — please write at least '
          '$descriptionMinLength characters.';
    }

    if (text.length > descriptionMaxLength) {
      return 'Description is too long (max $descriptionMaxLength characters). '
          'Please summarise your report.';
    }

    // Reject strings that are just one character repeated (e.g. "aaaaaaaaaa").
    if (RegExp(r'^(.)\1+$').hasMatch(text)) {
      return 'Please enter a meaningful description.';
    }

    return null;
  }

  // ── Search query ─────────────────────────────────────────────────────────

  /// Returns true if [report] matches [query] on issue type, location, or
  /// description (case-insensitive). Always returns true when query is empty.
  static bool matchesSearch({
    required String issueType,
    required String location,
    required String description,
    required String query,
  }) {
    if (query.isEmpty) return true;
    final q = query.toLowerCase();
    return issueType.toLowerCase().contains(q) ||
        location.toLowerCase().contains(q) ||
        description.toLowerCase().contains(q);
  }
}

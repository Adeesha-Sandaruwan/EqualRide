import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/community_report.dart';

class AccessibilityReportDraft {
  const AccessibilityReportDraft({
    required this.issueType,
    required this.description,
    required this.location,
    this.impactLevel = CommunityReport.defaultImpactLevel,
  });

  final String? issueType;
  final String description;
  final String location;
  final String impactLevel;

  bool get hasContent =>
      (issueType?.trim().isNotEmpty ?? false) ||
      description.trim().isNotEmpty ||
      location.trim().isNotEmpty;

  Map<String, Object?> toJson() => {
    'version': 1,
    'issueType': issueType,
    'description': description,
    'location': location,
    'impactLevel': impactLevel,
  };

  factory AccessibilityReportDraft.fromJson(Map<String, dynamic> json) {
    if (json['version'] != 1 ||
        (json['issueType'] != null && json['issueType'] is! String) ||
        json['description'] is! String ||
        json['location'] is! String ||
        (json['impactLevel'] != null && json['impactLevel'] is! String)) {
      throw const FormatException('Saved report draft has an invalid format.');
    }

    return AccessibilityReportDraft(
      issueType: json['issueType'] as String?,
      description: json['description'] as String,
      location: json['location'] as String,
      impactLevel: CommunityReport.impactLevelDescriptions
              .containsKey(json['impactLevel'])
          ? json['impactLevel'] as String
          : CommunityReport.defaultImpactLevel,
    );
  }
}

class AccessibilityReportDraftService {
  AccessibilityReportDraftService({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  static const _draftKey = 'accessibility_report_draft_v1';

  final SharedPreferencesAsync _preferences;

  Future<AccessibilityReportDraft?> loadDraft() async {
    final encodedDraft = await _preferences.getString(_draftKey);
    if (encodedDraft == null) return null;

    try {
      final decoded = jsonDecode(encodedDraft);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException(
          'Saved report draft has an invalid format.',
        );
      }

      final draft = AccessibilityReportDraft.fromJson(decoded);
      if (!draft.hasContent) {
        await clearDraft();
        return null;
      }
      return draft;
    } on FormatException {
      await clearDraft();
      rethrow;
    }
  }

  Future<void> saveDraft(AccessibilityReportDraft draft) async {
    if (!draft.hasContent) {
      await clearDraft();
      return;
    }
    await _preferences.setString(_draftKey, jsonEncode(draft.toJson()));
  }

  Future<void> clearDraft() => _preferences.remove(_draftKey);
}

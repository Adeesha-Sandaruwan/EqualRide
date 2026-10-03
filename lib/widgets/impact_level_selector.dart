import 'package:flutter/material.dart';

import '../models/community_report.dart';
import '../theme/app_theme.dart';

class ImpactLevelSelector extends StatelessWidget {
  const ImpactLevelSelector({
    super.key,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  final String value;
  final ValueChanged<String> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final description =
        CommunityReport.impactLevelDescriptions[value] ??
        CommunityReport.impactLevelDescriptions[CommunityReport
            .defaultImpactLevel]!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Access impact',
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: CommunityReport.impactLevelDescriptions.keys.map((level) {
            return ChoiceChip(
              label: Text(level),
              selected: value == level,
              onSelected: enabled ? (_) => onChanged(level) : null,
            );
          }).toList(),
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
        ),
      ],
    );
  }
}

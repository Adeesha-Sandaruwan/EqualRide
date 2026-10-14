import 'package:flutter/material.dart';

import '../models/community_report.dart';
import '../theme/app_theme.dart';
import 'report_impact_badge.dart';

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

  static IconData iconFor(String level) {
    switch (level) {
      case 'Low':
        return Icons.signal_cellular_alt_1_bar_rounded;
      case 'High':
        return Icons.signal_cellular_alt_rounded;
      case 'Critical':
        return Icons.block_rounded;
      default:
        return Icons.signal_cellular_alt_2_bar_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final selected = CommunityReport.impactLevelDescriptions.containsKey(value)
        ? value
        : CommunityReport.defaultImpactLevel;
    final description = CommunityReport.impactLevelDescriptions[selected]!;
    final selectedColor = ReportImpactBadge.colorFor(selected);

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
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            const gap = 10.0;
            final tileWidth = (constraints.maxWidth - gap) / 2;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: CommunityReport.impactLevelDescriptions.keys.map((
                level,
              ) {
                return SizedBox(
                  width: tileWidth,
                  child: _ImpactTile(
                    level: level,
                    selected: selected == level,
                    onTap: enabled ? () => onChanged(level) : null,
                  ),
                );
              }).toList(),
            );
          },
        ),
        const SizedBox(height: 10),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: selectedColor.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: selectedColor.withValues(alpha: 0.35)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(iconFor(selected), color: selectedColor, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  description,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ImpactTile extends StatelessWidget {
  const _ImpactTile({
    required this.level,
    required this.selected,
    required this.onTap,
  });

  final String level;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = ReportImpactBadge.colorFor(level);
    final dimmed = onTap == null;

    return Semantics(
      button: true,
      selected: selected,
      enabled: !dimmed,
      label: '$level impact',
      child: Opacity(
        opacity: dimmed ? 0.5 : 1,
        child: Material(
          color: selected
              ? color.withValues(alpha: 0.18)
              : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onTap,
            child: Container(
              constraints: const BoxConstraints(minHeight: 52),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: selected ? color : color.withValues(alpha: 0.30),
                  width: selected ? 1.6 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    ImpactLevelSelector.iconFor(level),
                    color: color,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      level,
                      style: TextStyle(
                        color: selected ? color : AppTheme.textPrimary,
                        fontWeight: selected
                            ? FontWeight.w800
                            : FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  if (selected)
                    Icon(Icons.check_circle_rounded, color: color, size: 18),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

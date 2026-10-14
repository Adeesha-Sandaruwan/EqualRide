import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../../../widgets/glass_panel.dart';

/// A single headline number with an icon, a label and an animated count-up.
class KpiCard extends StatelessWidget {
  const KpiCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.suffix = '',
    this.caption,
    this.accent = AppTheme.aqua,
    this.semanticsLabel,
  });

  final IconData icon;
  final String label;
  final num value;
  final String suffix;
  final String? caption;
  final Color accent;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticsLabel ??
          '$label: ${_format(value)}$suffix${caption == null ? '' : ', $caption'}',
      excludeSemantics: true,
      child: GlassPanel(
        padding: const EdgeInsets.all(16),
        borderRadius: 20,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: accent, size: 20),
            ),
            const SizedBox(height: 14),
            TweenAnimationBuilder<double>(
              tween: Tween(end: value.toDouble()),
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOutCubic,
              builder: (context, animated, _) {
                return FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${_format(animated)}$suffix',
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (caption != null) ...[
              const SizedBox(height: 2),
              Text(
                caption!,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _format(num number) => number.round().toString();
}

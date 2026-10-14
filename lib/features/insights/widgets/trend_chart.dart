// File: trend_chart.dart
//
// Custom-painted line chart of reports per day, with a text description for
// screen readers.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../../../widgets/glass_panel.dart';
import '../models/insight_summary.dart';

/// Area/line chart of reports created per day.
class TrendChart extends StatelessWidget {
  const TrendChart({super.key, required this.points});

  final List<TrendPoint> points;

  static String describe(List<TrendPoint> points) {
    if (points.isEmpty) return 'No trend data.';
    final total = points.fold<int>(0, (sum, p) => sum + p.count);
    final peak = points.reduce((a, b) => b.count > a.count ? b : a);
    if (total == 0) return 'No reports in this period.';
    return '$total reports in ${points.length} days. '
        'Busiest day ${_date(peak.date)} with ${peak.count}.';
  }

  static String _date(DateTime d) => '${d.day}/${d.month}';

  @override
  Widget build(BuildContext context) {
    final total = points.fold<int>(0, (sum, p) => sum + p.count);

    return GlassPanel(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Semantics(
        label: 'Reports per day. ${describe(points)}',
        excludeSemantics: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Reports per day',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  '$total total',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 150,
              width: double.infinity,
              child: total == 0
                  ? const Center(
                      child: Text(
                        'No reports in this period',
                        style: TextStyle(color: AppTheme.textSecondary),
                      ),
                    )
                  : TweenAnimationBuilder<double>(
                      key: ValueKey(points.length),
                      tween: Tween(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 700),
                      curve: Curves.easeOutCubic,
                      builder: (context, progress, _) {
                        return CustomPaint(
                          painter: _TrendPainter(points, progress),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 8),
            if (points.isNotEmpty)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _date(points.first.date),
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                  Text(
                    _date(points.last.date),
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _TrendPainter extends CustomPainter {
  _TrendPainter(this.points, this.progress);

  final List<TrendPoint> points;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final maxCount = math.max(1, points.map((p) => p.count).reduce(math.max));
    const topPad = 8.0;
    final chartHeight = size.height - topPad;

    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.10)
      ..strokeWidth = 1;
    for (var i = 0; i <= 3; i++) {
      final y = topPad + chartHeight * i / 3;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final stepX = points.length == 1 ? 0.0 : size.width / (points.length - 1);
    Offset at(int i) {
      final ratio = points[i].count / maxCount;
      return Offset(i * stepX, topPad + chartHeight * (1 - ratio * progress));
    }

    final line = Path()..moveTo(at(0).dx, at(0).dy);
    for (var i = 1; i < points.length; i++) {
      final prev = at(i - 1);
      final current = at(i);
      final midX = (prev.dx + current.dx) / 2;
      line.cubicTo(midX, prev.dy, midX, current.dy, current.dx, current.dy);
    }

    final area = Path.from(line)
      ..lineTo(at(points.length - 1).dx, size.height)
      ..lineTo(at(0).dx, size.height)
      ..close();

    canvas.drawPath(
      area,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.teal.withValues(alpha: 0.40),
            AppTheme.teal.withValues(alpha: 0.02),
          ],
        ).createShader(Offset.zero & size),
    );

    canvas.drawPath(
      line,
      Paint()
        ..color = AppTheme.aqua
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );

    final peakIndex = points.indexWhere((p) => p.count == maxCount);
    final peak = at(peakIndex);
    canvas.drawCircle(peak, 5, Paint()..color = AppTheme.navy);
    canvas.drawCircle(
      peak,
      5,
      Paint()
        ..color = AppTheme.aqua
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );

    final label = TextPainter(
      text: TextSpan(
        text: '$maxCount',
        style: const TextStyle(
          color: AppTheme.textPrimary,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final labelX = (peak.dx - label.width / 2).clamp(
      0.0,
      size.width - label.width,
    );
    label.paint(canvas, Offset(labelX, math.max(0, peak.dy - 20)));
  }

  @override
  bool shouldRepaint(_TrendPainter old) =>
      old.points != points || old.progress != progress;
}

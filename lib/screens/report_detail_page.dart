import 'package:flutter/material.dart';

import '../models/community_report.dart';
import '../services/accessibility_report_service.dart';
import '../theme/app_theme.dart';
import '../widgets/equal_ride_background.dart';
import '../widgets/glass_panel.dart';

// ─── Helpers (kept local so the detail page is self-contained) ───────────────

String _timeAgo(DateTime? dateTime) {
  if (dateTime == null) return 'Just now';
  final now = DateTime.now();
  final diff = now.difference(dateTime);
  if (diff.inSeconds < 60) return 'Just now';
  if (diff.inMinutes < 60) {
    final m = diff.inMinutes;
    return '$m ${m == 1 ? 'minute' : 'minutes'} ago';
  }
  if (diff.inHours < 24) {
    final h = diff.inHours;
    return '$h ${h == 1 ? 'hour' : 'hours'} ago';
  }
  if (diff.inDays == 1) return 'Yesterday';
  if (diff.inDays < 7) return '${diff.inDays} days ago';
  final months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${months[dateTime.month - 1]} ${dateTime.day}, ${dateTime.year}';
}

Color _statusColor(String status) {
  switch (status) {
    case 'Resolved':
      return const Color(0xFF66BB6A);
    case 'In Progress':
      return const Color(0xFF64B5F6);
    default:
      return const Color(0xFFFFB74D);
  }
}

IconData _statusIcon(String status) {
  switch (status) {
    case 'Resolved':
      return Icons.check_circle_rounded;
    case 'In Progress':
      return Icons.autorenew_rounded;
    default:
      return Icons.hourglass_top_rounded;
  }
}

Color _issueIconColor(String issueType) {
  switch (issueType) {
    case 'Wheelchair access':
      return const Color(0xFF64B5F6);
    case 'Ramp unavailable':
      return const Color(0xFFFFB74D);
    case 'Lift unavailable':
      return const Color(0xFFE57373);
    case 'Step-free access issue':
      return const Color(0xFFBA68C8);
    case 'Crowding':
      return const Color(0xFF4DD0E1);
    case 'Accessibility information incorrect':
      return const Color(0xFFFFD54F);
    default:
      return AppTheme.aqua;
  }
}

IconData _issueIcon(String issueType) {
  switch (issueType) {
    case 'Wheelchair access':
      return Icons.accessible_rounded;
    case 'Ramp unavailable':
      return Icons.stairs_rounded;
    case 'Lift unavailable':
      return Icons.elevator_rounded;
    case 'Step-free access issue':
      return Icons.do_not_step_rounded;
    case 'Crowding':
      return Icons.groups_rounded;
    case 'Accessibility information incorrect':
      return Icons.info_outline_rounded;
    default:
      return Icons.report_problem_rounded;
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  Report Detail Page
// ═══════════════════════════════════════════════════════════════════════════════

/// Full-screen detail view for a single [CommunityReport].
///
/// Shows the complete description, location, timestamps, current status,
/// upvote count, and lets the viewer mark the report as helpful.
class ReportDetailPage extends StatefulWidget {
  const ReportDetailPage({super.key, required this.report});

  final CommunityReport report;

  @override
  State<ReportDetailPage> createState() => _ReportDetailPageState();
}

class _ReportDetailPageState extends State<ReportDetailPage>
    with SingleTickerProviderStateMixin {
  final _service = AccessibilityReportService();

  late CommunityReport _report;
  bool _isUpvoting = false;
  bool _hasUpvoted = false; // tracks whether this session already upvoted

  late final AnimationController _fadeCtrl;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _report = widget.report;
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
    _fade = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _upvote() async {
    if (_isUpvoting || _hasUpvoted) return;
    setState(() => _isUpvoting = true);
    try {
      await _service.upvoteReport(reportId: _report.id);
      if (!mounted) return;
      setState(() {
        _hasUpvoted = true;
        _report = _report.copyWith(upvoteCount: _report.upvoteCount + 1);
      });
    } on AccessibilityReportException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _isUpvoting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = _report;
    final iconColor = _issueIconColor(r.issueType);
    final statusColor = _statusColor(r.status);

    return Scaffold(
      body: EqualRideBackground(
        child: SafeArea(
          child: FadeTransition(
            opacity: _fade,
            child: CustomScrollView(
              slivers: [
                // ── App bar ──
                SliverAppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  leading: IconButton(
                    tooltip: 'Back',
                    icon: const Icon(Icons.arrow_back_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                  title: const Text('Report Details'),
                  centerTitle: false,
                  pinned: true,
                ),

                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // ── Issue type header ──
                      GlassPanel(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              height: 52,
                              width: 52,
                              decoration: BoxDecoration(
                                color: iconColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(
                                _issueIcon(r.issueType),
                                color: iconColor,
                                size: 26,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    r.issueType,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(fontSize: 18),
                                  ),
                                  const SizedBox(height: 6),
                                  // Category chip
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppTheme.teal.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: AppTheme.teal.withOpacity(0.3),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          r.category == 'bus'
                                              ? Icons.directions_bus_rounded
                                              : Icons.train_rounded,
                                          size: 14,
                                          color: AppTheme.teal,
                                        ),
                                        const SizedBox(width: 5),
                                        Text(
                                          r.category == 'bus'
                                              ? 'On the bus'
                                              : 'Station / road',
                                          style: const TextStyle(
                                            color: AppTheme.teal,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // ── Status + upvotes row ──
                      Row(
                        children: [
                          // Status card
                          Expanded(
                            child: GlassPanel(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Status',
                                    style: TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.4,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(
                                        _statusIcon(r.status),
                                        color: statusColor,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        r.status,
                                        style: TextStyle(
                                          color: statusColor,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Upvotes card
                          Expanded(
                            child: GlassPanel(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Helpful votes',
                                    style: TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.4,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.thumb_up_alt_rounded,
                                        color: _hasUpvoted
                                            ? AppTheme.teal
                                            : AppTheme.textSecondary,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        '${r.upvoteCount}',
                                        style: TextStyle(
                                          color: _hasUpvoted
                                              ? AppTheme.teal
                                              : AppTheme.textPrimary,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // ── Location & time ──
                      GlassPanel(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            _DetailRow(
                              icon: Icons.location_on_outlined,
                              iconColor: AppTheme.aqua,
                              label: 'Location',
                              value: r.location,
                            ),
                            if (r.busNumber != null &&
                                r.busNumber!.isNotEmpty) ...[
                              const Divider(
                                height: 24,
                                color: Colors.white12,
                              ),
                              _DetailRow(
                                icon: Icons.directions_bus_rounded,
                                iconColor: AppTheme.teal,
                                label: 'Bus number',
                                value: r.busNumber!,
                              ),
                            ],
                            const Divider(height: 24, color: Colors.white12),
                            _DetailRow(
                              icon: Icons.access_time_rounded,
                              iconColor: AppTheme.aqua,
                              label: 'Reported',
                              value: _timeAgo(r.createdAt),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // ── Full description ──
                      GlassPanel(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Description',
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.4,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              r.description.isEmpty
                                  ? 'No description provided.'
                                  : r.description,
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 15,
                                height: 1.6,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),

                      // ── Mark as helpful button ──
                      FilledButton.icon(
                        onPressed:
                            (_isUpvoting || _hasUpvoted) ? null : _upvote,
                        style: FilledButton.styleFrom(
                          backgroundColor: _hasUpvoted
                              ? AppTheme.teal.withOpacity(0.4)
                              : AppTheme.teal,
                          foregroundColor: AppTheme.navy,
                          minimumSize: const Size.fromHeight(52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        icon: _isUpvoting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: AppTheme.navy,
                                ),
                              )
                            : Icon(
                                _hasUpvoted
                                    ? Icons.thumb_up_alt_rounded
                                    : Icons.thumb_up_alt_outlined,
                              ),
                        label: Text(
                          _hasUpvoted
                              ? 'Marked as helpful'
                              : 'Mark as helpful',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Small helper widget ──────────────────────────────────────────────────────

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

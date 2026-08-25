import 'dart:async';

import 'package:flutter/material.dart';

import '../models/community_report.dart';
import '../services/accessibility_report_service.dart';
import '../theme/app_theme.dart';
import '../widgets/equal_ride_background.dart';
import '../widgets/glass_panel.dart';

// ─── Time-ago helper ────────────────────────────────────────────────────────

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

// ─── Issue-type icon / colour mapping ───────────────────────────────────────

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

Color _issueIconColor(String issueType) {
  switch (issueType) {
    case 'Wheelchair access':
      return const Color(0xFF64B5F6); // blue
    case 'Ramp unavailable':
      return const Color(0xFFFFB74D); // amber
    case 'Lift unavailable':
      return const Color(0xFFE57373); // red
    case 'Step-free access issue':
      return const Color(0xFFBA68C8); // purple
    case 'Crowding':
      return const Color(0xFF4DD0E1); // cyan
    case 'Accessibility information incorrect':
      return const Color(0xFFFFD54F); // yellow
    default:
      return AppTheme.aqua;
  }
}

// ─── Status badge colours ───────────────────────────────────────────────────

Color _statusBackground(String status) {
  switch (status) {
    case 'Resolved':
      return const Color(0xFF66BB6A);
    case 'In Progress':
      return AppTheme.teal;
    default: // Pending
      return const Color(0xFFFFB74D);
  }
}

Color _statusForeground(String status) {
  switch (status) {
    case 'Resolved':
    case 'In Progress':
      return const Color(0xFF0A1E2C);
    default:
      return const Color(0xFF3E2723);
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  Community Reports Page
// ═══════════════════════════════════════════════════════════════════════════════

class CommunityReportsPage extends StatefulWidget {
  const CommunityReportsPage({super.key});

  @override
  State<CommunityReportsPage> createState() => _CommunityReportsPageState();
}

class _CommunityReportsPageState extends State<CommunityReportsPage>
    with SingleTickerProviderStateMixin {
  final _reportService = AccessibilityReportService();
  late final AnimationController _headerAnimCtrl;
  late final Animation<double> _headerFade;
  late final Animation<Offset> _headerSlide;

  @override
  void initState() {
    super.initState();
    _headerAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _headerFade = CurvedAnimation(
      parent: _headerAnimCtrl,
      curve: Curves.easeOut,
    );
    _headerSlide = Tween<Offset>(
      begin: const Offset(0, -0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _headerAnimCtrl,
      curve: Curves.easeOutCubic,
    ));
    _headerAnimCtrl.forward();
  }

  @override
  void dispose() {
    _headerAnimCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: EqualRideBackground(
        child: SafeArea(
          child: Column(
            children: [
              // ── Header ──
              SlideTransition(
                position: _headerSlide,
                child: FadeTransition(
                  opacity: _headerFade,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Row(
                      children: [
                        if (Navigator.canPop(context))
                          IconButton(
                            tooltip: 'Back',
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.arrow_back_rounded),
                          ),
                        const SizedBox(width: 4),
                        Container(
                          height: 44,
                          width: 44,
                          decoration: BoxDecoration(
                            color: AppTheme.teal.withOpacity(0.16),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.forum_rounded,
                            color: AppTheme.teal,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Community Reports',
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              FadeTransition(
                opacity: _headerFade,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Accessibility issues reported by the community',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // ── Content ──
              Expanded(
                child: StreamBuilder<List<CommunityReport>>(
                  stream: _reportService.getReportsStream(),
                  builder: (context, snapshot) {
                    // ─ Loading ─
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const _LoadingState();
                    }

                    // ─ Error ─
                    if (snapshot.hasError) {
                      return _ErrorState(
                        message: snapshot.error.toString(),
                        onRetry: () => setState(() {}),
                      );
                    }

                    final reports = snapshot.data ?? [];

                    // ─ Empty ─
                    if (reports.isEmpty) {
                      return const _EmptyState();
                    }

                    // ─ Data ─
                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
                      itemCount: reports.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        return _ReportCard(
                          report: reports[index],
                          animDelay: index,
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  Loading State
// ═══════════════════════════════════════════════════════════════════════════════

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 48,
            width: 48,
            child: CircularProgressIndicator(
              color: AppTheme.teal,
              strokeWidth: 3,
              backgroundColor: AppTheme.teal.withOpacity(0.15),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Loading community reports…',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  Empty State
// ═══════════════════════════════════════════════════════════════════════════════

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: GlassPanel(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 72,
                width: 72,
                decoration: BoxDecoration(
                  color: AppTheme.teal.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.sentiment_satisfied_alt_rounded,
                  color: AppTheme.teal,
                  size: 40,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'No reports yet',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              const Text(
                'The community hasn\'t reported any\naccessibility issues yet. That\'s great!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  Error State
// ═══════════════════════════════════════════════════════════════════════════════

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: GlassPanel(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 72,
                width: 72,
                decoration: BoxDecoration(
                  color: const Color(0xFFE57373).withOpacity(0.14),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.wifi_off_rounded,
                  color: Color(0xFFE57373),
                  size: 36,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Something went wrong',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'We couldn\'t load community reports.\nPlease check your connection and try again.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 22),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try again'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  Report Card
// ═══════════════════════════════════════════════════════════════════════════════

class _ReportCard extends StatefulWidget {
  const _ReportCard({
    required this.report,
    required this.animDelay,
  });

  final CommunityReport report;
  final int animDelay;

  @override
  State<_ReportCard> createState() => _ReportCardState();
}

class _ReportCardState extends State<_ReportCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    // Stagger: each card fades in after the previous
    Future.delayed(
      Duration(milliseconds: 80 * widget.animDelay),
      () {
        if (mounted) _ctrl.forward();
      },
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.report;
    final iconColor = _issueIconColor(r.issueType);

    return SlideTransition(
      position: _slide,
      child: FadeTransition(
        opacity: _fade,
        child: GlassPanel(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Issue type row ──
              Row(
                children: [
                  Container(
                    height: 42,
                    width: 42,
                    decoration: BoxDecoration(
                      color: iconColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _issueIcon(r.issueType),
                      color: iconColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      r.issueType,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontSize: 16,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // ── Status Badge ──
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: _statusBackground(r.status),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      r.status,
                      style: TextStyle(
                        color: _statusForeground(r.status),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // ── Location ──
              Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    color: AppTheme.aqua,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      r.location,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // ── Time ──
              Row(
                children: [
                  const Icon(
                    Icons.access_time_rounded,
                    color: AppTheme.aqua,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _timeAgo(r.createdAt),
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),

              // ── Description ──
              if (r.description.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    r.description,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13.5,
                      height: 1.45,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

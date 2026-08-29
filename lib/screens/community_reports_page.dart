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
      return const Color(0xFF66BB6A); // green
    case 'In Progress':
      return const Color(0xFF64B5F6); // blue
    default: // Pending
      return const Color(0xFFFFB74D); // amber
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

  // Incrementing this causes the StreamBuilder key to change, which disposes
  // the old stream subscription and opens a fresh one — the only reliable way
  // to "retry" a stream in Flutter.
  int _streamKey = 0;

  void _retry() => setState(() => _streamKey++);

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
                  key: ValueKey(_streamKey),
                  stream: _reportService.getReportsStream(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const _LoadingState();
                    }
                    if (snapshot.hasError) {
                      final err = snapshot.error;
                      final String code = err is AccessibilityReportException
                          ? err.message
                          : 'unknown';
                      debugPrint('[CommunityReports] Firestore error: $err');
                      return _ErrorState(
                        errorCode: code,
                        rawError: err.toString(),
                        onRetry: _retry,
                      );
                    }
                    final reports = snapshot.data ?? [];
                    if (reports.isEmpty) {
                      return const _EmptyState();
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                      itemCount: reports.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 14),
                      itemBuilder: (context, index) => _ReportCard(
                        report: reports[index],
                        animDelay: index,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      // ── FAB ──
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openSubmitForm(context),
        backgroundColor: AppTheme.teal,
        foregroundColor: AppTheme.navy,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Report issue',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
    );
  }

  void _openSubmitForm(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SubmitReportSheet(
        onSubmitted: () => setState(() => _streamKey++),
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

class _EmptyState extends StatefulWidget {
  const _EmptyState();

  @override
  State<_EmptyState> createState() => _EmptyStateState();
}

class _EmptyStateState extends State<_EmptyState> {
  bool _isSeeding = false;

  Future<void> _seedDemoData() async {
    setState(() => _isSeeding = true);
    try {
      await AccessibilityReportService().seedDemoReports();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not load demo data: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSeeding = false);
    }
  }

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
                'The community hasn\'t reported any\naccessibility issues yet.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 22),
              FilledButton.icon(
                onPressed: _isSeeding ? null : _seedDemoData,
                icon: _isSeeding
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: AppTheme.navy,
                        ),
                      )
                    : const Icon(Icons.add_circle_outline_rounded),
                label: Text(_isSeeding ? 'Loading demo data...' : 'Load demo reports'),
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
    required this.errorCode,
    required this.rawError,
    required this.onRetry,
  });

  final String errorCode;
  final String rawError;
  final VoidCallback onRetry;

  ({String title, String body, IconData icon, Color iconColor}) get _content {
    switch (errorCode) {
      case 'permission-denied':
        return (
          title: 'Access denied',
          body: 'Firestore security rules are blocking reads.\n'
              'Go to Firebase Console → Firestore → Rules and allow reads for authenticated users.',
          icon: Icons.lock_outline_rounded,
          iconColor: const Color(0xFFFFB74D),
        );
      case 'missing-index':
        return (
          title: 'Setting up reports',
          body: 'The database index is still being built.\n'
              'This only takes a minute — tap Try again shortly.',
          icon: Icons.hourglass_top_rounded,
          iconColor: const Color(0xFF64B5F6),
        );
      case 'network':
        return (
          title: 'No connection',
          body: 'Check your internet connection and tap Try again.',
          icon: Icons.wifi_off_rounded,
          iconColor: const Color(0xFFE57373),
        );
      default:
        return (
          title: 'Something went wrong',
          body: 'We couldn\'t load community reports.\n'
              'Please check your connection and try again.',
          icon: Icons.wifi_off_rounded,
          iconColor: const Color(0xFFE57373),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _content;
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
                  color: c.iconColor.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  c.icon,
                  color: c.iconColor,
                  size: 36,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                c.title,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                c.body,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                  height: 1.55,
                ),
              ),
              // ── Raw error detail (debug) ──
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  rawError,
                  style: const TextStyle(
                    color: Color(0xFFEF9A9A),
                    fontSize: 11,
                    fontFamily: 'monospace',
                    height: 1.5,
                  ),
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
                  // ── Status Badge (tappable) ──
                  _StatusBadge(report: r),
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

// ═══════════════════════════════════════════════════════════════════════════════
//  Status Badge — tappable, cycles Pending → In Progress → Resolved
// ═══════════════════════════════════════════════════════════════════════════════

class _StatusBadge extends StatefulWidget {
  const _StatusBadge({required this.report});
  final CommunityReport report;

  @override
  State<_StatusBadge> createState() => _StatusBadgeState();
}

class _StatusBadgeState extends State<_StatusBadge> {
  bool _isUpdating = false;

  static const _statuses = ['Pending', 'In Progress', 'Resolved'];

  static const _statusIcons = {
    'Pending': Icons.hourglass_top_rounded,
    'In Progress': Icons.autorenew_rounded,
    'Resolved': Icons.check_circle_rounded,
  };

  Future<void> _pickStatus(BuildContext context) async {
    final current = widget.report.status;
    // Capture before any async gap
    final messenger = ScaffoldMessenger.of(context);
    final RenderBox box = context.findRenderObject() as RenderBox;
    final offset = box.localToGlobal(Offset.zero);

    final chosen = await showMenu<String>(
      context: context,
      color: const Color(0xFF0E2A45),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
      ),
      position: RelativeRect.fromLTRB(
        offset.dx,
        offset.dy + box.size.height + 4,
        offset.dx + box.size.width,
        0,
      ),
      items: _statuses.map((s) {
        final isSelected = s == current;
        final bg = _statusBackground(s);
        return PopupMenuItem<String>(
          value: s,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: bg.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _statusIcons[s] ?? Icons.circle,
                  color: bg,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                s,
                style: TextStyle(
                  color: isSelected ? bg : AppTheme.textPrimary,
                  fontWeight:
                      isSelected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 14,
                ),
              ),
              if (isSelected) ...[
                const Spacer(),
                Icon(Icons.check_rounded, color: bg, size: 16),
              ],
            ],
          ),
        );
      }).toList(),
    );

    if (chosen == null || chosen == current || !mounted) return;

    setState(() => _isUpdating = true);
    try {
      await AccessibilityReportService().updateReportStatus(
        reportId: widget.report.id,
        newStatus: chosen,
      );
    } on AccessibilityReportException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.report.status;
    final bg = _statusBackground(status);
    final fg = _statusForeground(status);

    return GestureDetector(
      onTap: _isUpdating ? null : () => _pickStatus(context),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: _isUpdating
            ? SizedBox(
                height: 14,
                width: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: fg,
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    status,
                    style: TextStyle(
                      color: fg,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_drop_down_rounded,
                    color: fg,
                    size: 14,
                  ),
                ],
              ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  Submit Report Bottom Sheet
// ═══════════════════════════════════════════════════════════════════════════════

class _SubmitReportSheet extends StatefulWidget {
  const _SubmitReportSheet({required this.onSubmitted});

  /// Called after a successful submission so the feed can refresh.
  final VoidCallback onSubmitted;

  @override
  State<_SubmitReportSheet> createState() => _SubmitReportSheetState();
}

class _SubmitReportSheetState extends State<_SubmitReportSheet> {
  final _formKey = GlobalKey<FormState>();
  final _locationCtrl = TextEditingController();
  final _busNumberCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _service = AccessibilityReportService();

  String? _issueType;
  // 'bus' | 'road' — controls whether bus-number field shows
  String _category = 'bus';
  bool _isSubmitting = false;

  // Grouped issue types per category
  static const _busTypes = [
    'Ramp unavailable',
    'Wheelchair space blocked',
    'Broken seat or handrail',
    'No audio announcements',
    'Bus overcrowding',
    'Unsafe driving',
    'Driver behaviour',
    'Other',
  ];

  static const _roadTypes = [
    'Lift unavailable',
    'Step-free access issue',
    'Damaged pavement / road',
    'Missing tactile paving',
    'Blocked pedestrian path',
    'Poor lighting',
    'Wheelchair access',
    'Accessibility information incorrect',
    'Crowding',
    'Other',
  ];

  List<String> get _issueTypes =>
      _category == 'bus' ? _busTypes : _roadTypes;

  @override
  void dispose() {
    _locationCtrl.dispose();
    _busNumberCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    _locationCtrl.text = _locationCtrl.text.trim();
    _busNumberCtrl.text = _busNumberCtrl.text.trim();
    _descriptionCtrl.text = _descriptionCtrl.text.trim();

    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSubmitting = true);
    try {
      await _service.submitCommunityReport(
        issueType: _issueType!,
        description: _descriptionCtrl.text,
        location: _locationCtrl.text,
        busNumber: _category == 'bus' ? _busNumberCtrl.text : null,
      );
      if (!mounted) return;
      Navigator.pop(context);
      widget.onSubmitted();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Report submitted — thank you!')),
      );
    } on AccessibilityReportException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not submit report. Please try again.')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Pad bottom by keyboard height so the form isn't hidden
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0E2A45),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, 24 + bottomInset),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Drag handle ──
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ── Title ──
              Row(
                children: [
                  Container(
                    height: 40,
                    width: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.teal.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.edit_note_rounded,
                      color: AppTheme.teal,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Report an issue',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const Text(
                          'Help others by sharing what you found',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ── Category toggle ──
              _SectionLabel(label: 'What kind of issue?'),
              const SizedBox(height: 10),
              _CategoryToggle(
                value: _category,
                onChanged: (v) => setState(() {
                  _category = v;
                  _issueType = null; // reset type when category changes
                }),
              ),
              const SizedBox(height: 20),

              // ── Issue type ──
              _SectionLabel(label: 'Issue type'),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: _issueType,
                isExpanded: true,
                decoration: const InputDecoration(
                  hintText: 'Select the issue type',
                  prefixIcon: Icon(Icons.report_problem_outlined),
                ),
                items: _issueTypes
                    .map((t) => DropdownMenuItem(
                          value: t,
                          child: Text(t, overflow: TextOverflow.ellipsis),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _issueType = v),
                validator: (v) =>
                    v == null ? 'Please select an issue type.' : null,
              ),
              const SizedBox(height: 16),

              // ── Bus number (only for bus issues) ──
              if (_category == 'bus') ...[
                _SectionLabel(label: 'Bus number (optional)'),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _busNumberCtrl,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    hintText: 'e.g. 138, 100',
                    prefixIcon: Icon(Icons.directions_bus_rounded),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // ── Location ──
              _SectionLabel(label: 'Location'),
              const SizedBox(height: 10),
              TextFormField(
                controller: _locationCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  hintText: _category == 'bus'
                      ? 'e.g. Bus 138 – Colombo Fort to Kaduwela'
                      : 'e.g. Maradana Railway Station',
                  prefixIcon: const Icon(Icons.location_on_outlined),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Please enter a location.'
                    : null,
              ),
              const SizedBox(height: 16),

              // ── Description ──
              _SectionLabel(label: 'Description'),
              const SizedBox(height: 10),
              TextFormField(
                controller: _descriptionCtrl,
                minLines: 3,
                maxLines: 6,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'Describe what you saw or experienced…',
                  prefixIcon: Padding(
                    padding: EdgeInsets.only(bottom: 48),
                    child: Icon(Icons.notes_rounded),
                  ),
                  alignLabelWithHint: true,
                ),
                validator: (v) {
                  final text = v?.trim() ?? '';
                  if (text.isEmpty) return 'Please add a description.';
                  if (text.length < 15) {
                    return 'Please add a bit more detail (15 chars min).';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 28),

              // ── Submit ──
              FilledButton.icon(
                onPressed: _isSubmitting ? null : _submit,
                icon: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: AppTheme.navy,
                        ),
                      )
                    : const Icon(Icons.send_rounded),
                label: Text(_isSubmitting ? 'Submitting…' : 'Submit report'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Small helpers ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: AppTheme.textSecondary,
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
      ),
    );
  }
}

class _CategoryToggle extends StatelessWidget {
  const _CategoryToggle({
    required this.value,
    required this.onChanged,
  });

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _ToggleChip(
          label: 'On the bus',
          icon: Icons.directions_bus_rounded,
          selected: value == 'bus',
          onTap: () => onChanged('bus'),
        ),
        const SizedBox(width: 10),
        _ToggleChip(
          label: 'Station / road',
          icon: Icons.train_rounded,
          selected: value == 'road',
          onTap: () => onChanged('road'),
        ),
      ],
    );
  }
}

class _ToggleChip extends StatelessWidget {
  const _ToggleChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected
                ? AppTheme.teal.withValues(alpha: 0.18)
                : Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? AppTheme.teal
                  : Colors.white.withValues(alpha: 0.14),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: selected ? AppTheme.teal : AppTheme.textSecondary,
              ),
              const SizedBox(width: 7),
              Text(
                label,
                style: TextStyle(
                  color: selected ? AppTheme.teal : AppTheme.textSecondary,
                  fontWeight:
                      selected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

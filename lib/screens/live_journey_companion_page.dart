import 'package:flutter/material.dart';

import '../models/route_details.dart';
import '../theme/app_theme.dart';
import '../widgets/equal_ride_background.dart';
import '../widgets/glass_panel.dart';

class LiveJourneyCompanionPage extends StatefulWidget {
  const LiveJourneyCompanionPage({
    super.key,
    required this.routeDetails,
  });

  final RouteDetails routeDetails;

  @override
  State<LiveJourneyCompanionPage> createState() =>
      _LiveJourneyCompanionPageState();
}

class _LiveJourneyCompanionPageState extends State<LiveJourneyCompanionPage> {
  int currentStepIndex = 0;
  bool isHighContrast = false;
  bool isAudioGuidanceEnabled = true;

  void _nextStep() {
    if (currentStepIndex < widget.routeDetails.journeySteps.length - 1) {
      setState(() {
        currentStepIndex++;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 2),
          backgroundColor: AppTheme.teal,
          content: Text(
            'Proceeding to step ${currentStepIndex + 1}: ${widget.routeDetails.journeySteps[currentStepIndex].title}',
            style: const TextStyle(
              color: AppTheme.navy,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
    } else {
      _showArrivalDialog();
    }
  }

  void _previousStep() {
    if (currentStepIndex > 0) {
      setState(() {
        currentStepIndex--;
      });
    }
  }

  void _showArrivalDialog() {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF0F263E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_rounded,
                color: AppTheme.teal, size: 28),
            SizedBox(width: 10),
            Text(
              'Journey Complete!',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You have safely arrived at ${widget.routeDetails.destination}.',
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.teal.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.teal.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.eco_rounded, color: AppTheme.teal, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'SDG 11 Impact: You saved ${widget.routeDetails.carbonSavedKg} of CO₂ compared to a private car!',
                      style: const TextStyle(
                        color: AppTheme.teal,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Exit Live Companion
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.teal,
              foregroundColor: AppTheme.navy,
            ),
            child: const Text('Return to Route'),
          ),
        ],
      ),
    );
  }

  void _showAssistanceCard({required bool isPrioritySeat}) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: isHighContrast ? Colors.black : const Color(0xFF0D243B),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          border: Border.all(
            color: isPrioritySeat ? AppTheme.aqua : AppTheme.teal,
            width: 2.5,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(
                  isPrioritySeat
                      ? Icons.event_seat_rounded
                      : Icons.accessible_forward_rounded,
                  color: isPrioritySeat ? AppTheme.aqua : AppTheme.teal,
                  size: 38,
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, size: 28),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              isPrioritySeat
                  ? 'PLEASE OFFER PRIORITY SEAT'
                  : 'RAMP ASSISTANCE REQUESTED',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isPrioritySeat ? AppTheme.aqua : AppTheme.teal,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Show this card to fellow passengers or the transit crew.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
              ),
              child: Column(
                children: [
                  Text(
                    isPrioritySeat
                        ? 'I have mobility assistance needs and kindly require a designated priority seat.'
                        : 'I am using a mobility device and request ramp deployment for boarding/alighting.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isPrioritySeat
                        ? 'කරුණාකර ප්‍රමුඛ ආසනයක් ලබාදීමට සහය වන්න.'
                        : 'කරුණාකර රෝද පුටු රැම්ප් ආධාරකය සකසා දෙන්න.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isPrioritySeat ? AppTheme.aqua : AppTheme.teal,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => Navigator.pop(context),
              style: FilledButton.styleFrom(
                backgroundColor:
                    isPrioritySeat ? AppTheme.aqua : AppTheme.teal,
                foregroundColor: AppTheme.navy,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Close Notice',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final steps = widget.routeDetails.journeySteps;
    final currentStep = steps.isNotEmpty
        ? steps[currentStepIndex.clamp(0, steps.length - 1)]
        : null;

    final progress = steps.isEmpty
        ? 1.0
        : (currentStepIndex + 1) / steps.length;

    final bgColor = isHighContrast
        ? Colors.black
        : const Color(0xFF0A1929);

    return Scaffold(
      backgroundColor: bgColor,
      body: EqualRideBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Top Bar with Contrast toggle and Audio toggle
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: 'Exit Navigation',
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded, size: 24),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'LIVE ACCESSIBLE COMPANION',
                            style: TextStyle(
                              color: AppTheme.aqua,
                              fontWeight: FontWeight.w900,
                              fontSize: 11,
                              letterSpacing: 0.6,
                            ),
                          ),
                          Text(
                            widget.routeDetails.routeTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: isHighContrast
                          ? 'Standard Mode'
                          : 'High Contrast Mode',
                      icon: Icon(
                        isHighContrast
                            ? Icons.contrast_rounded
                            : Icons.brightness_6_rounded,
                        color: isHighContrast ? Colors.yellow : AppTheme.teal,
                      ),
                      onPressed: () {
                        setState(() => isHighContrast = !isHighContrast);
                      },
                    ),
                    IconButton(
                      tooltip: isAudioGuidanceEnabled
                          ? 'Audio Cues Active'
                          : 'Audio Muted',
                      icon: Icon(
                        isAudioGuidanceEnabled
                            ? Icons.volume_up_rounded
                            : Icons.volume_off_rounded,
                        color: isAudioGuidanceEnabled
                            ? AppTheme.aqua
                            : AppTheme.textSecondary,
                      ),
                      onPressed: () {
                        setState(() =>
                            isAudioGuidanceEnabled = !isAudioGuidanceEnabled);
                      },
                    ),
                  ],
                ),
              ),

              // Journey Progress Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Step ${currentStepIndex + 1} of ${steps.length}',
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          '${(progress * 100).toInt()}% Completed',
                          style: const TextStyle(
                            color: AppTheme.teal,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 8,
                        backgroundColor: Colors.white.withValues(alpha: 0.12),
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(AppTheme.teal),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Main Active Step Card
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  children: [
                    if (currentStep != null) ...[
                      Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isHighContrast
                                ? [
                                    const Color(0xFF1E1E1E),
                                    const Color(0xFF121212)
                                  ]
                                : [
                                    const Color(0xFF134E5E)
                                        .withValues(alpha: 0.65),
                                    const Color(0xFF1A365D)
                                        .withValues(alpha: 0.65),
                                  ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(26),
                          border: Border.all(
                            color: isHighContrast
                                ? Colors.yellow
                                : AppTheme.teal,
                            width: 2.0,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.teal.withValues(alpha: 0.25),
                              blurRadius: 18,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        AppTheme.teal.withValues(alpha: 0.22),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    currentStep.stepType.toUpperCase(),
                                    style: const TextStyle(
                                      color: AppTheme.teal,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                Row(
                                  children: [
                                    const Icon(Icons.timer_rounded,
                                        size: 16, color: AppTheme.aqua),
                                    const SizedBox(width: 4),
                                    Text(
                                      currentStep.durationOrWaitTime,
                                      style: const TextStyle(
                                        color: AppTheme.aqua,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              currentStep.title,
                              style: TextStyle(
                                color: isHighContrast
                                    ? Colors.yellow
                                    : AppTheme.textPrimary,
                                fontWeight: FontWeight.w900,
                                fontSize: isHighContrast ? 24 : 22,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              currentStep.subtitle,
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 15,
                                height: 1.35,
                              ),
                            ),
                            if (currentStep.surfaceCondition != null) ...[
                              const SizedBox(height: 14),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.accessible_forward_rounded,
                                      size: 18,
                                      color: AppTheme.teal,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Surface: ${currentStep.surfaceCondition}',
                                        style: const TextStyle(
                                          color: AppTheme.textPrimary,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            if (currentStep.facilityNote != null) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color:
                                      AppTheme.aqua.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.info_rounded,
                                      size: 18,
                                      color: AppTheme.aqua,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Feature: ${currentStep.facilityNote}',
                                        style: const TextStyle(
                                          color: AppTheme.aqua,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            if (currentStep.hazardAlert != null) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF5252)
                                      .withValues(alpha: 0.16),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0xFFFF5252)
                                        .withValues(alpha: 0.5),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.warning_amber_rounded,
                                      size: 18,
                                      color: Color(0xFFFF5252),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        currentStep.hazardAlert!,
                                        style: const TextStyle(
                                          color: Color(0xFFFF8B8B),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),

                    // Quick Assistance Display Cards (SDG 10 Inclusion Feature)
                    Text(
                      'Rider Assistance Cards (Tap to show conductor)',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () =>
                                _showAssistanceCard(isPrioritySeat: true),
                            child: Ink(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppTheme.aqua.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color:
                                      AppTheme.aqua.withValues(alpha: 0.45),
                                ),
                              ),
                              child: const Column(
                                children: [
                                  Icon(Icons.event_seat_rounded,
                                      color: AppTheme.aqua, size: 28),
                                  SizedBox(height: 6),
                                  Text(
                                    'Priority Seat Card',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: AppTheme.aqua,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () =>
                                _showAssistanceCard(isPrioritySeat: false),
                            child: Ink(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppTheme.teal.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color:
                                      AppTheme.teal.withValues(alpha: 0.45),
                                ),
                              ),
                              child: const Column(
                                children: [
                                  Icon(Icons.accessible_forward_rounded,
                                      color: AppTheme.teal, size: 28),
                                  SizedBox(height: 6),
                                  Text(
                                    'Ramp Support Card',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: AppTheme.teal,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    // Next Step Preview
                    if (currentStepIndex < steps.length - 1) ...[
                      Text(
                        'Up Next:',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                      ),
                      const SizedBox(height: 8),
                      GlassPanel(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            const Icon(Icons.arrow_forward_rounded,
                                color: AppTheme.teal, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                steps[currentStepIndex + 1].title,
                                style: const TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            Text(
                              steps[currentStepIndex + 1].durationOrWaitTime,
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Bottom Navigation Controls
              Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF0C1F33),
                  border: Border(
                    top: BorderSide(
                        color: Colors.white.withValues(alpha: 0.1)),
                  ),
                ),
                child: Row(
                  children: [
                    if (currentStepIndex > 0) ...[
                      OutlinedButton(
                        onPressed: _previousStep,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Icon(Icons.arrow_back_rounded, size: 20),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _nextStep,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.teal,
                          foregroundColor: AppTheme.navy,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        icon: Icon(
                          currentStepIndex == steps.length - 1
                              ? Icons.check_circle_rounded
                              : Icons.arrow_forward_rounded,
                          size: 20,
                        ),
                        label: Text(
                          currentStepIndex == steps.length - 1
                              ? 'Complete Journey'
                              : 'Next Step',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import 'accessibility_map_location_picker_page.dart';
import '../models/community_report.dart';
import '../services/accessibility_report_draft_service.dart';
import '../services/accessibility_report_service.dart';
import '../theme/app_theme.dart';
import '../widgets/equal_ride_background.dart';
import '../widgets/impact_level_selector.dart';
import '../widgets/glass_panel.dart';

class AccessibilityReportPage extends StatefulWidget {
  const AccessibilityReportPage({super.key});

  @override
  State<AccessibilityReportPage> createState() =>
      _AccessibilityReportPageState();
}

class _AccessibilityReportPageState extends State<AccessibilityReportPage> {
  final formKey = GlobalKey<FormState>();
  final descriptionController = TextEditingController();
  final locationController = TextEditingController();
  final draftService = AccessibilityReportDraftService();
  final reportService = AccessibilityReportService();
  Future<void> draftWriteQueue = Future<void>.value();
  Timer? draftSaveTimer;

  String? issueType;
  String impactLevel = CommunityReport.defaultImpactLevel;
  bool isSubmitting = false;
  bool isReviewing = false;
  bool isDraftLoading = true;
  bool isDraftSaving = false;
  bool isDiscardingDraft = false;
  bool isPickingLocation = false;
  bool hasSavedDraft = false;
  bool hasShownDraftSaveError = false;

  static const minimumDescriptionLength = 20;

  static const issueTypes = [
    'Wheelchair access',
    'Ramp unavailable',
    'Lift unavailable',
    'Step-free access issue',
    'Crowding',
    'Accessibility information incorrect',
    'Other',
  ];

  static const issueGuidance = {
    'Wheelchair access': (
      descriptionHint: 'Describe the access available and any barriers.',
      descriptionHelp: 'Mention ramps, door width, or step-free access.',
      locationHint: 'For example, the station entrance or platform',
    ),
    'Ramp unavailable': (
      descriptionHint: 'Describe when and where the ramp was unavailable.',
      descriptionHelp: 'Include the route or vehicle and what happened.',
      locationHint: 'For example, Bus 138 at Central Station',
    ),
    'Lift unavailable': (
      descriptionHint: 'Describe which lift was unavailable.',
      descriptionHelp:
          'Include the station, platform, and any alternative route.',
      locationHint: 'For example, Central Station platform 2',
    ),
    'Step-free access issue': (
      descriptionHint: 'Describe where the step-free route was blocked.',
      descriptionHelp: 'Mention steps, slopes, or barriers along the route.',
      locationHint: 'For example, the entrance to platform 2',
    ),
    'Crowding': (
      descriptionHint: 'Describe how crowding affected access or boarding.',
      descriptionHelp: 'Include the time and how it affected your journey.',
      locationHint: 'For example, the 8 AM bus stop on Main Street',
    ),
    'Accessibility information incorrect': (
      descriptionHint: 'Explain what information is inaccurate.',
      descriptionHelp: 'Compare the information with what you found on site.',
      locationHint: 'For example, the station or route shown in the app',
    ),
    'Other': (
      descriptionHint: 'Describe the accessibility issue you encountered.',
      descriptionHelp: 'Share what happened and how it affected your journey.',
      locationHint: 'For example, a route, stop, or station',
    ),
  };

  ({String descriptionHint, String descriptionHelp, String locationHint})
  get selectedIssueGuidance =>
      issueGuidance[issueType] ?? issueGuidance['Other']!;

  AccessibilityReportDraft get currentDraft => AccessibilityReportDraft(
    issueType: issueType,
    description: descriptionController.text,
    location: locationController.text,
    impactLevel: impactLevel,
  );

  @override
  void initState() {
    super.initState();
    unawaited(restoreDraft());
  }

  @override
  void dispose() {
    if (draftSaveTimer?.isActive ?? false) {
      draftSaveTimer?.cancel();
      unawaited(enqueueDraftSave(currentDraft));
    }
    descriptionController.dispose();
    locationController.dispose();
    super.dispose();
  }

  Future<void> restoreDraft() async {
    AccessibilityReportDraft? draft;
    Object? restoreError;

    try {
      draft = await draftService.loadDraft();
    } catch (error, stackTrace) {
      restoreError = error;
      debugPrint('Unable to restore accessibility report draft: $error');
      debugPrintStack(stackTrace: stackTrace);
    }

    if (!mounted) return;

    if (draft != null) {
      descriptionController.text = draft.description;
      locationController.text = draft.location;
      issueType = issueTypes.contains(draft.issueType) ? draft.issueType : null;
      impactLevel =
          CommunityReport.impactLevelDescriptions.containsKey(draft.impactLevel)
          ? draft.impactLevel
          : CommunityReport.defaultImpactLevel;
    }
    setState(() {
      isDraftLoading = false;
      hasSavedDraft = draft != null;
    });

    if (draft != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your saved report draft was restored.')),
      );
    } else if (restoreError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('We could not restore your saved report draft.'),
        ),
      );
    }
  }

  void scheduleDraftSave() {
    if (isDraftLoading || isDiscardingDraft || isSubmitting) return;
    draftSaveTimer?.cancel();
    setState(() => isDraftSaving = true);
    draftSaveTimer = Timer(const Duration(milliseconds: 500), () {
      unawaited(enqueueDraftSave(currentDraft));
    });
  }

  Future<void> enqueueDraftSave(AccessibilityReportDraft draft) {
    draftWriteQueue = draftWriteQueue.then((_) async {
      try {
        await draftService.saveDraft(draft);
        if (mounted) {
          setState(() {
            hasSavedDraft = draft.hasContent;
            isDraftSaving = false;
          });
        }
        hasShownDraftSaveError = false;
      } catch (error, stackTrace) {
        debugPrint('Unable to save accessibility report draft: $error');
        debugPrintStack(stackTrace: stackTrace);
        if (mounted) setState(() => isDraftSaving = false);
        if (mounted && !hasShownDraftSaveError) {
          hasShownDraftSaveError = true;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Your report draft could not be saved on this device.',
              ),
            ),
          );
        }
      }
    });
    return draftWriteQueue;
  }

  Future<void> restoreSavedDraft() async {
    if (isDraftLoading || isSubmitting || isDiscardingDraft) return;
    draftSaveTimer?.cancel();
    setState(() {
      isDraftLoading = true;
      isDraftSaving = false;
    });
    await draftWriteQueue;
    await restoreDraft();
  }

  Future<void> discardSavedDraft() async {
    if (isDraftLoading || isSubmitting || isDiscardingDraft) return;

    final shouldDiscard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard saved draft?'),
        content: const Text(
          'This will remove the report draft saved on this device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep draft'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    if (shouldDiscard != true || !mounted) return;

    draftSaveTimer?.cancel();
    setState(() {
      isDiscardingDraft = true;
      isDraftSaving = false;
    });
    try {
      await draftWriteQueue;
      await draftService.clearDraft();
      if (!mounted) return;
      descriptionController.clear();
      locationController.clear();
      formKey.currentState?.reset();
      setState(() {
        issueType = null;
        impactLevel = CommunityReport.defaultImpactLevel;
        hasSavedDraft = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saved report draft discarded.')),
      );
    } catch (error, stackTrace) {
      debugPrint('Unable to discard accessibility report draft: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('We could not discard the saved report draft.'),
        ),
      );
    } finally {
      if (mounted) setState(() => isDiscardingDraft = false);
    }
  }

  Future<void> selectLocationOnMap() async {
    if (isPickingLocation ||
        isSubmitting ||
        isDraftLoading ||
        isDiscardingDraft) {
      return;
    }

    setState(() => isPickingLocation = true);
    try {
      final selectedPoint = await Navigator.of(context).push<LatLng>(
        MaterialPageRoute(
          builder: (_) => AccessibilityMapLocationPickerPage(
            initialLocation: locationController.text,
          ),
        ),
      );
      if (!mounted || selectedPoint == null) return;

      locationController.text = formatMapCoordinates(selectedPoint);
      setState(() {});
      scheduleDraftSave();
      FocusScope.of(context).unfocus();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Map coordinates added to the location.')),
      );
    } catch (error, stackTrace) {
      debugPrint('Unable to select report location on map: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not open the map picker. Please enter a location manually.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => isPickingLocation = false);
    }
  }

  Future<bool> confirmReportDetails() async {
    if (isReviewing || isSubmitting || isDraftLoading || isDiscardingDraft) {
      return false;
    }

    setState(() => isReviewing = true);
    try {
      return await showDialog<bool>(
            context: context,
            builder: (context) {
              return Dialog(
                backgroundColor: AppTheme.navyLight,
                surfaceTintColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.16)),
                ),
                insetPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 24,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: 480,
                    maxHeight: MediaQuery.sizeOf(context).height * 0.82,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Container(
                              height: 48,
                              width: 48,
                              decoration: BoxDecoration(
                                color: AppTheme.teal.withValues(alpha: 0.16),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(
                                Icons.fact_check_outlined,
                                color: AppTheme.teal,
                              ),
                            ),
                            const SizedBox(width: 14),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Review your report',
                                    style: TextStyle(
                                      color: AppTheme.textPrimary,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Make sure everything looks right.',
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
                        const SizedBox(height: 18),
                        Flexible(
                          child: SingleChildScrollView(
                            child: Column(
                              children: [
                                _ReportReviewDetail(
                                  icon: Icons.report_problem_outlined,
                                  label: 'ISSUE TYPE',
                                  value: issueType!,
                                ),
                                const SizedBox(height: 10),
                                _ReportReviewDetail(
                                  icon: Icons.priority_high_rounded,
                                  label: 'ACCESS IMPACT',
                                  value:
                                      '$impactLevel — ${CommunityReport.impactLevelDescriptions[impactLevel]}',
                                ),
                                const SizedBox(height: 10),
                                _ReportReviewDetail(
                                  icon: Icons.location_on_outlined,
                                  label: 'LOCATION',
                                  value: locationController.text,
                                ),
                                const SizedBox(height: 10),
                                _ReportReviewDetail(
                                  icon: Icons.notes_rounded,
                                  label: 'WHAT HAPPENED',
                                  value: descriptionController.text,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => Navigator.pop(context, false),
                            icon: const Icon(Icons.edit_outlined),
                            label: const Text('Go back and edit'),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: () => Navigator.pop(context, true),
                            icon: const Icon(Icons.send_rounded),
                            label: const Text('Submit report'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ) ??
          false;
    } finally {
      if (mounted) setState(() => isReviewing = false);
    }
  }

  Future<void> submitReport() async {
    if (isSubmitting || isReviewing || isDraftLoading || isDiscardingDraft) {
      return;
    }

    descriptionController.text = descriptionController.text.trim();
    locationController.text = locationController.text.trim();

    if (!(formKey.currentState?.validate() ?? false)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fix the highlighted fields.')),
      );
      return;
    }

    if (!await confirmReportDetails() || !mounted) return;

    setState(() => isSubmitting = true);

    try {
      draftSaveTimer?.cancel();
      await enqueueDraftSave(currentDraft);
      await reportService.submitReport(
        issueType: issueType!,
        description: descriptionController.text,
        location: locationController.text,
        impactLevel: impactLevel,
      );

      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      String? draftCleanupWarning;
      try {
        await draftWriteQueue;
        await draftService.clearDraft();
      } catch (error, stackTrace) {
        debugPrint(
          'Unable to clear submitted accessibility report draft: $error',
        );
        debugPrintStack(stackTrace: stackTrace);
        draftCleanupWarning =
            'Report submitted, but the saved draft could not be cleared.';
      }
      if (!mounted) return;
      descriptionController.clear();
      locationController.clear();
      formKey.currentState?.reset();
      setState(() {
        issueType = null;
        impactLevel = CommunityReport.defaultImpactLevel;
        hasSavedDraft = false;
      });
      Navigator.of(context).pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            draftCleanupWarning ??
                'Accessibility report submitted successfully.',
          ),
        ),
      );
    } on AccessibilityReportException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('We could not submit your report. Please try again.'),
        ),
      );
    } finally {
      if (mounted) setState(() => isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final interactionsEnabled =
        !isDraftLoading && !isSubmitting && !isDiscardingDraft;

    return Scaffold(
      body: EqualRideBackground(
        child: SafeArea(
          child: Form(
            key: formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
                    children: [
                      Row(
                        children: [
                          if (Navigator.canPop(context))
                            IconButton(
                              tooltip: 'Back',
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.arrow_back_rounded),
                            ),
                          const SizedBox(width: 4),
                          Container(
                            height: 42,
                            width: 42,
                            decoration: BoxDecoration(
                              color: AppTheme.teal.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.accessible_forward_rounded,
                              color: AppTheme.teal,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Accessibility report',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      GlassPanel(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              height: 48,
                              width: 48,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [AppTheme.teal, AppTheme.aqua],
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(
                                Icons.campaign_rounded,
                                color: AppTheme.navy,
                                size: 25,
                              ),
                            ),
                            const SizedBox(width: 14),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Help make travel easier for everyone',
                                    style: TextStyle(
                                      color: AppTheme.textPrimary,
                                      fontSize: 18,
                                      height: 1.2,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  SizedBox(height: 7),
                                  Text(
                                    'Tell us what happened and where. Your report helps other travellers plan with confidence.',
                                    style: TextStyle(
                                      color: AppTheme.textSecondary,
                                      height: 1.45,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isDraftLoading) ...[
                        const SizedBox(height: 16),
                        const LinearProgressIndicator(
                          minHeight: 3,
                          borderRadius: BorderRadius.all(Radius.circular(4)),
                        ),
                      ],
                      if (hasSavedDraft || isDraftSaving) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.teal.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppTheme.teal.withValues(alpha: 0.35),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.drafts_outlined,
                                    color: AppTheme.teal,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      isDraftSaving
                                          ? 'Saving report draft on this device...'
                                          : 'Report draft saved on this device',
                                      style: const TextStyle(
                                        color: AppTheme.textPrimary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (hasSavedDraft) ...[
                                const SizedBox(height: 8),
                                const Text(
                                  'You can restore the saved version or discard it.',
                                  style: TextStyle(
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 4,
                                  children: [
                                    OutlinedButton.icon(
                                      onPressed:
                                          isDraftLoading ||
                                              isSubmitting ||
                                              isDraftSaving ||
                                              isDiscardingDraft
                                          ? null
                                          : restoreSavedDraft,
                                      icon: const Icon(Icons.restore_rounded),
                                      label: const Text('Restore draft'),
                                    ),
                                    TextButton.icon(
                                      onPressed:
                                          isDraftLoading ||
                                              isSubmitting ||
                                              isDiscardingDraft
                                          ? null
                                          : discardSavedDraft,
                                      icon: const Icon(
                                        Icons.delete_outline_rounded,
                                      ),
                                      label: const Text('Discard'),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 28),
                      GlassPanel(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const _FormSectionHeading(
                              number: '01',
                              title: 'What is the issue?',
                              subtitle: 'Choose the closest match.',
                              icon: Icons.report_problem_outlined,
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                              initialValue: issueType,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Issue type',
                                prefixIcon: Icon(Icons.report_problem_outlined),
                              ),
                              items: issueTypes
                                  .map(
                                    (type) => DropdownMenuItem(
                                      value: type,
                                      child: Text(
                                        type,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged:
                                  isDraftLoading ||
                                      isSubmitting ||
                                      isDiscardingDraft
                                  ? null
                                  : (value) {
                                      setState(() => issueType = value);
                                      scheduleDraftSave();
                                    },
                              validator: (value) =>
                                  value == null || value.isEmpty
                                  ? 'Please select an issue type.'
                                  : null,
                            ),
                            const SizedBox(height: 18),
                            const _FormSectionHeading(
                              number: '02',
                              title: 'How much does it affect access?',
                              subtitle:
                                  'This is separate from the report status.',
                              icon: Icons.priority_high_rounded,
                            ),
                            const SizedBox(height: 12),
                            ImpactLevelSelector(
                              value: impactLevel,
                              enabled: interactionsEnabled,
                              onChanged: (value) {
                                setState(() => impactLevel = value);
                                scheduleDraftSave();
                              },
                            ),
                            const SizedBox(height: 18),
                            const _FormSectionHeading(
                              number: '03',
                              title: 'Where did it happen?',
                              subtitle:
                                  'Add a place name or pinpoint it on the map.',
                              icon: Icons.place_outlined,
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              onPressed:
                                  interactionsEnabled && !isPickingLocation
                                  ? selectLocationOnMap
                                  : null,
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(52),
                                foregroundColor: AppTheme.aqua,
                                side: BorderSide(
                                  color: AppTheme.teal.withValues(alpha: 0.50),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              icon: isPickingLocation
                                  ? const SizedBox(
                                      height: 18,
                                      width: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.map_outlined),
                              label: Text(
                                isPickingLocation
                                    ? 'Opening map...'
                                    : 'Choose location on map',
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: locationController,
                              enabled: interactionsEnabled,
                              onChanged: (_) => scheduleDraftSave(),
                              keyboardType: TextInputType.text,
                              textInputAction: TextInputAction.done,
                              textCapitalization: TextCapitalization.words,
                              decoration: InputDecoration(
                                labelText: 'Place, stop, or station',
                                hintText: selectedIssueGuidance.locationHint,
                                prefixIcon: const Icon(
                                  Icons.location_on_outlined,
                                ),
                                helperText:
                                    'A landmark or entrance helps others find it.',
                              ),
                              validator: (value) =>
                                  value == null || value.trim().isEmpty
                                  ? 'Please enter the route or station location.'
                                  : null,
                            ),
                            const SizedBox(height: 18),
                            const _FormSectionHeading(
                              number: '04',
                              title: 'Tell us what happened',
                              subtitle:
                                  'A little detail can make a big difference.',
                              icon: Icons.subject_rounded,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: descriptionController,
                              enabled: interactionsEnabled,
                              onChanged: (_) => scheduleDraftSave(),
                              keyboardType: TextInputType.multiline,
                              textInputAction: TextInputAction.newline,
                              minLines: 4,
                              maxLines: 7,
                              textCapitalization: TextCapitalization.sentences,
                              decoration: InputDecoration(
                                labelText: 'Description',
                                alignLabelWithHint: true,
                                hintText: selectedIssueGuidance.descriptionHint,
                                helperText:
                                    selectedIssueGuidance.descriptionHelp,
                                prefixIcon: const Padding(
                                  padding: EdgeInsets.only(bottom: 48),
                                  child: Icon(Icons.notes_rounded),
                                ),
                              ),
                              buildCounter:
                                  (
                                    context, {
                                    required currentLength,
                                    required isFocused,
                                    maxLength,
                                  }) {
                                    final countLabel =
                                        currentLength < minimumDescriptionLength
                                        ? '$currentLength / $minimumDescriptionLength minimum'
                                        : '$currentLength characters';
                                    return Text(
                                      countLabel,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall,
                                    );
                                  },
                              validator: (value) {
                                final description = value?.trim() ?? '';
                                if (description.isEmpty) {
                                  return 'Please describe the accessibility issue.';
                                }
                                if (description.length <
                                    minimumDescriptionLength) {
                                  return 'Please add a little more detail (20 characters minimum).';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
                  decoration: BoxDecoration(
                    color: AppTheme.navy.withValues(alpha: 0.94),
                    border: Border(
                      top: BorderSide(
                        color: Colors.white.withValues(alpha: 0.10),
                      ),
                    ),
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed:
                          isSubmitting ||
                              isReviewing ||
                              isDraftLoading ||
                              isDiscardingDraft
                          ? null
                          : submitReport,
                      icon: isSubmitting
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                color: AppTheme.navy,
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Icon(Icons.send_rounded),
                      label: Text(
                        isDraftLoading
                            ? 'Restoring draft...'
                            : isReviewing
                            ? 'Preparing review...'
                            : isSubmitting
                            ? 'Submitting report...'
                            : 'Review and submit',
                      ),
                    ),
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

class _FormSectionHeading extends StatelessWidget {
  const _FormSectionHeading({
    required this.number,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String number;
  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          height: 40,
          width: 40,
          decoration: BoxDecoration(
            color: AppTheme.teal.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(icon, color: AppTheme.teal, size: 21),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        Text(
          number,
          style: TextStyle(
            color: AppTheme.aqua.withValues(alpha: 0.75),
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _ReportReviewDetail extends StatelessWidget {
  const _ReportReviewDetail({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.teal, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppTheme.aqua,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 6),
                SelectableText(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textPrimary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

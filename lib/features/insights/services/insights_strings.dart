// File: insights_strings.dart
//
// English and Sinhala text for the Insights feature, kept separate from the
// app-wide strings file to avoid merge conflicts. Missing Sinhala keys fall
// back to English.

import '../../../models/accessibility_preferences.dart';

/// English and Sinhala text for the Insights feature. Kept separate from the
/// shared app strings so this feature never edits files other people own.
class InsightsStrings {
  const InsightsStrings._();

  static String text(
    AppLanguage language,
    String key, [
    Map<String, Object> params = const {},
  ]) {
    final values = language == AppLanguage.sinhala ? _sinhala : _english;
    var value = values[key] ?? _english[key] ?? key;
    params.forEach((name, replacement) {
      value = value.replaceAll('{$name}', '$replacement');
    });
    return value;
  }

  static Iterable<String> get englishKeys => _english.keys;

  static const _english = {
    'title': 'Accessibility Insights',
    'entryTitle': 'Accessibility Insights',
    'entrySubtitle': 'Problem hotspots, trends and live conditions',
    'liveMap': 'LIVE MAP',
    'back': 'Back',
    'share': 'Share summary',
    'shareFailed': 'Could not open the share option on this device.',
    'copy': 'Copy',
    'copied': 'Summary copied',
    'email': 'Email',
    'overview': 'Overview',
    'totalReports': 'Total reports',
    'resolved': 'Resolved',
    'criticalOpen': 'Critical open',
    'oldestOpen': 'Oldest open',
    'nothingOpen': 'Nothing open',
    'backlogAge': 'Backlog age',
    'blockAccess': 'Block access fully',
    'busRoad': '{bus} bus · {road} road',
    'resolvedCount': '{n} resolved',
    'liveMapTitle': 'Live hotspot map',
    'topIssues': 'Most reported issues',
    'hotspots': 'Problem hotspots',
    'hotspotsHint':
        'Routes and places ranked by the severity of open problems.',
    'trend': 'Trend',
    'headlineNone': 'No reports in the last {days} days yet.',
    'headlineAllResolved': 'All {total} reports are resolved.',
    'headlineOpen': '{open} of {total} reports are still open.',
    'headlineCriticalOne': '1 critical issue needs attention.',
    'headlineCriticalMany': '{n} critical issues need attention.',
    'headlineMost': 'Most reported: {issue}.',
    'shareHeading': 'EqualRide accessibility insights (last {days} days)',
    'shareTotal': 'Reports: {total} ({open} open, {resolved} resolved)',
    'shareCritical': 'Critical open: {n}',
    'shareTopIssues': 'Top issues:',
    'shareHotspots': 'Hotspots:',
    'shareFooter': 'Shared from the EqualRide app',
  };

  // Translations should be reviewed by a native Sinhala speaker.
  static const _sinhala = {
    'title': 'ප්‍රවේශ්‍යතා තීක්ෂ්ණතා',
    'entryTitle': 'ප්‍රවේශ්‍යතා තීක්ෂ්ණතා',
    'entrySubtitle': 'ගැටලු ස්ථාන, ප්‍රවණතා සහ සජීවී තත්ත්වයන්',
    'liveMap': 'සජීවී සිතියම',
    'back': 'ආපසු',
    'share': 'සාරාංශය බෙදාගන්න',
    'shareFailed': 'මෙම උපාංගයේ බෙදාගැනීමේ විකල්පය විවෘත කළ නොහැක.',
    'copy': 'පිටපත් කරන්න',
    'copied': 'සාරාංශය පිටපත් කරන ලදී',
    'email': 'ඊමේල්',
    'overview': 'දළ විශ්ලේෂණය',
    'totalReports': 'මුළු වාර්තා',
    'resolved': 'විසඳූ',
    'criticalOpen': 'විවෘත බරපතළ',
    'oldestOpen': 'පැරණිතම විවෘත',
    'nothingOpen': 'විවෘත කිසිවක් නැත',
    'backlogAge': 'පොරොත්තු කාලය',
    'blockAccess': 'ප්‍රවේශය සම්පූර්ණයෙන් අවහිර කරයි',
    'busRoad': 'බස් {bus} · මාර්ග {road}',
    'resolvedCount': 'විසඳූ {n}',
    'liveMapTitle': 'සජීවී ගැටලු සිතියම',
    'topIssues': 'වැඩිම වාර්තා වූ ගැටලු',
    'hotspots': 'ගැටලු ස්ථාන',
    'hotspotsHint': 'විවෘත ගැටලුවල බරපතලකම අනුව ශ්‍රේණිගත මාර්ග සහ ස්ථාන.',
    'trend': 'ප්‍රවණතාව',
    'headlineNone': 'පසුගිය දින {days} තුළ තවම වාර්තා නැත.',
    'headlineAllResolved': 'වාර්තා {total}ම විසඳා ඇත.',
    'headlineOpen': 'වාර්තා {total}න් {open}ක් තවමත් විවෘතයි.',
    'headlineCriticalOne': 'බරපතළ ගැටලු 1කට අවධානය අවශ්‍යයි.',
    'headlineCriticalMany': 'බරපතළ ගැටලු {n}කට අවධානය අවශ්‍යයි.',
    'headlineMost': 'වැඩිම වාර්තා වූයේ: {issue}.',
    'shareHeading': 'EqualRide ප්‍රවේශ්‍යතා තීක්ෂ්ණතා (පසුගිය දින {days})',
    'shareTotal': 'වාර්තා: {total} (විවෘත {open}, විසඳූ {resolved})',
    'shareCritical': 'විවෘත බරපතළ: {n}',
    'shareTopIssues': 'ප්‍රධාන ගැටලු:',
    'shareHotspots': 'ගැටලු ස්ථාන:',
    'shareFooter': 'EqualRide යෙදුමෙන් බෙදාගන්නා ලදී',
  };
}

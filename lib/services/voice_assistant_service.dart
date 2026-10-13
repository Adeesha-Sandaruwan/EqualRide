import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../models/accessibility_preferences.dart';

/// Screen context details used by Voice Assistant to orient blind and elderly users
class VoiceScreenContext {
  const VoiceScreenContext({
    required this.name,
    required this.summary,
    this.readContent,
    this.onVoiceCommand,
  });

  final String name;
  final String summary;
  final String Function()? readContent;
  final Future<bool> Function(String rawCommand)? onVoiceCommand;
}

/// Global Voice Assistant Service providing Speech-to-Text, Text-to-Speech,
/// screen narration, and hands-free voice command navigation for EqualRide.
class VoiceAssistantService extends ChangeNotifier {
  VoiceAssistantService._internal();

  static final VoiceAssistantService instance = VoiceAssistantService._internal();

  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();

  bool _isInitialized = false;
  bool _isSpeechAvailable = false;
  bool _isListening = false;
  bool _isSpeaking = false;
  bool _isSlowSpeech = false;
  bool _autoScreenNarration = false;
  bool _isEnabled = true;

  AppLanguage _language = AppLanguage.english;
  String _lastWords = '';
  String _lastResponse = '';
  String _statusMessage = 'Ready';

  VoiceScreenContext? _currentScreen;

  // Callback to apply accessibility settings changes globally
  void Function(AccessibilityPreferences)? onUpdatePreferences;
  AccessibilityPreferences? Function()? onGetPreferences;
  GlobalKey<NavigatorState>? navigatorKey;

  // Getters
  bool get isListening => _isListening;
  bool get isSpeaking => _isSpeaking;
  bool get isSpeechAvailable => _isSpeechAvailable;
  bool get isSlowSpeech => _isSlowSpeech;
  bool get autoScreenNarration => _autoScreenNarration;
  bool get isEnabled => _isEnabled;
  AppLanguage get language => _language;
  String get lastWords => _lastWords;
  String get lastResponse => _lastResponse;
  String get statusMessage => _statusMessage;
  VoiceScreenContext? get currentScreen => _currentScreen;

  /// Initialize TTS and STT engines safely
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _initTts();
    } catch (e) {
      debugPrint('TTS init error: $e');
    }

    try {
      await _initStt();
    } catch (e) {
      debugPrint('STT init error: $e');
    }

    _isInitialized = true;
    notifyListeners();
  }

  Future<void> _initTts() async {
    try {
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
      final rate = _isSlowSpeech ? 0.38 : 0.48;
      await _tts.setSpeechRate(rate);

      if (_language == AppLanguage.sinhala) {
        await _tts.setLanguage('si-LK');
      } else {
        await _tts.setLanguage('en-US');
      }

      _tts.setStartHandler(() {
        _isSpeaking = true;
        _statusMessage = 'Speaking...';
        notifyListeners();
      });

      _tts.setCompletionHandler(() {
        _isSpeaking = false;
        _statusMessage = 'Ready';
        notifyListeners();
      });

      _tts.setCancelHandler(() {
        _isSpeaking = false;
        _statusMessage = 'Ready';
        notifyListeners();
      });

      _tts.setErrorHandler((msg) {
        _isSpeaking = false;
        _statusMessage = 'Ready';
        notifyListeners();
      });
    } catch (e) {
      debugPrint('Error configuring TTS: $e');
    }
  }

  Future<void> _initStt() async {
    try {
      _isSpeechAvailable = await _speech.initialize(
        onStatus: (status) {
          if (status == 'listening') {
            _isListening = true;
            _statusMessage = 'Listening... Speak now';
          } else if (status == 'notListening' || status == 'done') {
            _isListening = false;
            if (_statusMessage == 'Listening... Speak now') {
              _statusMessage = 'Ready';
            }
          }
          notifyListeners();
        },
        onError: (errorNotification) {
          _isListening = false;
          _statusMessage = 'Tap mic to try again';
          notifyListeners();
        },
      );
    } catch (e) {
      debugPrint('Speech-to-text initialization skipped or unsupported: $e');
      _isSpeechAvailable = false;
    }
  }

  /// Sync preferences from app settings
  void syncPreferences(AccessibilityPreferences preferences) {
    _isEnabled = preferences.voiceAssistantEnabled;
    _autoScreenNarration = preferences.voiceScreenNarration;
    _isSlowSpeech = preferences.voiceSlowSpeech;
    _language = preferences.language;

    final rate = _isSlowSpeech ? 0.38 : 0.48;
    _tts.setSpeechRate(rate);

    if (_language == AppLanguage.sinhala) {
      _tts.setLanguage('si-LK');
    } else {
      _tts.setLanguage('en-US');
    }

    notifyListeners();
  }

  /// Register context for current screen
  void registerScreen(VoiceScreenContext context, {bool announceNow = false}) {
    _currentScreen = context;
    notifyListeners();

    if (announceNow || _autoScreenNarration) {
      // Delay slightly to allow UI transition
      Future.delayed(const Duration(milliseconds: 400), () {
        if (_currentScreen?.name == context.name) {
          announceCurrentScreen();
        }
      });
    }
  }

  /// Speak text out loud using TTS
  Future<void> speak(String text, {bool interrupt = true}) async {
    if (!_isEnabled) return;
    if (text.trim().isEmpty) return;

    try {
      if (interrupt) {
        await _tts.stop();
      }
      _lastResponse = text;
      _isSpeaking = true;
      _statusMessage = 'Speaking...';
      notifyListeners();

      await _tts.speak(text);
    } catch (e) {
      debugPrint('TTS speak error: $e');
      _isSpeaking = false;
      notifyListeners();
    }
  }

  /// Stop speaking immediately
  Future<void> stopSpeaking() async {
    try {
      await _tts.stop();
      _isSpeaking = false;
      _statusMessage = 'Ready';
      notifyListeners();
    } catch (_) {}
  }

  /// Start listening for voice commands
  Future<void> startListening({BuildContext? context}) async {
    if (!_isEnabled) return;

    // Provide haptic feedback if available
    try {
      HapticFeedback.mediumImpact();
    } catch (_) {}

    await stopSpeaking();

    if (!_isSpeechAvailable) {
      await _initStt();
    }

    _lastWords = '';
    _statusMessage = 'Listening... Speak now';
    _isListening = true;
    notifyListeners();

    if (_isSpeechAvailable) {
      try {
        final localeId = _language == AppLanguage.sinhala ? 'si-LK' : 'en-US';
        await _speech.listen(
          onResult: (result) {
            _lastWords = result.recognizedWords;
            notifyListeners();

            if (result.finalResult && _lastWords.trim().isNotEmpty) {
              _onSpeechRecognitionComplete(_lastWords, context);
            }
          },
          listenOptions: stt.SpeechListenOptions(
            listenMode: stt.ListenMode.confirmation,
            cancelOnError: false,
          ),
          localeId: localeId,
        );
      } catch (e) {
        debugPrint('STT listen error: $e');
        _isListening = false;
        _statusMessage = 'Could not access microphone';
        notifyListeners();
      }
    } else {
      // If mic is not available on this platform/browser, prompt user
      _statusMessage = 'Microphone unavailable. You can use quick voice buttons below.';
      _isListening = false;
      notifyListeners();
    }
  }

  /// Stop listening
  Future<void> stopListening() async {
    try {
      await _speech.stop();
    } catch (_) {}
    _isListening = false;
    _statusMessage = 'Ready';
    notifyListeners();
  }

  /// Toggle listening state
  Future<void> toggleListening({BuildContext? context}) async {
    if (_isListening) {
      await stopListening();
    } else {
      await startListening(context: context);
    }
  }

  void _onSpeechRecognitionComplete(String words, BuildContext? context) {
    _isListening = false;
    _statusMessage = 'Processing command...';
    notifyListeners();

    executeVoiceCommand(words, context: context);
  }

  /// Announce the current screen orientation and purpose to the user
  Future<void> announceCurrentScreen() async {
    if (_currentScreen == null) {
      final msg = _language == AppLanguage.sinhala
          ? 'ඔබ සිටින්නේ EqualRide යෙදුමේ ප්‍රධාන පිටුවේය.'
          : 'You are on the EqualRide app.';
      await speak(msg);
      return;
    }

    final screenName = _currentScreen!.name;
    final summary = _currentScreen!.summary;

    final announcement = _language == AppLanguage.sinhala
        ? 'ඔබ සිටින්නේ $screenName පිටුවේය. $summary'
        : 'You are on $screenName. $summary';

    await speak(announcement);
  }

  /// Read the main content on the current screen out loud
  Future<void> readCurrentScreenContent() async {
    if (_currentScreen?.readContent != null) {
      final content = _currentScreen!.readContent!();
      if (content.isNotEmpty) {
        await speak(content);
        return;
      }
    }

    await announceCurrentScreen();
  }

  /// Provide audio help with available voice commands
  Future<void> provideVoiceHelp() async {
    final helpText = _language == AppLanguage.sinhala
        ? 'ඔබට මෙසේ පැවසිය හැක: '
            '"කොළඹට මාර්ග සොයන්න", '
            '"මම කොහේද", '
            '"තිරය කියවන්න", '
            '"ප්‍රධාන පිටුවට යන්න", '
            '"මනාප පිටුව", '
            '"සුරකින ලද ස්ථාන", '
            '"ඉහළ ප්‍රතිවිරෝධය ක්‍රියාත්මක කරන්න", '
            'හෝ "හඬ නවත්වන්න".'
        : 'Here are commands you can speak: '
            '"Find route to Colombo Fort", '
            '"Where am I?", '
            '"Read screen", '
            '"Go home", '
            '"Open preferences", '
            '"Saved locations", '
            '"Turn on high contrast", '
            '"Bigger text", '
            'or "Stop speaking".';

    await speak(helpText);
  }

  /// Main natural voice command processor
  Future<void> executeVoiceCommand(String rawCommand, {BuildContext? context}) async {
    final cleaned = rawCommand.trim().toLowerCase();
    _lastWords = rawCommand;
    notifyListeners();

    if (cleaned.isEmpty) return;

    // 1. Check if the current screen has a custom voice command handler
    if (_currentScreen?.onVoiceCommand != null) {
      final handled = await _currentScreen!.onVoiceCommand!(cleaned);
      if (handled) return;
    }

    // 2. Global command matching:

    // Stop speaking
    if (cleaned.contains('stop') ||
        cleaned.contains('quiet') ||
        cleaned.contains('silence') ||
        cleaned.contains('නවත්වන්න')) {
      await stopSpeaking();
      return;
    }

    // Repeat last response
    if (cleaned.contains('repeat') ||
        cleaned.contains('say again') ||
        cleaned.contains('නැවත කියන්න')) {
      if (_lastResponse.isNotEmpty) {
        await speak(_lastResponse);
      } else {
        await announceCurrentScreen();
      }
      return;
    }

    // Where am I? / Orientation
    if (cleaned.contains('where am i') ||
        cleaned.contains('what screen') ||
        cleaned.contains('මම කොහේද') ||
        cleaned.contains('කොහෙද ඉන්නේ')) {
      await announceCurrentScreen();
      return;
    }

    // Read screen / Read page
    if (cleaned.contains('read screen') ||
        cleaned.contains('read page') ||
        cleaned.contains('read content') ||
        cleaned.contains('තිරය කියවන්න') ||
        cleaned.contains('කියවන්න')) {
      await readCurrentScreenContent();
      return;
    }

    // Voice Help
    if (cleaned.contains('help') ||
        cleaned.contains('what can i say') ||
        cleaned.contains('commands') ||
        cleaned.contains('උපකාර') ||
        cleaned.contains('විධාන')) {
      await provideVoiceHelp();
      return;
    }

    // High Contrast toggle
    if (cleaned.contains('high contrast') || cleaned.contains('ප්‍රතිවිරෝධය')) {
      final enable = !cleaned.contains('off') &&
          !cleaned.contains('disable') &&
          !cleaned.contains('අක්‍රිය');
      _updatePreference((p) => p.copyWith(highContrast: enable));
      final msg = enable
          ? (_language == AppLanguage.sinhala
              ? 'ඉහළ ප්‍රතිවිරෝධතා මාදිලිය ක්‍රියාත්මක කරන ලදී.'
              : 'High contrast mode enabled.')
          : (_language == AppLanguage.sinhala
              ? 'ඉහළ ප්‍රතිවිරෝධතා මාදිලිය අක්‍රිය කරන ලදී.'
              : 'High contrast mode turned off.');
      await speak(msg);
      return;
    }

    // Text size adjustments
    if (cleaned.contains('bigger text') ||
        cleaned.contains('larger text') ||
        cleaned.contains('increase text') ||
        cleaned.contains('විශාල අකුරු')) {
      _updatePreference((p) => p.copyWith(textScale: 1.3));
      await speak(_language == AppLanguage.sinhala
          ? 'අකුරු ප්‍රමාණය විශාල කරන ලදී.'
          : 'Text size set to large.');
      return;
    }

    if (cleaned.contains('normal text') ||
        cleaned.contains('standard text') ||
        cleaned.contains('smaller text') ||
        cleaned.contains('සාමාන්‍ය අකුරු')) {
      _updatePreference((p) => p.copyWith(textScale: 1.0));
      await speak(_language == AppLanguage.sinhala
          ? 'අකුරු ප්‍රමාණය සාමාන්‍ය කරන ලදී.'
          : 'Text size set to standard.');
      return;
    }

    // Language toggle
    if (cleaned.contains('switch to sinhala') ||
        cleaned.contains('sinhala language') ||
        cleaned.contains('සිංහල')) {
      _updatePreference((p) => p.copyWith(language: AppLanguage.sinhala));
      _language = AppLanguage.sinhala;
      await _tts.setLanguage('si-LK');
      await speak('භාෂාව සිංහල ලෙස වෙනස් කරන ලදී.');
      return;
    }

    if (cleaned.contains('switch to english') ||
        cleaned.contains('english language') ||
        cleaned.contains('ඉංග්‍රීසි')) {
      _updatePreference((p) => p.copyWith(language: AppLanguage.english));
      _language = AppLanguage.english;
      await _tts.setLanguage('en-US');
      await speak('Language changed to English.');
      return;
    }

    // Step-free routing preference
    if (cleaned.contains('step free') ||
        cleaned.contains('wheelchair') ||
        cleaned.contains('avoid stairs') ||
        cleaned.contains('පඩි රහිත')) {
      _updatePreference((p) => p.copyWith(stepFreeRoutes: true));
      await speak(_language == AppLanguage.sinhala
          ? 'පඩි රහිත මාර්ග ප්‍රමුඛතාවය ක්‍රියාත්මක කරන ලදී.'
          : 'Step-free route preference enabled.');
      return;
    }

    // Navigation: Go Home
    if (cleaned.contains('go home') ||
        cleaned.contains('take me home') ||
        cleaned.contains('home screen') ||
        cleaned.contains('මුල් පිටුව') ||
        cleaned == 'home') {
      final nav = _getNavigator(context);
      if (nav != null) {
        nav.popUntil((route) => route.isFirst);
        await speak(_language == AppLanguage.sinhala
            ? 'මුල් පිටුවට පැමිණියා.'
            : 'Returned to Home screen.');
      }
      return;
    }

    // Route search (e.g. "find route to [destination]", "take me to [X]", "go to [X]")
    final destination = _extractDestination(cleaned);
    if (destination != null && destination.isNotEmpty) {
      await _triggerRouteSearch(destination, context);
      return;
    }

    // If unhandled, inform user politely
    final unhandled = _language == AppLanguage.sinhala
        ? 'සමාවන්න, මට "$rawCommand" විධානය හඳුනාගත නොහැකි විය. උපකාර සඳහා "උපකාර" යැයි පවසන්න.'
        : 'Sorry, I did not recognize "$rawCommand". Say "help" to hear available commands.';
    await speak(unhandled);
  }

  String? _extractDestination(String command) {
    final patterns = [
      RegExp(r'(?:find route to|find routes to|route to|directions to|directions for|go to|take me to|navigate to|search route to|search for|bus to|train to)\s+(.+)', caseSensitive: false),
      RegExp(r'(.+)\s+(?:දක්වා මාර්ග|වෙත මාර්ග|යන්න|සොයන්න)', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(command);
      if (match != null && match.groupCount >= 1) {
        final dest = match.group(1)?.trim();
        // Discard if destination is just general command like 'home' or 'preferences'
        if (dest != null &&
            dest != 'home' &&
            dest != 'preferences' &&
            dest != 'settings' &&
            dest != 'help') {
          return dest;
        }
      }
    }

    return null;
  }

  Future<void> _triggerRouteSearch(String destination, BuildContext? context) async {
    final nav = _getNavigator(context);

    await speak(_language == AppLanguage.sinhala
        ? '$destination දක්වා ප්‍රවේශසහිත මාර්ග සොයමින් පවතී...'
        : 'Searching accessible routes to $destination...');

    if (nav != null) {
      // Pop back to home first if needed, then perform search
      nav.popUntil((route) => route.isFirst);

      // We broadcast so HomePage can update text fields and search
      _searchDestinationStreamController.add(destination);
    }
  }

  final StreamController<String> _searchDestinationStreamController =
      StreamController<String>.broadcast();
  Stream<String> get onVoiceDestinationRequested =>
      _searchDestinationStreamController.stream;

  void _updatePreference(AccessibilityPreferences Function(AccessibilityPreferences) update) {
    if (onGetPreferences != null && onUpdatePreferences != null) {
      final current = onGetPreferences!() ?? const AccessibilityPreferences();
      final updated = update(current);
      onUpdatePreferences!(updated);
      syncPreferences(updated);
    }
  }

  NavigatorState? _getNavigator(BuildContext? context) {
    if (navigatorKey?.currentState != null) {
      return navigatorKey!.currentState;
    }
    if (context != null && context.mounted) {
      return Navigator.of(context);
    }
    return null;
  }

  @override
  void dispose() {
    _searchDestinationStreamController.close();
    super.dispose();
  }
}

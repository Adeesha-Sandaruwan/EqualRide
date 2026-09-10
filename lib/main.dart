import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'models/accessibility_preferences.dart';
import 'screens/accessibility_report_page.dart';
import 'screens/auth_page.dart';
import 'screens/home_page.dart';
import 'screens/preferences_page.dart';
import 'services/auth_service.dart';
import 'services/user_profile_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const EqualRideApp());
}

class EqualRideApp extends StatefulWidget {
  const EqualRideApp({super.key});

  @override
  State<EqualRideApp> createState() => _EqualRideAppState();
}

class _EqualRideAppState extends State<EqualRideApp> {
  AccessibilityPreferences displayPreferences =
      const AccessibilityPreferences();

  void updateDisplayPreferences(AccessibilityPreferences preferences) {
    setState(() {
      displayPreferences = preferences;
    });
  }

  ThemeData get appTheme {
    final baseTheme = AppTheme.darkTheme;

    if (!displayPreferences.highContrast) {
      return baseTheme;
    }

    return baseTheme.copyWith(
      scaffoldBackgroundColor: Colors.black,
      dividerColor: Colors.white,
      colorScheme: baseTheme.colorScheme.copyWith(
        primary: Colors.yellowAccent,
        onPrimary: Colors.black,
        secondary: Colors.cyanAccent,
        onSecondary: Colors.black,
        surface: Colors.black,
        onSurface: Colors.white,
      ),
      textTheme: baseTheme.textTheme.apply(
        bodyColor: Colors.white,
        displayColor: Colors.white,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EqualRide',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: appTheme,
      theme: appTheme,
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);

        Widget app = MediaQuery(
          data: mediaQuery.copyWith(
            textScaler: TextScaler.linear(displayPreferences.textScale),
          ),
          child: child ?? const SizedBox.shrink(),
        );

        if (displayPreferences.highContrast) {
          app = ColorFiltered(
            colorFilter: const ColorFilter.matrix([
              1.6, 0, 0, 0, -64,
              0, 1.6, 0, 0, -64,
              0, 0, 1.6, 0, -64,
              0, 0, 0, 1, 0,
            ]),
            child: app,
          );
        }

        return app;
      },
      home: AppRouter(
        onPreferencesChanged: updateDisplayPreferences,
      ),
    );
  }
}

class AppRouter extends StatelessWidget {
  const AppRouter({
    super.key,
    required this.onPreferencesChanged,
  });

  final ValueChanged<AccessibilityPreferences> onPreferencesChanged;

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const LoadingPage();
        }

        final user = authSnapshot.data;

        if (user == null) {
          return const AuthPage();
        }

        return UserSetupRouter(
          user: user,
          onPreferencesChanged: onPreferencesChanged,
        );
      },
    );
  }
}

class UserSetupRouter extends StatefulWidget {
  const UserSetupRouter({
    super.key,
    required this.user,
    required this.onPreferencesChanged,
  });

  final User user;
  final ValueChanged<AccessibilityPreferences> onPreferencesChanged;

  @override
  State<UserSetupRouter> createState() => _UserSetupRouterState();
}

class _UserSetupRouterState extends State<UserSetupRouter> {
  late Future<AccessibilityPreferences?> preferencesFuture;
  final profileService = UserProfileService();

  double? appliedTextScale;
  bool? appliedHighContrast;

  @override
  void initState() {
    super.initState();
    refreshPreferences();
  }

  void refreshPreferences() {
    preferencesFuture = profileService.getPreferences(widget.user.uid);
  }

  void applyDisplayPreferences(AccessibilityPreferences preferences) {
    final alreadyApplied =
        appliedTextScale == preferences.textScale &&
            appliedHighContrast == preferences.highContrast;

    if (alreadyApplied) return;

    appliedTextScale = preferences.textScale;
    appliedHighContrast = preferences.highContrast;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.onPreferencesChanged(preferences);
      }
    });
  }

  Future<void> savePreferences(
    AccessibilityPreferences preferences,
  ) async {
    await profileService.savePreferences(
      userId: widget.user.uid,
      email: widget.user.email ?? '',
      preferences: preferences,
    );

    applyDisplayPreferences(preferences);

    if (mounted) {
      setState(refreshPreferences);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AccessibilityPreferences?>(
      future: preferencesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingPage();
        }

        final preferences = snapshot.data;

        if (preferences == null) {
          return PreferencesPage(
            initialPreferences: const AccessibilityPreferences(),
            onSave: savePreferences,
          );
        }

        applyDisplayPreferences(preferences);

        return HomePage(
          email: widget.user.email ?? 'User',
          preferences: preferences,
          onLogout: AuthService().logout,
          onEditPreferences: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => PreferencesPage(
                  initialPreferences: preferences,
                  onSave: savePreferences,
                ),
              ),
            );

            if (mounted) {
              setState(refreshPreferences);
            }
          },
          onReportAccessibilityIssue: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const AccessibilityReportPage(),
              ),
            );
          },
        );
      },
    );
  }
}

class LoadingPage extends StatelessWidget {
  const LoadingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
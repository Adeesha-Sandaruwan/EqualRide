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

class EqualRideApp extends StatelessWidget {
  const EqualRideApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EqualRide',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: AppTheme.darkTheme,
      theme: AppTheme.darkTheme,
      home: const AppRouter(),
    );
  }
}

class AppRouter extends StatelessWidget {
  const AppRouter({super.key});

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

        return UserSetupRouter(user: user);
      },
    );
  }
}

class UserSetupRouter extends StatefulWidget {
  const UserSetupRouter({
    super.key,
    required this.user,
  });

  final User user;

  @override
  State<UserSetupRouter> createState() => _UserSetupRouterState();
}

class _UserSetupRouterState extends State<UserSetupRouter> {
  late Future<AccessibilityPreferences?> _preferencesFuture;
  final profileService = UserProfileService();

  @override
  void initState() {
    super.initState();
    _refreshPreferences();
  }

  void _refreshPreferences() {
    _preferencesFuture = profileService.getPreferences(widget.user.uid);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AccessibilityPreferences?>(
      future: _preferencesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingPage();
        }

        final preferences = snapshot.data;

        if (preferences == null) {
          return PreferencesPage(
            initialPreferences: const AccessibilityPreferences(),
            onSave: (newPreferences) async {
              await profileService.savePreferences(
                userId: widget.user.uid,
                email: widget.user.email ?? '',
                preferences: newPreferences,
              );
              // Refresh preferences and rebuild
              if (mounted) {
                setState(() {
                  _refreshPreferences();
                });
              }
            },
          );
        }

        return HomePage(
          email: widget.user.email ?? 'User',
          preferences: preferences,
          onLogout: AuthService().logout,
          onEditPreferences: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) {
                  return PreferencesPage(
                    initialPreferences: preferences,
                    onSave: (newPreferences) async {
                      await profileService.savePreferences(
                        userId: widget.user.uid,
                        email: widget.user.email ?? '',
                        preferences: newPreferences,
                      );
                      // Pop back to HomePage
                      if (mounted) {
                        Navigator.of(context).pop();
                      }
                    },
                  );
                },
              ),
            );
            // After PreferencesPage closes, refresh preferences
            if (mounted) {
              setState(() {
                _refreshPreferences();
              });
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
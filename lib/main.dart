import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'models/accessibility_preferences.dart';
import 'screens/auth_page.dart';
import 'screens/home_page.dart';
import 'screens/preferences_page.dart';
import 'services/auth_service.dart';
import 'services/user_profile_service.dart';

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
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
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

class UserSetupRouter extends StatelessWidget {
  const UserSetupRouter({
    super.key,
    required this.user,
  });

  final User user;

  @override
  Widget build(BuildContext context) {
    final profileService = UserProfileService();

    return FutureBuilder<AccessibilityPreferences?>(
      future: profileService.getPreferences(user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingPage();
        }

        final preferences = snapshot.data;

        if (preferences == null) {
          return PreferencesPage(
            initialPreferences: const AccessibilityPreferences(),
            onSave: (newPreferences) {
              profileService.savePreferences(
                userId: user.uid,
                email: user.email ?? '',
                preferences: newPreferences,
              );
            },
          );
        }

        return HomePage(
          email: user.email ?? 'User',
          preferences: preferences,
          onLogout: AuthService().logout,
          onEditPreferences: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) {
                  return PreferencesPage(
                    initialPreferences: preferences,
                    onSave: (newPreferences) {
                      profileService.savePreferences(
                        userId: user.uid,
                        email: user.email ?? '',
                        preferences: newPreferences,
                      );
                    },
                  );
                },
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
import 'package:flutter/material.dart';

import 'models/accessibility_preferences.dart';
import 'screens/auth_page.dart';
import 'screens/home_page.dart';
import 'screens/preferences_page.dart';

void main() {
  runApp(const InclusiveTransportApp());
}

class InclusiveTransportApp extends StatefulWidget {
  const InclusiveTransportApp({super.key});

  @override
  State<InclusiveTransportApp> createState() =>
      _InclusiveTransportAppState();
}

class _InclusiveTransportAppState extends State<InclusiveTransportApp> {
  String? registeredEmail;
  String? registeredPassword;

  AccessibilityPreferences preferences = const AccessibilityPreferences();
  AppPage page = AppPage.auth;

  void registerUser(String email, String password) {
    setState(() {
      registeredEmail = email;
      registeredPassword = password;
      page = AppPage.preferences;
    });
  }

  bool logIn(String email, String password) {
    final isValid =
        email == registeredEmail && password == registeredPassword;

    if (isValid) {
      setState(() => page = AppPage.home);
    }

    return isValid;
  }

  void savePreferences(AccessibilityPreferences newPreferences) {
    setState(() {
      preferences = newPreferences;
      page = AppPage.home;
    });
  }

  void openPreferences() {
    setState(() => page = AppPage.preferences);
  }

  void logOut() {
    setState(() => page = AppPage.auth);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Inclusive Transport Companion',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: switch (page) {
        AppPage.auth => AuthPage(
            onRegister: registerUser,
            onLogin: logIn,
          ),
        AppPage.preferences => PreferencesPage(
            initialPreferences: preferences,
            onSave: savePreferences,
          ),
        AppPage.home => HomePage(
            email: registeredEmail ?? 'User',
            preferences: preferences,
            onLogout: logOut,
            onEditPreferences: openPreferences,
          ),
      },
    );
  }
}

enum AppPage { auth, preferences, home }
import 'package:flutter/material.dart';

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
  AccessibilityPreferences preferences = AccessibilityPreferences();

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
            onEditPreferences: () {
              setState(() => page = AppPage.preferences);
            },
          ),
      },
    );
  }
}

enum AppPage { auth, preferences, home }

class AccessibilityPreferences {
  final bool stepFreeRoutes;
  final bool lowCrowding;
  final bool prioritySeating;
  final bool accessibilityAlerts;

  AccessibilityPreferences({
    this.stepFreeRoutes = true,
    this.lowCrowding = false,
    this.prioritySeating = true,
    this.accessibilityAlerts = true,
  });
}

class AuthPage extends StatefulWidget {
  const AuthPage({
    super.key,
    required this.onRegister,
    required this.onLogin,
  });

  final void Function(String email, String password) onRegister;
  final bool Function(String email, String password) onLogin;

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLogin = false;
  bool obscurePassword = true;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void submit() {
    if (!formKey.currentState!.validate()) return;

    final email = emailController.text.trim();
    final password = passwordController.text;

    if (isLogin) {
      final success = widget.onLogin(email, password);

      if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Account not found. Register first, then use those details to log in.',
            ),
          ),
        );
      }
    } else {
      widget.onRegister(email, password);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = isLogin ? 'Welcome back' : 'Create your account';
    final buttonLabel = isLogin ? 'Log in' : 'Create account';

    return Scaffold(
      appBar: AppBar(title: const Text('Inclusive Transport Companion')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(Icons.accessible_forward,
                        size: 72, color: Colors.teal),
                    const SizedBox(height: 16),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Start planning public-transport journeys around your accessibility needs.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      decoration: const InputDecoration(
                        labelText: 'Email address',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Enter your email address.';
                        }
                        if (!value.contains('@')) {
                          return 'Enter a valid email address.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: passwordController,
                      obscureText: obscurePassword,
                      autofillHints: const [AutofillHints.password],
                      decoration: InputDecoration(
                        labelText: 'Password',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          tooltip: obscurePassword
                              ? 'Show password'
                              : 'Hide password',
                          icon: Icon(
                            obscurePassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() => obscurePassword = !obscurePassword);
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.length < 6) {
                          return 'Use at least 6 characters.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: submit,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(buttonLabel),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() => isLogin = !isLogin);
                      },
                      child: Text(
                        isLogin
                            ? 'Need an account? Create one'
                            : 'Already have an account? Log in',
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Demo note: accounts are kept only while this app is running. A secure backend will replace this in a later task.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class PreferencesPage extends StatefulWidget {
  const PreferencesPage({
    super.key,
    required this.initialPreferences,
    required this.onSave,
  });

  final AccessibilityPreferences initialPreferences;
  final void Function(AccessibilityPreferences preferences) onSave;

  @override
  State<PreferencesPage> createState() => _PreferencesPageState();
}

class _PreferencesPageState extends State<PreferencesPage> {
  late bool stepFreeRoutes;
  late bool lowCrowding;
  late bool prioritySeating;
  late bool accessibilityAlerts;

  @override
  void initState() {
    super.initState();
    stepFreeRoutes = widget.initialPreferences.stepFreeRoutes;
    lowCrowding = widget.initialPreferences.lowCrowding;
    prioritySeating = widget.initialPreferences.prioritySeating;
    accessibilityAlerts = widget.initialPreferences.accessibilityAlerts;
  }

  void save() {
    widget.onSave(
      AccessibilityPreferences(
        stepFreeRoutes: stepFreeRoutes,
        lowCrowding: lowCrowding,
        prioritySeating: prioritySeating,
        accessibilityAlerts: accessibilityAlerts,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Accessibility preferences')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Personalise your journeys',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          const Text(
            'These settings will later be used when finding and comparing routes.',
          ),
          const SizedBox(height: 24),
          SwitchListTile(
            title: const Text('Prefer step-free routes'),
            subtitle: const Text('Prioritise ramps, lifts and step-free access.'),
            value: stepFreeRoutes,
            onChanged: (value) => setState(() => stepFreeRoutes = value),
          ),
          SwitchListTile(
            title: const Text('Avoid crowded transport'),
            subtitle: const Text('Prioritise lower crowd-level updates when available.'),
            value: lowCrowding,
            onChanged: (value) => setState(() => lowCrowding = value),
          ),
          SwitchListTile(
            title: const Text('Show priority-seat information'),
            subtitle: const Text('Include reported priority-seat availability.'),
            value: prioritySeating,
            onChanged: (value) => setState(() => prioritySeating = value),
          ),
          SwitchListTile(
            title: const Text('Accessibility alerts'),
            subtitle: const Text('Receive relevant accessibility-condition alerts later.'),
            value: accessibilityAlerts,
            onChanged: (value) =>
                setState(() => accessibilityAlerts = value),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: save,
            child: const Padding(
              padding: EdgeInsets.all(12),
              child: Text('Save preferences'),
            ),
          ),
        ],
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({
    super.key,
    required this.email,
    required this.preferences,
    required this.onLogout,
    required this.onEditPreferences,
  });

  final String email;
  final AccessibilityPreferences preferences;
  final VoidCallback onLogout;
  final VoidCallback onEditPreferences;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inclusive Transport Companion'),
        actions: [
          IconButton(
            tooltip: 'Log out',
            icon: const Icon(Icons.logout),
            onPressed: onLogout,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Welcome, $email',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            const Text(
              'Sprint 1 user-management increment is working. Route planning and community reports belong to later Jira work.',
            ),
            const SizedBox(height: 24),
            Card(
              child: ListTile(
                leading: const Icon(Icons.tune),
                title: const Text('Your accessibility preferences'),
                subtitle: Text(
                  preferences.stepFreeRoutes
                      ? 'Step-free routes are preferred'
                      : 'No step-free route preference selected',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: onEditPreferences,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
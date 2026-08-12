import 'package:flutter/material.dart';

import '../models/accessibility_preferences.dart';

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
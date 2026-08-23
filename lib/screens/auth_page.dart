import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/equal_ride_background.dart';
import '../widgets/glass_panel.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final authService = AuthService();

  bool isLogin = false;
  bool obscurePassword = true;
  bool isSubmitting = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (!formKey.currentState!.validate()) return;

    setState(() => isSubmitting = true);

    try {
      final email = emailController.text.trim();
      final password = passwordController.text;

      if (isLogin) {
        await authService.login(email: email, password: password);
      } else {
        await authService.register(email: email, password: password);
      }
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(authErrorMessage(error.code))),
      );
    } finally {
      if (mounted) setState(() => isSubmitting = false);
    }
  }

  String authErrorMessage(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'An account already exists for this email.';
      case 'invalid-email':
        return 'Enter a valid email address.';
      case 'weak-password':
        return 'Use a stronger password with at least 6 characters.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Email or password is incorrect.';
      default:
        return 'Unable to continue. Please try again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = isLogin ? 'Welcome back' : 'Move freely, your way';
    final buttonLabel = isLogin ? 'Log in' : 'Create account';

    return Scaffold(
      body: EqualRideBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _BrandHeader(),
                    const SizedBox(height: 32),
                    GlassPanel(
                      child: Form(
                        key: formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              title,
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              isLogin
                                  ? 'Sign in to continue planning accessible journeys.'
                                  : 'Create an account to personalise every journey.',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 28),
                            TextFormField(
                              controller: emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(
                                labelText: 'Email address',
                                hintText: 'you@example.com',
                                prefixIcon: Icon(Icons.mail_outline_rounded),
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
                              decoration: InputDecoration(
                                labelText: 'Password',
                                hintText: 'At least 6 characters',
                                prefixIcon:
                                    const Icon(Icons.lock_outline_rounded),
                                suffixIcon: IconButton(
                                  tooltip: obscurePassword
                                      ? 'Show password'
                                      : 'Hide password',
                                  icon: Icon(
                                    obscurePassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                  ),
                                  onPressed: () {
                                    setState(
                                      () => obscurePassword = !obscurePassword,
                                    );
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
                              onPressed: isSubmitting ? null : submit,
                              child: isSubmitting
                                  ? const SizedBox(
                                      height: 22,
                                      width: 22,
                                      child: CircularProgressIndicator(
                                        color: AppTheme.navy,
                                        strokeWidth: 2.5,
                                      ),
                                    )
                                  : Text(buttonLabel),
                            ),
                            const SizedBox(height: 10),
                            TextButton(
                              onPressed: isSubmitting
                                  ? null
                                  : () {
                                      setState(() => isLogin = !isLogin);
                                    },
                              child: Text(
                                isLogin
                                    ? 'New to EqualRide? Create an account'
                                    : 'Already have an account? Log in',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    const _TrustMessage(),
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

class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          height: 54,
          width: 54,
          decoration: BoxDecoration(
            color: AppTheme.teal,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: AppTheme.teal.withOpacity(0.30),
                blurRadius: 22,
              ),
            ],
          ),
          child: const Icon(
            Icons.accessible_forward_rounded,
            color: AppTheme.navy,
            size: 30,
          ),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'EqualRide',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const Text(
              'Accessible travel companion',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ],
        ),
      ],
    );
  }
}

class _TrustMessage extends StatelessWidget {
  const _TrustMessage();

  @override
  Widget build(BuildContext context) {
    return const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.verified_user_outlined, color: AppTheme.aqua),
        SizedBox(width: 10),
        Expanded(
          child: Text(
            'Your account and accessibility preferences are stored securely.',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
        ),
      ],
    );
  }
}
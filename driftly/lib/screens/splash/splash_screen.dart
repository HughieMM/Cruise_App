import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Splash Screen - Auth Gate
///
/// This screen:
/// 1. Shows a loading indicator while checking auth state
/// 2. Checks if user is logged in via Firebase Auth
/// 3. Routes to appropriate screen:
///    - Not logged in → /auth
///    - Logged in but incomplete profile → /onboarding/profile
///    - Logged in with profile → /home
///
/// TODO: Add Firebase Auth state listener in a future prompt
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }

  Future<void> _checkAuthState() async {
    // Simulate auth check delay
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // TODO: Replace with actual Firebase Auth check
    // For now, always route to auth screen
    final bool isLoggedIn = false;

    if (isLoggedIn) {
      // TODO: Check if profile is complete
      context.go('/home');
    } else {
      context.go('/auth');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Driftly Logo/Icon (placeholder)
            Icon(
              Icons.sailing,
              size: 100,
              color: Colors.white,
            ),
            const SizedBox(height: 24),
            const Text(
              'Driftly',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Connect Before You Sail',
              style: TextStyle(
                fontSize: 18,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

/// Splash Screen - Auth Gate
///
/// This screen:
/// 1. Shows a loading indicator while checking auth state
/// 2. Checks if user is logged in via Firebase Auth
/// 3. Routes to appropriate screen:
///    - Not logged in → /auth
///    - Logged in but incomplete profile → /onboarding/profile
///    - Logged in with profile → /home
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
    // Give a small delay for splash screen visibility
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Wait for auth state to be initialized
    // The AuthProvider's constructor already starts listening to auth changes
    // Give it a moment to load the initial state
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    // Check authentication and profile status
    if (authProvider.isSignedIn) {
      // User is logged in, check profile completeness
      if (authProvider.hasProfile) {
        // Profile exists, check if it's complete
        if (authProvider.appUser!.isProfileComplete) {
          // Profile is complete, go to home
          context.go('/home');
        } else {
          // Profile incomplete - check what's missing
          final user = authProvider.appUser!;
          if (user.currentSailingId == null) {
            // No sailing selected, go to sailing selection
            context.go('/onboarding/sailing');
          } else {
            // Has sailing but might be missing other data
            // For now, send to profile to complete
            context.go('/onboarding/profile');
          }
        }
      } else {
        // No profile exists yet, start onboarding
        context.go('/onboarding/profile');
      }
    } else {
      // User not logged in, go to auth screen
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

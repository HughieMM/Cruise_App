import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_background.dart';
import '../../widgets/driftly_glyph.dart';

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
    final splashVisibility = Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Wait for the real auth-state + profile-load work to finish, however
    // long that takes, instead of guessing with a fixed delay — a slow
    // Firestore fetch on a real device easily exceeds a short guess,
    // which was sending fully-onboarded returning users into onboarding
    // just because their profile hadn't loaded in time yet.
    if (authProvider.isLoading) {
      await _waitForAuthReady(authProvider);
    }

    // Still respect the splash's minimum visible time even if auth
    // resolved instantly.
    await splashVisibility;

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

  /// Resolves once [authProvider] finishes its initial auth-state +
  /// profile load (isLoading flips to false), or after a generous
  /// timeout — so a genuine network failure still falls through to a
  /// routing decision instead of hanging the splash screen forever.
  Future<void> _waitForAuthReady(AuthProvider authProvider) {
    final completer = Completer<void>();

    void listener() {
      if (!authProvider.isLoading && !completer.isCompleted) {
        completer.complete();
      }
    }

    authProvider.addListener(listener);

    final timeout = Future.delayed(const Duration(seconds: 10), () {
      if (!completer.isCompleted) completer.complete();
    });

    return completer.future.whenComplete(() {
      authProvider.removeListener(listener);
      timeout.ignore();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: AppBackground(
        variant: BackgroundVariant.starfield,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const DriftlyGlyph(),
              const SizedBox(height: 24),
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [AppColors.teal, Colors.white],
                ).createShader(bounds),
                child: Text(
                  'Driftly',
                  style: AppTextStyles.displayLarge.copyWith(fontSize: 52),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'CONNECT BEFORE YOU SAIL',
                style: AppTextStyles.smallCaps(color: AppColors.teal),
              ),
              const SizedBox(height: 48),
              const CircularProgressIndicator(
                color: AppColors.teal,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

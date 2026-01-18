import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../screens/splash/splash_screen.dart';
import '../../screens/auth/sign_in_sign_up_screen.dart';
import '../../screens/onboarding/onboarding_profile_screen.dart';
import '../../screens/onboarding/select_sailing_screen.dart';
import '../../screens/onboarding/choose_pods_screen.dart';
import '../../screens/home/home_shell.dart';

/// Driftly App Router Configuration
///
/// Routes:
/// - / (splash) → Auth gate checks if user is logged in
/// - /auth → Sign in / Sign up screen
/// - /onboarding/profile → User profile setup
/// - /onboarding/sailing → Choose cruise line, ship, and date
/// - /onboarding/pods → Select 1-3 pods to join
/// - /home → Main app with bottom navigation (Home, Pods, Hangouts, Hot Zones, Profile)
class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
    routes: [
      // Splash Screen (Auth Gate)
      GoRoute(
        path: '/',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),

      // Authentication
      GoRoute(
        path: '/auth',
        name: 'auth',
        builder: (context, state) => const SignInSignUpScreen(),
      ),

      // Onboarding Flow
      GoRoute(
        path: '/onboarding/profile',
        name: 'onboarding-profile',
        builder: (context, state) => const OnboardingProfileScreen(),
      ),
      GoRoute(
        path: '/onboarding/sailing',
        name: 'onboarding-sailing',
        builder: (context, state) => const SelectSailingScreen(),
      ),
      GoRoute(
        path: '/onboarding/pods',
        name: 'onboarding-pods',
        builder: (context, state) => const ChoosePodsScreen(),
      ),

      // Main App (Home Shell with Bottom Navigation)
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) {
          // Extract tab query parameter if provided
          final tab = state.uri.queryParameters['tab'] ?? 'home';
          return HomeShell(initialTab: tab);
        },
      ),
    ],

    // Error handling
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Error: ${state.error}'),
      ),
    ),
  );
}

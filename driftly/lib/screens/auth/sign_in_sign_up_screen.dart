import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_background.dart';
import '../../widgets/driftly_glyph.dart';
import '../../widgets/pill_button.dart';
import '../../widgets/small_caps_label.dart';

/// Sign In / Sign Up Screen
///
/// Features:
/// - Email/password authentication with Firebase Auth
/// - Toggle between sign-in and sign-up modes
/// - Form validation
///
/// Flow:
/// - After successful sign-up → /onboarding/profile
/// - After successful sign-in → Check profile completeness → /home or /onboarding
class SignInSignUpScreen extends StatefulWidget {
  const SignInSignUpScreen({super.key});

  @override
  State<SignInSignUpScreen> createState() => _SignInSignUpScreenState();
}

class _SignInSignUpScreenState extends State<SignInSignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isSignUp = false;
  bool _obscurePassword = true;
  bool _showForm = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleAuth() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    bool success;
    if (_isSignUp) {
      success = await authProvider.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
    } else {
      success = await authProvider.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
    }

    if (!mounted) return;

    if (success) {
      // For sign-up, navigate to onboarding
      if (_isSignUp) {
        context.go('/onboarding/profile');
      }
      // For sign-in, navigation handled by splash screen
    } else {
      // Show error message
      final error = authProvider.errorMessage ?? 'Authentication failed';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: AppBackground(
        variant: BackgroundVariant.starfield,
        child: SafeArea(
          child: _showForm ? _buildForm(context) : _buildWelcome(context),
        ),
      ),
    );
  }

  Widget _buildWelcome(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Center(child: DriftlyGlyph(size: 150)),
            const SizedBox(height: 24),
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [AppColors.teal, Colors.white],
              ).createShader(bounds),
              child: Text(
                'Driftly',
                textAlign: TextAlign.center,
                style: AppTextStyles.displayLarge.copyWith(fontSize: 48),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: SmallCapsLabel('Life at Sea · Connected', color: AppColors.teal),
            ),
            const SizedBox(height: 16),
            Text(
              'Find your crew. Discover the ship.\nStay in the drift.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySecondary.copyWith(fontSize: 15),
            ),
            const SizedBox(height: 48),
            PillButton(
              label: 'Board the Ship',
              color: AppColors.teal,
              onPressed: () => setState(() {
                _isSignUp = true;
                _showForm = true;
              }),
            ),
            const SizedBox(height: 12),
            PillButton(
              label: 'Sign in with Cruise ID',
              variant: PillVariant.outlined,
              color: Colors.white,
              onPressed: () => setState(() {
                _isSignUp = false;
                _showForm = true;
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: AppColors.teal),
                  onPressed: () => setState(() => _showForm = false),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _isSignUp ? 'Create Account' : 'Welcome Back',
                textAlign: TextAlign.center,
                style: AppTextStyles.displayMedium,
              ),
              const SizedBox(height: 8),
              Text(
                _isSignUp
                    ? 'Join Driftly and connect with fellow cruisers'
                    : 'Sign in to continue your journey',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySecondary,
              ),
              const SizedBox(height: 48),

              // Email Field
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email, color: AppColors.teal),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  if (!value.contains('@')) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Password Field
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _handleAuth(),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock, color: AppColors.teal),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your password';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Auth Button
              Consumer<AuthProvider>(
                builder: (context, authProvider, child) {
                  return PillButton(
                    label: authProvider.isLoading
                        ? '...'
                        : (_isSignUp ? 'Sign Up' : 'Sign In'),
                    color: AppColors.teal,
                    onPressed: authProvider.isLoading ? null : _handleAuth,
                  );
                },
              ),
              const SizedBox(height: 16),

              // Toggle Sign In / Sign Up
              TextButton(
                onPressed: () {
                  setState(() {
                    _isSignUp = !_isSignUp;
                  });
                  // Clear error when switching modes
                  Provider.of<AuthProvider>(context, listen: false)
                      .clearError();
                },
                child: Text(
                  _isSignUp
                      ? 'Already have an account? Sign In'
                      : "Don't have an account? Sign Up",
                  style: const TextStyle(color: AppColors.teal),
                ),
              ),

              // Error Message Display
              Consumer<AuthProvider>(
                builder: (context, authProvider, child) {
                  if (authProvider.errorMessage != null) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Text(
                        authProvider.errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.coral,
                          fontSize: 14,
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

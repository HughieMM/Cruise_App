import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_background.dart';
import '../../widgets/pill_button.dart';

/// Suspended Screen
///
/// Shown instead of the normal app for an account with isBanned: true —
/// reached a 3rd content-moderation strike. Sign out is the only action;
/// there's no in-app appeals flow, so a false-positive ban has to be
/// reversed manually (Firebase console) for now.
class SuspendedScreen extends StatelessWidget {
  const SuspendedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: AppBackground(
        variant: BackgroundVariant.starfield,
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.block, size: 64, color: AppColors.coral),
                  const SizedBox(height: 24),
                  Text(
                    'Account Suspended',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.displaySmall,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Your account was suspended for repeated violations of '
                    'our community guidelines.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodySecondary,
                  ),
                  const SizedBox(height: 40),
                  PillButton(
                    label: 'Sign Out',
                    color: AppColors.coral,
                    onPressed: () async {
                      await Provider.of<AuthProvider>(context, listen: false).signOut();
                      if (context.mounted) context.go('/auth');
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

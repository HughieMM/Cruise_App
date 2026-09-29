import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/content_moderation_service.dart';

/// Shows the right dialog for a blocked message — a warning with the
/// remaining-strikes count, or a distinct "suspended" dialog that signs
/// the user out — shared across Pod/Tribe/DM chat since all three throw
/// the same ContentModerationException on a blocked send.
Future<void> showModerationResultDialog(
  BuildContext context,
  ModerationCheckResult result,
) async {
  if (result.justBanned) {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Account Suspended'),
        content: const Text(
          'Your account has been suspended for repeated violations of '
          'our community guidelines.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );

    if (!context.mounted) return;
    await Provider.of<AuthProvider>(context, listen: false).signOut();
    if (!context.mounted) return;
    context.go('/suspended');
    return;
  }

  final remaining = 2 - result.strikeCount + 1;
  await showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Message not sent'),
      content: Text(
        remaining > 0
            ? 'That message violates our community guidelines. '
                'Warning ${result.strikeCount} of 2 — $remaining more before '
                'your account is suspended.'
            : 'That message violates our community guidelines. '
                'This was your final warning.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}

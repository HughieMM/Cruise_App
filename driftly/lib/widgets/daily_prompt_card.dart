import 'package:flutter/material.dart';
import '../models/daily_prompt.dart';

/// Displays the daily prompt for a pod
/// Shows a category-relevant conversation starter
class DailyPromptCard extends StatelessWidget {
  final String podName;
  final VoidCallback? onTap;

  const DailyPromptCard({
    super.key,
    required this.podName,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final prompt = DailyPrompts.getTodaysPrompt(podName);

    if (prompt == null) return const SizedBox.shrink();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.purple.withOpacity(0.3),
              Colors.blue.withOpacity(0.3),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  prompt.emoji,
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          "TODAY'S PROMPT",
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    prompt.prompt,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.white.withOpacity(0.5),
            ),
          ],
        ),
      ),
    );
  }
}

/// Inline prompt suggestion for chat input
class DailyPromptChip extends StatelessWidget {
  final String podName;
  final VoidCallback onTap;

  const DailyPromptChip({
    super.key,
    required this.podName,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final prompt = DailyPrompts.getTodaysPrompt(podName);

    if (prompt == null) return const SizedBox.shrink();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.purple.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.purple.withOpacity(0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(prompt.emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            const Text(
              "Daily Prompt",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.purple,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.auto_awesome,
              size: 14,
              color: Colors.purple.withOpacity(0.7),
            ),
          ],
        ),
      ),
    );
  }
}

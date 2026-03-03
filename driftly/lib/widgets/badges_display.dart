import 'package:flutter/material.dart';
import '../models/achievement_badge.dart';
import '../services/badge_service.dart';

/// Displays user's achievement badges
/// Can be used in profile or as a popup
class BadgesDisplay extends StatelessWidget {
  final String userId;
  final bool showAll; // Show all badges (earned + locked) or just earned

  const BadgesDisplay({
    super.key,
    required this.userId,
    this.showAll = false,
  });

  @override
  Widget build(BuildContext context) {
    final badgeService = BadgeService();

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: badgeService.getAllBadgesWithProgress(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final allBadges = snapshot.data ?? [];
        final badgesToShow = showAll
            ? allBadges
            : allBadges.where((b) => b['isEarned'] == true).toList();

        if (badgesToShow.isEmpty) {
          return const Center(
            child: Text(
              'No badges earned yet!\nStart participating to earn badges.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: badgesToShow.map((badgeData) {
            final info = badgeData['info'] as BadgeInfo;
            final isEarned = badgeData['isEarned'] as bool;
            final progress = badgeData['progress'] as int;

            return _BadgeItem(
              info: info,
              isEarned: isEarned,
              progress: progress,
            );
          }).toList(),
        );
      },
    );
  }
}

class _BadgeItem extends StatelessWidget {
  final BadgeInfo info;
  final bool isEarned;
  final int progress;

  const _BadgeItem({
    required this.info,
    required this.isEarned,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showBadgeDetails(context),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isEarned
                  ? Colors.amber.withOpacity(0.2)
                  : Colors.grey.withOpacity(0.2),
              border: Border.all(
                color: isEarned ? Colors.amber : Colors.grey.shade400,
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                info.icon,
                style: TextStyle(
                  fontSize: 28,
                  color: isEarned ? null : Colors.grey,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: 70,
            child: Text(
              info.name,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: isEarned ? Colors.white : Colors.grey,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (!isEarned && info.target > 1)
            Text(
              '$progress/${info.target}',
              style: TextStyle(
                fontSize: 9,
                color: Colors.grey.shade500,
              ),
            ),
        ],
      ),
    );
  }

  void _showBadgeDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isEarned
                    ? Colors.amber.withOpacity(0.2)
                    : Colors.grey.withOpacity(0.2),
              ),
              child: Center(
                child: Text(
                  info.icon,
                  style: const TextStyle(fontSize: 48),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              info.name,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              info.description,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 12),
            if (!isEarned) ...[
              LinearProgressIndicator(
                value: progress / info.target,
                backgroundColor: Colors.grey.shade300,
                valueColor: const AlwaysStoppedAnimation(Colors.amber),
              ),
              const SizedBox(height: 8),
              Text(
                '$progress / ${info.target}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ] else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 18),
                    SizedBox(width: 6),
                    Text(
                      'Earned!',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

/// Compact badge row for profile summary
class BadgesRow extends StatelessWidget {
  final String userId;
  final VoidCallback? onViewAll;

  const BadgesRow({
    super.key,
    required this.userId,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    final badgeService = BadgeService();

    return StreamBuilder<List<AchievementBadge>>(
      stream: badgeService.streamUserBadges(userId),
      builder: (context, snapshot) {
        final badges = snapshot.data ?? [];
        final displayBadges = badges.take(5).toList();
        final hasMore = badges.length > 5;

        return Row(
          children: [
            ...displayBadges.map((badge) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _SmallBadge(badge: badge),
                )),
            if (hasMore && onViewAll != null)
              GestureDetector(
                onTap: onViewAll,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey.withOpacity(0.3),
                  ),
                  child: Center(
                    child: Text(
                      '+${badges.length - 5}',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            if (badges.isEmpty)
              Text(
                'No badges yet',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              ),
          ],
        );
      },
    );
  }
}

class _SmallBadge extends StatelessWidget {
  final AchievementBadge badge;

  const _SmallBadge({required this.badge});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: badge.name,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.amber.withOpacity(0.2),
          border: Border.all(color: Colors.amber, width: 1.5),
        ),
        child: Center(
          child: Text(badge.icon, style: const TextStyle(fontSize: 16)),
        ),
      ),
    );
  }
}

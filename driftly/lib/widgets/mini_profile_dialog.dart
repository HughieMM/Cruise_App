import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../services/firestore_service.dart';
import '../services/connection_service.dart';
import '../models/app_user.dart';
import '../models/connection_request.dart';
import 'report_dialog.dart';

/// Shared mini profile dialog — shows a user's photos/age/social links with
/// Report/Block actions, used from both Pod and Tribe group chats.
///
/// [showConnectButton] gates the "First Mates" connect flow — deliberately
/// only ever passed true from Pod chat, never Tribe chat, so Tribe stays a
/// closed unit (no side-channel 1:1s forming from within it).
class MiniProfileDialog extends StatelessWidget {
  final String userId;
  final String userName;
  final String sailingId;
  final FirestoreService firestoreService;
  final bool showConnectButton;

  const MiniProfileDialog({
    super.key,
    required this.userId,
    required this.userName,
    required this.sailingId,
    required this.firestoreService,
    this.showConnectButton = false,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.grey[900],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: FutureBuilder<AppUser?>(
        future: firestoreService.getUser(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox(
              height: 200,
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final user = snapshot.data;
          if (user == null) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.person_off, size: 48, color: Colors.grey[600]),
                  const SizedBox(height: 16),
                  Text(
                    'Profile not found',
                    style: TextStyle(color: Colors.grey[400]),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ],
              ),
            );
          }

          // Collect all available photos
          final photos = <String>[
            if (user.facePhotoUrl != null) user.facePhotoUrl!,
            if (user.funPhotoUrl != null) user.funPhotoUrl!,
            if (user.wildcardPhotoUrl != null) user.wildcardPhotoUrl!,
          ];

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with name and age
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.name,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              user.ageBand,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue[300],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.grey),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Photo gallery (up to 3 photos)
                if (photos.isNotEmpty)
                  SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: photos.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: EdgeInsets.only(
                            right: index < photos.length - 1 ? 8 : 0,
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              photos[index],
                              width: 100,
                              height: 120,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 100,
                                  height: 120,
                                  color: Colors.grey[800],
                                  child: Icon(
                                    Icons.image_not_supported,
                                    color: Colors.grey[600],
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  )
                else
                  Container(
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.no_photography, color: Colors.grey[600]),
                          const SizedBox(height: 8),
                          Text(
                            'No photos yet',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Social Links
                if (user.socialLinks.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Divider(color: Colors.grey),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: user.socialLinks.entries.map((entry) {
                      return _SocialLinkChip(
                        platform: entry.key,
                        handle: entry.value,
                      );
                    }).toList(),
                  ),
                ],

                const SizedBox(height: 16),

                // Connect (First Mates) — Pod chat only
                Consumer<AuthProvider>(
                  builder: (context, authProvider, _) {
                    final currentUserId = authProvider.appUser?.uid;
                    final currentUserName = authProvider.appUser?.name ?? '';
                    if (!showConnectButton || currentUserId == null || currentUserId == userId) {
                      return const SizedBox.shrink();
                    }

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _ConnectButton(
                        sailingId: sailingId,
                        currentUserId: currentUserId,
                        currentUserName: currentUserName,
                        targetId: userId,
                        targetName: userName,
                      ),
                    );
                  },
                ),

                // Report & Block Actions
                Consumer<AuthProvider>(
                  builder: (context, authProvider, _) {
                    final currentUserId = authProvider.appUser?.uid;
                    // Don't show for own profile
                    if (currentUserId == null || currentUserId == userId) {
                      return const SizedBox.shrink();
                    }

                    return Column(
                      children: [
                        const Divider(color: Colors.grey),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            TextButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                showReportDialog(
                                  context: context,
                                  reporterId: currentUserId,
                                  reportedUserId: userId,
                                  contentType: 'user',
                                );
                              },
                              icon: const Icon(Icons.flag_outlined, size: 18),
                              label: const Text('Report'),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.orange,
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                showBlockDialog(
                                  context: context,
                                  userId: currentUserId,
                                  blockedUserId: userId,
                                  blockedUserName: userName,
                                );
                              },
                              icon: const Icon(Icons.block, size: 18),
                              label: const Text('Block'),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Connect button whose state (Connect / Request Sent / Message) is driven
/// by any existing connection request between the two users.
class _ConnectButton extends StatefulWidget {
  final String sailingId;
  final String currentUserId;
  final String currentUserName;
  final String targetId;
  final String targetName;

  const _ConnectButton({
    required this.sailingId,
    required this.currentUserId,
    required this.currentUserName,
    required this.targetId,
    required this.targetName,
  });

  @override
  State<_ConnectButton> createState() => _ConnectButtonState();
}

class _ConnectButtonState extends State<_ConnectButton> {
  final _connectionService = ConnectionService();
  late Future<ConnectionRequest?> _statusFuture;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _statusFuture = _connectionService.getConnectionBetween(
      sailingId: widget.sailingId,
      uidA: widget.currentUserId,
      uidB: widget.targetId,
    );
  }

  Future<void> _sendRequest() async {
    setState(() => _isSending = true);
    try {
      await _connectionService.sendConnectionRequest(
        sailingId: widget.sailingId,
        requesterId: widget.currentUserId,
        requesterName: widget.currentUserName,
        targetId: widget.targetId,
        targetName: widget.targetName,
      );
      if (!mounted) return;
      setState(() {
        _statusFuture = _connectionService.getConnectionBetween(
          sailingId: widget.sailingId,
          uidA: widget.currentUserId,
          uidB: widget.targetId,
        );
        _isSending = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send request: $e')),
      );
    }
  }

  void _openMessages(BuildContext context) {
    Navigator.pop(context); // close the profile dialog first
    context.push(
      '/messages/${widget.targetId}',
      extra: {'otherUserName': widget.targetName},
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ConnectionRequest?>(
      future: _statusFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 36,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }

        final request = snapshot.data;

        if (request == null) {
          return SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isSending ? null : _sendRequest,
              icon: _isSending
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.group_add, size: 18),
              label: const Text('Connect'),
            ),
          );
        }

        if (request.status == 'accepted') {
          return SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _openMessages(context),
              icon: const Icon(Icons.message_outlined, size: 18),
              label: const Text('Message'),
            ),
          );
        }

        if (request.status == 'pending') {
          return SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: null,
              icon: const Icon(Icons.hourglass_top, size: 18),
              label: const Text('Request Sent'),
            ),
          );
        }

        // Declined — allow trying again.
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isSending ? null : _sendRequest,
            icon: const Icon(Icons.group_add, size: 18),
            label: const Text('Connect'),
          ),
        );
      },
    );
  }
}

/// Social link chip widget
class _SocialLinkChip extends StatelessWidget {
  final String platform;
  final String handle;

  const _SocialLinkChip({
    required this.platform,
    required this.handle,
  });

  IconData _getIcon() {
    switch (platform.toLowerCase()) {
      case 'instagram':
        return Icons.camera_alt;
      case 'snapchat':
        return Icons.chat_bubble;
      case 'tiktok':
        return Icons.music_note;
      case 'twitter':
        return Icons.alternate_email;
      default:
        return Icons.link;
    }
  }

  Color _getColor() {
    switch (platform.toLowerCase()) {
      case 'instagram':
        return const Color(0xFFE4405F);
      case 'snapchat':
        return const Color(0xFFFFFC00);
      case 'tiktok':
        return const Color(0xFF00F2EA);
      case 'twitter':
        return const Color(0xFF1DA1F2);
      default:
        return Colors.blue;
    }
  }

  Future<void> _openSocialLink() async {
    String? url;
    switch (platform.toLowerCase()) {
      case 'instagram':
        url = 'https://instagram.com/$handle';
        break;
      case 'snapchat':
        url = 'https://snapchat.com/add/$handle';
        break;
      case 'tiktok':
        url = 'https://tiktok.com/@$handle';
        break;
      case 'twitter':
        url = 'https://twitter.com/$handle';
        break;
    }
    if (url != null) {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColor();
    return GestureDetector(
      onTap: _openSocialLink,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_getIcon(), size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              '@$handle',
              style: TextStyle(
                fontSize: 13,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

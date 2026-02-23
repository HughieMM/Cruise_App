import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../models/message.dart';
import '../../models/pod.dart';
import '../../models/app_user.dart';
import '../../utils/constants.dart';

/// Pod Chat Screen
///
/// Displays real-time group chat for a specific pod
/// Features:
/// - Real-time message streaming with StreamBuilder
/// - Send text messages
/// - Auto-scroll to bottom on new messages
/// - Visual distinction between own messages and others
class PodChatScreen extends StatefulWidget {
  final String sailingId;
  final String podId;
  final Pod pod;

  const PodChatScreen({
    super.key,
    required this.sailingId,
    required this.podId,
    required this.pod,
  });

  @override
  State<PodChatScreen> createState() => _PodChatScreenState();
}

class _PodChatScreenState extends State<PodChatScreen> {
  final _firestoreService = FirestoreService();
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isSending = false;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Check if message is expiring soon (within 1 hour of expiry)
  bool _isMessageExpiringSoon(DateTime timestamp) {
    final expiryTime = timestamp.add(AppConstants.messageExpiryDuration);
    final now = DateTime.now();
    final timeUntilExpiry = expiryTime.difference(now);
    return timeUntilExpiry.inHours <= 1 && timeUntilExpiry.inSeconds > 0;
  }

  // Check if message has expired
  bool _isMessageExpired(DateTime timestamp) {
    final expiryTime = timestamp.add(AppConstants.messageExpiryDuration);
    return DateTime.now().isAfter(expiryTime);
  }

  // Get time remaining until message expires
  String _getExpiryText(DateTime timestamp) {
    final expiryTime = timestamp.add(AppConstants.messageExpiryDuration);
    final timeLeft = expiryTime.difference(DateTime.now());

    if (timeLeft.inMinutes <= 0) {
      return 'Expired';
    } else if (timeLeft.inMinutes < 60) {
      return 'Expires in ${timeLeft.inMinutes}m';
    } else {
      return 'Expires in ${timeLeft.inHours}h';
    }
  }

  // Show mini profile dialog for a user
  Future<void> _showMiniProfile(String userId, String userName) async {
    showDialog(
      context: context,
      builder: (context) => _MiniProfileDialog(
        userId: userId,
        userName: userName,
        firestoreService: _firestoreService,
      ),
    );
  }

  // Helper to parse color from hex string
  Color _parseColor(String hexColor) {
    try {
      final hex = hexColor.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (e) {
      return Colors.blue;
    }
  }

  // Scroll to bottom of chat
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  // Send a message
  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.appUser;

    if (user == null) return;

    setState(() => _isSending = true);

    try {
      await _firestoreService.sendMessage(
        sailingId: widget.sailingId,
        podId: widget.podId,
        userId: user.uid,
        userName: user.name,
        text: text,
        userPhotoUrl: user.selfieUrl,
      );

      _messageController.clear();
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send message: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  // Format timestamp for display
  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays == 0) {
      // Today - show time only
      return DateFormat('h:mm a').format(timestamp);
    } else if (difference.inDays == 1) {
      // Yesterday
      return 'Yesterday ${DateFormat('h:mm a').format(timestamp)}';
    } else if (difference.inDays < 7) {
      // This week - show day and time
      return DateFormat('EEE h:mm a').format(timestamp);
    } else {
      // Older - show date and time
      return DateFormat('MMM d, h:mm a').format(timestamp);
    }
  }

  @override
  Widget build(BuildContext context) {
    final podColor = _parseColor(widget.pod.color);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.pod.name),
            Text(
              '${widget.pod.memberCount} members',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ],
        ),
        backgroundColor: podColor.withOpacity(0.1),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              // TODO: Show pod info/members
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              podColor.withOpacity(0.15),
              podColor.withOpacity(0.05),
              Colors.black.withOpacity(0.95),
            ],
            stops: const [0.0, 0.3, 1.0],
          ),
        ),
        child: Column(
          children: [
            // Messages List
            Expanded(
              child: Consumer<AuthProvider>(
                builder: (context, authProvider, child) {
                  final currentUserId = authProvider.appUser?.uid;

                  return StreamBuilder<List<Message>>(
                    stream: _firestoreService.streamMessages(
                      sailingId: widget.sailingId,
                      podId: widget.podId,
                      limit: 100,
                    ),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline, size: 48, color: Colors.red),
                              const SizedBox(height: 16),
                              Text(
                                'Error loading messages',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                snapshot.error.toString(),
                                style: Theme.of(context).textTheme.bodySmall,
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        );
                      }

                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      // Filter out expired messages
                      final messages = snapshot.data!
                          .where((m) => !_isMessageExpired(m.timestamp))
                          .toList();

                      if (messages.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.chat_bubble_outline,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No messages yet',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Be the first to say hello!',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Colors.grey[600],
                                    ),
                              ),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: podColor.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.timer_outlined, size: 16, color: podColor),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Messages expire after 10 hours',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: podColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      // Auto-scroll to bottom when new messages arrive
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _scrollToBottom();
                      });

                      return ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final message = messages[index];
                          final isOwnMessage = message.userId == currentUserId;
                          final showAvatar = index == 0 ||
                              messages[index - 1].userId != message.userId;

                          return _buildMessageBubble(
                            message: message,
                            isOwnMessage: isOwnMessage,
                            showAvatar: showAvatar,
                            podColor: podColor,
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),

            // Message Input
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[900],
                border: Border(
                  top: BorderSide(color: podColor.withOpacity(0.3), width: 1),
                ),
              ),
              padding: const EdgeInsets.all(8.0),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Expiry reminder
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.timer_outlined, size: 12, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            'Messages disappear after 10 hours',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        // Text Input
                        Expanded(
                          child: TextField(
                            controller: _messageController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'Type a message...',
                              hintStyle: TextStyle(color: Colors.grey[500]),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: BorderSide(color: Colors.grey[700]!),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: BorderSide(color: Colors.grey[700]!),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: BorderSide(color: podColor),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              filled: true,
                              fillColor: Colors.grey[850],
                            ),
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) => _sendMessage(),
                            maxLines: null,
                            textCapitalization: TextCapitalization.sentences,
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Send Button
                        CircleAvatar(
                          backgroundColor: podColor,
                          child: IconButton(
                            icon: _isSending
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.send, color: Colors.white),
                            onPressed: _isSending ? null : _sendMessage,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble({
    required Message message,
    required bool isOwnMessage,
    required bool showAvatar,
    required Color podColor,
  }) {
    final isExpiringSoon = _isMessageExpiringSoon(message.timestamp);
    final opacity = isExpiringSoon ? 0.7 : 1.0;

    return Opacity(
      opacity: opacity,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          mainAxisAlignment:
              isOwnMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Avatar (for other users) - clickable to show mini profile
            if (!isOwnMessage)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: showAvatar
                    ? GestureDetector(
                        onTap: () => _showMiniProfile(message.userId, message.userName),
                        child: message.userPhotoUrl != null
                            ? CircleAvatar(
                                radius: 16,
                                backgroundImage: NetworkImage(message.userPhotoUrl!),
                                backgroundColor: podColor.withOpacity(0.2),
                              )
                            : CircleAvatar(
                                radius: 16,
                                backgroundColor: podColor.withOpacity(0.2),
                                child: Text(
                                  message.userName.isNotEmpty
                                      ? message.userName[0].toUpperCase()
                                      : '?',
                                  style: TextStyle(
                                    color: podColor,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                      )
                    : const SizedBox(width: 32),
              ),

            // Message Bubble
            Flexible(
              child: Column(
                crossAxisAlignment: isOwnMessage
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  // Sender Name (for other users) - clickable
                  if (!isOwnMessage && showAvatar)
                    GestureDetector(
                      onTap: () => _showMiniProfile(message.userId, message.userName),
                      child: Padding(
                        padding: const EdgeInsets.only(left: 12, bottom: 4),
                        child: Text(
                          message.userName,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[400],
                          ),
                        ),
                      ),
                    ),

                  // Message Content
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isOwnMessage ? podColor : Colors.grey[800],
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(isOwnMessage ? 16 : 4),
                        bottomRight: Radius.circular(isOwnMessage ? 4 : 16),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          message.text,
                          style: TextStyle(
                            fontSize: 15,
                            color: isOwnMessage ? Colors.white : Colors.grey[100],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _formatTimestamp(message.timestamp),
                              style: TextStyle(
                                fontSize: 11,
                                color: isOwnMessage
                                    ? Colors.white.withOpacity(0.7)
                                    : Colors.grey[500],
                              ),
                            ),
                            // Show expiry indicator for messages expiring soon
                            if (isExpiringSoon) ...[
                              const SizedBox(width: 6),
                              Icon(
                                Icons.timer_outlined,
                                size: 12,
                                color: isOwnMessage
                                    ? Colors.white.withOpacity(0.7)
                                    : Colors.orange[300],
                              ),
                              const SizedBox(width: 2),
                              Text(
                                _getExpiryText(message.timestamp),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isOwnMessage
                                      ? Colors.white.withOpacity(0.7)
                                      : Colors.orange[300],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Spacing for own messages
            if (isOwnMessage) const SizedBox(width: 48),
          ],
        ),
      ),
    );
  }
}

/// Mini Profile Dialog - shows user profile with photos, age, and social links
class _MiniProfileDialog extends StatelessWidget {
  final String userId;
  final String userName;
  final FirestoreService firestoreService;

  const _MiniProfileDialog({
    required this.userId,
    required this.userName,
    required this.firestoreService,
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
                              color: Colors.blue.withOpacity(0.2),
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
              ],
            ),
          );
        },
      ),
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
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3)),
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

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../models/message.dart';
import '../../models/pod.dart';

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
      body: Column(
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

                    final messages = snapshot.data!;

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
              color: Theme.of(context).scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(8.0),
            child: SafeArea(
              child: Row(
                children: [
                  // Text Input
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: Colors.grey[300]!),
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
                        fillColor: Colors.grey[50],
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble({
    required Message message,
    required bool isOwnMessage,
    required bool showAvatar,
    required Color podColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isOwnMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Avatar (for other users)
          if (!isOwnMessage)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: showAvatar
                  ? CircleAvatar(
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
                // Sender Name (for other users)
                if (!isOwnMessage && showAvatar)
                  Padding(
                    padding: const EdgeInsets.only(left: 12, bottom: 4),
                    child: Text(
                      message.userName,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
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
                    color: isOwnMessage ? podColor : Colors.grey[200],
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
                          color: isOwnMessage ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatTimestamp(message.timestamp),
                        style: TextStyle(
                          fontSize: 11,
                          color: isOwnMessage
                              ? Colors.white.withOpacity(0.8)
                              : Colors.grey[600],
                        ),
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
    );
  }
}

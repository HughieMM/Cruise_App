import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/connection_service.dart';
import '../../models/message.dart';
import '../../theme/app_colors.dart';

/// Private 1:1 "First Mates" chat between two connected users. Reached
/// only after a Pod-originated connect request has been accepted — there
/// is no path into this screen from Tribe.
class DirectMessageScreen extends StatefulWidget {
  final String otherUserId;
  final String otherUserName;

  const DirectMessageScreen({
    super.key,
    required this.otherUserId,
    required this.otherUserName,
  });

  @override
  State<DirectMessageScreen> createState() => _DirectMessageScreenState();
}

class _DirectMessageScreenState extends State<DirectMessageScreen> {
  final _connectionService = ConnectionService();
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  late Future<String> _threadIdFuture;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId = authProvider.appUser!.uid;
    _threadIdFuture = _connectionService.getOrCreateThread(currentUserId, widget.otherUserId);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

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

  Future<void> _sendMessage(String threadId) async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.appUser;
    if (user == null) return;

    setState(() => _isSending = true);
    try {
      await _connectionService.sendDirectMessage(
        threadId: threadId,
        userId: user.uid,
        userName: user.name,
        userPhotoUrl: user.selfieUrl,
        text: text,
      );
      _messageController.clear();
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send message: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Widget _buildMessageBubble(Message message, bool isOwnMessage) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isOwnMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isOwnMessage) ...[
            CircleAvatar(
              radius: 14,
              backgroundImage: message.userPhotoUrl != null
                  ? NetworkImage(message.userPhotoUrl!)
                  : null,
              backgroundColor: AppColors.tealTint,
              child: message.userPhotoUrl == null
                  ? Text(
                      message.userName.isNotEmpty ? message.userName[0].toUpperCase() : '?',
                      style: const TextStyle(color: AppColors.teal, fontSize: 12, fontWeight: FontWeight.w600),
                    )
                  : null,
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isOwnMessage ? AppColors.teal : Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isOwnMessage ? 16 : 4),
                  bottomRight: Radius.circular(isOwnMessage ? 4 : 16),
                ),
              ),
              child: Text(
                message.text,
                style: TextStyle(color: isOwnMessage ? Colors.black : Colors.white),
              ),
            ),
          ),
          if (isOwnMessage) const SizedBox(width: 8),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = Provider.of<AuthProvider>(context, listen: false).appUser!.uid;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.otherUserName),
        backgroundColor: AppColors.tealTint,
      ),
      body: FutureBuilder<String>(
        future: _threadIdFuture,
        builder: (context, threadSnapshot) {
          if (!threadSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final threadId = threadSnapshot.data!;

          return Column(
            children: [
              Expanded(
                child: StreamBuilder<List<Message>>(
                  stream: _connectionService.streamDirectMessages(threadId),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final messages = snapshot.data!;
                    if (messages.isEmpty) {
                      return Center(
                        child: Text(
                          'Say hello to ${widget.otherUserName}!',
                          style: TextStyle(color: Colors.grey[400]),
                        ),
                      );
                    }

                    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

                    return ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final message = messages[index];
                        return _buildMessageBubble(message, message.userId == currentUserId);
                      },
                    );
                  },
                ),
              ),
              ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.background.withValues(alpha: 0.75),
                      border: Border(top: BorderSide(color: AppColors.tealBorder, width: 1)),
                    ),
                    padding: const EdgeInsets.all(8.0),
                    child: SafeArea(
                      top: false,
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _messageController,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                hintText: 'Type a message...',
                                hintStyle: TextStyle(color: Colors.grey[500]),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(24),
                                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(24),
                                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(24),
                                  borderSide: const BorderSide(color: AppColors.teal),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                filled: true,
                                fillColor: Colors.white.withValues(alpha: 0.08),
                              ),
                              textInputAction: TextInputAction.send,
                              onSubmitted: (_) => _sendMessage(threadId),
                              maxLines: null,
                              textCapitalization: TextCapitalization.sentences,
                            ),
                          ),
                          const SizedBox(width: 8),
                          CircleAvatar(
                            backgroundColor: AppColors.teal,
                            child: IconButton(
                              icon: _isSending
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                                    )
                                  : const Icon(Icons.send, color: Colors.black),
                              onPressed: _isSending ? null : () => _sendMessage(threadId),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

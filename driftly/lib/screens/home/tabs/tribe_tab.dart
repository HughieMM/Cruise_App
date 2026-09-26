import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/tribe_provider.dart';
import '../../../models/tribe.dart';
import '../../../models/message.dart';
import '../../../services/tribe_service.dart';
import '../../../services/badge_service.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../widgets/glass_card.dart';
import '../../../widgets/icon_badge.dart';
import '../../../widgets/pill_button.dart';
import '../../tribe/daily_photo_screen.dart' show SeaYaScreen;

/// Tribe Tab
///
/// Shows the user's tribe (random matched group of 4-6)
/// Includes tribe chat, member profiles, and daily photo feature
class TribeTab extends StatefulWidget {
  const TribeTab({super.key});

  @override
  State<TribeTab> createState() => _TribeTabState();
}

class _TribeTabState extends State<TribeTab> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();
  final TribeService _tribeService = TribeService();
  final BadgeService _badgeService = BadgeService();
  bool _isInitialized = false;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeTribe();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _chatScrollController.dispose();
    super.dispose();
  }

  void _scrollChatToBottom() {
    if (_chatScrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_chatScrollController.hasClients) {
          _chatScrollController.animateTo(
            _chatScrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  Future<void> _sendTribeMessage(String sailingId, String tribeId) async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.appUser;
    if (user == null) return;

    setState(() => _isSending = true);

    try {
      await _tribeService.sendTribeMessage(
        sailingId: sailingId,
        tribeId: tribeId,
        userId: user.uid,
        userName: user.name,
        userPhotoUrl: user.selfieUrl,
        text: text,
      );
      _messageController.clear();
      _scrollChatToBottom();

      // Track badge progress for tribe messages sent
      final newBadge = await _badgeService.incrementStat(
        userId: user.uid,
        statName: 'tribe_messages_sent',
      );

      if (newBadge != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Text(newBadge.icon, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Badge Earned!', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(newBadge.name),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send message: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _initializeTribe() async {
    if (_isInitialized) return;
    _isInitialized = true;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final tribeProvider = Provider.of<TribeProvider>(context, listen: false);
    final user = authProvider.appUser;

    if (user != null && user.currentSailingId != null) {
      await tribeProvider.initializeTribe(
        sailingId: user.currentSailingId!,
        tribeId: user.currentTribeId,
        userId: user.uid,
      );

      // Also load pending sibling requests
      await tribeProvider.loadPendingRequests(
        sailingId: user.currentSailingId!,
        email: user.email,
      );
    }
  }

  void _showSiblingRequestDialog() {
    final emailController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Join with a Friend'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enter your friend\'s email to request being in the same tribe.',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Friend\'s Email',
                  hintText: 'friend@example.com',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an email';
                  }
                  if (!value.contains('@')) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              Text(
                'Your friend must also be registered for the same cruise.',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          Consumer2<AuthProvider, TribeProvider>(
            builder: (context, authProvider, tribeProvider, child) {
              return ElevatedButton(
                onPressed: tribeProvider.isLoading
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;

                        final user = authProvider.appUser;
                        if (user == null || user.currentSailingId == null) {
                          return;
                        }

                        final success = await tribeProvider.createSiblingRequest(
                          sailingId: user.currentSailingId!,
                          requesterId: user.uid,
                          requesterName: user.name,
                          targetEmail: emailController.text.trim(),
                        );

                        if (!context.mounted) return;

                        Navigator.pop(context);

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              success
                                  ? 'Request sent! Your friend will be notified.'
                                  : tribeProvider.errorMessage ?? 'Failed to send request',
                            ),
                            backgroundColor: success ? Colors.green : Colors.red,
                          ),
                        );
                      },
                child: tribeProvider.isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Send Request'),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showMemberProfile(TribeMember member) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),

              // Photo
              CircleAvatar(
                radius: 60,
                backgroundImage: member.photoUrl != null
                    ? NetworkImage(member.photoUrl!)
                    : null,
                child: member.photoUrl == null
                    ? Text(
                        member.userName.isNotEmpty
                            ? member.userName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(fontSize: 40),
                      )
                    : null,
              ),
              const SizedBox(height: 16),

              // Name & badges
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    member.userName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (member.isLeader) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Leader',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),

              // Age band & gender
              Text(
                '${member.ageBand} • ${member.gender[0].toUpperCase()}${member.gender.substring(1)}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 24),

              // Interests
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Interests',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: member.interests.map((interest) {
                  return Chip(
                    label: Text(interest),
                    backgroundColor: Theme.of(context)
                        .colorScheme
                        .primaryContainer
                        .withValues(alpha: 0.5),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Joined date
              Text(
                'Joined tribe ${_formatJoinDate(member.joinedAt)}',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatJoinDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'today';
    } else if (diff.inDays == 1) {
      return 'yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else {
      return '${date.day}/${date.month}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, TribeProvider>(
      builder: (context, authProvider, tribeProvider, child) {
        final user = authProvider.appUser;

        if (tribeProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        // No tribe yet
        if (!tribeProvider.hasTribe) {
          return _buildNoTribeView(tribeProvider, user);
        }

        // Has tribe - show tribe view
        return _buildTribeView(tribeProvider, user);
      },
    );
  }

  Widget _buildNoTribeView(TribeProvider tribeProvider, user) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Text('Your Tribe', style: AppTextStyles.displayMedium),
            const SizedBox(height: 8),
            Text(
              'You haven\'t been matched to a tribe yet',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 32),

            // Info card
            GlassCard(
              borderColor: AppColors.tealBorder,
              tintColor: AppColors.tealTint,
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const IconBadge(
                    icon: Icons.groups,
                    backgroundColor: AppColors.teal,
                    size: 72,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Tribes are Small Groups',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You\'ll be randomly matched with 3-5 other cruisers in your age group who share some of your interests.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[300]),
                  ),
                  const SizedBox(height: 16),
                  Divider(color: Colors.grey[700]),
                  const SizedBox(height: 16),
                  _buildFeatureRow(
                    Icons.cake,
                    'Same age band as you',
                  ),
                  const SizedBox(height: 12),
                  _buildFeatureRow(
                    Icons.favorite,
                    '1-2 shared interests',
                  ),
                  const SizedBox(height: 12),
                  _buildFeatureRow(
                    Icons.wc,
                    'Balanced gender mix',
                  ),
                  const SizedBox(height: 12),
                  _buildFeatureRow(
                    Icons.calendar_today,
                    'Matching happens 5 days before sailing',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Pending requests
            if (tribeProvider.pendingRequests.isNotEmpty) ...[
              const Text(
                'Friend Requests',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              ...tribeProvider.pendingRequests.map((request) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: GlassCard(
                    padding: EdgeInsets.zero,
                    child: ListTile(
                      leading: const IconBadge(
                        icon: Icons.person_add,
                        backgroundColor: AppColors.teal,
                      ),
                      title: Text(
                        request.requesterName,
                        style: const TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(
                        'Wants to be in your tribe',
                        style: TextStyle(color: Colors.grey[400]),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.close, color: AppColors.coral),
                            onPressed: () async {
                              await tribeProvider.declineSiblingRequest(
                                sailingId: user?.currentSailingId ?? '',
                                requestId: request.id,
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.check, color: AppColors.teal),
                            onPressed: () async {
                              await tribeProvider.acceptSiblingRequest(
                                sailingId: user?.currentSailingId ?? '',
                                requestId: request.id,
                                targetId: user?.uid ?? '',
                                targetName: user?.name ?? '',
                              );
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Request accepted! You\'ll be matched together.'),
                                    backgroundColor: AppColors.teal,
                                  ),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 24),
            ],

            // Join with friend button
            PillButton(
              label: 'Join with a Friend',
              icon: Icons.person_add,
              variant: PillVariant.outlined,
              color: AppColors.teal,
              onPressed: _showSiblingRequestDialog,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.teal),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(color: Colors.grey[300]),
          ),
        ),
      ],
    );
  }

  Widget _buildTribeView(TribeProvider tribeProvider, user) {
    final tribe = tribeProvider.currentTribe!;
    final members = tribeProvider.tribeMembers;

    return SafeArea(
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tribe.name,
                            style: AppTextStyles.displaySmall,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${members.length} members • ${tribe.ageBand}',
                            style: TextStyle(
                              color: Colors.grey[400],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Daily photo button
                    if (!tribeProvider.hasSubmittedSeaYa)
                      PillButton(
                        label: 'Daily Pic',
                        icon: Icons.camera_alt,
                        color: AppColors.teal,
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => SeaYaScreen(
                                promptedAt: DateTime.now(),
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                // Members horizontal scroll
                SizedBox(
                  height: 80,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: members.length,
                    itemBuilder: (context, index) {
                      final member = members[index];
                      return GestureDetector(
                        onTap: () => _showMemberProfile(member),
                        child: Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: Column(
                            children: [
                              Stack(
                                children: [
                                  CircleAvatar(
                                    radius: 28,
                                    backgroundImage: member.photoUrl != null
                                        ? NetworkImage(member.photoUrl!)
                                        : null,
                                    child: member.photoUrl == null
                                        ? Text(
                                            member.userName.isNotEmpty
                                                ? member.userName[0].toUpperCase()
                                                : '?',
                                          )
                                        : null,
                                  ),
                                  if (member.isLeader)
                                    Positioned(
                                      right: 0,
                                      bottom: 0,
                                      child: Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: const BoxDecoration(
                                          color: AppColors.amber,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.star,
                                          size: 12,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                member.userName.split(' ').first,
                                style: const TextStyle(fontSize: 12, color: Colors.white),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Shared interests
                if (tribe.commonInterests.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: tribe.commonInterests.map((interest) {
                      return Chip(
                        label: Text(
                          interest,
                          style: const TextStyle(fontSize: 12),
                        ),
                        visualDensity: VisualDensity.compact,
                        backgroundColor: Theme.of(context)
                            .colorScheme
                            .primaryContainer
                            .withValues(alpha: 0.5),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),

          const Divider(height: 1),

          // Daily photos section
          if (tribeProvider.seaYaPhotos.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Today\'s Moments',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: tribeProvider.seaYaPhotos.length,
                      itemBuilder: (context, index) {
                        final photo = tribeProvider.seaYaPhotos[index];
                        return Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: Column(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  photo.photoUrl,
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    width: 80,
                                    height: 80,
                                    color: Colors.grey[300],
                                    child: const Icon(Icons.image),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                photo.userName.split(' ').first,
                                style: const TextStyle(fontSize: 11, color: Colors.white),
                              ),
                              Text(
                                photo.responseTimeFormatted,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey[400],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
          ],

          // Chat area
          Expanded(
            child: StreamBuilder<List<Message>>(
              stream: _tribeService.streamTribeMessages(
                sailingId: user.currentSailingId!,
                tribeId: tribe.id,
              ),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data!;

                if (messages.isEmpty) {
                  return Center(
                    child: Text(
                      'No messages yet.\nSay hello to your tribe!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[400]),
                    ),
                  );
                }

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _scrollChatToBottom();
                });

                return ListView.builder(
                  controller: _chatScrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    // Stream is newest-first; reverse for display.
                    final message = messages[messages.length - 1 - index];
                    final isOwnMessage = message.userId == user.uid;

                    return _buildTribeMessageBubble(message, isOwnMessage);
                  },
                );
              },
            ),
          ),

          // Message input
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
                            hintText: 'Message your tribe...',
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
                          onSubmitted: (_) => _sendTribeMessage(
                            user.currentSailingId!,
                            tribe.id,
                          ),
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
                          onPressed: _isSending
                              ? null
                              : () => _sendTribeMessage(user.currentSailingId!, tribe.id),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTribeMessageBubble(Message message, bool isOwnMessage) {
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
            child: Column(
              crossAxisAlignment: isOwnMessage ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isOwnMessage)
                  Padding(
                    padding: const EdgeInsets.only(left: 12, bottom: 4),
                    child: Text(
                      message.userName,
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[400]),
                    ),
                  ),
                Container(
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
              ],
            ),
          ),
          if (isOwnMessage) const SizedBox(width: 8),
        ],
      ),
    );
  }
}

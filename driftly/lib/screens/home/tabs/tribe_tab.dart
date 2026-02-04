import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/tribe_provider.dart';
import '../../../models/tribe.dart';
import '../../tribe/daily_photo_screen.dart';

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
  bool _isInitialized = false;

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
    super.dispose();
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
                        .withOpacity(0.5),
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
            const Text(
              'Your Tribe',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You haven\'t been matched to a tribe yet',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 32),

            // Info card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(
                      Icons.groups,
                      size: 64,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Tribes are Small Groups',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'You\'ll be randomly matched with 3-5 other cruisers in your age group who share some of your interests.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
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
            ),
            const SizedBox(height: 24),

            // Pending requests
            if (tribeProvider.pendingRequests.isNotEmpty) ...[
              const Text(
                'Friend Requests',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              ...tribeProvider.pendingRequests.map((request) {
                return Card(
                  child: ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.person_add),
                    ),
                    title: Text(request.requesterName),
                    subtitle: const Text('Wants to be in your tribe'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: () async {
                            await tribeProvider.declineSiblingRequest(
                              sailingId: user?.currentSailingId ?? '',
                              requestId: request.id,
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.check, color: Colors.green),
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
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 24),
            ],

            // Join with friend button
            OutlinedButton.icon(
              onPressed: _showSiblingRequestDialog,
              icon: const Icon(Icons.person_add),
              label: const Text('Join with a Friend'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(color: Colors.grey[700]),
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
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${members.length} members • ${tribe.ageBand}',
                            style: TextStyle(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Daily photo button
                    if (!tribeProvider.hasSubmittedDailyPhoto)
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => DailyPhotoScreen(
                                promptedAt: DateTime.now(),
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.camera_alt, size: 18),
                        label: const Text('Daily Pic'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
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
                                          color: Colors.amber,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.star,
                                          size: 12,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                member.userName.split(' ').first,
                                style: const TextStyle(fontSize: 12),
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
                            .withOpacity(0.5),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),

          const Divider(height: 1),

          // Daily photos section
          if (tribeProvider.dailyPhotos.isNotEmpty) ...[
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
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: tribeProvider.dailyPhotos.length,
                      itemBuilder: (context, index) {
                        final photo = tribeProvider.dailyPhotos[index];
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
                                style: const TextStyle(fontSize: 11),
                              ),
                              Text(
                                photo.responseTimeFormatted,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey[500],
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

          // Chat area placeholder
          Expanded(
            child: Center(
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
                    'Tribe Chat Coming Soon!',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Chat with your tribe members',
                    style: TextStyle(
                      color: Colors.grey[500],
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
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/connection_service.dart';
import '../../../models/connection_request.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/glass_card.dart';
import '../../../widgets/icon_badge.dart';
import '../../../widgets/small_caps_label.dart';

/// First Mates Section
///
/// Embedded at the bottom of the Home tab (not its own bottom-nav tab):
/// pending incoming connect requests (Accept/Decline) and accepted
/// connections you can message privately. There is deliberately no path
/// into this from Tribe — connect requests only ever originate from Pod
/// chat's profile dialog.
class FirstMatesSection extends StatefulWidget {
  const FirstMatesSection({super.key});

  @override
  State<FirstMatesSection> createState() => _FirstMatesSectionState();
}

class _FirstMatesSectionState extends State<FirstMatesSection> {
  final _connectionService = ConnectionService();
  final Set<String> _respondingTo = {};

  Future<void> _accept(String sailingId, ConnectionRequest request) async {
    setState(() => _respondingTo.add(request.id));
    try {
      await _connectionService.acceptConnectionRequest(
        sailingId: sailingId,
        requestId: request.id,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to accept: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _respondingTo.remove(request.id));
    }
  }

  Future<void> _decline(String sailingId, ConnectionRequest request) async {
    setState(() => _respondingTo.add(request.id));
    try {
      await _connectionService.declineConnectionRequest(
        sailingId: sailingId,
        requestId: request.id,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to decline: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _respondingTo.remove(request.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.appUser;
        final sailingId = user?.currentSailingId;

        if (user == null || sailingId == null) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StreamBuilder<List<ConnectionRequest>>(
              stream: _connectionService.streamIncomingRequests(sailingId, user.uid),
              builder: (context, snapshot) {
                final requests = snapshot.data ?? [];
                if (requests.isEmpty) return const SizedBox.shrink();

                return Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SmallCapsLabel('Requests', color: AppColors.gold),
                      const SizedBox(height: 12),
                      ...requests.map((request) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: GlassCard(
                              borderColor: AppColors.goldBorder,
                              tintColor: AppColors.goldTint,
                              child: Row(
                                children: [
                                  const IconBadge(icon: Icons.group_add, backgroundColor: AppColors.gold),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      request.requesterName,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  if (_respondingTo.contains(request.id))
                                    const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  else ...[
                                    IconButton(
                                      icon: const Icon(Icons.check_circle, color: AppColors.teal),
                                      onPressed: () => _accept(sailingId, request),
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.cancel, color: Colors.grey[500]),
                                      onPressed: () => _decline(sailingId, request),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          )),
                    ],
                  ),
                );
              },
            ),
            const SmallCapsLabel('First Mates', color: AppColors.teal),
            const SizedBox(height: 12),
            StreamBuilder<List<ConnectionRequest>>(
              stream: _connectionService.streamAcceptedConnections(sailingId, user.uid),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final connections = snapshot.data!;
                if (connections.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Column(
                      children: [
                        Icon(Icons.group_add, size: 48, color: Colors.grey[600]),
                        const SizedBox(height: 12),
                        Text(
                          'No First Mates yet',
                          style: TextStyle(
                            color: Colors.grey[300],
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Connect with someone from a Pod chat to start messaging privately.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  children: connections.map((connection) {
                    final otherName = connection.otherUserName(user.uid);
                    final otherId = connection.otherUserId(user.uid);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: GlassCard(
                        padding: EdgeInsets.zero,
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppColors.tealTint,
                            child: Text(
                              otherName.isNotEmpty ? otherName[0].toUpperCase() : '?',
                              style: const TextStyle(color: AppColors.teal, fontWeight: FontWeight.w600),
                            ),
                          ),
                          title: Text(otherName, style: const TextStyle(color: Colors.white)),
                          trailing: const Icon(Icons.chevron_right, color: AppColors.teal),
                          onTap: () => context.push(
                            '/messages/$otherId',
                            extra: {'otherUserName': otherName},
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        );
      },
    );
  }
}

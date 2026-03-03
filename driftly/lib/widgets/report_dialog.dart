import 'package:flutter/material.dart';
import '../models/content_report.dart';
import '../services/moderation_service.dart';

/// Report Content Dialog
///
/// Reusable dialog for reporting users, photos, or messages
class ReportDialog extends StatefulWidget {
  final String reporterId;
  final String reportedUserId;
  final String contentType; // 'user', 'photo', 'message'
  final String? contentId;
  final String? photoUrl;
  final String? sailingId;

  const ReportDialog({
    super.key,
    required this.reporterId,
    required this.reportedUserId,
    required this.contentType,
    this.contentId,
    this.photoUrl,
    this.sailingId,
  });

  @override
  State<ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<ReportDialog> {
  final ModerationService _moderationService = ModerationService();
  final _detailsController = TextEditingController();

  String? _selectedReason;
  bool _isSubmitting = false;

  List<ReportOption> get _reasons {
    if (widget.contentType == 'photo') {
      return ReportReasons.photoReasons;
    }
    return ReportReasons.userReasons;
  }

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    if (_selectedReason == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a reason')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await _moderationService.submitReport(
        reporterId: widget.reporterId,
        reportedUserId: widget.reportedUserId,
        contentType: widget.contentType,
        reason: _selectedReason!,
        contentId: widget.contentId,
        details: _detailsController.text.trim().isNotEmpty
            ? _detailsController.text.trim()
            : null,
        sailingId: widget.sailingId,
        photoUrl: widget.photoUrl,
      );

      if (!mounted) return;

      Navigator.of(context).pop(true);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Report submitted. Thank you for keeping Driftly safe.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() => _isSubmitting = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit report: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.grey[900],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.flag, color: Colors.red, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Report Content',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        widget.contentType == 'photo'
                            ? 'This photo will be reviewed'
                            : 'This user will be reviewed',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Info banner for photo reports
            if (widget.contentType == 'photo')
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange[300], size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Photos with 2+ reports are automatically removed',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange[200],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Reason Selection
            const Text(
              'What\'s the issue?',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            ..._reasons.map((reason) => _buildReasonOption(reason)),
            const SizedBox(height: 16),

            // Additional Details
            const Text(
              'Additional details (optional)',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _detailsController,
              maxLines: 3,
              maxLength: 500,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Provide more context...',
                hintStyle: TextStyle(color: Colors.grey[600]),
                filled: true,
                fillColor: Colors.grey[850],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                counterStyle: TextStyle(color: Colors.grey[600]),
              ),
            ),
            const SizedBox(height: 20),

            // Actions
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed:
                        _isSubmitting ? null : () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitReport,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Submit Report'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReasonOption(ReportOption reason) {
    final isSelected = _selectedReason == reason.value;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedReason = reason.value;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.red.withOpacity(0.2)
              : Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.red : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? Colors.red : Colors.grey,
                  width: 2,
                ),
                color: isSelected ? Colors.red : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reason.label,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: isSelected ? Colors.red[200] : Colors.white,
                    ),
                  ),
                  Text(
                    reason.description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Block User Confirmation Dialog
class BlockUserDialog extends StatefulWidget {
  final String userId;
  final String blockedUserId;
  final String blockedUserName;

  const BlockUserDialog({
    super.key,
    required this.userId,
    required this.blockedUserId,
    required this.blockedUserName,
  });

  @override
  State<BlockUserDialog> createState() => _BlockUserDialogState();
}

class _BlockUserDialogState extends State<BlockUserDialog> {
  final ModerationService _moderationService = ModerationService();
  bool _isBlocking = false;

  Future<void> _blockUser() async {
    setState(() => _isBlocking = true);

    try {
      await _moderationService.blockUser(
        userId: widget.userId,
        blockedUserId: widget.blockedUserId,
      );

      if (!mounted) return;

      Navigator.of(context).pop(true);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${widget.blockedUserName} has been blocked'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() => _isBlocking = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to block user: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.grey[900],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Block User?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Block ${widget.blockedUserName}?',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 12),
          Text(
            'They won\'t be able to:',
            style: TextStyle(color: Colors.grey[400], fontSize: 14),
          ),
          const SizedBox(height: 8),
          _buildBulletPoint('See your profile'),
          _buildBulletPoint('Message you in pods'),
          _buildBulletPoint('See your hangouts'),
          const SizedBox(height: 12),
          Text(
            'You can unblock them anytime from settings.',
            style: TextStyle(color: Colors.grey[500], fontSize: 12),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isBlocking ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isBlocking ? null : _blockUser,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          child: _isBlocking
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Block'),
        ),
      ],
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ', style: TextStyle(color: Colors.grey[400])),
          Text(
            text,
            style: TextStyle(color: Colors.grey[400], fontSize: 13),
          ),
        ],
      ),
    );
  }
}

/// Helper function to show report dialog
Future<bool?> showReportDialog({
  required BuildContext context,
  required String reporterId,
  required String reportedUserId,
  required String contentType,
  String? contentId,
  String? photoUrl,
  String? sailingId,
}) {
  return showDialog<bool>(
    context: context,
    builder: (context) => ReportDialog(
      reporterId: reporterId,
      reportedUserId: reportedUserId,
      contentType: contentType,
      contentId: contentId,
      photoUrl: photoUrl,
      sailingId: sailingId,
    ),
  );
}

/// Helper function to show block dialog
Future<bool?> showBlockDialog({
  required BuildContext context,
  required String userId,
  required String blockedUserId,
  required String blockedUserName,
}) {
  return showDialog<bool>(
    context: context,
    builder: (context) => BlockUserDialog(
      userId: userId,
      blockedUserId: blockedUserId,
      blockedUserName: blockedUserName,
    ),
  );
}

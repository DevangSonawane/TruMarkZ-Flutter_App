import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../../../../../core/models/sdc_approval_models.dart';
import '../../../../../core/models/verification_models.dart';
import '../../../../../core/network/api_client.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/widgets/tmz_card.dart';
import '../../../data/verification_repository.dart';

/// Organization-side partial-SDC approval section.
///
/// Per `sdc_partial_approval_flutter.md` (org side only):
/// - Lists `GET /sdc/batches/{batch_id}/approvals` (newest first).
/// - Pending items drive the badge count; decided items stay in history.
/// - `selected_user_ids` are resolved locally against [batchUsers] by id.
/// - Decide via `POST /sdc/approvals/{request_id}/decide`.
class SdcPartialApprovalSection extends ConsumerStatefulWidget {
  const SdcPartialApprovalSection({
    super.key,
    required this.batchId,
    required this.batchUsers,
    required this.isProductBatch,
    this.nameById = const <String, String>{},
  });

  final String batchId;
  final List<VerificationUser> batchUsers;
  final bool isProductBatch;
  final Map<String, String> nameById;

  @override
  ConsumerState<SdcPartialApprovalSection> createState() =>
      _SdcPartialApprovalSectionState();
}

class _SdcPartialApprovalSectionState
    extends ConsumerState<SdcPartialApprovalSection> {
  final Set<String> _deciding = <String>{};
  bool _showHistory = false;

  Map<String, VerificationUser> get _usersById {
    final Map<String, VerificationUser> map = <String, VerificationUser>{};
    for (final VerificationUser u in widget.batchUsers) {
      map[u.id.trim()] = u;
    }
    return map;
  }

  Map<String, String> get _nameOverrideById {
    final Map<String, String> map = <String, String>{};
    widget.nameById.forEach((String k, String v) {
      if (k.trim().isNotEmpty && v.trim().isNotEmpty) {
        map[k.trim()] = v.trim();
      }
    });
    return map;
  }

  String _displayNameFor(String batchUserId) {
    final String key = batchUserId.trim();
    final String? override = _nameOverrideById[key];
    if (override != null && override.trim().isNotEmpty) return override.trim();
    final VerificationUser? u = _usersById[key];
    if (u == null) {
      final String raw = batchUserId.trim();
      return raw.length > 12 ? '${raw.substring(0, 12)}…' : raw;
    }
    if (widget.isProductBatch) {
      final String name = u.productName.trim();
      if (name.isNotEmpty) return name;
    }
    final String name = u.fullName.trim();
    if (name.isNotEmpty) return name;
    final String email = u.email.trim();
    if (email.isNotEmpty) return email;
    final String raw = u.id.trim();
    return raw.length > 12 ? '${raw.substring(0, 12)}…' : raw;
  }

  Future<void> _refresh() async {
    ref.invalidate(sdcApprovalsProvider(widget.batchId.trim()));
    try {
      await ref.read(sdcApprovalsProvider(widget.batchId.trim()).future);
    } catch (_) {
      // Error is surfaced by the provider's AsyncValue.
    }
  }

  Future<void> _confirmAndDecide(
    SdcPartialApprovalRequest request,
    String decision,
  ) async {
    final String? reason = await _showDecisionSheet(request, decision);
    if (reason == null) return; // user cancelled
    final String requestId = request.id;
    if (_deciding.contains(requestId)) return;
    setState(() => _deciding.add(requestId));
    try {
      final SdcPartialApprovalRequest updated = await ref
          .read(verificationRepositoryProvider)
          .decideSdcApproval(
            requestId: requestId,
            decision: decision,
            reason: reason.trim().isEmpty ? null : reason.trim(),
          );
      if (!mounted) return;
      // Confirm the returned status matches what we sent.
      final String expected = decision.trim().toLowerCase();
      final String actual = sdcPartialApprovalStatusToJson(updated.status);
      if (actual != expected) {
        await _refresh();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Decision recorded. Refreshing latest status…'),
          ),
        );
        return;
      }
      await _refresh();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            expected == 'approved'
                ? 'Approved. Generation is now unblocked for the superadmin — nothing generates automatically.'
                : 'Rejected. This selection will stay blocked.',
          ),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      await _refresh();
      if (!mounted) return;
      final String message = switch (e.statusCode) {
        404 => 'Request not found. It may belong to another organization.',
        409 =>
          'Already decided — someone on your team already acted. Showing the recorded decision.',
        400 => 'Invalid decision. Please try again.',
        _ => e.message,
      };
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not submit decision: $e')),
      );
    } finally {
      if (mounted) setState(() => _deciding.remove(requestId));
    }
  }

  /// Returns the typed reason, or null if the user cancelled.
  Future<String?> _showDecisionSheet(
    SdcPartialApprovalRequest request,
    String decision,
  ) {
    final TextEditingController reasonController = TextEditingController();
    final bool approving = decision.trim().toLowerCase() == 'approved';
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext sheetContext) {
        final double inset = MediaQuery.paddingOf(sheetContext).bottom;
        final double keyboard = MediaQuery.viewInsetsOf(sheetContext).bottom;
        return Container(
          padding: EdgeInsets.fromLTRB(20, 14, 20, 18 + inset + keyboard),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0E0E0),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                approving ? 'Approve request?' : 'Reject request?',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${request.selectedUserIds.length} user(s) in scope • ${request.id.length > 8 ? request.id.substring(0, 8) : request.id}…',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: reasonController,
                maxLines: 3,
                minLines: 2,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  hintText: 'Optional note (shown back as decision_reason)…',
                  hintStyle: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13.5,
                    color: AppColors.textTertiary,
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF7F9FC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.divider),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.divider),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.brandBlue),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(sheetContext).pop(),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.of(
                        sheetContext,
                      ).pop(reasonController.text),
                      style: FilledButton.styleFrom(
                        backgroundColor: approving
                            ? AppColors.success
                            : AppColors.danger,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(approving ? 'Approve' : 'Reject'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final String batchId = widget.batchId.trim();
    if (batchId.isEmpty) return const SizedBox.shrink();
    final AsyncValue<List<SdcPartialApprovalRequest>> approvalsAsync = ref
        .watch(sdcApprovalsProvider(batchId));

    return approvalsAsync.when(
      loading: () => const TMZCard(
        padding: EdgeInsets.all(AppSpacing.x4),
        child: Row(
          children: <Widget>[
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text(
              'Checking SDC approvals…',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
      error: (Object err, _) {
        // A 404 here means no approvals route/batch for this org — hide
        // quietly but allow retry; other errors show a compact card.
        final String message = err is ApiException && err.statusCode == 404
            ? 'No approval requests for this batch yet.'
            : 'Could not load SDC approvals.';
        return TMZCard(
          padding: const EdgeInsets.all(AppSpacing.x4),
          child: Row(
            children: <Widget>[
              const Icon(
                LucideIcons.shieldAlert,
                color: AppColors.textTertiary,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              TextButton(
                onPressed: _refresh,
                child: const Text('Retry'),
              ),
            ],
          ),
        );
      },
      data: (List<SdcPartialApprovalRequest> items) {
        final List<SdcPartialApprovalRequest> pending = items
            .where((SdcPartialApprovalRequest r) => r.isPending)
            .toList();
        final List<SdcPartialApprovalRequest> history = items
            .where((SdcPartialApprovalRequest r) => !r.isPending)
            .toList();
        if (items.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'SDC APPROVALS',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.18,
                          color: Color(0xFF323232),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Approve partial SDC generation for this batch',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                _PendingBadge(count: pending.length),
              ],
            ),
            const SizedBox(height: AppSpacing.x3),
            if (pending.isEmpty)
              const TMZCard(
                padding: EdgeInsets.all(AppSpacing.x4),
                child: Row(
                  children: <Widget>[
                    Icon(
                      LucideIcons.badgeCheck,
                      color: AppColors.success,
                      size: 20,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'No pending requests. History is shown below.',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              for (final SdcPartialApprovalRequest request in pending) ...<
                Widget
              >[
                _ApprovalCard(
                  request: request,
                  isProductBatch: widget.isProductBatch,
                  displayNameFor: _displayNameFor,
                  isDeciding: _deciding.contains(request.id),
                  onApprove: () => _confirmAndDecide(request, 'approved'),
                  onReject: () => _confirmAndDecide(request, 'rejected'),
                ),
                const SizedBox(height: AppSpacing.x2),
              ],
            if (history.isNotEmpty) ...<Widget>[
              const SizedBox(height: AppSpacing.x2),
              InkWell(
                onTap: () => setState(() => _showHistory = !_showHistory),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 8,
                  ),
                  child: Row(
                    children: <Widget>[
                      Icon(
                        _showHistory
                            ? LucideIcons.chevronDown
                            : LucideIcons.chevronRight,
                        size: 18,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'History (${history.length})',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_showHistory)
                for (final SdcPartialApprovalRequest request in history) ...<
                  Widget
                >[
                  _ApprovalCard(
                    request: request,
                    isProductBatch: widget.isProductBatch,
                    displayNameFor: _displayNameFor,
                    isDeciding: false,
                    onApprove: null,
                    onReject: null,
                  ),
                  const SizedBox(height: AppSpacing.x2),
                ],
            ],
          ],
        );
      },
    );
  }
}

class _PendingBadge extends StatelessWidget {
  const _PendingBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final bool hasPending = count > 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: hasPending ? AppColors.dangerBg : AppColors.successBg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            hasPending ? LucideIcons.bellRing : LucideIcons.badgeCheck,
            size: 15,
            color: hasPending ? AppColors.danger : AppColors.success,
          ),
          const SizedBox(width: 6),
          Text(
            hasPending ? '$count pending' : 'Up to date',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: hasPending ? AppColors.danger : AppColors.success,
            ),
          ),
        ],
      ),
    );
  }
}

class _ApprovalCard extends StatelessWidget {
  const _ApprovalCard({
    required this.request,
    required this.isProductBatch,
    required this.displayNameFor,
    required this.isDeciding,
    required this.onApprove,
    required this.onReject,
  });

  final SdcPartialApprovalRequest request;
  final bool isProductBatch;
  final String Function(String) displayNameFor;
  final bool isDeciding;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  bool get _isPending => request.isPending;

  @override
  Widget build(BuildContext context) {
    final int total = request.selectedUserIds.length;
    final List<String> previewNames = request.selectedUserIds
        .take(3)
        .map(displayNameFor)
        .toList();
    final String remainder = total > 3 ? ' +${total - 3} more' : '';
    final String created = _formatDateTime(request.createdAt);
    final String decided = (request.decidedAt ?? '').trim().isNotEmpty
        ? _formatDateTime(request.decidedAt!.trim())
        : '';

    return TMZCard(
      padding: const EdgeInsets.all(AppSpacing.x4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              _StatusPill(status: request.status),
              const Spacer(),
              if (created.isNotEmpty)
                Text(
                  created,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textTertiary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '$total user${total == 1 ? '' : 's'} in scope',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.1,
              color: AppColors.textPrimary,
            ),
          ),
          if (previewNames.isNotEmpty) ...<Widget>[
            const SizedBox(height: 4),
            Text(
              '${previewNames.join(', ')}$remainder',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ],
          if ((request.decisionReason ?? '').trim().isNotEmpty) ...<Widget>[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 9,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F9FC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.divider),
              ),
              child: Text(
                'Note: ${(request.decisionReason ?? '').trim()}',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
          if (decided.isNotEmpty && !_isPending) ...<Widget>[
            const SizedBox(height: 6),
            Text(
              'Decided $decided',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                color: AppColors.textTertiary,
              ),
            ),
          ],
          if (_isPending) ...<Widget>[
            const SizedBox(height: 12),
            if (isDeciding)
              const Row(
                children: <Widget>[
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Submitting…',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              )
            else
              Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onReject,
                      icon: const Icon(LucideIcons.x, size: 17),
                      label: const Text('Reject'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.danger,
                        side: const BorderSide(color: AppColors.danger),
                        minimumSize: const Size.fromHeight(44),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: onApprove,
                      icon: const Icon(LucideIcons.check, size: 17),
                      label: const Text('Approve'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(44),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 8),
            const Text(
              'Approving only unblocks a later superadmin action for this exact selection. Nothing generates automatically.',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  static String _formatDateTime(String raw) {
    final DateTime? parsed = DateTime.tryParse(raw.trim());
    if (parsed == null) return raw.trim();
    final DateTime local = parsed.toLocal();
    const List<String> months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final String day = local.day.toString().padLeft(2, '0');
    final String mon = months[(local.month - 1).clamp(0, 11)];
    final String hh = local.hour.toString().padLeft(2, '0');
    final String mm = local.minute.toString().padLeft(2, '0');
    return '$day $mon ${local.year}, $hh:$mm';
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final SdcPartialApprovalStatus status;

  @override
  Widget build(BuildContext context) {
    final (Color fg, Color bg, String label, IconData icon) = switch (status) {
      SdcPartialApprovalStatus.pending => (
        const Color(0xFFB45309),
        const Color(0xFFFEF3C7),
        'Pending',
        LucideIcons.hourglass,
      ),
      SdcPartialApprovalStatus.approved => (
        AppColors.success,
        AppColors.successBg,
        'Approved',
        LucideIcons.badgeCheck,
      ),
      SdcPartialApprovalStatus.rejected => (
        AppColors.danger,
        AppColors.dangerBg,
        'Rejected',
        LucideIcons.circleX,
      ),
      SdcPartialApprovalStatus.unknown => (
        AppColors.textSecondary,
        const Color(0xFFF1F5F9),
        'Unknown',
        LucideIcons.helpCircle,
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 13, color: fg),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../../../../../core/models/certificate_access_models.dart';
import '../../../../../core/models/org_permission.dart';
import '../../../../../core/models/verification_models.dart';
import '../../../../../core/network/api_client.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/widgets/tmz_card.dart';
import '../../../data/verification_repository.dart';

/// Human Secure Certificate Access for one batch
/// (`flutter_secureflow_trumarkz.md` §18B/§18D, organization side only).
///
/// - Shows whether report links are public or need the holder's approval.
/// - Lists visitor grants and lets the organization revoke live ones.
/// - Offers the only mode change the backend accepts: gating a Permission
///   Required batch created before the feature shipped. Any `409` is shown
///   verbatim.
///
/// Hidden for non-Human batches and backends without the endpoint.
class CertificateAccessSection extends ConsumerStatefulWidget {
  const CertificateAccessSection({
    super.key,
    required this.batchId,
    required this.credentialVisibility,
    required this.batchUsers,
    this.onModeChanged,
  });

  final String batchId;

  /// The batch's consent mode; an Open batch can never be gated.
  final String credentialVisibility;
  final List<VerificationUser> batchUsers;

  /// Lets the page reload batch detail so its mode label stays in sync.
  final VoidCallback? onModeChanged;

  @override
  ConsumerState<CertificateAccessSection> createState() =>
      _CertificateAccessSectionState();
}

class _CertificateAccessSectionState
    extends ConsumerState<CertificateAccessSection> {
  final Set<String> _revoking = <String>{};
  bool _changingMode = false;

  String get _batchId => widget.batchId.trim();

  bool get _isOpenBatch =>
      canonicalCredentialVisibility(widget.credentialVisibility) == 'public';

  void _refresh() => ref.invalidate(certificateAccessProvider(_batchId));

  String _holderName(String batchUserId) {
    for (final VerificationUser u in widget.batchUsers) {
      if (u.id.trim() == batchUserId && u.fullName.trim().isNotEmpty) {
        return u.fullName.trim();
      }
    }
    return 'Certificate holder';
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _requireHolderApproval() async {
    if (_changingMode) return;
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Require holder approval?'),
        content: const Text(
          'Report links for this batch will only open for your organization '
          'or for visitors the certificate holder approves.\n\n'
          'This also applies to report links and QR codes in certificates '
          'already issued for this batch.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Require approval'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _changingMode = true);
    try {
      await ref
          .read(verificationRepositoryProvider)
          .setCertificateAccessMode(
            batchId: _batchId,
            mode: certificateAccessHolderApproval,
          );
      _toast('Reports now require the holder\'s approval.');
      _refresh();
      widget.onModeChanged?.call();
    } on ApiException catch (e) {
      // 409 messages explain the consent-mode conflict; show them as-is.
      _toast(e.message);
    } catch (_) {
      _toast('Could not change certificate access. Please try again.');
    } finally {
      if (mounted) setState(() => _changingMode = false);
    }
  }

  Future<void> _revoke(CertificateAccessGrant grant) async {
    if (_revoking.contains(grant.id)) return;
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Revoke access?'),
        content: Text(
          '${grant.granteeEmail.isEmpty ? 'This visitor' : grant.granteeEmail} '
          'will no longer be able to open reports for '
          '${_holderName(grant.batchUserId)}.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Revoke'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _revoking.add(grant.id));
    try {
      await ref
          .read(verificationRepositoryProvider)
          .revokeCertificateAccessGrant(batchId: _batchId, grantId: grant.id);
      _toast('Access revoked.');
    } on ApiException catch (e) {
      _toast(
        e.statusCode == 404
            ? 'This request has already finished. Refreshing…'
            : e.message,
      );
    } catch (_) {
      _toast('Could not revoke access. Please try again.');
    } finally {
      if (mounted) setState(() => _revoking.remove(grant.id));
      _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_batchId.isEmpty) return const SizedBox.shrink();
    final AsyncValue<CertificateAccessInfo> accessAsync = ref.watch(
      certificateAccessProvider(_batchId),
    );

    return accessAsync.when(
      loading: () => const SizedBox.shrink(),
      // 400 (non-Human), 404 (no endpoint / not ours): nothing to manage.
      error: (Object err, _) {
        if (err is ApiException &&
            (err.statusCode == 400 || err.statusCode == 404)) {
          return const SizedBox.shrink();
        }
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
              const Expanded(
                child: Text(
                  'Could not load certificate access.',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              TextButton(onPressed: _refresh, child: const Text('Retry')),
            ],
          ),
        );
      },
      data: (CertificateAccessInfo info) => _content(info),
    );
  }

  Widget _content(CertificateAccessInfo info) {
    final bool gated = info.isHolderApproval;
    final List<CertificateAccessGrant> grants = info.grants;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text(
          'CERTIFICATE ACCESS',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.18,
            color: Color(0xFF323232),
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Who can open the verification reports linked from certificates',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.x3),
        TMZCard(
          padding: const EdgeInsets.all(AppSpacing.x4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: gated ? AppColors.blueTint : AppColors.offWhite,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      gated ? LucideIcons.lock : LucideIcons.globe,
                      size: 18,
                      color: gated
                          ? AppColors.brandBlue
                          : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          gated ? 'Holder approval required' : 'Public',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          gated
                              ? 'Only your organization and visitors the '
                                    'holder approves can open reports.'
                              : 'Anyone with a report link or QR can open it.',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (!gated && !_isOpenBatch) ...<Widget>[
                const SizedBox(height: AppSpacing.x3),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _changingMode ? null : _requireHolderApproval,
                    icon: _changingMode
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(LucideIcons.lock, size: 16),
                    label: const Text('Require holder approval'),
                  ),
                ),
              ],
              if (gated) ...<Widget>[
                const SizedBox(height: AppSpacing.x3),
                const Divider(height: 1, color: AppColors.divider),
                const SizedBox(height: AppSpacing.x3),
                Text(
                  grants.isEmpty
                      ? 'No visitor has requested access yet.'
                      : 'Visitor requests (${grants.length})',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                for (final CertificateAccessGrant grant in grants) ...<Widget>[
                  const SizedBox(height: AppSpacing.x2),
                  _GrantRow(
                    grant: grant,
                    holderName: _holderName(grant.batchUserId),
                    revoking: _revoking.contains(grant.id),
                    onRevoke: grant.canRevoke ? () => _revoke(grant) : null,
                  ),
                ],
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _GrantRow extends StatelessWidget {
  const _GrantRow({
    required this.grant,
    required this.holderName,
    required this.revoking,
    required this.onRevoke,
  });

  final CertificateAccessGrant grant;
  final String holderName;
  final bool revoking;
  final VoidCallback? onRevoke;

  static String _date(DateTime? dt) {
    if (dt == null) return '';
    final DateTime local = dt.toLocal();
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
    return '${local.day} ${months[local.month - 1]} ${local.year}';
  }

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color fg) = switch (grant.status) {
      'approved' => (AppColors.badgeValidBg, AppColors.badgeValidFg),
      'pending_email' || 'pending_approval' => (
        AppColors.badgePendingBg,
        AppColors.badgePendingFg,
      ),
      'expired' => (AppColors.badgeExpiredBg, AppColors.badgeExpiredFg),
      _ => (AppColors.badgeRevokedBg, AppColors.badgeRevokedFg),
    };
    final String expires = grant.status == 'approved'
        ? _date(grant.expiresAt)
        : '';
    final String requested = _date(grant.requestedAt);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                grant.granteeEmail.isEmpty ? 'Visitor' : grant.granteeEmail,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                <String>[
                  'For $holderName',
                  if (requested.isNotEmpty) 'requested $requested',
                  if (expires.isNotEmpty) 'expires $expires',
                ].join(' • '),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  grant.statusLabel,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: fg,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (onRevoke != null)
          revoking
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.danger,
                  ),
                  onPressed: onRevoke,
                  child: const Text('Revoke'),
                ),
      ],
    );
  }
}

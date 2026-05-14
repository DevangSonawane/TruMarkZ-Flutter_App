import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/models/verification_models.dart';
import '../../../../../core/network/api_client.dart';
import '../../../../../core/router/app_router.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/widgets/tmz_button.dart';
import '../../../../../core/widgets/tmz_card.dart';
import '../../../data/verification_repository.dart';

class IndividualRecordDetailPage extends ConsumerStatefulWidget {
  const IndividualRecordDetailPage({super.key});

  @override
  ConsumerState<IndividualRecordDetailPage> createState() =>
      _IndividualRecordDetailPageState();
}

class _IndividualRecordDetailPageState
    extends ConsumerState<IndividualRecordDetailPage> {
  bool _didInit = false;
  String _userId = '';

  AsyncValue<VerificationUser> _data = const AsyncLoading();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInit) return;
    _didInit = true;
    _userId = (GoRouterState.of(context).uri.queryParameters['user_id'] ?? '')
        .trim();
    _load();
  }

  Future<void> _load() async {
    if (_userId.isEmpty) {
      setState(() {
        _data = AsyncError(
          const ApiException(statusCode: null, message: 'Missing user_id.'),
          StackTrace.current,
        );
      });
      return;
    }
    setState(() => _data = const AsyncLoading());
    try {
      final VerificationRepository repo = ref.read(
        verificationRepositoryProvider,
      );
      final VerificationUser res = await repo.getUserVerification(_userId);
      if (!mounted) return;
      setState(() => _data = AsyncData(res));
    } on ApiException catch (e, st) {
      if (!mounted) return;
      setState(() => _data = AsyncError(e, st));
    } catch (e, st) {
      if (!mounted) return;
      setState(() => _data = AsyncError(e, st));
    }
  }

  void _goBack(BuildContext context) {
    final GoRouter router = GoRouter.of(context);
    if (router.canPop()) {
      context.pop();
    } else {
      context.go(AppRouter.appBatchesPath);
    }
  }

  Future<void> _approve() async {
    final VerificationUser? user = _data.valueOrNull;
    if (user == null) return;
    try {
      final VerificationRepository repo = ref.read(
        verificationRepositoryProvider,
      );
      await repo.updateVerificationStatus(userId: user.id, status: 'verified');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Approved successfully.')));
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Something went wrong. Please try again.'),
        ),
      );
    }
  }

  Future<void> _reject() async {
    final VerificationUser? user = _data.valueOrNull;
    if (user == null) return;

    final TextEditingController controller = TextEditingController();
    final String? reason = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Reject Verification'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: 'Reason for rejection'),
            maxLines: 3,
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.of(context).pop(controller.text.trim()),
              child: const Text('Reject'),
            ),
          ],
        );
      },
    );

    if (reason == null) return;
    if (!mounted) return;
    if (reason.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a reason.')));
      return;
    }

    try {
      final VerificationRepository repo = ref.read(
        verificationRepositoryProvider,
      );
      await repo.updateVerificationStatus(
        userId: user.id,
        status: 'failed',
        reason: reason,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Rejected successfully.')));
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Something went wrong. Please try again.'),
        ),
      );
    }
  }

  Future<void> _generateCertificate() async {
    final VerificationUser? user = _data.valueOrNull;
    if (user == null) return;
    try {
      final VerificationRepository repo = ref.read(
        verificationRepositoryProvider,
      );
      final GenerateCertificateResponse res = await repo.generateCertificate(
        user.id,
      );
      if (!mounted) return;
      _showCertificateSheet(res);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Something went wrong. Please try again.'),
        ),
      );
    }
  }

  void _showCertificateSheet(GenerateCertificateResponse res) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext context) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.x4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Certificate Ready', style: AppTypography.heading1),
                const SizedBox(height: AppSpacing.x2),
                Text(
                  res.message.isEmpty ? 'Generated successfully.' : res.message,
                  style: AppTypography.body2.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.x4),
                TMZButton(
                  label: 'Download PDF',
                  icon: Icons.download_rounded,
                  onPressed: () async {
                    final Uri? uri = Uri.tryParse(res.pdfUrl);
                    if (uri == null) return;
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  },
                ),
                const SizedBox(height: AppSpacing.x2),
                TMZCard(
                  padding: const EdgeInsets.all(AppSpacing.x4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'QR Code Link',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textTertiary,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        res.qrCodeData,
                        style: AppTypography.body2.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.x3),
                      TMZButton(
                        label: 'Copy Link',
                        icon: Icons.copy_rounded,
                        variant: TMZButtonVariant.secondary,
                        onPressed: () async {
                          await Clipboard.setData(
                            ClipboardData(text: res.qrCodeData),
                          );
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Link copied.')),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openUrl(String url) async {
    final Uri? uri = Uri.tryParse(url);
    if (uri == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Invalid URL.')));
      return;
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () => _goBack(context),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text('Individual Record Detail'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Refresh',
            onPressed: _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: _data.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (Object err, _) => Padding(
            padding: const EdgeInsets.all(AppSpacing.x4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Unable to load record', style: AppTypography.display2),
                const SizedBox(height: AppSpacing.x2),
                Text(
                  err.toString(),
                  style: AppTypography.body2.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.x4),
                ElevatedButton.icon(
                  onPressed: _load,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
          data: (VerificationUser user) {
            final String statusLabel = _statusLabel(user.verificationStatus);
            final _StatusStyle style = _statusStyle(user.verificationStatus);

            return ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.x4,
                AppSpacing.x3,
                AppSpacing.x4,
                AppSpacing.x6,
              ),
              children: <Widget>[
                Row(
                  children: <Widget>[
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: AppColors.brandBlue.withAlpha(14),
                      backgroundImage: (user.photoUrl ?? '').trim().isNotEmpty
                          ? NetworkImage(user.photoUrl!)
                          : null,
                      child: (user.photoUrl ?? '').trim().isNotEmpty
                          ? null
                          : const Icon(
                              Icons.person_rounded,
                              color: AppColors.brandBlue,
                            ),
                    ),
                    const SizedBox(width: AppSpacing.x3),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            user.fullName.trim().isEmpty
                                ? 'Unnamed'
                                : user.fullName,
                            style: AppTypography.heading1.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user.email,
                            style: AppTypography.body2.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: style.bg,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: style.fg.withAlpha(40)),
                      ),
                      child: Text(
                        statusLabel.toUpperCase(),
                        style: AppTypography.caption.copyWith(
                          color: style.fg,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.x4),
                TMZCard(
                  padding: const EdgeInsets.all(AppSpacing.x4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('Details', style: AppTypography.heading2),
                      const SizedBox(height: AppSpacing.x3),
                      _kv('Phone', user.phoneNumber),
                      _kv('DOB', user.dob ?? '—'),
                      _kv('Aadhar', user.aadharNumber ?? '—'),
                      _kv('PAN', user.panNumber ?? '—'),
                      _kv(
                        'Invite',
                        user.inviteAccepted ? 'Accepted' : 'Pending',
                      ),
                      const SizedBox(height: AppSpacing.x2),
                      _kv('Address', _formatAddress(user)),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.x4),
                Text('Documents', style: AppTypography.heading2),
                const SizedBox(height: AppSpacing.x2),
                if (user.documents.isEmpty)
                  Text(
                    'No documents uploaded.',
                    style: AppTypography.body2.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  )
                else
                  for (final VerificationDocument d
                      in user.documents) ...<Widget>[
                    _DocumentCard(
                      doc: d,
                      onView: d.documentUrl.trim().isEmpty
                          ? null
                          : () => _openUrl(d.documentUrl),
                    ),
                    const SizedBox(height: AppSpacing.x2),
                  ],
                const SizedBox(height: AppSpacing.x4),
                Text('Actions', style: AppTypography.heading2),
                const SizedBox(height: AppSpacing.x2),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: TMZButton(
                        label: 'Approve',
                        icon: Icons.check_rounded,
                        onPressed: _approve,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.x3),
                    Expanded(
                      child: TMZButton(
                        label: 'Reject',
                        icon: Icons.close_rounded,
                        variant: TMZButtonVariant.dangerGhost,
                        onPressed: _reject,
                      ),
                    ),
                  ],
                ),
                if (user.verificationStatus == 'verified') ...<Widget>[
                  const SizedBox(height: AppSpacing.x3),
                  TMZButton(
                    label: 'Generate Certificate',
                    icon: Icons.qr_code_rounded,
                    onPressed: _generateCertificate,
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  static Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 92,
            child: Text(
              k,
              style: AppTypography.caption.copyWith(
                color: AppColors.textTertiary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Expanded(
            child: Text(
              v.trim().isEmpty ? '—' : v,
              style: AppTypography.body2.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _formatAddress(VerificationUser u) {
    final List<String> parts = <String>[
      if ((u.addressLine1 ?? '').trim().isNotEmpty) u.addressLine1!.trim(),
      if ((u.addressLine2 ?? '').trim().isNotEmpty) u.addressLine2!.trim(),
      if ((u.addressLine3 ?? '').trim().isNotEmpty) u.addressLine3!.trim(),
      if ((u.state ?? '').trim().isNotEmpty) u.state!.trim(),
      if ((u.country ?? '').trim().isNotEmpty) u.country!.trim(),
      if ((u.pincode ?? '').trim().isNotEmpty) u.pincode!.trim(),
    ];
    return parts.isEmpty ? '—' : parts.join(', ');
  }

  static String _statusLabel(String raw) {
    switch (raw) {
      case 'verified':
        return 'Verified';
      case 'failed':
        return 'Failed';
      default:
        return 'Pending';
    }
  }

  static _StatusStyle _statusStyle(String raw) {
    switch (raw) {
      case 'verified':
        return const _StatusStyle(
          bg: AppColors.successBg,
          fg: AppColors.success,
        );
      case 'failed':
        return const _StatusStyle(bg: AppColors.dangerBg, fg: AppColors.error);
      default:
        return const _StatusStyle(bg: Color(0xFFFFFBEB), fg: Color(0xFFF59E0B));
    }
  }
}

class _DocumentCard extends StatelessWidget {
  const _DocumentCard({required this.doc, required this.onView});

  final VerificationDocument doc;
  final VoidCallback? onView;

  @override
  Widget build(BuildContext context) {
    final _DocStatusStyle style = _docStyle(doc.verificationStatus);

    return TMZCard(
      padding: const EdgeInsets.all(AppSpacing.x4),
      child: Row(
        children: <Widget>[
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: style.bg, shape: BoxShape.circle),
            child: Icon(style.icon, color: style.fg),
          ),
          const SizedBox(width: AppSpacing.x3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  doc.documentLabel,
                  style: AppTypography.body1.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: style.bg,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: style.fg.withAlpha(40)),
                      ),
                      child: Text(
                        style.label.toUpperCase(),
                        style: AppTypography.caption.copyWith(
                          color: style.fg,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.7,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F6FF),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'v${doc.version}',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                if ((doc.verificationReason ?? '')
                    .trim()
                    .isNotEmpty) ...<Widget>[
                  const SizedBox(height: 8),
                  Text(
                    doc.verificationReason!,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.25,
                    ),
                  ),
                ],
              ],
            ),
          ),
          TMZButton(
            label: 'View',
            fullWidth: false,
            icon: Icons.open_in_new_rounded,
            variant: TMZButtonVariant.secondary,
            onPressed: onView,
          ),
        ],
      ),
    );
  }

  static _DocStatusStyle _docStyle(String raw) {
    switch (raw) {
      case 'verified':
        return const _DocStatusStyle(
          bg: AppColors.successBg,
          fg: AppColors.success,
          label: 'Verified',
          icon: Icons.check_circle_rounded,
        );
      case 'failed':
        return const _DocStatusStyle(
          bg: AppColors.dangerBg,
          fg: AppColors.error,
          label: 'Failed',
          icon: Icons.cancel_rounded,
        );
      default:
        return const _DocStatusStyle(
          bg: Color(0xFFFFFBEB),
          fg: Color(0xFFF59E0B),
          label: 'Pending',
          icon: Icons.hourglass_bottom_rounded,
        );
    }
  }
}

class _StatusStyle {
  const _StatusStyle({required this.bg, required this.fg});

  final Color bg;
  final Color fg;
}

class _DocStatusStyle {
  const _DocStatusStyle({
    required this.bg,
    required this.fg,
    required this.label,
    required this.icon,
  });

  final Color bg;
  final Color fg;
  final String label;
  final IconData icon;
}

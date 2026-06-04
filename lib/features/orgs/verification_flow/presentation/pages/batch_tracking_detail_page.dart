import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/models/verification_models.dart';
import '../../../../../core/network/api_client.dart';
import '../../../../../core/router/app_router.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/widgets/tmz_card.dart';
import '../../../data/verification_repository.dart';

class BatchTrackingDetailPage extends ConsumerStatefulWidget {
  const BatchTrackingDetailPage({super.key});

  @override
  ConsumerState<BatchTrackingDetailPage> createState() =>
      _BatchTrackingDetailPageState();
}

class _BatchTrackingDetailPageState
    extends ConsumerState<BatchTrackingDetailPage> {
  bool _didInit = false;
  String _batchId = '';

  AsyncValue<VerificationListResponse> _data = const AsyncLoading();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInit) return;
    _didInit = true;
    _batchId = (GoRouterState.of(context).uri.queryParameters['batch_id'] ?? '')
        .trim();
    _load();
  }

  Future<void> _load() async {
    setState(() => _data = const AsyncLoading());
    try {
      final VerificationRepository repo = ref.read(
        verificationRepositoryProvider,
      );
      final VerificationListResponse res = await repo.getAllVerifications(
        batchId: _batchId,
        limit: 500,
        offset: 0,
      );
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

  @override
  Widget build(BuildContext context) {
    final String title = _batchId.trim().isEmpty
        ? 'Batch'
        : 'Batch ${_batchId.substring(0, _batchId.length.clamp(0, 10))}';

    return Scaffold(
      backgroundColor: AppColors.brandBlue,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.x4,
                AppSpacing.x3,
                AppSpacing.x4,
                AppSpacing.x3,
              ),
              child: Row(
                children: <Widget>[
                  IconButton(
                    tooltip: 'Back',
                    onPressed: () => _goBack(context),
                    icon: const Icon(Icons.arrow_back_rounded),
                    color: Colors.white,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.heading1.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  color: Color(0xFFF7F9FC),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: _data.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (Object err, _) => Padding(
                    padding: const EdgeInsets.all(AppSpacing.x4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Unable to load batch',
                          style: AppTypography.display2,
                        ),
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
                  data: (VerificationListResponse res) {
                    return ListView(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(
                        AppSpacing.x4,
                        AppSpacing.x4,
                        AppSpacing.x4,
                        AppSpacing.x6 +
                            MediaQuery.viewPaddingOf(context).bottom,
                      ),
                      children: <Widget>[
                        _SummarySection(
                          verified: res.verified,
                          pending: res.pending,
                          failed: res.failed,
                        ),
                        const SizedBox(height: AppSpacing.x4),
                        const _SectionHeader(
                          title: 'RECORDS',
                          subtitle: 'People in this batch',
                        ),
                        const SizedBox(height: AppSpacing.x3),
                        for (final VerificationUser u in res.users) ...<Widget>[
                          _UserTile(
                            user: u,
                            onTap: () => context.push(
                              '${AppRouter.individualRecordDetailPath}?user_id=${Uri.encodeQueryComponent(u.id)}',
                            ),
                          ),
                          const SizedBox(height: AppSpacing.x2),
                        ],
                        if (res.users.isEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: AppSpacing.x6),
                            child: Center(
                              child: Text(
                                'No records found.',
                                style: AppTypography.body2.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummarySection extends StatelessWidget {
  const _SummarySection({
    required this.verified,
    required this.pending,
    required this.failed,
  });

  final int verified;
  final int pending;
  final int failed;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: _FigmaStatCard(
            label: 'Verified',
            value: verified.toString(),
            labelColor: const Color(0xFF10B981),
            labelLetterSpacing: 0.08848852291703224,
            valueColor: const Color(0xFF0B0F19),
            compact: true,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _FigmaStatCard(
            label: 'Pending',
            value: pending.toString(),
            labelColor: const Color(0xFFF59E0B),
            labelLetterSpacing: 0.15169461071491241,
            valueColor: const Color(0xFF0B0F19),
            compact: true,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _FigmaStatCard(
            label: 'Failed',
            value: failed.toString(),
            labelColor: const Color(0xFFEF4444),
            labelLetterSpacing: 0.12641217559576035,
            valueColor: const Color(0xFF0B0F19),
            compact: true,
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            height: 17.750728607177734 / 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.1833819150924683,
            color: Color(0xFF323232),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            height: 20 / 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _FigmaStatCard extends StatelessWidget {
  const _FigmaStatCard({
    required this.label,
    required this.value,
    required this.labelColor,
    required this.labelLetterSpacing,
    required this.valueColor,
    this.compact = false,
  });

  final String label;
  final String value;
  final Color labelColor;
  final double labelLetterSpacing;
  final Color valueColor;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minHeight: compact ? 84 : 91.83381652832031),
      padding: EdgeInsets.all(compact ? 12.0 : 17.259475708007812),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(compact ? 12 : 12.94460678100586),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: compact ? 1 : 1.0787172317504883,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.024),
            offset: Offset(0, compact ? 1 : 1.0787172317504883),
            blurRadius: compact ? 2 : 2.1574344635009766,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: Offset(0, compact ? 1 : 1.0787172317504883),
            blurRadius: compact ? 3 : 3.236151695251465,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textHeightBehavior: const TextHeightBehavior(
              applyHeightToFirstAscent: false,
              applyHeightToLastDescent: false,
            ),
            style: TextStyle(
              fontFamily: 'SF Pro Rounded',
              fontSize: compact ? 11.8 : 12.94460678100586,
              height: compact
                  ? 16.2 / 11.8
                  : 17.259475708007812 / 12.94460678100586,
              fontWeight: FontWeight.w500,
              letterSpacing: labelLetterSpacing,
              color: labelColor,
            ),
          ),
          SizedBox(height: compact ? 4 : 4.314868927001953),
          Text(
            value,
            textHeightBehavior: const TextHeightBehavior(
              applyHeightToFirstAscent: false,
              applyHeightToLastDescent: false,
            ),
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: compact ? 20 : 25.88921356201172,
              height: compact
                  ? 28 / 20
                  : 34.518951416015625 / 25.88921356201172,
              fontWeight: FontWeight.w600,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _UserTile extends StatelessWidget {
  const _UserTile({required this.user, required this.onTap});

  final VerificationUser user;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (_StatusStyle style, String label) = _statusStyle(
      user.verificationStatus,
    );
    final String? photoUrl = (user.photoUrl ?? '').trim().isEmpty
        ? null
        : user.photoUrl!.trim();

    return TMZCard(
      padding: const EdgeInsets.all(AppSpacing.x4),
      onTap: onTap,
      child: Row(
        children: <Widget>[
          ClipOval(
            child: Container(
              width: 48,
              height: 48,
              color: const Color(0xFFEAF2FF),
              child: photoUrl == null
                  ? const Icon(Icons.person_rounded, color: AppColors.brandBlue)
                  : Image.network(
                      photoUrl,
                      fit: BoxFit.cover,
                      errorBuilder:
                          (
                            BuildContext context,
                            Object error,
                            StackTrace? stackTrace,
                          ) => const Icon(
                            Icons.person_rounded,
                            color: AppColors.brandBlue,
                          ),
                    ),
            ),
          ),
          const SizedBox(width: AppSpacing.x3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  user.fullName.trim().isEmpty ? 'Unnamed' : user.fullName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    height: 22 / 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    height: 18 / 13,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: <Widget>[
                    _StatusBadge(label: label, style: style),
                    const SizedBox(width: 10),
                    if (user.inviteAccepted)
                      _MiniPill(
                        icon: Icons.check_rounded,
                        label: 'Invite accepted',
                        color: AppColors.success,
                      )
                    else
                      _MiniPill(
                        icon: Icons.schedule_rounded,
                        label: 'Invite pending',
                        color: const Color(0xFFF59E0B),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.textTertiary,
          ),
        ],
      ),
    );
  }

  static (_StatusStyle, String) _statusStyle(String raw) {
    switch (raw) {
      case 'verified':
        return (const _StatusStyle.verified(), 'Verified');
      case 'failed':
        return (const _StatusStyle.failed(), 'Failed');
      default:
        return (const _StatusStyle.pending(), 'Pending');
    }
  }
}

class _MiniPill extends StatelessWidget {
  const _MiniPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withAlpha(32)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              height: 16 / 12,
              fontWeight: FontWeight.w700,
            ).copyWith(color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.style});

  final String label;
  final _StatusStyle style;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: style.bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: style.fg.withAlpha(30)),
      ),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 11,
          height: 15 / 11,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.8,
        ).copyWith(color: style.fg),
      ),
    );
  }
}

class _StatusStyle {
  const _StatusStyle({required this.bg, required this.fg});

  final Color bg;
  final Color fg;

  const _StatusStyle.pending()
    : bg = const Color(0xFFFFFBEB),
      fg = const Color(0xFFF59E0B);

  const _StatusStyle.verified()
    : bg = AppColors.successBg,
      fg = AppColors.success;

  const _StatusStyle.failed() : bg = AppColors.dangerBg, fg = AppColors.error;
}

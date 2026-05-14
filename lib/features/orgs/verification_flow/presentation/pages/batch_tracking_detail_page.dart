import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/models/verification_models.dart';
import '../../../../../core/network/api_client.dart';
import '../../../../../core/router/app_router.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
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
      backgroundColor: AppColors.pageBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () => _goBack(context),
          icon: const Icon(Icons.arrow_back_rounded),
          color: AppColors.brandBlue,
        ),
        title: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.heading1.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: _data.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (Object err, _) => Padding(
            padding: const EdgeInsets.all(AppSpacing.x4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Unable to load batch', style: AppTypography.display2),
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
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.x4,
                AppSpacing.x3,
                AppSpacing.x4,
                AppSpacing.x6,
              ),
              children: <Widget>[
                _SummaryBar(
                  verified: res.verified,
                  pending: res.pending,
                  failed: res.failed,
                ),
                const SizedBox(height: AppSpacing.x4),
                Text('Records', style: AppTypography.heading2),
                const SizedBox(height: AppSpacing.x2),
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
    );
  }
}

class _SummaryBar extends StatelessWidget {
  const _SummaryBar({
    required this.verified,
    required this.pending,
    required this.failed,
  });

  final int verified;
  final int pending;
  final int failed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border.withAlpha(140)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.brandBlue.withAlpha(16),
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: _Stat(
              label: 'Verified',
              value: verified,
              color: AppColors.success,
            ),
          ),
          const SizedBox(width: AppSpacing.x3),
          Expanded(
            child: _Stat(
              label: 'Pending',
              value: pending,
              color: const Color(0xFFF59E0B),
            ),
          ),
          const SizedBox(width: AppSpacing.x3),
          Expanded(
            child: _Stat(
              label: 'Failed',
              value: failed,
              color: AppColors.error,
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, required this.color});

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withAlpha(16),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label.toUpperCase(),
            style: AppTypography.caption.copyWith(
              color: AppColors.textTertiary,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value.toString(),
            style: AppTypography.heading1.copyWith(
              color: color,
              fontWeight: FontWeight.w900,
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

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.x4),
          child: Row(
            children: <Widget>[
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: style.bg,
                  shape: BoxShape.circle,
                ),
                child: Icon(style.icon, color: style.fg),
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
                      style: AppTypography.body1.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.body2.copyWith(
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
        ),
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
            style: AppTypography.caption.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
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
        style: AppTypography.caption.copyWith(
          color: style.fg,
          fontWeight: FontWeight.w900,
          fontSize: 11,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _StatusStyle {
  const _StatusStyle({required this.bg, required this.fg, required this.icon});

  final Color bg;
  final Color fg;
  final IconData icon;

  const _StatusStyle.pending()
    : bg = const Color(0xFFFFFBEB),
      fg = const Color(0xFFF59E0B),
      icon = Icons.hourglass_bottom_rounded;

  const _StatusStyle.verified()
    : bg = AppColors.successBg,
      fg = AppColors.success,
      icon = Icons.check_circle_rounded;

  const _StatusStyle.failed()
    : bg = AppColors.dangerBg,
      fg = AppColors.error,
      icon = Icons.cancel_rounded;
}

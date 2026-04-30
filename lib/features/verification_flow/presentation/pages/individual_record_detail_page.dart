import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/tmz_badge.dart';
import '../../../../core/widgets/tmz_button.dart';
import '../../../../core/widgets/tmz_card.dart';

class IndividualRecordDetailPage extends StatelessWidget {
  const IndividualRecordDetailPage({super.key});

  static int _tryParseInt(String? value, {required int fallback}) {
    if (value == null) return fallback;
    final int? parsed = int.tryParse(value);
    return parsed ?? fallback;
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final GoRouterState state = GoRouterState.of(context);

    final String batchName =
        (state.uri.queryParameters['batch'] ?? 'Batch #A1C3').trim();
    final String personName = (state.uri.queryParameters['name'] ?? 'John Doe')
        .trim();
    final String statusRaw = (state.uri.queryParameters['status'] ?? 'pending')
        .trim();
    final _RecordStatus status = _parseRecordStatus(statusRaw);

    final int checksDone = _tryParseInt(
      state.uri.queryParameters['checks_done'],
      fallback: 2,
    );
    final int checksTotal = _tryParseInt(
      state.uri.queryParameters['checks_total'],
      fallback: 6,
    );

    final bool inBatchesShell = state.uri.path.startsWith(
      AppRouter.appBatchesPath,
    );
    final String credentialPath = inBatchesShell
        ? AppRouter.appCredentialDetailPath
        : AppRouter.credentialDetailPath;

    final List<_CheckItem> checks = <_CheckItem>[
      const _CheckItem('Identity (Aadhaar/PAN)', _CheckState.verified),
      const _CheckItem('Address Verification', _CheckState.inReview),
      const _CheckItem('Driving License', _CheckState.verified),
      const _CheckItem('Employment (EPFO)', _CheckState.pending),
      const _CheckItem('Criminal Record', _CheckState.pending),
      const _CheckItem('Photo Match', _CheckState.verified),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: <Widget>[
            SvgPicture.asset(
              'assets/icons/trumarkz_shield.svg',
              height: 22,
              colorFilter: ColorFilter.mode(scheme.primary, BlendMode.srcIn),
            ),
            const SizedBox(width: AppSpacing.x2),
            const Text('Individual Record Detail'),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.x4),
                children: <Widget>[
                  Text(personName, style: AppTypography.display2),
                  const SizedBox(height: AppSpacing.x2),
                  Text(
                    '$batchName • ${status.label} • $checksDone/$checksTotal checks',
                    style: AppTypography.body2.copyWith(
                      color: scheme.onSurface.withAlpha(160),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.x4),
                  TMZCard(
                    child: ListTile(
                      leading: const Icon(Icons.badge_outlined),
                      title: const Text('Record Status'),
                      subtitle: Text(status.subtitle),
                      trailing: _statusBadge(status),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.x3),
                  Text('Checks', style: AppTypography.heading2),
                  const SizedBox(height: AppSpacing.x2),
                  for (final _CheckItem item in checks) ...<Widget>[
                    TMZCard(
                      child: ListTile(
                        leading: Icon(item.state.icon, color: item.state.color),
                        title: Text(item.title),
                        subtitle: Text(item.state.label),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Evidence view coming soon.'),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: AppSpacing.x2),
                  ],
                  const SizedBox(height: AppSpacing.x3),
                  Text('On-chain Proof', style: AppTypography.heading2),
                  const SizedBox(height: AppSpacing.x2),
                  TMZCard(
                    child: ListTile(
                      leading: const Icon(Icons.link_rounded),
                      title: const Text('Transaction Hash'),
                      subtitle: const Text('0x9f3a...c812  •  Block 19288321'),
                      trailing: const Icon(Icons.open_in_new_rounded),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Explorer link coming soon.'),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: AppSpacing.x3),
                  Text('Dispute', style: AppTypography.heading2),
                  const SizedBox(height: AppSpacing.x2),
                  TMZCard(
                    child: ListTile(
                      leading: const Icon(Icons.report_gmailerrorred_rounded),
                      title: const Text('Raise a dispute'),
                      subtitle: const Text(
                        'Flag incorrect evidence or mismatched data',
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Dispute flow coming soon.'),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.x4,
                  AppSpacing.x2,
                  AppSpacing.x4,
                  AppSpacing.x4,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    TMZButton(
                      label: 'View Credential',
                      icon: Icons.qr_code_rounded,
                      onPressed: () => context.push(
                        '$credentialPath?name=${Uri.encodeQueryComponent(personName)}&status=${status.name}',
                      ),
                    ),
                    const SizedBox(height: AppSpacing.x2),
                    TMZButton(
                      label: 'Back to Batch',
                      variant: TMZButtonVariant.secondary,
                      icon: Icons.arrow_back_rounded,
                      onPressed: () => context.pop(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static TMZBadge _statusBadge(_RecordStatus status) {
    return switch (status) {
      _RecordStatus.verified => const TMZBadge(
        label: 'Verified',
        backgroundColor: AppColors.success,
        foregroundColor: Colors.white,
      ),
      _RecordStatus.inReview => const TMZBadge(
        label: 'In Review',
        backgroundColor: AppColors.brandBlue,
        foregroundColor: Colors.white,
      ),
      _RecordStatus.pending => const TMZBadge(
        label: 'Pending',
        backgroundColor: Color(0xFFF59E0B),
        foregroundColor: Colors.white,
      ),
      _RecordStatus.failed => const TMZBadge(
        label: 'Failed',
        backgroundColor: AppColors.error,
        foregroundColor: Colors.white,
      ),
    };
  }
}

enum _RecordStatus { verified, inReview, pending, failed }

_RecordStatus _parseRecordStatus(String raw) {
  return switch (raw.toLowerCase()) {
    'verified' => _RecordStatus.verified,
    'inreview' || 'in_review' || 'review' => _RecordStatus.inReview,
    'failed' || 'rejected' => _RecordStatus.failed,
    _ => _RecordStatus.pending,
  };
}

extension on _RecordStatus {
  String get label => switch (this) {
    _RecordStatus.verified => 'Verified',
    _RecordStatus.inReview => 'In review',
    _RecordStatus.pending => 'Pending',
    _RecordStatus.failed => 'Failed',
  };

  String get subtitle => switch (this) {
    _RecordStatus.verified => 'All checks completed successfully.',
    _RecordStatus.inReview => 'Evidence is being reviewed by a verifier.',
    _RecordStatus.pending => 'Checks are queued or waiting for assignment.',
    _RecordStatus.failed => 'One or more checks failed. Review evidence.',
  };
}

enum _CheckState { verified, inReview, pending, failed }

extension on _CheckState {
  String get label => switch (this) {
    _CheckState.verified => 'Verified',
    _CheckState.inReview => 'In review',
    _CheckState.pending => 'Pending',
    _CheckState.failed => 'Failed',
  };

  IconData get icon => switch (this) {
    _CheckState.verified => Icons.check_circle_rounded,
    _CheckState.inReview => Icons.autorenew_rounded,
    _CheckState.pending => Icons.hourglass_bottom_rounded,
    _CheckState.failed => Icons.cancel_rounded,
  };

  Color get color => switch (this) {
    _CheckState.verified => AppColors.success,
    _CheckState.inReview => AppColors.brandBlue,
    _CheckState.pending => const Color(0xFFF59E0B),
    _CheckState.failed => AppColors.error,
  };
}

class _CheckItem {
  const _CheckItem(this.title, this.state);

  final String title;
  final _CheckState state;
}

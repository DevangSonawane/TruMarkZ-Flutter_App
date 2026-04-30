import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/tmz_badge.dart';
import '../../../../core/widgets/tmz_card.dart';

class BatchTrackingDetailPage extends StatelessWidget {
  const BatchTrackingDetailPage({super.key});

  static int _tryParseInt(String? value, {required int fallback}) {
    if (value == null) return fallback;
    final int? parsed = int.tryParse(value);
    return parsed ?? fallback;
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Map<String, String> qp = GoRouterState.of(
      context,
    ).uri.queryParameters;

    final String batchName = (qp['batch'] ?? 'Batch #A1C3').trim().isNotEmpty
        ? qp['batch']!.trim()
        : 'Batch #A1C3';
    final int total = _tryParseInt(qp['records'], fallback: 80);
    final int completed = _tryParseInt(qp['completed'], fallback: 24);

    final double progress = total <= 0 ? 0 : (completed / total).clamp(0, 1);

    final List<_RecordStatus> records = _RecordStatus.sample(total: total);

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
            const Text('Batch Tracking Detail'),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.x4),
        children: <Widget>[
          Text(batchName, style: AppTypography.display2),
          const SizedBox(height: AppSpacing.x2),
          Text(
            'Live progress • $completed/$total complete',
            style: AppTypography.body2.copyWith(
              color: scheme.onSurface.withAlpha(160),
            ),
          ),
          const SizedBox(height: AppSpacing.x3),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: scheme.onSurface.withAlpha(10),
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.brandBlue,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.x5),
          Text('Records', style: AppTypography.heading2),
          const SizedBox(height: AppSpacing.x2),
          for (final _RecordStatus record in records) ...<Widget>[
            TMZCard(
              onTap: () {
                context.push(
                  '${AppRouter.appIndividualRecordDetailPath}?batch=${Uri.encodeQueryComponent(batchName)}&name=${Uri.encodeQueryComponent(record.name)}&status=${record.status.name}&checks_done=${record.checksDone}&checks_total=${record.checksTotal}',
                );
              },
              child: ListTile(
                leading: const Icon(Icons.person_outline_rounded),
                title: Text(record.name),
                subtitle: Text(
                  '${record.statusLabel} • ${record.checksDone}/${record.checksTotal} checks',
                ),
                trailing: _badgeForStatus(record.status),
              ),
            ),
            const SizedBox(height: AppSpacing.x2),
          ],
        ],
      ),
    );
  }

  static Widget _badgeForStatus(_RecordVerificationStatus status) {
    return switch (status) {
      _RecordVerificationStatus.verified => const TMZBadge(
        label: 'Verified',
        backgroundColor: AppColors.success,
        foregroundColor: Colors.white,
      ),
      _RecordVerificationStatus.inReview => const TMZBadge(
        label: 'In Review',
        backgroundColor: Color(0xFF2563EB),
        foregroundColor: Colors.white,
      ),
      _RecordVerificationStatus.pending => const TMZBadge(
        label: 'Pending',
        backgroundColor: Color(0xFFF59E0B),
        foregroundColor: Colors.white,
      ),
      _RecordVerificationStatus.failed => const TMZBadge(
        label: 'Failed',
        backgroundColor: AppColors.error,
        foregroundColor: Colors.white,
      ),
    };
  }
}

enum _RecordVerificationStatus { verified, inReview, pending, failed }

class _RecordStatus {
  const _RecordStatus({
    required this.name,
    required this.status,
    required this.checksDone,
    required this.checksTotal,
  });

  final String name;
  final _RecordVerificationStatus status;
  final int checksDone;
  final int checksTotal;

  String get statusLabel => switch (status) {
    _RecordVerificationStatus.verified => 'Verified',
    _RecordVerificationStatus.inReview => 'In review',
    _RecordVerificationStatus.pending => 'Pending',
    _RecordVerificationStatus.failed => 'Failed',
  };

  static List<_RecordStatus> sample({required int total}) {
    final int n = (total.clamp(1, 12));
    final List<_RecordStatus> base = <_RecordStatus>[
      const _RecordStatus(
        name: 'John Doe',
        status: _RecordVerificationStatus.verified,
        checksDone: 6,
        checksTotal: 6,
      ),
      const _RecordStatus(
        name: 'Jane Smith',
        status: _RecordVerificationStatus.inReview,
        checksDone: 4,
        checksTotal: 6,
      ),
      const _RecordStatus(
        name: 'Asha Nair',
        status: _RecordVerificationStatus.pending,
        checksDone: 2,
        checksTotal: 6,
      ),
      const _RecordStatus(
        name: 'Mohit Singh',
        status: _RecordVerificationStatus.failed,
        checksDone: 3,
        checksTotal: 6,
      ),
    ];

    if (n <= base.length) return base.take(n).toList();

    final List<_RecordStatus> out = <_RecordStatus>[...base];
    for (int i = base.length; i < n; i++) {
      out.add(
        _RecordStatus(
          name: 'Record ${i + 1}',
          status: i.isEven
              ? _RecordVerificationStatus.pending
              : _RecordVerificationStatus.inReview,
          checksDone: i.isEven ? 1 : 3,
          checksTotal: 6,
        ),
      );
    }
    return out;
  }
}

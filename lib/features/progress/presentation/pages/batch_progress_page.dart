import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/tmz_card.dart';

class BatchProgressPage extends StatelessWidget {
  const BatchProgressPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final List<_OrgBatch> batches = _OrgBatch.sampleNow();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: <Widget>[
            SvgPicture.asset(
              'assets/icons/trumarkz_shield.svg',
              height: 24,
              colorFilter: ColorFilter.mode(scheme.primary, BlendMode.srcIn),
            ),
            const SizedBox(width: AppSpacing.x2),
            const Text('Batch Progress'),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.x4),
        children: <Widget>[
          Text('Verification batches', style: AppTypography.display2),
          const SizedBox(height: AppSpacing.x2),
          Text(
            'Track multi-credential verification runs for your organisation.',
            style: AppTypography.body2.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.x4),
          for (final _OrgBatch batch in batches) ...<Widget>[
            _BatchCard(batch: batch),
            const SizedBox(height: AppSpacing.x3),
          ],
        ],
      ),
    );
  }
}

class _BatchCard extends StatelessWidget {
  const _BatchCard({required this.batch});

  final _OrgBatch batch;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final double progress = batch.totalRecords <= 0
        ? 0
        : (batch.completedRecords / batch.totalRecords).clamp(0, 1);
    final int pct = (progress * 100).round();

    final bool nearBreach = batch.isNearSlaBreach;
    final bool breached = batch.isSlaBreached;

    final Color borderColor = breached
        ? AppColors.error.withAlpha(140)
        : (nearBreach
              ? const Color(0xFFF59E0B).withAlpha(160)
              : scheme.outlineVariant.withAlpha(150));

    final Color chipBg = breached
        ? AppColors.error.withAlpha(16)
        : (nearBreach
              ? const Color(0xFFF59E0B).withAlpha(18)
              : AppColors.brandBlue.withAlpha(14));
    final Color chipFg = breached
        ? AppColors.error
        : (nearBreach ? const Color(0xFFB45309) : AppColors.brandBlue);

    return TMZCard(
      onTap: () => context.go(
        '${AppRouter.appBatchTrackingDetailPath}?batch=${Uri.encodeQueryComponent(batch.name)}&records=${batch.totalRecords}&completed=${batch.completedRecords}',
      ),
      padding: const EdgeInsets.all(AppSpacing.x4),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),
        padding: const EdgeInsets.all(AppSpacing.x4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.brandBlue.withAlpha(16),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.timelapse_rounded,
                    color: AppColors.brandBlue,
                  ),
                ),
                const SizedBox(width: AppSpacing.x3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        batch.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.body1.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${batch.createdLabel} • Verifier: ${batch.verifierAssigned}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.body2.copyWith(
                          color: scheme.onSurface.withAlpha(160),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.x2),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: chipBg,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: chipFg.withAlpha(70)),
                  ),
                  child: Text(
                    breached
                        ? 'SLA BREACHED'
                        : (nearBreach ? 'NEAR SLA' : 'IN PROGRESS'),
                    style: AppTypography.caption.copyWith(
                      color: chipFg,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.x3),
            Row(
              children: <Widget>[
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 10,
                      backgroundColor: scheme.onSurface.withAlpha(10),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        breached
                            ? AppColors.error
                            : (nearBreach
                                  ? const Color(0xFFF59E0B)
                                  : AppColors.brandBlue),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.x3),
                Text(
                  '$pct%',
                  style: AppTypography.body2.copyWith(
                    fontWeight: FontWeight.w900,
                    color: chipFg,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.x3),
            Row(
              children: <Widget>[
                Expanded(
                  child: _MetaLine(
                    icon: Icons.people_alt_outlined,
                    label: 'Records',
                    value: '${batch.completedRecords}/${batch.totalRecords}',
                  ),
                ),
                const SizedBox(width: AppSpacing.x2),
                Expanded(
                  child: _MetaLine(
                    icon: Icons.timer_outlined,
                    label: 'SLA',
                    value: batch.slaLabel,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaLine extends StatelessWidget {
  const _MetaLine({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x3),
      decoration: BoxDecoration(
        color: scheme.onSurface.withAlpha(6),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.x2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  label.toUpperCase(),
                  style: AppTypography.caption.copyWith(
                    color: scheme.onSurface.withAlpha(140),
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.body2.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OrgBatch {
  const _OrgBatch({
    required this.name,
    required this.createdAt,
    required this.verifierAssigned,
    required this.totalRecords,
    required this.completedRecords,
    required this.slaDeadline,
  });

  final String name;
  final DateTime createdAt;
  final String verifierAssigned;
  final int totalRecords;
  final int completedRecords;
  final DateTime slaDeadline;

  bool get isSlaBreached => DateTime.now().isAfter(slaDeadline);

  bool get isNearSlaBreach {
    final Duration diff = slaDeadline.difference(DateTime.now());
    return diff.inHours <= 12 && diff.inSeconds > 0;
  }

  String get createdLabel {
    final DateTime d = createdAt;
    final String dd = d.day.toString().padLeft(2, '0');
    final String mm = d.month.toString().padLeft(2, '0');
    return '$dd/$mm/${d.year}';
  }

  String get slaLabel {
    final Duration diff = slaDeadline.difference(DateTime.now());
    if (diff.isNegative) {
      final int h = diff.abs().inHours;
      return 'Overdue by ${h}h';
    }
    if (diff.inHours < 24) return 'Due in ${diff.inHours}h';
    return 'Due in ${diff.inDays}d';
  }

  static List<_OrgBatch> sampleNow() {
    final DateTime now = DateTime.now();
    return <_OrgBatch>[
      _OrgBatch(
        name: 'Driver Verification Q1',
        createdAt: now.subtract(const Duration(days: 2)),
        verifierAssigned: 'Anita',
        totalRecords: 200,
        completedRecords: 124,
        slaDeadline: now.add(const Duration(hours: 22)),
      ),
      _OrgBatch(
        name: 'Delivery Staff Batch 4',
        createdAt: now.subtract(const Duration(days: 1, hours: 6)),
        verifierAssigned: 'Rohit',
        totalRecords: 80,
        completedRecords: 24,
        slaDeadline: now.add(const Duration(hours: 9)),
      ),
      _OrgBatch(
        name: 'Security Personnel',
        createdAt: now.subtract(const Duration(days: 3)),
        verifierAssigned: 'Kiran',
        totalRecords: 50,
        completedRecords: 50,
        slaDeadline: now.subtract(const Duration(hours: 6)),
      ),
      _OrgBatch(
        name: 'Healthcare Nurses — May',
        createdAt: now.subtract(const Duration(hours: 18)),
        verifierAssigned: 'Meera',
        totalRecords: 120,
        completedRecords: 18,
        slaDeadline: now.add(const Duration(days: 2, hours: 4)),
      ),
    ];
  }
}

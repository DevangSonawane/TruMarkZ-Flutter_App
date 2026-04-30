import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

class OrgCredentialsPage extends StatelessWidget {
  const OrgCredentialsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.textPrimary,
        titleSpacing: 12,
        title: Row(
          children: <Widget>[
            SvgPicture.asset(
              'assets/icons/trumarkz_shield.svg',
              height: 18,
              colorFilter: const ColorFilter.mode(
                AppColors.brandBlue,
                BlendMode.srcIn,
              ),
            ),
            const SizedBox(width: AppSpacing.x2),
            Text(
              'TruMarkZ',
              style: AppTypography.heading2.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        actions: <Widget>[
          IconButton(
            tooltip: 'Search',
            onPressed: () {},
            icon: const Icon(Icons.search_rounded),
          ),
          IconButton(
            tooltip: 'Filter',
            onPressed: () {},
            icon: const Icon(Icons.tune_rounded),
          ),
          const SizedBox(width: AppSpacing.x2),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.x4,
          AppSpacing.x2,
          AppSpacing.x4,
          AppSpacing.x10,
        ),
        children: <Widget>[
          _OrgHeroCard(
            orgName: 'Apex Logistics Pvt. Ltd.',
            onNewBatch: () => context.push(AppRouter.verificationPlanSetupPath),
          ),
          const SizedBox(height: AppSpacing.x4),
          const _MetricGrid(),
          const SizedBox(height: AppSpacing.x6),
          Row(
            children: <Widget>[
              Text(
                'ACTIVE BATCHES',
                style: AppTypography.caption.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => context.go(AppRouter.appBatchesPath),
                child: Text(
                  'See all',
                  style: AppTypography.body2.copyWith(
                    color: AppColors.brandBlue,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.x3),
          _ActiveBatchCard(
            status: _BatchCardStatus.inProgress,
            title: 'Driver Verification Q1',
            batchId: 'A1C3',
            recordCount: 200,
            doneChecks: const <String>['Identity', 'DL check'],
            pendingChecks: const <String>['Police', 'Address'],
            verifiedCount: 60,
            totalCount: 200,
            verifierName: 'SafeCheck Pvt.',
            slaLabel: 'SLA: 3 days left',
            onTap: () => context.push(AppRouter.batchTrackingDetailPath),
          ),
          const SizedBox(height: AppSpacing.x3),
          _ActiveBatchCard(
            status: _BatchCardStatus.slaAlert,
            title: 'Warehouse Staff Feb',
            batchId: 'B9K2',
            recordCount: 85,
            doneChecks: const <String>['Identity'],
            pendingChecks: const <String>['Police', 'Address'],
            verifiedCount: 45,
            totalCount: 85,
            verifierName: 'SafeCheck Pvt.',
            slaLabel: 'SLA: 30% remaining',
            onTap: () => context.push(AppRouter.batchTrackingDetailPath),
          ),
          const SizedBox(height: AppSpacing.x3),
          _ActiveBatchCard(
            status: _BatchCardStatus.completed,
            title: 'Product Compliance — Silk',
            batchId: 'P0S7',
            recordCount: 50,
            doneChecks: const <String>['Document', 'Audit', 'Lab'],
            pendingChecks: const <String>[],
            verifiedCount: 50,
            totalCount: 50,
            verifierName: 'SafeCheck Pvt.',
            slaLabel: 'Completed',
            onTap: () => context.push(AppRouter.batchTrackingDetailPath),
          ),
        ],
      ),
    );
  }
}

class _OrgHeroCard extends StatelessWidget {
  const _OrgHeroCard({required this.orgName, required this.onNewBatch});

  final String orgName;
  final VoidCallback onNewBatch;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withAlpha(10),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: <Widget>[
            Positioned(
              top: -24,
              right: -22,
              child: Opacity(
                opacity: 0.06,
                child: SvgPicture.asset(
                  'assets/icons/trumarkz_shield.svg',
                  width: 140,
                  height: 140,
                  colorFilter: const ColorFilter.mode(
                    AppColors.textPrimary,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.x6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const _VerifiedOrganisationPill(),
                  const SizedBox(height: AppSpacing.x5),
                  Text(
                    'WELCOME BACK',
                    style: AppTypography.caption.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.4,
                      color: AppColors.textTertiary.withAlpha(170),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.x2),
                  Text(
                    orgName,
                    style: AppTypography.display1.copyWith(
                      fontSize: 30,
                      height: 1.12,
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.x2),
                  Text(
                    'Your operations are running smoothly.',
                    style: AppTypography.body2.copyWith(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.x5),
                  _NewBatchButton(onTap: onNewBatch),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VerifiedOrganisationPill extends StatelessWidget {
  const _VerifiedOrganisationPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF10B981).withAlpha(24),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFF10B981).withAlpha(64)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Color(0xFF10B981),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'Verified Organisation',
            style: AppTypography.body2.copyWith(
              fontWeight: FontWeight.w800,
              color: const Color(0xFF10B981),
            ),
          ),
        ],
      ),
    );
  }
}

class _NewBatchButton extends StatelessWidget {
  const _NewBatchButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.brandBlue,
            borderRadius: BorderRadius.circular(18),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: AppColors.brandBlue.withAlpha(90),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(18),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withAlpha(170)),
                ),
                child: const Icon(
                  Icons.add_rounded,
                  size: 18,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'New batch',
                style: AppTypography.body1.copyWith(
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid();

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppSpacing.x3,
      crossAxisSpacing: AppSpacing.x3,
      childAspectRatio: 1.65,
      children: const <Widget>[
        _MetricTile(
          value: '12,842',
          label: 'Total credentials',
          valueColor: AppColors.textPrimary,
        ),
        _MetricTile(
          value: '99.9%',
          label: 'Compliance rate',
          valueColor: Color(0xFF10B981),
        ),
        _MetricTile(
          value: '3',
          label: 'Active batches',
          valueColor: AppColors.brandBlue,
        ),
        _MetricTile(
          value: '1.2s',
          label: 'Avg processing',
          valueColor: AppColors.textPrimary,
        ),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.value,
    required this.label,
    required this.valueColor,
  });

  final String value;
  final String label;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppSpacing.x4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            value,
            style: AppTypography.heading1.copyWith(
              fontSize: 20,
              height: 1.15,
              fontWeight: FontWeight.w800,
              color: valueColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.body2.copyWith(
              fontSize: 11,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

enum _BatchCardStatus { inProgress, slaAlert, completed }

class _ActiveBatchCard extends StatelessWidget {
  const _ActiveBatchCard({
    required this.status,
    required this.title,
    required this.batchId,
    required this.recordCount,
    required this.doneChecks,
    required this.pendingChecks,
    required this.verifiedCount,
    required this.totalCount,
    required this.verifierName,
    required this.slaLabel,
    required this.onTap,
  });

  final _BatchCardStatus status;
  final String title;
  final String batchId;
  final int recordCount;
  final List<String> doneChecks;
  final List<String> pendingChecks;
  final int verifiedCount;
  final int totalCount;
  final String verifierName;
  final String slaLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (
      Color borderColor,
      Color accent,
      _StatusPill statusPill,
    ) = switch (status) {
      _BatchCardStatus.inProgress => (
        AppColors.border.withAlpha(140),
        AppColors.brandBlue,
        const _StatusPill.inProgress(),
      ),
      _BatchCardStatus.slaAlert => (
        AppColors.danger.withAlpha(90),
        AppColors.danger,
        const _StatusPill.slaAlert(),
      ),
      _BatchCardStatus.completed => (
        AppColors.success.withAlpha(90),
        AppColors.success,
        const _StatusPill.completed(),
      ),
    };

    final double progress = totalCount == 0
        ? 0
        : (verifiedCount / totalCount).clamp(0, 1);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.x4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.clip,
                          style: AppTypography.heading1.copyWith(
                            color: AppColors.textPrimary,
                            fontSize: 18,
                            height: 1.15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.x2),
                      statusPill,
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Batch #$batchId · $recordCount records',
                    maxLines: 2,
                    overflow: TextOverflow.clip,
                    style: AppTypography.body2.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      height: 1.25,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (status == _BatchCardStatus.slaAlert) ...<Widget>[
                    const SizedBox(height: AppSpacing.x3),
                    const _SlaWarningRow(
                      label: '30% of SLA time remaining — verifier alerted',
                    ),
                  ],
                  const SizedBox(height: AppSpacing.x3),
                  _CheckChipRow(done: doneChecks, pending: pendingChecks),
                  const SizedBox(height: AppSpacing.x4),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 6,
                            backgroundColor: AppColors.offWhite,
                            valueColor: AlwaysStoppedAnimation<Color>(accent),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.x3),
                      Text(
                        '$verifiedCount/$totalCount',
                        style: AppTypography.body2.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.x3),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          'Verifier: $verifierName',
                          style: AppTypography.body2.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        slaLabel,
                        style: AppTypography.body2.copyWith(
                          color: status == _BatchCardStatus.slaAlert
                              ? AppColors.danger
                              : AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CheckChipRow extends StatelessWidget {
  const _CheckChipRow({required this.done, required this.pending});

  final List<String> done;
  final List<String> pending;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.hardEdge,
      child: Row(
        children: <Widget>[
          for (int i = 0; i < done.length; i++) ...<Widget>[
            const _DotChip(dotColor: Color(0xFF10B981)).withLabel(done[i]),
            if (i != done.length - 1 || pending.isNotEmpty)
              const SizedBox(width: 8),
          ],
          for (int i = 0; i < pending.length; i++) ...<Widget>[
            const _DotChip(dotColor: Color(0xFFF59E0B)).withLabel(pending[i]),
            if (i != pending.length - 1) const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _DotChip extends StatelessWidget {
  const _DotChip({required this.dotColor, this.label});

  final Color dotColor;
  final String? label;

  _DotChip withLabel(String text) => _DotChip(dotColor: dotColor, label: text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: dotColor.withAlpha(22),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: dotColor.withAlpha(55)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            label ?? '',
            style: AppTypography.body2.copyWith(
              color: dotColor,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.label,
    required this.background,
    required this.foreground,
  });

  const _StatusPill.inProgress()
    : this(
        label: 'In progress',
        background: const Color(0xFF1E3A8A),
        foreground: const Color(0xFF3B82F6),
      );

  const _StatusPill.slaAlert()
    : this(
        label: 'SLA alert',
        background: const Color(0xFF7F1D1D),
        foreground: const Color(0xFFFCA5A5),
      );

  const _StatusPill.completed()
    : this(
        label: 'Completed',
        background: const Color(0xFF064E3B),
        foreground: const Color(0xFF34D399),
      );

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: background.withAlpha(26),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: foreground.withAlpha(64)),
      ),
      child: Text(
        label,
        style: AppTypography.body2.copyWith(
          fontSize: 13,
          color: foreground,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _SlaWarningRow extends StatelessWidget {
  const _SlaWarningRow({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.x3,
        vertical: AppSpacing.x2,
      ),
      decoration: BoxDecoration(
        color: AppColors.danger.withAlpha(14),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.danger.withAlpha(70)),
      ),
      child: Row(
        children: <Widget>[
          const Icon(
            Icons.warning_amber_rounded,
            size: 16,
            color: AppColors.danger,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: AppTypography.caption.copyWith(
                fontSize: 11,
                color: AppColors.danger,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

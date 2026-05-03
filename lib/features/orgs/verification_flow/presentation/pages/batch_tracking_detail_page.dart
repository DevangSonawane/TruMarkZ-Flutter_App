import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/router/app_router.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';

class BatchTrackingDetailPage extends StatelessWidget {
  const BatchTrackingDetailPage({super.key});

  static int _tryParseInt(String? value, {required int fallback}) =>
      int.tryParse(value ?? '') ?? fallback;

  static double _tryParseDouble(String? value, {required double fallback}) =>
      double.tryParse(value ?? '') ?? fallback;

  @override
  Widget build(BuildContext context) {
    final Map<String, String> qp = GoRouterState.of(
      context,
    ).uri.queryParameters;

    final String batchName = (qp['batch'] ?? 'Driver Onboarding Q1').trim();
    final String industry = (qp['industry'] ?? 'Transport Industry').trim();
    final int records = _tryParseInt(qp['records'], fallback: 200);
    final String createdLabel = (qp['created'] ?? '02 Apr').trim();
    final String slaLabel = (qp['sla'] ?? '5 days').trim();
    final double progress = _tryParseDouble(
      qp['progress'],
      fallback: 0.85,
    ).clamp(0, 1);
    final int riskCount = _tryParseInt(qp['risk'], fallback: 24);

    return Scaffold(
      backgroundColor: AppColors.pageBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        toolbarHeight: 64,
        leading: IconButton(
          onPressed: () {
            final GoRouter router = GoRouter.of(context);
            if (router.canPop()) {
              context.pop();
            } else {
              context.go(AppRouter.appBatchesPath);
            }
          },
          icon: const Icon(Icons.arrow_back_rounded),
          color: AppColors.brandBlue,
        ),
        title: Text(
          batchName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.heading1.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: <Widget>[],
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.90),
                border: const Border(
                  bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1),
                ),
                boxShadow: const <BoxShadow>[
                  BoxShadow(
                    color: Color(0x0D2563EB),
                    blurRadius: 10,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          20,
          24,
          20,
          140 + MediaQuery.viewPaddingOf(context).bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _QuickStatsGrid(
              records: records,
              createdLabel: createdLabel,
              slaLabel: slaLabel,
            ),
            const SizedBox(height: 24),
            _OverallProgressCard(progress: progress),
            const SizedBox(height: 24),
            _ComplianceChecksSection(
              batchName: batchName,
              industry: industry,
              progress: progress,
            ),
            const SizedBox(height: 24),
            _SlaAlertCard(riskCount: riskCount),
          ],
        ),
      ),
    );
  }
}

class _CardShadow extends BoxShadow {
  const _CardShadow()
    : super(
        color: const Color(0x142563EB),
        blurRadius: 12,
        offset: const Offset(0, 2),
      );
}

class _QuickStatsGrid extends StatelessWidget {
  const _QuickStatsGrid({
    required this.records,
    required this.createdLabel,
    required this.slaLabel,
  });

  final int records;
  final String createdLabel;
  final String slaLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: _StatCard(label: 'Records', value: '$records'),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(label: 'Created', value: createdLabel),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(label: 'SLA', value: slaLabel),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const <BoxShadow>[_CardShadow()],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: AppColors.textTertiary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppTypography.heading2.copyWith(
              color: AppColors.brandBlue,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _OverallProgressCard extends StatelessWidget {
  const _OverallProgressCard({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final int pct = (progress * 100).round();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const <BoxShadow>[_CardShadow()],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Overall Progress',
                      style: AppTypography.heading2.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Verification phase in progress',
                      style: AppTypography.body2.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '$pct%',
                style: AppTypography.display2.copyWith(
                  fontSize: 28,
                  color: AppColors.brandBlue,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _GradientProgressBar(value: progress),
        ],
      ),
    );
  }
}

class _GradientProgressBar extends StatelessWidget {
  const _GradientProgressBar({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: Container(
        height: 12,
        color: AppColors.blueTint,
        child: Align(
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: value.clamp(0, 1),
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: <Color>[AppColors.brandBlue, Color(0xFF1D4ED8)],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ComplianceChecksSection extends StatelessWidget {
  const _ComplianceChecksSection({
    required this.batchName,
    required this.industry,
    required this.progress,
  });

  final String batchName;
  final String industry;
  final double progress;

  @override
  Widget build(BuildContext context) {
    // Keep these sample-y for now; later wire to real batch state.
    final List<_ComplianceCheck> checks = <_ComplianceCheck>[
      const _ComplianceCheck(
        title: 'Identity Check',
        subtitle: 'Biometric verified',
        icon: Icons.fingerprint_rounded,
        iconFg: AppColors.brandBlue,
        iconBg: Color(0xFFEFF6FF),
        status: _ComplianceStatus.verified,
      ),
      const _ComplianceCheck(
        title: 'Criminal Record',
        subtitle: 'Database searching...',
        icon: Icons.gavel_rounded,
        iconFg: AppColors.warning,
        iconBg: Color(0xFFFFF7ED),
        status: _ComplianceStatus.processing,
      ),
      const _ComplianceCheck(
        title: 'Past Employment',
        subtitle: 'Waiting for employer',
        icon: Icons.work_rounded,
        iconFg: AppColors.textTertiary,
        iconBg: Color(0xFFF8FAFC),
        status: _ComplianceStatus.pending,
      ),
      const _ComplianceCheck(
        title: 'Address Verification',
        subtitle: 'Mismatch detected',
        icon: Icons.home_work_rounded,
        iconFg: AppColors.error,
        iconBg: Color(0xFFFEF2F2),
        status: _ComplianceStatus.alert,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                'Compliance Checks',
                style: AppTypography.heading2.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Text(
              'View All'.toUpperCase(),
              style: AppTypography.caption.copyWith(
                color: AppColors.brandBlue,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        for (final _ComplianceCheck check in checks) ...<Widget>[
          _ComplianceCheckCard(check: check),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

enum _ComplianceStatus { verified, processing, pending, alert }

class _ComplianceCheck {
  const _ComplianceCheck({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconFg,
    required this.iconBg,
    required this.status,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconFg;
  final Color iconBg;
  final _ComplianceStatus status;
}

class _ComplianceCheckCard extends StatelessWidget {
  const _ComplianceCheckCard({required this.check});

  final _ComplianceCheck check;

  @override
  Widget build(BuildContext context) {
    final Widget statusPill = switch (check.status) {
      _ComplianceStatus.verified => _Pill(
        bg: AppColors.blueTint,
        fg: AppColors.brandBlue,
        icon: Icons.verified_rounded,
        label: 'Verified',
        filledIcon: true,
      ),
      _ComplianceStatus.processing => _Pill(
        bg: const Color(0xFFFFDBCD),
        fg: AppColors.warning,
        label: 'Processing',
      ),
      _ComplianceStatus.pending => _Pill(
        bg: const Color(0xFFE1E2ED),
        fg: AppColors.textTertiary,
        label: 'Pending',
      ),
      _ComplianceStatus.alert => _Pill(
        bg: const Color(0xFFFFDAD6),
        fg: AppColors.error,
        icon: Icons.warning_amber_rounded,
        label: 'Alert',
      ),
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const <BoxShadow>[_CardShadow()],
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: check.iconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(check.icon, color: check.iconFg, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  check.title,
                  style: AppTypography.body2.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  check.subtitle,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textTertiary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          statusPill,
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.bg,
    required this.fg,
    required this.label,
    this.icon,
    this.filledIcon = false,
  });

  final Color bg;
  final Color fg;
  final String label;
  final IconData? icon;
  final bool filledIcon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, size: 14, color: fg, fill: filledIcon ? 1 : 0),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: fg,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _SlaAlertCard extends StatelessWidget {
  const _SlaAlertCard({required this.riskCount});

  final int riskCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xCCFEF2F2),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFFDAD6)),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.history_toggle_off_rounded,
                    color: AppColors.error,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        '$riskCount records at risk',
                        style: AppTypography.body2.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Approaching SLA threshold',
                        style: AppTypography.body2.copyWith(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 44),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'Resolve',
              style: AppTypography.body2.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

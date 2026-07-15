import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/tmz_badge.dart';
import '../../../../core/widgets/tmz_card.dart';

class VerificationReportsPage extends StatefulWidget {
  const VerificationReportsPage({super.key});

  @override
  State<VerificationReportsPage> createState() =>
      _VerificationReportsPageState();
}

class _VerificationReportsPageState extends State<VerificationReportsPage> {
  final List<_ReportRow> _reports = <_ReportRow>[
    const _ReportRow(
      id: 'r_identity_1',
      category: 'Identity Verification',
      title: 'Identity Verification',
      date: '05 Apr 2024',
      status: 'Verified',
    ),
    const _ReportRow(
      id: 'r_address_1',
      category: 'Address Verification',
      title: 'Address Verification',
      date: '05 Apr 2024',
      status: 'Verified',
    ),
    const _ReportRow(
      id: 'r_police_1',
      category: 'Police Clearance',
      title: 'Police Clearance',
      date: '04 Apr 2024',
      status: 'Verified',
    ),
  ];

  int _tabIndex = 0;

  List<_ReportRow> get _filtered {
    final String filter = switch (_tabIndex) {
      1 => 'Address Verification',
      2 => 'Identity Verification',
      _ => 'All',
    };
    if (filter == 'All') return _reports;
    return _reports.where((r) => r.category == filter).toList();
  }

  @override
  Widget build(BuildContext context) {
    final List<_ReportRow> visible = _filtered;
    final double safeBottom = MediaQuery.viewPaddingOf(context).bottom;
    final double screenWidth = MediaQuery.sizeOf(context).width;
    const double refWidth = 402;
    final double contentWidth = screenWidth < refWidth ? screenWidth : refWidth;
    final double scale = contentWidth / refWidth;
    double s(double value) => value * scale;

    return Scaffold(
      backgroundColor: AppColors.brandBlue,
      body: SafeArea(
        bottom: false,
        child: Center(
          child: SizedBox(
            width: contentWidth,
            child: Column(
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.fromLTRB(s(16), s(12), s(16), s(12)),
                  child: Row(
                    children: <Widget>[
                      IconButton(
                        tooltip: 'Back',
                        onPressed: () => context.go(AppRouter.dashboardPath),
                        icon: const Icon(Icons.arrow_back_rounded),
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Reports',
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
                SizedBox(height: s(0)),
                Expanded(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F9FC),
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(s(20)),
                      ),
                    ),
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(
                        s(16),
                        s(32),
                        s(16),
                        s(28) + safeBottom + s(110),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Verification Reports',
                            style: AppTypography.display2.copyWith(
                              color: AppColors.textPrimary,
                            ),
                          ),
                          SizedBox(height: s(8)),
                          Text(
                            'View and review verification reports for your organisation.',
                            style: AppTypography.body2.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          SizedBox(height: s(24)),
                          _filters(),
                          SizedBox(height: s(24)),
                          if (visible.isEmpty)
                            TMZCard(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: AppSpacing.x2,
                                ),
                                child: Center(
                                  child: Text(
                                    'No reports found.',
                                    style: AppTypography.body2.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              ),
                            )
                          else
                            for (
                              int i = 0;
                              i < visible.length;
                              i++
                            ) ...<Widget>[
                              _ReportCard(
                                report: visible[i],
                                onTap: () => context.push(
                                  '${AppRouter.appReportDetailPath}?id=${Uri.encodeQueryComponent(visible[i].id)}',
                                ),
                              ),
                              if (i != visible.length - 1)
                                SizedBox(height: s(11)),
                            ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _filters() {
    final List<String> tabs = <String>[
      'All',
      'Address Verification',
      'Identity Verification',
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Row(
          children: <Widget>[
            for (int i = 0; i < tabs.length; i++) ...<Widget>[
              _FilterChip(
                label: tabs[i],
                selected: _tabIndex == i,
                onTap: () => setState(() => _tabIndex = i),
              ),
              const SizedBox(width: AppSpacing.x2),
            ],
          ],
        ),
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({required this.report, required this.onTap});

  final _ReportRow report;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TMZCard(
      onTap: onTap,
      child: Row(
        children: <Widget>[
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.blueTint,
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.description_rounded,
              color: AppColors.brandBlue,
              size: 22,
            ),
          ),
          const SizedBox(width: AppSpacing.x3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  report.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.body1.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  report.category,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  report.date,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.x2),
          _statusBadge(report.status),
        ],
      ),
    );
  }

  Widget _statusBadge(String status) {
    final String normalized = status.trim().toLowerCase();
    if (normalized.contains('fail') || normalized.contains('reject')) {
      return TMZBadge.failed(label: status);
    }
    if (normalized.contains('pend')) {
      return TMZBadge.pending(label: status);
    }
    return TMZBadge.verified(label: status);
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.x4,
          vertical: AppSpacing.x2,
        ),
        decoration: BoxDecoration(
          color: selected ? AppColors.brandBlue : AppColors.cardSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.brandBlue : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.body2.copyWith(
            fontSize: 13,
            color: selected ? Colors.white : AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _ReportRow {
  const _ReportRow({
    required this.id,
    required this.category,
    required this.title,
    required this.date,
    required this.status,
  });

  final String id;
  final String category;
  final String title;
  final String date;
  final String status;
}

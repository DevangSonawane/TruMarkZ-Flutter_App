import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/animations/screen_entry_mixin.dart';
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

class _VerificationReportsPageState extends State<VerificationReportsPage>
    with ScreenEntryMixin {
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
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final List<_ReportRow> visible = _filtered;

    return Scaffold(
      backgroundColor: AppColors.pageBg,
      appBar: AppBar(
        title: Row(
          children: <Widget>[
            SvgPicture.asset(
              'assets/icons/trumarkz_shield.svg',
              height: 22,
              colorFilter: ColorFilter.mode(scheme.primary, BlendMode.srcIn),
            ),
            const SizedBox(width: AppSpacing.x2),
            const Text('Verification Reports'),
          ],
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.x6,
            AppSpacing.x6,
            AppSpacing.x6,
            AppSpacing.x8,
          ),
          children: <Widget>[
            entry(
              Text(
                'Verification Reports',
                style: AppTypography.display2.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.x2),
            entry(
              Text(
                'View and download verification reports',
                style: AppTypography.body2.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              delayMs: 40,
            ),
            const SizedBox(height: AppSpacing.x4),
            entry(_filters(), delayMs: 60),
            const SizedBox(height: AppSpacing.x4),
            ...staggerChildren(
              <Widget>[
                for (final _ReportRow report in visible)
                  _ReportCard(
                    report: report,
                    onTap: () => context.push(
                      '${AppRouter.appReportDetailPath}?id=${Uri.encodeQueryComponent(report.id)}',
                    ),
                  ),
              ],
              startDelayMs: 60,
              stepMs: 55,
              maxDelayMs: 240,
            ),
            if (visible.isEmpty)
              TMZCard(
                child: Text(
                  'No reports found.',
                  style: AppTypography.body2.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
          ],
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
    );
  }
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({required this.report, required this.onTap});

  final _ReportRow report;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.x4),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: TMZCard(
          child: Row(
            children: <Widget>[
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.brandBlue.withAlpha(14),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.description_outlined,
                  color: AppColors.brandBlue,
                  size: 18,
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
                      style: AppTypography.heading2.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      report.date,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              TMZBadge.verified(),
            ],
          ),
        ),
      ),
    );
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
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.x4,
          vertical: AppSpacing.x2,
        ),
        decoration: BoxDecoration(
          color: selected ? AppColors.brandBlue : AppColors.cardSurface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? AppColors.brandBlue : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.body2.copyWith(
            color: selected ? Colors.white : AppColors.textSecondary,
            fontWeight: FontWeight.w800,
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

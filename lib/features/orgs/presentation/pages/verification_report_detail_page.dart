import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/animations/screen_entry_mixin.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/tmz_badge.dart';
import '../../../../core/widgets/tmz_button.dart';
import '../../../../core/widgets/tmz_card.dart';

class VerificationReportDetailPage extends StatelessWidget
    with ScreenEntryMixin {
  const VerificationReportDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Map<String, String> qp = GoRouterState.of(
      context,
    ).uri.queryParameters;
    final String id = (qp['id'] ?? 'r_identity_1').trim();

    final _ReportDetail detail = _mockDetail(id);

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
            const Text('Report'),
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
              TMZCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            detail.title,
                            style: AppTypography.heading1.copyWith(
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        TMZBadge.verified(),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.x2),
                    Text(
                      detail.date,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.x3),
                    Text(
                      detail.summary,
                      style: AppTypography.body2.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.x4),
            entry(
              Text(
                'Documentation',
                style: AppTypography.heading1.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              delayMs: 40,
            ),
            const SizedBox(height: AppSpacing.x3),
            entry(
              TMZCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    for (final _DocItem d in detail.docs) ...<Widget>[
                      Row(
                        children: <Widget>[
                          const Icon(
                            Icons.insert_drive_file_outlined,
                            color: AppColors.textSecondary,
                            size: 18,
                          ),
                          const SizedBox(width: AppSpacing.x2),
                          Expanded(
                            child: Text(
                              d.label,
                              style: AppTypography.body2.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Text(
                            d.kind,
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.x2),
                    ],
                  ],
                ),
              ),
              delayMs: 60,
            ),
            const SizedBox(height: AppSpacing.x4),
            entry(
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  TMZButton(
                    label: 'Download PDF',
                    variant: TMZButtonVariant.secondary,
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Downloading ${detail.title}.pdf (mock)',
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.x3),
                  TMZButton(
                    label: 'View Evidence',
                    variant: TMZButtonVariant.ghost,
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Evidence viewer (mock)')),
                      );
                    },
                  ),
                ],
              ),
              delayMs: 80,
            ),
          ],
        ),
      ),
    );
  }
}

_ReportDetail _mockDetail(String id) {
  return switch (id) {
    'r_address_1' => _ReportDetail(
      title: 'Address Verification',
      date: '05 Apr 2024',
      summary:
          'Address verified against submitted proof and field verification notes. No discrepancies found.',
      docs: const <_DocItem>[
        _DocItem(label: 'Address Proof (Aadhaar)', kind: 'PDF'),
        _DocItem(label: 'Field Visit Notes', kind: 'TXT'),
        _DocItem(label: 'Photo Evidence', kind: 'JPG'),
      ],
    ),
    'r_police_1' => _ReportDetail(
      title: 'Police Clearance',
      date: '04 Apr 2024',
      summary:
          'Police clearance verified. Report indicates no adverse records as of the verification date.',
      docs: const <_DocItem>[
        _DocItem(label: 'Police Clearance Certificate', kind: 'PDF'),
        _DocItem(label: 'Verifier Notes', kind: 'TXT'),
      ],
    ),
    _ => _ReportDetail(
      title: 'Identity Verification',
      date: '05 Apr 2024',
      summary:
          'Identity verified using KYC checks and document validation. Match score: 98%.',
      docs: const <_DocItem>[
        _DocItem(label: 'ID Document (PAN)', kind: 'PDF'),
        _DocItem(label: 'Selfie Match Result', kind: 'PNG'),
        _DocItem(label: 'Verification Log', kind: 'TXT'),
      ],
    ),
  };
}

class _ReportDetail {
  const _ReportDetail({
    required this.title,
    required this.date,
    required this.summary,
    required this.docs,
  });

  final String title;
  final String date;
  final String summary;
  final List<_DocItem> docs;
}

class _DocItem {
  const _DocItem({required this.label, required this.kind});

  final String label;
  final String kind;
}

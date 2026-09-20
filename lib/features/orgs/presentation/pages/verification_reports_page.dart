import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/models/verification_models.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/tmz_badge.dart';
import '../../../../core/widgets/tmz_card.dart';
import '../../data/verification_repository.dart';

class VerificationReportsPage extends ConsumerStatefulWidget {
  const VerificationReportsPage({super.key});

  @override
  ConsumerState<VerificationReportsPage> createState() =>
      _VerificationReportsPageState();
}

class _VerificationReportsPageState
    extends ConsumerState<VerificationReportsPage> {
  AsyncValue<List<_ReportRow>> _reports = const AsyncLoading();
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() => _reports = const AsyncLoading());
    try {
      final VerificationRepository repo = ref.read(
        verificationRepositoryProvider,
      );
      final VerificationListResponse response = await repo.getAllVerifications(
        limit: 100,
      );
      if (!mounted) return;
      setState(() => _reports = AsyncData(_buildReportRows(response.users)));
    } catch (e, st) {
      if (!mounted) return;
      setState(() => _reports = AsyncError(e, st));
    }
  }

  List<_ReportRow> _buildReportRows(List<VerificationUser> users) {
    final List<_ReportRow> rows = <_ReportRow>[];
    for (final VerificationUser user in users) {
      for (final VerificationCheckStatus check in user.verificationChecks) {
        if (!check.hasOpenableReport) continue;
        rows.add(
          _ReportRow(
            id: '${user.id}_${check.name}_${rows.length}',
            category: check.name.trim().isEmpty ? 'Verification' : check.name,
            title: user.fullName.trim().isEmpty ? check.name : user.fullName,
            subject: check.name,
            date: _formatDateLabel(user.updatedAt, user.createdAt),
            status: _statusLabel(check.status),
            source: check.label.trim().isEmpty ? 'manual' : check.label,
            url: check.reportUrl,
          ),
        );
      }
    }
    return rows;
  }

  List<_ReportRow> _filtered(List<_ReportRow> reports) {
    final String filter = switch (_tabIndex) {
      1 => 'manual',
      2 => 'automatic',
      _ => 'All',
    };
    if (filter == 'All') return reports;
    return reports
        .where((r) => r.source.trim().toLowerCase() == filter)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
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
                      IconButton(
                        tooltip: 'Refresh',
                        onPressed: _loadReports,
                        icon: const Icon(Icons.refresh_rounded),
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
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
                            'View manual verification reports shared for your organisation.',
                            style: AppTypography.body2.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          SizedBox(height: s(24)),
                          _filters(),
                          SizedBox(height: s(24)),
                          _reports.when(
                            loading: () => const Center(
                              child: Padding(
                                padding: EdgeInsets.all(AppSpacing.x6),
                                child: CircularProgressIndicator(),
                              ),
                            ),
                            error: (Object err, _) => TMZCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    'Unable to load reports',
                                    style: AppTypography.heading2,
                                  ),
                                  const SizedBox(height: AppSpacing.x2),
                                  Text(
                                    err.toString(),
                                    style: AppTypography.body2.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.x3),
                                  TextButton.icon(
                                    onPressed: _loadReports,
                                    icon: const Icon(Icons.refresh_rounded),
                                    label: const Text('Retry'),
                                  ),
                                ],
                              ),
                            ),
                            data: (List<_ReportRow> reports) {
                              final List<_ReportRow> visible = _filtered(
                                reports,
                              );
                              if (visible.isEmpty) {
                                return TMZCard(
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
                                );
                              }
                              return Column(
                                children: <Widget>[
                                  for (
                                    int i = 0;
                                    i < visible.length;
                                    i++
                                  ) ...<Widget>[
                                    _ReportCard(
                                      report: visible[i],
                                      onTap: () => context.push(
                                        '${AppRouter.appReportDetailPath}?id=${Uri.encodeQueryComponent(visible[i].id)}&title=${Uri.encodeQueryComponent(visible[i].title)}&category=${Uri.encodeQueryComponent(visible[i].category)}&status=${Uri.encodeQueryComponent(visible[i].status)}&url=${Uri.encodeQueryComponent(visible[i].url)}',
                                      ),
                                    ),
                                    if (i != visible.length - 1)
                                      SizedBox(height: s(11)),
                                  ],
                                ],
                              );
                            },
                          ),
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
    const List<String> tabs = <String>['All', 'Manual', 'Automatic'];

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

  static String _formatDateLabel(String updatedAt, String createdAt) {
    final String raw = updatedAt.trim().isNotEmpty
        ? updatedAt.trim()
        : createdAt.trim();
    if (raw.isEmpty) return 'Report available';
    final DateTime? parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
    final DateTime local = parsed.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year}';
  }

  static String _statusLabel(String raw) {
    final String status = raw.trim().toLowerCase();
    if (status.contains('reject')) return 'Rejected';
    if (status.contains('fail')) return 'Failed';
    if (status.contains('pend')) return 'Pending';
    if (status.contains('approve') || status.contains('verified')) {
      return 'Verified';
    }
    return status.isEmpty ? 'Pending' : raw;
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
                  report.subject.trim().isEmpty
                      ? report.category
                      : report.subject,
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
    required this.subject,
    required this.date,
    required this.status,
    required this.source,
    required this.url,
  });

  final String id;
  final String category;
  final String title;
  final String subject;
  final String date;
  final String status;
  final String source;
  final String url;
}

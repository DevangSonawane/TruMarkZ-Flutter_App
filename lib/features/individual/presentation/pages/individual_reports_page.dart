import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';

class IndividualReportsPage extends StatefulWidget {
  const IndividualReportsPage({super.key});

  @override
  State<IndividualReportsPage> createState() => _IndividualReportsPageState();
}

class _IndividualReportsPageState extends State<IndividualReportsPage> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _labelTimer;
  _ReportFilter _selectedFilter = _ReportFilter.all;
  DateTime? _lastRefreshedAt;

  static const List<_ReportMock> _reports = <_ReportMock>[
    _ReportMock(
      title: 'Identity Verification Summary',
      subtitle: 'KYC, address, and document checks',
      status: 'Complete',
      statusColor: AppColors.success,
      date: 'Today • 09:42 AM',
      score: '98%',
      detail:
          'All core identity checks were completed successfully with no follow-up needed.',
      filter: _ReportFilter.complete,
    ),
    _ReportMock(
      title: 'Skill Tree Review',
      subtitle: 'Technical, soft skills, and project evidence',
      status: 'In review',
      statusColor: AppColors.warning,
      date: 'Yesterday • 04:18 PM',
      score: '81%',
      detail:
          'A fresh skill profile draft is being compiled from the latest user uploads.',
      filter: _ReportFilter.review,
    ),
    _ReportMock(
      title: 'SDC Certificate Audit',
      subtitle: 'Certificate data and validity snapshot',
      status: 'Complete',
      statusColor: AppColors.success,
      date: '18 May 2026',
      score: '100%',
      detail:
          'The mock SDC certificate is aligned with the current profile details.',
      filter: _ReportFilter.complete,
    ),
    _ReportMock(
      title: 'Support Escalation Log',
      subtitle: 'Notes, exceptions, and manual follow-up items',
      status: 'Pending',
      statusColor: AppColors.textTertiary,
      date: '16 May 2026',
      score: '3 items',
      detail:
          'A few follow-up notes are waiting to be reviewed by the operations team.',
      filter: _ReportFilter.pending,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      if (!mounted) return;
      setState(() {});
    });
    _labelTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted) return;
      setState(() {});
    });
  }

  @override
  void dispose() {
    _labelTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _refreshReports() {
    setState(() {
      _lastRefreshedAt = DateTime.now();
    });
  }

  String _updatedLabel() {
    final DateTime? refreshedAt = _lastRefreshedAt;
    if (refreshedAt == null) return 'Updated today';

    final Duration elapsed = DateTime.now().difference(refreshedAt);
    if (elapsed.inSeconds < 10) return 'Updated just now';
    if (elapsed.inSeconds < 60) {
      final int seconds = elapsed.inSeconds;
      return 'Updated $seconds sec${seconds == 1 ? '' : 's'} ago';
    }
    if (elapsed.inMinutes < 2) return 'Updated 1 min ago';
    if (elapsed.inMinutes < 60) {
      final int minutes = elapsed.inMinutes;
      return 'Updated $minutes min${minutes == 1 ? '' : 's'} ago';
    }
    if (elapsed.inHours < 24) return 'Updated today';
    return 'Updated yesterday';
  }

  @override
  Widget build(BuildContext context) {
    final double safeBottom = MediaQuery.viewPaddingOf(context).bottom;
    final String search = _searchController.text.trim().toLowerCase();
    final List<_ReportMock> visibleReports = _reports.where((
      _ReportMock report,
    ) {
      if (_selectedFilter != _ReportFilter.all &&
          report.filter != _selectedFilter) {
        return false;
      }
      if (search.isEmpty) return true;
      return report.title.toLowerCase().contains(search) ||
          report.subtitle.toLowerCase().contains(search) ||
          report.detail.toLowerCase().contains(search) ||
          report.status.toLowerCase().contains(search);
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.brandBlue,
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final double contentWidth = constraints.maxWidth < 402
                ? constraints.maxWidth
                : 402;
            final double scale = contentWidth / 402;
            double s(double v) => v * scale;

            return Center(
              child: SizedBox(
                width: contentWidth,
                height: constraints.maxHeight,
                child: Column(
                  children: <Widget>[
                    Padding(
                      padding: EdgeInsets.fromLTRB(s(16), s(8), s(16), 0),
                      child: Row(
                        children: <Widget>[
                          InkResponse(
                            onTap: () =>
                                context.go(AppRouter.individualIdentityPath),
                            radius: s(22),
                            child: const Padding(
                              padding: EdgeInsets.all(6),
                              child: Icon(
                                Icons.arrow_back_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                          ),
                          SizedBox(width: s(12)),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Text(
                                  'Reports',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: s(21),
                                    fontWeight: FontWeight.w600,
                                    height: 19.5 / 21,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(height: s(2)),
                                Text(
                                  'View your verification reports and summaries',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: s(12),
                                    fontWeight: FontWeight.w500,
                                    height: 17 / 12,
                                    color: Colors.white.withValues(alpha: 0.82),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: s(18)),
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
                            s(24),
                            s(16),
                            s(20 + safeBottom + 120),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              _SearchField(controller: _searchController),
                              SizedBox(height: s(14)),
                              SizedBox(
                                width: double.infinity,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    _FilterChip(
                                      scale: scale,
                                      width: 44.73396301269531,
                                      label: 'All',
                                      selected:
                                          _selectedFilter == _ReportFilter.all,
                                      onTap: () {
                                        setState(() {
                                          _selectedFilter = _ReportFilter.all;
                                        });
                                      },
                                    ),
                                    SizedBox(width: s(5.61)),
                                    _FilterChip(
                                      scale: scale,
                                      width: 86,
                                      label: 'Complete',
                                      selected:
                                          _selectedFilter ==
                                          _ReportFilter.complete,
                                      onTap: () {
                                        setState(() {
                                          _selectedFilter =
                                              _ReportFilter.complete;
                                        });
                                      },
                                    ),
                                    SizedBox(width: s(6.92)),
                                    _FilterChip(
                                      scale: scale,
                                      width: 85,
                                      label: 'In review',
                                      selected:
                                          _selectedFilter ==
                                          _ReportFilter.review,
                                      onTap: () {
                                        setState(() {
                                          _selectedFilter =
                                              _ReportFilter.review;
                                        });
                                      },
                                    ),
                                    SizedBox(width: s(7.69)),
                                    _FilterChip(
                                      scale: scale,
                                      width: 62.73396301269531,
                                      label: 'Pending',
                                      selected:
                                          _selectedFilter ==
                                          _ReportFilter.pending,
                                      onTap: () {
                                        setState(() {
                                          _selectedFilter =
                                              _ReportFilter.pending;
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: s(16)),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: <Widget>[
                                  Text(
                                    _updatedLabel(),
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: s(12),
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.brandBlue,
                                    ),
                                  ),
                                  SizedBox(width: s(8)),
                                  InkResponse(
                                    onTap: _refreshReports,
                                    radius: s(12),
                                    child: Container(
                                      width: s(20),
                                      height: s(20),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(s(6)),
                                        border: Border.all(
                                          color: AppColors.border
                                              .withValues(alpha: 0.75),
                                        ),
                                      ),
                                      alignment: Alignment.center,
                                      child: Icon(
                                        Icons.refresh_rounded,
                                        size: s(12),
                                        color: AppColors.brandBlue,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: s(12)),
                              if (visibleReports.isEmpty)
                                Padding(
                                  padding: EdgeInsets.only(top: s(20)),
                                  child: Center(
                                    child: Text(
                                      'No reports found',
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: s(14),
                                        height: 20 / 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textTertiary,
                                      ),
                                    ),
                                  ),
                                )
                              else
                                for (int i = 0; i < visibleReports.length; i++)
                                  ...<Widget>[
                                    _ReportCard(
                                      scale: scale,
                                      report: visibleReports[i],
                                    ),
                                    if (i != visibleReports.length - 1)
                                      SizedBox(height: s(12)),
                                  ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              offset: const Offset(0, 1),
              blurRadius: 2,
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(16, 14.5, 16, 14.5),
        child: Row(
          children: <Widget>[
            SvgPicture.asset(
              'assets/icons/figma/all_batches_search.svg',
              width: 16,
              height: 16,
              colorFilter: const ColorFilter.mode(
                Color(0xFF9CA3AF),
                BlendMode.srcIn,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: controller,
                maxLines: 1,
                cursorColor: AppColors.brandBlue,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  height: 16.943182 / 14,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF0B0F19),
                ),
                decoration: InputDecoration(
                  isCollapsed: true,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  focusedErrorBorder: InputBorder.none,
                  hintText: 'Search reports',
                  hintStyle: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    height: 16.943182 / 14,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF9CA3AF),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.scale,
    required this.width,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final double scale;
  final double width;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    double s(double v) => v * scale;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(s(12)),
      child: Container(
        width: s(width),
        height: s(29.830284118652344),
        decoration: BoxDecoration(
          color: selected ? AppColors.brandBlue : Colors.white,
          borderRadius: BorderRadius.circular(s(12)),
          border: Border.all(
            color: selected ? AppColors.brandBlue : const Color(0xFFE5E7EB),
            width: s(selected ? 1.7988859415054321 : 0.7683491706848145),
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: s(10.756889343261719),
            height: 15.366982460021973 / 10.756889343261719,
            fontWeight: FontWeight.w600,
            letterSpacing: label == 'All'
                ? 0.21009549498558044
                : label == 'Complete'
                ? 0.04
                : label == 'In review'
                ? 0.04201909899711609
                : 0.05252387374639511,
            color: selected ? Colors.white : const Color(0xFF4B5563),
          ),
        ),
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({required this.scale, required this.report});

  final double scale;
  final _ReportMock report;

  @override
  Widget build(BuildContext context) {
    double s(double v) => v * scale;

    return Container(
      padding: EdgeInsets.all(s(16)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(s(18)),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: s(12),
            offset: Offset(0, s(4)),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: s(52),
                height: s(52),
                decoration: BoxDecoration(
                  color: AppColors.blueTint,
                  borderRadius: BorderRadius.circular(s(16)),
                ),
                child: Icon(
                  Icons.description_rounded,
                  color: AppColors.brandBlue,
                  size: s(26),
                ),
              ),
              SizedBox(width: s(12)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      report.title,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: s(15),
                        fontWeight: FontWeight.w800,
                        height: 22 / 15,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: s(4)),
                    Text(
                      report.subtitle,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: s(12),
                        fontWeight: FontWeight.w400,
                        height: 18 / 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: s(8)),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: s(10),
                  vertical: s(7),
                ),
                decoration: BoxDecoration(
                  color: report.statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(s(12)),
                ),
                child: Text(
                  report.status,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: s(10),
                    fontWeight: FontWeight.w800,
                    letterSpacing: s(0.25),
                    color: report.statusColor,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: s(14)),
          Row(
            children: <Widget>[
              Expanded(
                child: _StatChip(
                  scale: scale,
                  label: 'Date',
                  value: report.date,
                  icon: Icons.event_rounded,
                ),
              ),
              SizedBox(width: s(10)),
              Expanded(
                child: _StatChip(
                  scale: scale,
                  label: 'Score',
                  value: report.score,
                  icon: Icons.insights_rounded,
                ),
              ),
            ],
          ),
          SizedBox(height: s(12)),
          Text(
            report.detail,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: s(12),
              height: 18 / 12,
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.scale,
    required this.label,
    required this.value,
    required this.icon,
  });

  final double scale;
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    double s(double v) => v * scale;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: s(10),
        vertical: s(9),
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(s(14)),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: <Widget>[
          Icon(icon, size: s(14), color: AppColors.textTertiary),
          SizedBox(width: s(8)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: s(10),
                    fontWeight: FontWeight.w600,
                    color: AppColors.textTertiary,
                  ),
                ),
                SizedBox(height: s(2)),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: s(11),
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
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

enum _ReportFilter { all, complete, review, pending }

class _ReportMock {
  const _ReportMock({
    required this.title,
    required this.subtitle,
    required this.status,
    required this.statusColor,
    required this.date,
    required this.score,
    required this.detail,
    required this.filter,
  });

  final String title;
  final String subtitle;
  final String status;
  final Color statusColor;
  final String date;
  final String score;
  final String detail;
  final _ReportFilter filter;
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/router/app_router.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/widgets/tmz_button.dart';
import '../../../../../core/widgets/tmz_card.dart';

class BatchCreatedSuccessPage extends StatelessWidget {
  const BatchCreatedSuccessPage({super.key});

  static int _tryParseInt(String? value, {required int fallback}) {
    if (value == null) return fallback;
    final int? parsed = int.tryParse(value);
    return parsed ?? fallback;
  }

  static Set<String> _parseCsvSet(String? raw) {
    if (raw == null) return <String>{};
    return raw
        .split(',')
        .map((String s) => s.trim())
        .where((String s) => s.isNotEmpty)
        .toSet();
  }

  static String _formatStartedOn(DateTime dt) {
    const List<String> months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final int hour12 = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
    final String mm = dt.minute.toString().padLeft(2, '0');
    final String ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}, $hour12:$mm $ampm';
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, String> qp = GoRouterState.of(context).uri.queryParameters;

    final String batchName =
        (qp['batch']?.trim().isNotEmpty ?? false) ? qp['batch']!.trim() : 'New Batch';
    final int records = _tryParseInt(qp['records'], fallback: 80);
    final Set<String> checks = _parseCsvSet(qp['checks']);
    final int selectedChecks = checks.isEmpty ? 6 : checks.length;
    final int tasksCreated = records * selectedChecks;

    final DateTime startedOn = DateTime.tryParse(qp['startedOn'] ?? '')?.toLocal() ??
        DateTime.now();

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.textPrimary,
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.x4,
                  36,
                  AppSpacing.x4,
                  AppSpacing.x4,
                ),
                children: <Widget>[
                  Center(
                    child: Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFEEF3FF), width: 4),
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: const Color(0xFF2563EB).withAlpha(16),
                            blurRadius: 24,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.check_circle_rounded,
                        size: 54,
                        color: AppColors.brandBlue,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.x6),
                  Text(
                    'Batch Created Successfully!',
                    textAlign: TextAlign.center,
                    style: AppTypography.display2.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.x2),
                  Text(
                    'System is now creating one verification task per check per record.',
                    textAlign: TextAlign.center,
                    style: AppTypography.body2.copyWith(
                      color: const Color(0xFF434655),
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.x6),
                  TMZCard(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.x4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: Text(
                                  'Batch Details',
                                  style: AppTypography.heading2.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.folder_rounded,
                                color: AppColors.brandBlue,
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.x4),
                          Text(
                            'Batch Name',
                            style: AppTypography.caption.copyWith(
                              color: const Color(0xFF737686),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            batchName,
                            style: AppTypography.body1.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.x4),
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: _KeyValue(
                                  k: 'Total Records',
                                  v: records.toString(),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.x4),
                              Expanded(
                                child: _KeyValue(
                                  k: 'Selected Checks',
                                  v: selectedChecks.toString(),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.x4),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3F3FE),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  'Total Tasks Created',
                                  style: AppTypography.caption.copyWith(
                                    color: const Color(0xFF394C84),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                RichText(
                                  text: TextSpan(
                                    style: AppTypography.body1.copyWith(
                                      color: AppColors.brandBlue,
                                      fontWeight: FontWeight.w900,
                                    ),
                                    children: <InlineSpan>[
                                      TextSpan(text: tasksCreated.toString()),
                                      TextSpan(
                                        text:
                                            '  (${records.toString()} Records x ${selectedChecks.toString()} Checks)',
                                        style: AppTypography.caption.copyWith(
                                          color: const Color(0xFF737686),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.x4),
                          Container(
                            padding: const EdgeInsets.only(top: AppSpacing.x4),
                            decoration: BoxDecoration(
                              border: Border(
                                top: BorderSide(
                                  color: const Color(0xFFC3C6D7).withAlpha(140),
                                ),
                              ),
                            ),
                            child: Column(
                              children: <Widget>[
                                Row(
                                  children: <Widget>[
                                    Expanded(
                                      child: Text(
                                        'Status',
                                        style: AppTypography.body2.copyWith(
                                          color: const Color(0xFF434655),
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEEF3FF),
                                        borderRadius: BorderRadius.circular(999),
                                      ),
                                      child: Text(
                                        'Processing Started',
                                        style: AppTypography.caption.copyWith(
                                          color: AppColors.brandBlue,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.x3),
                                Row(
                                  children: <Widget>[
                                    Expanded(
                                      child: Text(
                                        'Started On',
                                        style: AppTypography.body2.copyWith(
                                          color: const Color(0xFF434655),
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      _formatStartedOn(startedOn),
                                      style: AppTypography.caption.copyWith(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.x4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEEF3FF),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Row(
                              children: <Widget>[
                                const Icon(
                                  Icons.info_rounded,
                                  size: 18,
                                  color: AppColors.brandBlue,
                                ),
                                const SizedBox(width: AppSpacing.x2),
                                Expanded(
                                  child: Text(
                                    'You can track real-time status of each record and each check.',
                                    style: AppTypography.caption.copyWith(
                                      color: AppColors.brandBlue,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
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
                child: TMZButton(
                  label: 'Go to Batch Dashboard',
                  icon: Icons.arrow_forward_rounded,
                  onPressed: () {
                    context.go(AppRouter.dashboardPath);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KeyValue extends StatelessWidget {
  const _KeyValue({required this.k, required this.v});

  final String k;
  final String v;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          k,
          style: AppTypography.caption.copyWith(
            color: const Color(0xFF737686),
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          v,
          style: AppTypography.body1.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

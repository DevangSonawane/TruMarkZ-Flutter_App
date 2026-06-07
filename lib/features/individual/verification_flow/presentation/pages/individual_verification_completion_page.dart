import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/router/app_router.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../orgs/verification_flow/presentation/pages/human_verification_checks_catalog.dart';
import 'individual_industry_label_utils.dart';

class IndividualVerificationCompletionPage extends StatefulWidget {
  const IndividualVerificationCompletionPage({super.key});

  @override
  State<IndividualVerificationCompletionPage> createState() =>
      _IndividualVerificationCompletionPageState();
}

class _IndividualVerificationCompletionPageState
    extends State<IndividualVerificationCompletionPage>
    with SingleTickerProviderStateMixin {
  static const double _referenceWidth = 402;
  static const Color _panelBg = Color(0xFFF7F9FC);

  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Map<String, String> _queryParams(BuildContext context) {
    return GoRouterState.of(context).uri.queryParameters;
  }

  List<String> _selectedCheckIds(BuildContext context) {
    final String raw = (_queryParams(context)['checks'] ?? '').trim();
    if (raw.isEmpty) return const <String>[];
    final List<String> ids = raw
        .split(',')
        .map((String e) => e.trim())
        .where((String e) => e.isNotEmpty)
        .toList();
    ids.sort();
    return ids;
  }

  String _applicantName(BuildContext context) {
    final Map<String, String> qp = _queryParams(context);
    final String name = (qp['full_name'] ?? '').trim();
    if (name.isNotEmpty) return name;
    return 'Individual request';
  }

  String _industryLabel(BuildContext context) {
    final Map<String, String> qp = _queryParams(context);
    final String raw = (qp['industry_label'] ?? qp['industry'] ?? '').trim();
    return summarizeIndividualIndustryLabel(raw, fallback: 'Individual');
  }

  int _estimatedTotal(BuildContext context) {
    int total = 0;
    for (final String id in _selectedCheckIds(context)) {
      total += HumanVerificationChecksCatalog.byId[id]?.priceMinInr ?? 0;
    }
    return total;
  }

  String _formatCurrency(int value) {
    final String digits = value.toString();
    final StringBuffer out = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      final int remaining = digits.length - i;
      out.write(digits[i]);
      if (remaining > 1 && remaining % 3 == 1) {
        out.write(',');
      }
    }
    return '₹$out';
  }

  void _backToDashboard() {
    context.go(AppRouter.individualIdentityPath);
  }

  @override
  Widget build(BuildContext context) {
    final List<String> checkIds = _selectedCheckIds(context);
    final int total = _estimatedTotal(context);
    final String industryLabel = _industryLabel(context);
    final String applicantName = _applicantName(context);
    final String checkSummary = checkIds.isEmpty
        ? 'No checks selected'
        : summarizeIndividualIndustryLabel(
            checkIds
                .map(
                  (String id) => HumanVerificationChecksCatalog.byId[id]?.title ?? id,
                )
                .join(', '),
            fallback: '${checkIds.length} checks selected',
          );

    return Scaffold(
      backgroundColor: AppColors.brandBlue,
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final double contentWidth = constraints.maxWidth < _referenceWidth
                ? constraints.maxWidth
                : _referenceWidth;
            final double scale = contentWidth / _referenceWidth;
            double s(double v) => v * scale;

            return Center(
              child: SizedBox(
                width: contentWidth,
                height: constraints.maxHeight,
                child: Column(
                  children: <Widget>[
                    Padding(
                      padding: EdgeInsets.fromLTRB(s(16), s(10), s(16), 0),
                      child: Row(
                        children: <Widget>[
                          InkResponse(
                            onTap: _backToDashboard,
                            radius: s(22),
                            child: const Icon(
                              Icons.arrow_back_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          SizedBox(width: s(12)),
                          Expanded(
                            child: Text(
                              'Verification Submitted',
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
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: s(18)),
                    Expanded(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: _panelBg,
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(s(20)),
                          ),
                        ),
                        child: Column(
                          children: <Widget>[
                            Expanded(
                              child: SingleChildScrollView(
                                padding: EdgeInsets.fromLTRB(
                                  s(16),
                                  s(28),
                                  s(16),
                                  s(24),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    _PendingHero(
                                      scale: scale,
                                      pulse: _pulseController,
                                    ),
                                    SizedBox(height: s(24)),
                                    _StatusSummaryCard(
                                      scale: scale,
                                      applicantName: applicantName,
                                      industryLabel: industryLabel,
                                      checkSummary: checkSummary,
                                      estimatedTotal: _formatCurrency(total),
                                      checkCount: checkIds.length,
                                    ),
                                    SizedBox(height: s(16)),
                                    _TimelineCard(scale: scale),
                                    SizedBox(height: s(16)),
                                    _NoteCard(scale: scale),
                                  ],
                                ),
                              ),
                            ),
                            _BottomActions(
                              scale: scale,
                              primaryLabel: 'Back to Dashboard',
                              primaryOnTap: _backToDashboard,
                              secondaryLabel: 'View Profile',
                              secondaryOnTap: () =>
                                  context.go(AppRouter.individualProfilePath),
                            ),
                          ],
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

class _PendingHero extends StatelessWidget {
  const _PendingHero({
    required this.scale,
    required this.pulse,
  });

  final double scale;
  final AnimationController pulse;

  @override
  Widget build(BuildContext context) {
    double s(double v) => v * scale;

    return Center(
      child: AnimatedBuilder(
        animation: pulse,
        builder: (BuildContext context, Widget? child) {
          final double t = Curves.easeInOut.transform(pulse.value);
          return Transform.scale(
            scale: 1.0 + (t * 0.025),
            child: child,
          );
        },
        child: Container(
          width: s(120),
          height: s(120),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: <Color>[
                const Color(0xFFD8E6FF),
                const Color(0xFFBFD3FF).withAlpha(140),
                const Color(0xFFF7F9FC),
              ],
              stops: const <double>[0.0, 0.68, 1.0],
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              Container(
                width: s(90),
                height: s(90),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: Colors.black.withAlpha(12),
                      blurRadius: s(18),
                      offset: Offset(0, s(8)),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.hourglass_top_rounded,
                size: s(42),
                color: AppColors.brandBlue,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusSummaryCard extends StatelessWidget {
  const _StatusSummaryCard({
    required this.scale,
    required this.applicantName,
    required this.industryLabel,
    required this.checkSummary,
    required this.estimatedTotal,
    required this.checkCount,
  });

  final double scale;
  final String applicantName;
  final String industryLabel;
  final String checkSummary;
  final String estimatedTotal;
  final int checkCount;

  @override
  Widget build(BuildContext context) {
    double s(double v) => v * scale;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(s(16)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(s(22)),
        border: Border.all(color: const Color(0xFFE7EBF3)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: s(18),
            offset: Offset(0, s(8)),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: s(12),
                  vertical: s(7),
                ),
                decoration: BoxDecoration(
                  color: AppColors.badgePendingBg,
                  borderRadius: BorderRadius.circular(s(999)),
                ),
                child: Text(
                  'PENDING REVIEW',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: s(10),
                    fontWeight: FontWeight.w800,
                    letterSpacing: s(0.9),
                    color: AppColors.badgePendingFg,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '#${checkCount.toString().padLeft(2, '0')} CHECKS',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: s(10),
                  fontWeight: FontWeight.w800,
                  letterSpacing: s(0.8),
                  color: const Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
          SizedBox(height: s(14)),
          Text(
            applicantName,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: s(18),
              fontWeight: FontWeight.w800,
              height: 1.15,
              color: const Color(0xFF111827),
            ),
          ),
          SizedBox(height: s(14)),
          _DetailRow(scale: scale, label: 'Industry', value: industryLabel),
          SizedBox(height: s(12)),
          _DetailRow(scale: scale, label: 'Checks', value: checkSummary),
          SizedBox(height: s(12)),
          _DetailRow(scale: scale, label: 'Estimated cost', value: estimatedTotal),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.scale,
    required this.label,
    required this.value,
  });

  final double scale;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    double s(double v) => v * scale;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(
          width: s(92),
          child: Text(
            label.toUpperCase(),
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: s(10),
              fontWeight: FontWeight.w800,
              letterSpacing: s(0.8),
              color: const Color(0xFF94A3B8),
            ),
          ),
        ),
        Expanded(
          child: Text(
            value.isEmpty ? '—' : value,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: s(13),
              fontWeight: FontWeight.w600,
              height: 1.35,
              color: const Color(0xFF111827),
            ),
          ),
        ),
      ],
    );
  }
}

class _TimelineCard extends StatelessWidget {
  const _TimelineCard({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    double s(double v) => v * scale;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(s(16)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(s(22)),
        border: Border.all(color: const Color(0xFFE7EBF3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'What happens next',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: s(18),
              fontWeight: FontWeight.w800,
              height: 1.2,
              color: const Color(0xFF111827),
            ),
          ),
          SizedBox(height: s(14)),
          _TimelineItem(
            scale: scale,
            active: true,
            title: 'Submitted',
            subtitle: 'Your request is now in the system.',
          ),
          _TimelineItem(
            scale: scale,
            active: false,
            title: 'Under review',
            subtitle: 'Our team will verify the selected checks.',
          ),
          _TimelineItem(
            scale: scale,
            active: false,
            title: 'Completion update',
            subtitle: 'You will be notified once the review is complete.',
            isLast: true,
          ),
        ],
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  const _TimelineItem({
    required this.scale,
    required this.active,
    required this.title,
    required this.subtitle,
    this.isLast = false,
  });

  final double scale;
  final bool active;
  final String title;
  final String subtitle;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    double s(double v) => v * scale;
    final Color fg = active ? AppColors.brandBlue : const Color(0xFF64748B);
    final Color dot = active ? AppColors.brandBlue : const Color(0xFFCBD5E1);

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : s(12)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            margin: EdgeInsets.only(top: s(3)),
            width: s(12),
            height: s(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: dot,
              boxShadow: active
                  ? <BoxShadow>[
                      BoxShadow(
                        color: AppColors.brandBlue.withAlpha(40),
                        blurRadius: s(10),
                        offset: Offset(0, s(4)),
                      ),
                    ]
                  : null,
            ),
          ),
          SizedBox(width: s(12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: s(13),
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                    color: fg,
                  ),
                ),
                SizedBox(height: s(3)),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: s(12),
                    fontWeight: FontWeight.w500,
                    height: 1.45,
                    color: const Color(0xFF64748B),
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

class _NoteCard extends StatelessWidget {
  const _NoteCard({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    double s(double v) => v * scale;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(s(16)),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF3FF),
        borderRadius: BorderRadius.circular(s(22)),
        border: Border.all(color: const Color(0xFFD6E2FF)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(
            Icons.info_outline_rounded,
            size: s(20),
            color: AppColors.brandBlue,
          ),
          SizedBox(width: s(10)),
          Expanded(
            child: Text(
              'You can leave this page safely. The verification will stay pending until the review is complete.',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: s(12),
                fontWeight: FontWeight.w500,
                height: 1.45,
                color: const Color(0xFF334155),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomActions extends StatelessWidget {
  const _BottomActions({
    required this.scale,
    required this.primaryLabel,
    required this.primaryOnTap,
    required this.secondaryLabel,
    required this.secondaryOnTap,
  });

  final double scale;
  final String primaryLabel;
  final VoidCallback primaryOnTap;
  final String secondaryLabel;
  final VoidCallback secondaryOnTap;

  @override
  Widget build(BuildContext context) {
    double s(double v) => v * scale;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(s(16), s(8), s(16), s(10)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            SizedBox(
              width: double.infinity,
              height: s(52),
              child: ElevatedButton(
                onPressed: primaryOnTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandBlue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(s(16)),
                  ),
                ),
                child: Text(
                  primaryLabel,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: s(14),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            SizedBox(height: s(10)),
            SizedBox(
              width: double.infinity,
              height: s(52),
              child: OutlinedButton(
                onPressed: secondaryOnTap,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.brandBlue,
                  side: const BorderSide(color: Color(0xFFD6E2FF)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(s(16)),
                  ),
                ),
                child: Text(
                  secondaryLabel,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: s(14),
                    fontWeight: FontWeight.w700,
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

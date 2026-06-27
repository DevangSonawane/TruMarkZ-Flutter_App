import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/router/app_router.dart';
import '../../../../../core/theme/app_colors.dart';

String _displayId(String id) {
  final String v = id.trim();
  if (v.isEmpty) return '—';
  return v;
}

class OrgVerificationCompletionView extends StatefulWidget {
  const OrgVerificationCompletionView({
    super.key,
    required this.headerTitle,
    required this.title,
    required this.subtitle,
    required this.subjectName,
    required this.subjectIdLabel,
    required this.subjectIdValue,
    required this.metrics,
    required this.primaryActionLabel,
    required this.primaryAction,
    required this.secondaryActionLabel,
    required this.secondaryAction,
    this.tertiaryActionLabel,
    this.tertiaryAction,
  });

  final String headerTitle;
  final String title;
  final String subtitle;
  final String subjectName;
  final String subjectIdLabel;
  final String subjectIdValue;
  final List<OrgCompletionMetric> metrics;
  final String primaryActionLabel;
  final VoidCallback primaryAction;
  final String secondaryActionLabel;
  final VoidCallback secondaryAction;
  final String? tertiaryActionLabel;
  final VoidCallback? tertiaryAction;

  @override
  State<OrgVerificationCompletionView> createState() =>
      _OrgVerificationCompletionViewState();
}

class _OrgVerificationCompletionViewState
    extends State<OrgVerificationCompletionView>
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

  void _goDashboard() {
    context.go(AppRouter.dashboardPath);
  }

  @override
  Widget build(BuildContext context) {
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
                            onTap: _goDashboard,
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
                              widget.headerTitle,
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
                                      subjectName: widget.subjectName,
                                      subjectIdLabel: widget.subjectIdLabel,
                                      subjectIdValue: widget.subjectIdValue,
                                      metrics: widget.metrics,
                                      title: widget.title,
                                      subtitle: widget.subtitle,
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
                              primaryLabel: widget.primaryActionLabel,
                              primaryOnTap: widget.primaryAction,
                              secondaryLabel: widget.secondaryActionLabel,
                              secondaryOnTap: widget.secondaryAction,
                              tertiaryLabel: widget.tertiaryActionLabel,
                              tertiaryOnTap: widget.tertiaryAction,
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

class OrgCompletionMetric {
  const OrgCompletionMetric({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;
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
    required this.subjectName,
    required this.subjectIdLabel,
    required this.subjectIdValue,
    required this.metrics,
    required this.title,
    required this.subtitle,
  });

  final double scale;
  final String subjectName;
  final String subjectIdLabel;
  final String subjectIdValue;
  final List<OrgCompletionMetric> metrics;
  final String title;
  final String subtitle;

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
                '${metrics.length.toString().padLeft(2, '0')} METRICS',
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
            title,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: s(18),
              fontWeight: FontWeight.w800,
              height: 1.15,
              color: const Color(0xFF111827),
            ),
          ),
          SizedBox(height: s(10)),
          Text(
            subtitle,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: s(13),
              fontWeight: FontWeight.w400,
              height: 1.45,
              color: const Color(0xFF6B7280),
            ),
          ),
          SizedBox(height: s(14)),
          Text(
            subjectName,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: s(15),
              fontWeight: FontWeight.w700,
              height: 1.2,
              color: const Color(0xFF111827),
            ),
          ),
          SizedBox(height: s(10)),
          Text(
            subjectIdLabel.toUpperCase(),
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: s(10),
              fontWeight: FontWeight.w800,
              letterSpacing: s(0.8),
              height: 1.4,
              color: const Color(0xFF94A3B8),
            ),
          ),
          SizedBox(height: s(6)),
          SizedBox(
            width: double.infinity,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Text(
                _displayId(subjectIdValue),
                maxLines: 1,
                softWrap: false,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: s(14),
                  fontWeight: FontWeight.w700,
                  height: 1.25,
                  color: const Color(0xFF111827),
                ),
              ),
            ),
          ),
          SizedBox(height: s(16)),
          Row(
            children: <Widget>[
              for (int i = 0; i < metrics.length; i++) ...<Widget>[
                Expanded(
                  child: _MetricTile(
                    metric: metrics[i],
                    scale: scale,
                  ),
                ),
                if (i != metrics.length - 1) SizedBox(width: s(10)),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.metric,
    required this.scale,
  });

  final OrgCompletionMetric metric;
  final double scale;

  @override
  Widget build(BuildContext context) {
    double s(double v) => v * scale;

    return Container(
      padding: EdgeInsets.symmetric(vertical: s(14)),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(s(16)),
        border: Border.all(color: const Color(0xFFE7EBF3)),
      ),
      child: Column(
        children: <Widget>[
          Text(
            metric.value,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: s(20),
              fontWeight: FontWeight.w800,
              height: 1.08,
              color: const Color(0xFF111827),
            ),
          ),
          SizedBox(height: s(6)),
          Text(
            metric.label.toUpperCase(),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: s(10),
              fontWeight: FontWeight.w800,
              letterSpacing: s(0.7),
              height: 1.35,
              color: const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
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
    this.tertiaryLabel,
    this.tertiaryOnTap,
  });

  final double scale;
  final String primaryLabel;
  final VoidCallback primaryOnTap;
  final String secondaryLabel;
  final VoidCallback secondaryOnTap;
  final String? tertiaryLabel;
  final VoidCallback? tertiaryOnTap;

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
            if (tertiaryLabel != null && tertiaryOnTap != null) ...<Widget>[
              SizedBox(height: s(10)),
              SizedBox(
                width: double.infinity,
                height: s(48),
                child: TextButton(
                  onPressed: tertiaryOnTap,
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF334155),
                    backgroundColor: const Color(0xFFF8FAFC),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(s(14)),
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                  ),
                  child: Text(
                    tertiaryLabel!,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: s(13),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

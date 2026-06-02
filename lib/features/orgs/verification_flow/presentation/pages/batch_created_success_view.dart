import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/widgets/tmz_button.dart';

class BatchCreatedSuccessView extends StatelessWidget {
  const BatchCreatedSuccessView({
    super.key,
    required this.heroAssetPath,
    required this.title,
    required this.subtitle,
    required this.batchName,
    required this.batchIdLabel,
    required this.batchIdValue,
    required this.metrics,
    required this.primaryActionLabel,
    required this.primaryAction,
    required this.secondaryActionLabel,
    required this.secondaryAction,
    this.banners = const <BatchCreatedBanner>[],
    this.heroSize = 148,
  });

  final String heroAssetPath;
  final String title;
  final String subtitle;
  final String batchName;
  final String batchIdLabel;
  final String batchIdValue;
  final List<BatchCreatedMetric> metrics;
  final String primaryActionLabel;
  final VoidCallback primaryAction;
  final String secondaryActionLabel;
  final VoidCallback secondaryAction;
  final List<BatchCreatedBanner> banners;
  final double heroSize;

  static String _shortId(String id) {
    final String v = id.trim();
    if (v.isEmpty) return '—';
    return v.length <= 12 ? v : '${v.substring(0, 12)}…';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.brandBlue,
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final double referenceWidth = 402;
            final double contentWidth = constraints.maxWidth < referenceWidth
                ? constraints.maxWidth
                : referenceWidth;
            final double scale = contentWidth / referenceWidth;
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
                          Expanded(
                            child: Text(
                              title,
                              textAlign: TextAlign.center,
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
                          color: Colors.white,
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(s(20)),
                          ),
                        ),
                        child: Column(
                          children: <Widget>[
                            Expanded(
                              child: ListView(
                                padding: EdgeInsets.fromLTRB(
                                  s(16),
                                  s(24),
                                  s(16),
                                  s(24),
                                ),
                                children: <Widget>[
                                  Center(
                                    child: Container(
                                      width: s(heroSize + 36),
                                      height: s(heroSize + 36),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF8FAFF),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: const Color(0xFFE8EEFF),
                                          width: s(2),
                                        ),
                                      ),
                                      alignment: Alignment.center,
                                      child: Container(
                                        width: s(heroSize),
                                        height: s(heroSize),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                          boxShadow: <BoxShadow>[
                                            BoxShadow(
                                              color: Colors.black.withAlpha(10),
                                              blurRadius: s(28),
                                              offset: Offset(0, s(12)),
                                            ),
                                          ],
                                        ),
                                        alignment: Alignment.center,
                                        child: SvgPicture.asset(
                                          heroAssetPath,
                                          width: s(heroSize) * 0.84,
                                          height: s(heroSize) * 0.84,
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: s(28)),
                                  Text(
                                    title,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: s(30),
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: s(1.15),
                                      height: 1.05,
                                      color: const Color(0xFF111827),
                                    ),
                                  ),
                                  SizedBox(height: s(10)),
                                  Text(
                                    subtitle,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: s(12),
                                      fontWeight: FontWeight.w400,
                                      height: 1.45,
                                      color: const Color(0xFF94A3B8),
                                    ),
                                  ),
                                  SizedBox(height: s(28)),
                                  Container(
                                    padding: EdgeInsets.all(s(16)),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(
                                        s(24),
                                      ),
                                      border: Border.all(
                                        color: const Color(0xFFE7EBF3),
                                      ),
                                      boxShadow: <BoxShadow>[
                                        BoxShadow(
                                          color: Colors.black.withAlpha(8),
                                          blurRadius: s(20),
                                          offset: Offset(0, s(10)),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Row(
                                          children: <Widget>[
                                            Expanded(
                                              child: Text(
                                                'Batch Details',
                                                style: TextStyle(
                                                  fontFamily: 'Inter',
                                                  fontSize: s(18),
                                                  fontWeight: FontWeight.w800,
                                                  height: 1.2,
                                                  color: const Color(
                                                    0xFF111827,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            Container(
                                              width: s(36),
                                              height: s(36),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFF4F7FF),
                                                borderRadius:
                                                    BorderRadius.circular(
                                                  s(12),
                                                ),
                                              ),
                                              child: const Icon(
                                                Icons.folder_rounded,
                                                color: AppColors.brandBlue,
                                                size: 20,
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: s(18)),
                                        Text(
                                          batchName,
                                          style: TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: s(15),
                                            fontWeight: FontWeight.w900,
                                            height: 1.2,
                                            color: const Color(0xFF111827),
                                          ),
                                        ),
                                        SizedBox(height: s(12)),
                                        Text(
                                          batchIdLabel.toUpperCase(),
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
                                        Text(
                                          _shortId(batchIdValue),
                                          style: TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: s(14),
                                            fontWeight: FontWeight.w800,
                                            height: 1.3,
                                            color: const Color(0xFF111827),
                                          ),
                                        ),
                                        SizedBox(height: s(18)),
                                        Row(
                                          children: <Widget>[
                                            for (int i = 0; i < metrics.length; i++)
                                              ...<Widget>[
                                                Expanded(
                                                  child: _MetricTile(
                                                    metric: metrics[i],
                                                    scale: scale,
                                                  ),
                                                ),
                                                if (i != metrics.length - 1)
                                                  SizedBox(width: s(10)),
                                              ],
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (banners.isNotEmpty) ...<Widget>[
                                    SizedBox(height: s(16)),
                                    for (int i = 0; i < banners.length; i++)
                                      ...<Widget>[
                                        _InfoBanner(
                                          banner: banners[i],
                                          scale: scale,
                                        ),
                                        if (i != banners.length - 1)
                                          SizedBox(height: s(12)),
                                      ],
                                  ],
                                ],
                              ),
                            ),
                            SafeArea(
                              top: false,
                              child: Padding(
                                padding: EdgeInsets.fromLTRB(
                                  s(16),
                                  s(8),
                                  s(16),
                                  s(16),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    _GradientCtaButton(
                                      label: primaryActionLabel,
                                      icon: Icons.arrow_forward_rounded,
                                      gradient: const LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: <Color>[
                                          AppColors.brandBlue,
                                          AppColors.deepNavy,
                                        ],
                                      ),
                                      enabled: true,
                                      onPressed: primaryAction,
                                    ),
                                    SizedBox(height: s(12)),
                                    TMZButton(
                                      label: secondaryActionLabel,
                                      icon: Icons.dashboard_rounded,
                                      variant: TMZButtonVariant.secondary,
                                      onPressed: secondaryAction,
                                    ),
                                  ],
                                ),
                              ),
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

class BatchCreatedMetric {
  const BatchCreatedMetric({required this.label, required this.value});

  final String label;
  final String value;
}

class BatchCreatedBanner {
  const BatchCreatedBanner({
    required this.title,
    required this.subtitle,
    required this.color,
    required this.bg,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final Color color;
  final Color bg;
  final IconData icon;
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.metric, required this.scale});

  final BatchCreatedMetric metric;
  final double scale;

  @override
  Widget build(BuildContext context) {
    double s(double v) => v * scale;
    return Container(
      padding: EdgeInsets.all(s(12)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(s(16)),
        border: Border.all(color: const Color(0xFFE7EBF3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            metric.label.toUpperCase(),
            style: AppTypography.caption.copyWith(
              color: AppColors.textTertiary,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
          SizedBox(height: s(6)),
          Row(
            children: <Widget>[
              Container(
                width: s(10),
                height: s(10),
                decoration: const BoxDecoration(
                  color: AppColors.brandBlue,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: s(8)),
              Text(
                metric.value,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: s(24),
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                  color: const Color(0xFF111827),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({required this.banner, required this.scale});

  final BatchCreatedBanner banner;
  final double scale;

  @override
  Widget build(BuildContext context) {
    double s(double v) => v * scale;
    return Container(
      padding: EdgeInsets.all(s(16)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(s(18)),
        border: Border.all(color: banner.color.withAlpha(45)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withAlpha(6),
            blurRadius: s(14),
            offset: Offset(0, s(8)),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: s(36),
            height: s(36),
            decoration: BoxDecoration(
              color: banner.bg,
              borderRadius: BorderRadius.circular(s(12)),
            ),
            child: Icon(banner.icon, color: banner.color, size: s(20)),
          ),
          SizedBox(width: s(12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  banner.title,
                  style: AppTypography.body1.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: s(6)),
                Text(
                  banner.subtitle,
                  style: AppTypography.body2.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.25,
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

class _GradientCtaButton extends StatefulWidget {
  const _GradientCtaButton({
    required this.label,
    required this.icon,
    required this.gradient,
    required this.enabled,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final Gradient gradient;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  State<_GradientCtaButton> createState() => _GradientCtaButtonState();
}

class _GradientCtaButtonState extends State<_GradientCtaButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final Widget content = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(
          widget.label,
          style: AppTypography.button.copyWith(color: Colors.white),
        ),
        const SizedBox(width: 10),
        Icon(widget.icon, color: Colors.white, size: 18),
      ],
    );

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 150),
      opacity: widget.enabled ? 1 : 0.45,
      child: SizedBox(
        height: 56,
        width: double.infinity,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: widget.gradient,
            borderRadius: BorderRadius.circular(18),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: AppColors.brandBlue.withAlpha(40),
                blurRadius: 22,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: widget.enabled ? widget.onPressed : null,
              onHighlightChanged: (bool value) =>
                  setState(() => _isPressed = value),
              child: AnimatedScale(
                duration: const Duration(milliseconds: 90),
                scale: _isPressed ? 0.985 : 1,
                child: Center(child: content),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

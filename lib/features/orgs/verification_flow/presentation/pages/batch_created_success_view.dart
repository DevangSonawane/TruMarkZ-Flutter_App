import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';

class BatchCreatedSuccessView extends StatefulWidget {
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
    this.heroSize = 124,
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
  final double heroSize;

  @override
  State<BatchCreatedSuccessView> createState() =>
      _BatchCreatedSuccessViewState();
}

class _BatchCreatedSuccessViewState extends State<BatchCreatedSuccessView>
    with SingleTickerProviderStateMixin {
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

  static String _displayId(String id) {
    final String v = id.trim();
    if (v.isEmpty) return '—';
    return v;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.brandBlue,
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            const double referenceWidth = 402;
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
                      child: Text(
                        widget.title,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: s(21),
                          fontWeight: FontWeight.w700,
                          height: 1.15,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    SizedBox(height: s(14)),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(s(22)),
                          ),
                        ),
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            s(16),
                            s(18),
                            s(16),
                            s(16),
                          ),
                          child: Column(
                            children: <Widget>[
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    _HeroIllustration(
                                      assetPath: widget.heroAssetPath,
                                      heroSize: s(widget.heroSize),
                                      pulse: _pulseController,
                                    ),
                                    SizedBox(height: s(22)),
                                    Text(
                                      widget.title,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: s(30),
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: s(0.2),
                                        height: 1.08,
                                        color: const Color(0xFF111827),
                                      ),
                                    ),
                                    SizedBox(height: s(10)),
                                    Text(
                                      widget.subtitle,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: s(13),
                                        fontWeight: FontWeight.w400,
                                        height: 1.45,
                                        color: const Color(0xFF6B7280),
                                      ),
                                    ),
                                    SizedBox(height: s(22)),
                                    Container(
                                      width: double.infinity,
                                      padding: EdgeInsets.all(s(16)),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(
                                          s(22),
                                        ),
                                        border: Border.all(
                                          color: const Color(0xFFE7EBF3),
                                        ),
                                        boxShadow: <BoxShadow>[
                                          BoxShadow(
                                            color: Colors.black.withAlpha(8),
                                            blurRadius: s(18),
                                            offset: Offset(0, s(8)),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: <Widget>[
                                          Text(
                                            'Batch Details',
                                            style: TextStyle(
                                              fontFamily: 'Inter',
                                              fontSize: s(18),
                                              fontWeight: FontWeight.w800,
                                              height: 1.2,
                                              color: const Color(0xFF111827),
                                            ),
                                          ),
                                          SizedBox(height: s(14)),
                                          Text(
                                            widget.batchName,
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
                                            widget.batchIdLabel.toUpperCase(),
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
                                              physics:
                                                  const BouncingScrollPhysics(),
                                              child: Text(
                                                _displayId(widget.batchIdValue),
                                                maxLines: 1,
                                                softWrap: false,
                                                style: TextStyle(
                                                  fontFamily: 'Inter',
                                                  fontSize: s(14),
                                                  fontWeight: FontWeight.w700,
                                                  height: 1.25,
                                                  color: const Color(
                                                    0xFF111827,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          SizedBox(height: s(16)),
                                          Row(
                                            children: <Widget>[
                                              for (
                                                int i = 0;
                                                i < widget.metrics.length;
                                                i++
                                              ) ...<Widget>[
                                                Expanded(
                                                  child: _MetricTile(
                                                    metric: widget.metrics[i],
                                                    scale: scale,
                                                  ),
                                                ),
                                                if (i !=
                                                    widget.metrics.length - 1)
                                                  SizedBox(width: s(10)),
                                              ],
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SafeArea(
                                top: false,
                                child: Padding(
                                  padding: EdgeInsets.only(top: s(14)),
                                  child: Row(
                                    children: <Widget>[
                                      Expanded(
                                        child: _PrimaryActionButton(
                                          label: widget.primaryActionLabel,
                                          onPressed: widget.primaryAction,
                                        ),
                                      ),
                                      SizedBox(width: s(12)),
                                      Expanded(
                                        child: _SecondaryActionButton(
                                          label: widget.secondaryActionLabel,
                                          onPressed: widget.secondaryAction,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
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

class BatchCreatedMetric {
  const BatchCreatedMetric({required this.label, required this.value});

  final String label;
  final String value;
}

class _HeroIllustration extends StatelessWidget {
  const _HeroIllustration({
    required this.assetPath,
    required this.heroSize,
    required this.pulse,
  });

  final String assetPath;
  final double heroSize;
  final Animation<double> pulse;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulse,
      builder: (BuildContext context, Widget? child) {
        final double t = Curves.easeInOut.transform(pulse.value);
        final double scale = 0.95 + (0.08 * t);
        final double yOffset = 3 - (6 * t);
        final double haloOpacity = 0.07 + (0.08 * t);
        final double ringScale = 0.98 + (0.08 * t);
        final double checkProgress = Curves.easeOutCubic.transform(t);

        return Transform.scale(
          scale: scale,
          child: Transform.translate(
            offset: Offset(0, yOffset),
            child: SizedBox(
              width: heroSize + 68,
              height: heroSize + 68,
              child: Stack(
                alignment: Alignment.center,
                children: <Widget>[
                  Container(
                    width: heroSize + 56,
                    height: heroSize + 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFE8EEFF),
                        width: 2,
                      ),
                    ),
                  ),
                  Transform.scale(
                    scale: ringScale,
                    child: Container(
                      width: heroSize + 42,
                      height: heroSize + 42,
                      decoration: BoxDecoration(
                        color: const Color(
                          0xFFF8FAFF,
                        ).withAlpha((haloOpacity * 255).round()),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFE8EEFF),
                          width: 2,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Container(
                        width: heroSize,
                        height: heroSize,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: <BoxShadow>[
                            BoxShadow(
                              color: Colors.black.withAlpha(12),
                              blurRadius: 28,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: CustomPaint(
                          size: Size(heroSize * 0.9, heroSize * 0.9),
                          painter: _BatchSuccessPainter(t: checkProgress),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: heroSize * 0.10,
                    top: heroSize * 0.18,
                    child: _FloatingDot(size: 12, opacity: 0.35 + (0.35 * t)),
                  ),
                  Positioned(
                    right: heroSize * 0.06,
                    top: heroSize * 0.11,
                    child: _FloatingDot(
                      size: 10,
                      opacity: 0.25 + (0.30 * (1 - t)),
                    ),
                  ),
                  Positioned(
                    right: heroSize * 0.02,
                    bottom: heroSize * 0.12,
                    child: _FloatingDot(size: 8, opacity: 0.20 + (0.28 * t)),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _FloatingDot extends StatelessWidget {
  const _FloatingDot({required this.size, required this.opacity});

  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFFBFDBFE).withAlpha((opacity * 255).round()),
        shape: BoxShape.circle,
      ),
    );
  }
}

class _BatchSuccessPainter extends CustomPainter {
  _BatchSuccessPainter({required this.t});

  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = size.center(Offset.zero);
    final double outerRadius = size.shortestSide * 0.48;
    final double middleRadius = size.shortestSide * 0.39;
    final double innerRadius = size.shortestSide * 0.28;

    final Paint outerGlow = Paint()
      ..color = const Color(0xFF2563EB).withAlpha((18 + (18 * t)).round())
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, outerRadius, outerGlow);

    final Paint middleFill = Paint()..color = Colors.white;
    final Paint middleStroke = Paint()
      ..color = const Color(0xFFE8EEFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5;
    canvas.drawCircle(center, middleRadius, middleFill);
    canvas.drawCircle(center, middleRadius, middleStroke);

    final Paint innerFill = Paint()
      ..color = const Color(0xFF2563EB)
      ..style = PaintingStyle.fill;
    final double pulse = 0.96 + (0.04 * t);
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(pulse, pulse);
    canvas.drawCircle(Offset.zero, innerRadius, innerFill);

    final Paint dotPaint = Paint()..style = PaintingStyle.fill;
    final List<_DotSpec> dots = <_DotSpec>[
      _DotSpec(
        const Offset(-0.34, -0.40),
        0.048,
        const Color(0xFF93C5FD),
        0.35,
        0.9,
      ),
      _DotSpec(
        const Offset(0.34, -0.44),
        0.040,
        const Color(0xFFBFDBFE),
        0.25,
        0.75,
      ),
      _DotSpec(
        const Offset(0.42, 0.18),
        0.034,
        const Color(0xFFDBEAFE),
        0.20,
        0.6,
      ),
      _DotSpec(
        const Offset(-0.46, 0.12),
        0.038,
        const Color(0xFFBFDBFE),
        0.30,
        0.8,
      ),
    ];
    for (final _DotSpec dot in dots) {
      final double drift = 1 + (0.08 * t * dot.drift);
      dotPaint.color = dot.color.withAlpha(
        ((dot.opacity + (0.25 * t)) * 255).round(),
      );
      canvas.drawCircle(
        Offset(
          dot.offset.dx * size.shortestSide * drift,
          dot.offset.dy * size.shortestSide * drift,
        ),
        dot.radius * size.shortestSide,
        dotPaint,
      );
    }

    final Paint checkPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final Path checkPath = Path()
      ..moveTo(-0.20 * size.shortestSide, 0.02 * size.shortestSide)
      ..lineTo(-0.02 * size.shortestSide, 0.20 * size.shortestSide)
      ..lineTo(0.30 * size.shortestSide, -0.14 * size.shortestSide);
    final ui.PathMetrics metrics = checkPath.computeMetrics();
    for (final ui.PathMetric metric in metrics) {
      final Path extract = metric.extractPath(0, metric.length * t);
      canvas.drawPath(extract, checkPaint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _BatchSuccessPainter oldDelegate) =>
      oldDelegate.t != t;
}

class _DotSpec {
  const _DotSpec(
    this.offset,
    this.radius,
    this.color,
    this.opacity,
    this.drift,
  );

  final Offset offset;
  final double radius;
  final Color color;
  final double opacity;
  final double drift;
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
        color: const Color(0xFFF8FAFF),
        borderRadius: BorderRadius.circular(s(16)),
        border: Border.all(color: const Color(0xFFE7EBF3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            metric.label.toUpperCase(),
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: s(10),
              fontWeight: FontWeight.w800,
              letterSpacing: s(0.7),
              height: 1.2,
              color: const Color(0xFF94A3B8),
            ),
          ),
          SizedBox(height: s(8)),
          Text(
            metric.value,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: s(24),
              fontWeight: FontWeight.w800,
              height: 1.1,
              color: const Color(0xFF111827),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryActionButton extends StatefulWidget {
  const _PrimaryActionButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  State<_PrimaryActionButton> createState() => _PrimaryActionButtonState();
}

class _PrimaryActionButtonState extends State<_PrimaryActionButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return _ActionButtonShell(
      onPressed: widget.onPressed,
      pressed: _pressed,
      background: Colors.white,
      border: Border.all(color: const Color(0xFFD8E1F0), width: 1.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            widget.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.brandBlue,
            ),
          ),
          const SizedBox(width: 8),
          const Icon(
            Icons.arrow_forward_rounded,
            color: AppColors.brandBlue,
            size: 18,
          ),
        ],
      ),
      onHighlightChanged: (bool value) => setState(() => _pressed = value),
    );
  }
}

class _SecondaryActionButton extends StatefulWidget {
  const _SecondaryActionButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  State<_SecondaryActionButton> createState() => _SecondaryActionButtonState();
}

class _SecondaryActionButtonState extends State<_SecondaryActionButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return _ActionButtonShell(
      onPressed: widget.onPressed,
      pressed: _pressed,
      gradient: null,
      border: Border.all(color: const Color(0xFFD8E1F0), width: 1.5),
      background: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const Icon(
            Icons.dashboard_rounded,
            color: AppColors.brandBlue,
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            widget.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.brandBlue,
            ),
          ),
        ],
      ),
      onHighlightChanged: (bool value) => setState(() => _pressed = value),
    );
  }
}

class _ActionButtonShell extends StatelessWidget {
  const _ActionButtonShell({
    required this.onPressed,
    required this.pressed,
    required this.child,
    required this.onHighlightChanged,
    this.gradient,
    this.background,
    this.border,
  });

  final VoidCallback onPressed;
  final bool pressed;
  final Widget child;
  final ValueChanged<bool> onHighlightChanged;
  final Gradient? gradient;
  final Color? background;
  final BoxBorder? border;

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = BorderRadius.circular(18);
    return AnimatedScale(
      duration: const Duration(milliseconds: 90),
      scale: pressed ? 0.985 : 1,
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          color: background,
          gradient: gradient,
          borderRadius: radius,
          border: border,
          boxShadow: background == Colors.white
              ? <BoxShadow>[
                  BoxShadow(
                    color: Colors.black.withAlpha(6),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ]
              : gradient == null
              ? const <BoxShadow>[]
              : <BoxShadow>[
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
            borderRadius: radius,
            onTap: onPressed,
            onHighlightChanged: onHighlightChanged,
            splashColor: Colors.white.withAlpha(26),
            highlightColor: Colors.white.withAlpha(12),
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../../../../core/theme/app_colors.dart';

/// Animated "Verify Products & People" hero card for the org dashboard
/// (replaces the old static promo image).
///
/// Motion budget (same recipe as the ZingIt home banners): one shared 8s
/// clock drives all ambient motion — drifting blobs, flowing wave lines,
/// floating tiles and the verify loop — plus a one-shot entrance for the
/// copy. Reduced motion holds a composed still frame.
///
/// Verify loop on the clock:
/// 0.06–0.28 a scan line sweeps the product tile, 0.28 its check pops,
/// 0.38–0.60 focus brackets close on the identity tile, 0.60 its check pops,
/// 0.92–1.0 everything clears for the next loop.
class OrgHeroBanner extends StatefulWidget {
  const OrgHeroBanner({
    super.key,
    required this.scale,
    required this.height,
    required this.onTap,
  });

  final double scale;
  final double height;
  final VoidCallback onTap;

  @override
  State<OrgHeroBanner> createState() => _OrgHeroBannerState();
}

class _OrgHeroBannerState extends State<OrgHeroBanner>
    with TickerProviderStateMixin {
  late final AnimationController _clock = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 8),
  );
  late final AnimationController _enter = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      // A composed still frame: both tiles verified, nothing moving.
      _clock
        ..stop()
        ..value = 0.8;
      _enter.value = 1;
      _started = true;
      return;
    }
    if (!_clock.isAnimating) _clock.repeat();
    if (!_started) {
      _started = true;
      _enter.forward();
    }
  }

  @override
  void dispose() {
    _clock.dispose();
    _enter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double scale = widget.scale;
    return Semantics(
      button: true,
      label: 'Verify products and people. Start a new batch.',
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18 * scale),
          child: SizedBox(
            width: double.infinity,
            height: widget.height,
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints box) {
                final double copyWidth = box.maxWidth * 0.56;
                return Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    RepaintBoundary(
                      child: CustomPaint(
                        painter: _BackdropPainter(clock: _clock, scale: scale),
                      ),
                    ),
                    Positioned(
                      left: 16 * scale,
                      top: 0,
                      bottom: 0,
                      width: copyWidth - 16 * scale,
                      child: _Copy(enter: _enter, scale: scale),
                    ),
                    Positioned(
                      left: copyWidth,
                      top: 0,
                      bottom: 0,
                      right: 0,
                      child: _VerifyArt(
                        clock: _clock,
                        enter: _enter,
                        scale: scale,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _Copy extends StatelessWidget {
  const _Copy({required this.enter, required this.scale});

  final Animation<double> enter;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _EnterPop(
          enter: enter,
          from: 0.6,
          interval: const Interval(0, 0.45, curve: Curves.easeOutBack),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: 7 * scale,
                vertical: 3 * scale,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(
                    LucideIcons.shieldCheck,
                    size: 11 * scale,
                    color: const Color(0xFF7DD3FC),
                  ),
                  SizedBox(width: 4 * scale),
                  Text(
                    'TRUSTED VERIFICATION',
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'Inter',
                      fontSize: 8 * scale,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.9,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(height: 8 * scale),
        _EnterSlide(
          enter: enter,
          interval: const Interval(0.08, 0.6, curve: Curves.easeOutBack),
          dx: -30 * scale,
          child: Text(
            'Verify',
            style: TextStyle(
              color: Colors.white,
              fontFamily: 'Inter',
              fontSize: 24 * scale,
              height: 1.0,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.6,
            ),
          ),
        ),
        SizedBox(height: 2 * scale),
        _EnterSlide(
          enter: enter,
          interval: const Interval(0.16, 0.7, curve: Curves.easeOutBack),
          dx: -40 * scale,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              'Products & People',
              maxLines: 1,
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'Inter',
                fontSize: 19 * scale,
                height: 1.1,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
          ),
        ),
        SizedBox(height: 12 * scale),
        _EnterRise(
          enter: enter,
          interval: const Interval(0.32, 0.9),
          child: Container(
            padding: EdgeInsets.fromLTRB(
              13 * scale,
              6 * scale,
              8 * scale,
              6 * scale,
            ),
            decoration: const ShapeDecoration(
              color: Colors.white,
              shape: StadiumBorder(),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  'New batch',
                  style: TextStyle(
                    color: AppColors.brandBlue,
                    fontFamily: 'Inter',
                    fontSize: 11.5 * scale,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(width: 2 * scale),
                Icon(
                  LucideIcons.chevronRight,
                  size: 14 * scale,
                  color: AppColors.brandBlue,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Right half: product + identity tiles running the verify loop, with a
/// status chip that narrates the current step.
class _VerifyArt extends StatelessWidget {
  const _VerifyArt({
    required this.clock,
    required this.enter,
    required this.scale,
  });

  final Animation<double> clock;
  final Animation<double> enter;
  final double scale;

  static const Color _green = Color(0xFF16A34A);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints box) {
        final double tile = math.min(box.maxWidth * 0.44, box.maxHeight * 0.5);
        return AnimatedBuilder(
          animation: clock,
          builder: (BuildContext context, _) {
            final double t = clock.value;
            final double clear = 1 - ((t - 0.92) / 0.08).clamp(0.0, 1.0);
            final double scan = ((t - 0.06) / 0.22).clamp(0.0, 1.0);
            final double checkA = ((t - 0.28) / 0.06).clamp(0.0, 1.0) * clear;
            final double focus = ((t - 0.38) / 0.22).clamp(0.0, 1.0) * clear;
            final double checkB = ((t - 0.60) / 0.06).clamp(0.0, 1.0) * clear;
            final String status = (t < 0.30 || t > 0.96)
                ? 'Scanning product'
                : t < 0.62
                ? 'Matching identity'
                : 'All verified';
            return Stack(
              clipBehavior: Clip.none,
              children: <Widget>[
                Positioned(
                  left: box.maxWidth * 0.02,
                  top: box.maxHeight * 0.12,
                  child: _EnterPop(
                    enter: enter,
                    interval: const Interval(
                      0.15,
                      0.65,
                      curve: Curves.easeOutBack,
                    ),
                    child: _Float(
                      t: t,
                      phase: 0,
                      amplitude: 3 * scale,
                      tilt: -0.06,
                      child: _Tile(
                        size: tile,
                        scale: scale,
                        icon: LucideIcons.package,
                        tint: const Color(0xFFCFF3F1),
                        check: checkA,
                        overlay: scan > 0 && scan < 1
                            ? _ScanLine(progress: scan, scale: scale)
                            : null,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: box.maxWidth * 0.06,
                  top: box.maxHeight * 0.24,
                  child: _EnterPop(
                    enter: enter,
                    interval: const Interval(
                      0.27,
                      0.77,
                      curve: Curves.easeOutBack,
                    ),
                    child: _Float(
                      t: t,
                      phase: 0.5,
                      amplitude: 3 * scale,
                      tilt: 0.06,
                      child: _Tile(
                        size: tile,
                        scale: scale,
                        icon: LucideIcons.user,
                        tint: const Color(0xFFF3EEDC),
                        check: checkB,
                        overlay: CustomPaint(
                          painter: _BracketsPainter(
                            focus: focus,
                            verified: checkB,
                            scale: scale,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 4 * scale,
                  right: 4 * scale,
                  bottom: box.maxHeight * 0.07,
                  child: Center(
                    child: _EnterRise(
                      enter: enter,
                      interval: const Interval(0.45, 1),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: _StatusChip(
                          status: status,
                          done: status == 'All verified',
                          scale: scale,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.size,
    required this.scale,
    required this.icon,
    required this.tint,
    required this.check,
    this.overlay,
  });

  final double size;
  final double scale;
  final IconData icon;
  final Color tint;
  final double check;
  final Widget? overlay;

  @override
  Widget build(BuildContext context) {
    final double badge = 18 * scale;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14 * scale),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[Colors.white, tint],
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14 * scale),
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  Center(
                    child: Icon(
                      icon,
                      size: size * 0.44,
                      color: AppColors.brandBlue,
                    ),
                  ),
                  ?overlay,
                ],
              ),
            ),
          ),
          Positioned(
            right: -badge * 0.35,
            top: -badge * 0.35,
            child: _CheckBadge(progress: check, size: badge),
          ),
        ],
      ),
    );
  }
}

/// Glowing line sweeping top → bottom across a tile.
class _ScanLine extends StatelessWidget {
  const _ScanLine({required this.progress, required this.scale});

  final double progress;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final double eased = Curves.easeInOut.transform(progress);
    final double fade = math.sin(progress * math.pi);
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints box) => Stack(
        children: <Widget>[
          Positioned(
            left: 0,
            right: 0,
            top: box.maxHeight * eased - 10 * scale,
            height: 12 * scale,
            child: Opacity(
              opacity: fade,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: <Color>[
                      const Color(0xFF22D3EE).withValues(alpha: 0),
                      const Color(0xFF22D3EE).withValues(alpha: 0.55),
                    ],
                  ),
                  border: const Border(
                    bottom: BorderSide(color: Color(0xFF06B6D4), width: 2),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Face-ID style corner brackets that close in as [focus] goes 0 → 1 and
/// turn green once [verified].
class _BracketsPainter extends CustomPainter {
  _BracketsPainter({
    required this.focus,
    required this.verified,
    required this.scale,
  });

  final double focus;
  final double verified;
  final double scale;

  @override
  void paint(Canvas canvas, Size size) {
    if (focus <= 0) return;
    final double e = Curves.easeOutCubic.transform(focus);
    final double inset = size.width * (0.02 + 0.12 * e);
    final double arm = size.width * 0.16;
    final Rect r = Rect.fromLTRB(
      inset,
      inset,
      size.width - inset,
      size.height - inset,
    );
    final Paint p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2 * scale
      ..strokeCap = StrokeCap.round
      ..color = Color.lerp(
        AppColors.brandBlue,
        _VerifyArt._green,
        verified,
      )!.withValues(alpha: focus.clamp(0.0, 1.0));
    for (final (Offset c, double dx, double dy) in <(Offset, double, double)>[
      (r.topLeft, 1, 1),
      (r.topRight, -1, 1),
      (r.bottomLeft, 1, -1),
      (r.bottomRight, -1, -1),
    ]) {
      canvas.drawPath(
        Path()
          ..moveTo(c.dx, c.dy + arm * dy)
          ..lineTo(c.dx, c.dy)
          ..lineTo(c.dx + arm * dx, c.dy),
        p,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BracketsPainter oldDelegate) =>
      oldDelegate.focus != focus ||
      oldDelegate.verified != verified ||
      oldDelegate.scale != scale;
}

/// Green check that pops in with a spring as [progress] goes 0 → 1.
class _CheckBadge extends StatelessWidget {
  const _CheckBadge({required this.progress, required this.size});

  final double progress;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (progress <= 0) return SizedBox(width: size, height: size);
    return Transform.scale(
      scale: Curves.easeOutBack.transform(progress),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _VerifyArt._green,
          border: Border.all(color: Colors.white, width: 1.5),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: _VerifyArt._green.withValues(alpha: 0.5),
              blurRadius: 8,
            ),
          ],
        ),
        child: Icon(LucideIcons.check, size: size * 0.62, color: Colors.white),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.status,
    required this.done,
    required this.scale,
  });

  final String status;
  final bool done;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: EdgeInsets.symmetric(horizontal: 8 * scale, vertical: 4 * scale),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: done
                ? Icon(
                    LucideIcons.shieldCheck,
                    key: const ValueKey<bool>(true),
                    size: 11 * scale,
                    color: _VerifyArt._green,
                  )
                : SizedBox(
                    key: const ValueKey<bool>(false),
                    width: 9 * scale,
                    height: 9 * scale,
                    child: const CircularProgressIndicator(
                      strokeWidth: 1.6,
                      color: AppColors.brandBlue,
                    ),
                  ),
          ),
          SizedBox(width: 5 * scale),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            transitionBuilder: (Widget child, Animation<double> animation) =>
                FadeTransition(
                  opacity: animation,
                  child: SizeTransition(
                    sizeFactor: animation,
                    axis: Axis.horizontal,
                    child: child,
                  ),
                ),
            child: Text(
              status,
              key: ValueKey<String>(status),
              style: TextStyle(
                color: done ? _VerifyArt._green : AppColors.textPrimary,
                fontFamily: 'Inter',
                fontSize: 9 * scale,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Brand gradient with soft drifting blobs, flowing wave lines and a
/// twinkling sparkle, all on the shared clock.
class _BackdropPainter extends CustomPainter {
  _BackdropPainter({required this.clock, required this.scale})
    : super(repaint: clock);

  final Animation<double> clock;
  final double scale;

  @override
  void paint(Canvas canvas, Size size) {
    final double a = clock.value * 2 * math.pi;
    final Rect rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color(0xFF2341A8),
            AppColors.brandBlue,
            Color(0xFF12256A),
          ],
        ).createShader(rect),
    );

    void blob(Offset c, double r, Color color) => canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = RadialGradient(
          colors: <Color>[color, color.withValues(alpha: 0)],
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );

    blob(
      Offset(
        size.width * (0.72 + 0.04 * math.sin(a)),
        size.height * (0.25 + 0.08 * math.cos(a)),
      ),
      size.height * 0.85,
      const Color(0xFFA7E3DA).withValues(alpha: 0.32),
    );
    blob(
      Offset(
        size.width * (0.94 + 0.03 * math.cos(a)),
        size.height * (0.85 + 0.06 * math.sin(a)),
      ),
      size.height * 0.7,
      const Color(0xFFF1E6C8).withValues(alpha: 0.26),
    );
    blob(
      Offset(size.width * 0.05, size.height * (1.0 + 0.05 * math.sin(a))),
      size.height * 0.55,
      const Color(0xFF3B82F6).withValues(alpha: 0.28),
    );

    // Flowing wave lines across the lower right.
    final Paint line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (int i = 0; i < 6; i++) {
      line.color = Colors.white.withValues(alpha: 0.07 + i * 0.012);
      final Path path = Path();
      final double baseY = size.height * (0.6 + i * 0.07);
      for (double x = size.width * 0.35; x <= size.width; x += 4) {
        final double u = x / size.width;
        final double y =
            baseY + math.sin(u * 2 * math.pi * 1.2 + a + i * 0.35) * 8 * scale;
        if (x == size.width * 0.35) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      canvas.drawPath(path, line);
    }

    // Twinkling four-point sparkle.
    final double tw = (math.sin(a * 2) + 1) / 2;
    final Offset s = Offset(size.width * 0.52, size.height * 0.16);
    final double r = (3 + 3 * tw) * scale;
    canvas.drawPath(
      Path()
        ..moveTo(s.dx, s.dy - r * 1.6)
        ..quadraticBezierTo(s.dx, s.dy, s.dx + r, s.dy)
        ..quadraticBezierTo(s.dx, s.dy, s.dx, s.dy + r * 1.6)
        ..quadraticBezierTo(s.dx, s.dy, s.dx - r, s.dy)
        ..quadraticBezierTo(s.dx, s.dy, s.dx, s.dy - r * 1.6),
      Paint()..color = Colors.white.withValues(alpha: 0.35 + 0.45 * tw),
    );
  }

  @override
  bool shouldRepaint(covariant _BackdropPainter oldDelegate) =>
      oldDelegate.clock != clock || oldDelegate.scale != scale;
}

/// Gentle bob + sway, two bobs per clock loop.
class _Float extends StatelessWidget {
  const _Float({
    required this.t,
    required this.phase,
    required this.amplitude,
    required this.child,
    this.tilt = 0,
  });

  final double t;
  final double phase;
  final double amplitude;
  final double tilt;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final double a = (t * 2 + phase) * 2 * math.pi;
    return Transform.translate(
      offset: Offset(0, math.sin(a) * amplitude),
      child: Transform.rotate(angle: tilt + math.cos(a) * 0.03, child: child),
    );
  }
}

/// Entrance: scale up (with the interval's curve) and fade in.
class _EnterPop extends StatelessWidget {
  const _EnterPop({
    required this.enter,
    required this.interval,
    required this.child,
    this.from = 0.0,
  });

  final Animation<double> enter;
  final Curve interval;
  final double from;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final CurvedAnimation curved = CurvedAnimation(
      parent: enter,
      curve: interval,
    );
    return AnimatedBuilder(
      animation: curved,
      child: child,
      builder: (BuildContext context, Widget? child) {
        final double v = curved.value;
        return Opacity(
          opacity: v.clamp(0.0, 1.0),
          child: Transform.scale(scale: from + (1 - from) * v, child: child),
        );
      },
    );
  }
}

/// Entrance: slide in horizontally with a settling skew.
class _EnterSlide extends StatelessWidget {
  const _EnterSlide({
    required this.enter,
    required this.interval,
    required this.dx,
    required this.child,
  });

  final Animation<double> enter;
  final Curve interval;
  final double dx;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final CurvedAnimation curved = CurvedAnimation(
      parent: enter,
      curve: interval,
    );
    return AnimatedBuilder(
      animation: curved,
      child: child,
      builder: (BuildContext context, Widget? child) {
        final double v = curved.value;
        final double rest = 1 - v;
        return Opacity(
          opacity: v.clamp(0.0, 1.0),
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.translationValues(dx * rest, 0, 0)
              ..multiply(Matrix4.skewX(-0.3 * rest)),
            child: child,
          ),
        );
      },
    );
  }
}

/// Entrance: rise into place and fade in.
class _EnterRise extends StatelessWidget {
  const _EnterRise({
    required this.enter,
    required this.interval,
    required this.child,
  });

  final Animation<double> enter;
  final Interval interval;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final CurvedAnimation curved = CurvedAnimation(
      parent: enter,
      curve: Interval(interval.begin, interval.end, curve: Curves.easeOutCubic),
    );
    return AnimatedBuilder(
      animation: curved,
      child: child,
      builder: (BuildContext context, Widget? child) => Opacity(
        opacity: curved.value,
        child: Transform.translate(
          offset: Offset(0, 10 * (1 - curved.value)),
          child: child,
        ),
      ),
    );
  }
}

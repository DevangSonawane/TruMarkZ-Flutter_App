import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: Stack(
          children: <Widget>[
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: <Color>[AppColors.brandBlue, AppColors.deepNavy],
                  ),
                ),
              ),
            ),
            const Center(child: _SplashHero()),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.x8),
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 1800),
                  curve: Curves.easeOutCubic,
                  onEnd: _navigateOnce,
                  builder: (BuildContext context, double t, _) {
                    return SizedBox(
                      width: 120,
                      height: 2,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: FractionallySizedBox(
                            widthFactor: t,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(102),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateOnce() {
    if (_navigated || !mounted) return;
    _navigated = true;
    context.go(AppRouter.onboardingPath);
  }
}

class _SplashHero extends StatelessWidget {
  const _SplashHero();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Stack(
          alignment: Alignment.center,
          children: <Widget>[
            const _Ring(size: 168, alpha: 20)
                .animate(
                  onPlay: (AnimationController c) {
                    c.repeat(reverse: true, period: 2000.ms);
                  },
                )
                .scale(
                  begin: const Offset(1, 1),
                  end: const Offset(1.15, 1.15),
                ),
            const _Ring(size: 220, alpha: 13)
                .animate(
                  onPlay: (AnimationController c) {
                    c.repeat(reverse: true, period: 2000.ms);
                  },
                )
                .scale(
                  begin: const Offset(1, 1),
                  end: const Offset(1.15, 1.15),
                ),
            Image.asset(
                  'assets/icons/app_icon.png',
                  height: 72,
                  fit: BoxFit.contain,
                )
                .animate()
                .fadeIn(duration: 320.ms)
                .scale(
                  begin: const Offset(0.8, 0.8),
                  end: const Offset(1, 1),
                  curve: Curves.easeOutBack,
                  duration: 360.ms,
                )
                .then(delay: 400.ms)
                .shimmer(duration: 900.ms, color: Colors.white.withAlpha(140)),
          ],
        ),
        const SizedBox(height: AppSpacing.x4),
        Text(
          'TruMarkZ',
          style: AppTypography.display2.copyWith(
            color: Colors.white,
            fontSize: 34,
            fontWeight: FontWeight.w700,
          ),
        ).animate().fadeIn(delay: 80.ms, duration: 260.ms),
        const SizedBox(height: AppSpacing.x2),
        Text(
          'VERIFY • TRUST • TRANSFORM',
          textAlign: TextAlign.center,
          style: AppTypography.label.copyWith(
            color: Colors.white.withAlpha(200),
            letterSpacing: 2.2,
            fontWeight: FontWeight.w600,
          ),
        ).animate().fadeIn(delay: 140.ms, duration: 260.ms),
      ],
    );
  }
}

class _Ring extends StatelessWidget {
  const _Ring({required this.size, required this.alpha});

  final double size;
  final int alpha;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withAlpha(alpha), width: 2),
      ),
    );
  }
}

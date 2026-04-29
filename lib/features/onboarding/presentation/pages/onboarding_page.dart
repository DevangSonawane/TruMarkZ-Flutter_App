import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'dart:math' as math;

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _pageIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FF),
      body: SafeArea(
        child: Stack(
          children: <Widget>[
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, -0.45),
                    radius: 1.1,
                    colors: <Color>[
                      const Color(0xFFEAF1FF),
                      const Color(0xFFF3F6FF),
                      const Color(0xFFFFFFFF),
                    ],
                  ),
                ),
              ),
            ),
            Column(
              children: <Widget>[
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (int i) => setState(() => _pageIndex = i),
                    children: <Widget>[
                      _OnboardingHero(
                        badgeLabel: 'TRUMARKZ VERIFIED',
                        title: 'Verify Anyone.\nAnything.',
                        description:
                            'Secure, blockchain-backed credentials for\nworkers, products and services — all in one\nplace.',
                      ),
                      const _OnboardingHero(
                        badgeLabel: 'INSTANT CHECKS',
                        title: 'Scan & Verify\nin Seconds.',
                        description:
                            'Use QR scanning to validate credentials and\nsee proofs instantly.',
                      ),
                      const _OnboardingHero(
                        badgeLabel: 'TRUSTED NETWORK',
                        title: 'Built for\nTeams.',
                        description:
                            'Run bulk verification workflows and keep\ncompliance at 99.99%.',
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.x6,
                  AppSpacing.x6,
                  AppSpacing.x6,
                  AppSpacing.x6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(32),
                  ),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: Colors.black.withAlpha(10),
                      blurRadius: 24,
                      offset: const Offset(0, -6),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      _pageIndex == 0
                          ? 'Verify Anyone.\nAnything.'
                          : _pageIndex == 1
                              ? 'Scan & Verify\nin Seconds.'
                              : 'Built for\nTeams.',
                      textAlign: TextAlign.center,
                      style: AppTypography.display2.copyWith(
                        color: const Color(0xFF0B0F19),
                        fontSize: 30,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.x3),
                    Text(
                      _pageIndex == 0
                          ? 'Secure, blockchain-backed credentials for\nworkers, products and services — all in one\nplace.'
                          : _pageIndex == 1
                              ? 'Use QR scanning to validate credentials and\nsee proofs instantly.'
                              : 'Run bulk verification workflows and keep\ncompliance at 99.99%.',
                      textAlign: TextAlign.center,
                      style: AppTypography.body2.copyWith(
                        color: const Color(0xFF64748B),
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.x4),
                    _DotsIndicator(index: _pageIndex, count: 3),
                    const SizedBox(height: AppSpacing.x4),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.brandBlue,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(56),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          textStyle: AppTypography.button,
                        ),
                        onPressed: () => context.go(AppRouter.loginPath),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            const Text('Get Started'),
                            const SizedBox(width: 10),
                            const Icon(Icons.arrow_forward_rounded, size: 18),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.x4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Text(
                          'Already have an account? ',
                          style: AppTypography.body2.copyWith(
                            color: const Color(0xFF64748B),
                          ),
                        ),
                        InkWell(
                          onTap: () => context.go(AppRouter.loginPath),
                          child: Text(
                            'Sign In',
                            style: AppTypography.body2.copyWith(
                              color: scheme.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingHero extends StatelessWidget {
  const _OnboardingHero({
    required this.badgeLabel,
    required this.title,
    required this.description,
  });

  final String badgeLabel;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Column(
      children: <Widget>[
        const SizedBox(height: AppSpacing.x10),
        SizedBox(
          height: 240,
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  color: scheme.primary.withAlpha(16),
                  shape: BoxShape.circle,
                ),
              ),
              SvgPicture.asset(
                'assets/icons/trumarkz_shield.svg',
                height: 86,
                colorFilter: ColorFilter.mode(scheme.primary, BlendMode.srcIn),
              ).animate().fadeIn(duration: 250.ms).scale(
                    begin: const Offset(0.96, 0.96),
                    end: const Offset(1, 1),
                    duration: 250.ms,
                  ),
              Positioned(
                left: 28,
                child: const _FloatIcon(
                  icon: Icons.check_circle_rounded,
                  phase: 0.0,
                ),
              ),
              Positioned(
                top: 36,
                right: 108,
                child: const _FloatIcon(
                  icon: Icons.verified_rounded,
                  phase: 1.6,
                ),
              ),
              Positioned(
                right: 28,
                child: const _FloatIcon(
                  icon: Icons.lock_rounded,
                  phase: 3.2,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.x4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            color: scheme.primary.withAlpha(14),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: scheme.primary.withAlpha(22)),
          ),
          child: Text(
            badgeLabel,
            style: AppTypography.caption.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: 1.6,
              color: scheme.primary,
            ),
          ),
        ),
      ],
    );
  }
}

class _FloatIcon extends StatefulWidget {
  const _FloatIcon({
    required this.icon,
    required this.phase,
  });

  final IconData icon;
  final double phase;

  @override
  State<_FloatIcon> createState() => _FloatIconState();
}

class _FloatIconState extends State<_FloatIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    final Widget tile = Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withAlpha(12),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Icon(widget.icon, color: scheme.primary),
    );

    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, _) {
        final double t = _controller.value * (math.pi * 2) + widget.phase;
        final double dy = math.sin(t) * 6;
        final double dx = math.sin(t * 0.7) * 2;
        final double rot = math.sin(t * 0.35) * 0.04;
        return Transform.translate(
          offset: Offset(dx, dy),
          child: Transform.rotate(
            angle: rot,
            child: tile,
          ),
        );
      },
    );
  }
}

class _DotsIndicator extends StatelessWidget {
  const _DotsIndicator({required this.index, required this.count});

  final int index;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List<Widget>.generate(count, (int i) {
        final bool active = i == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: active ? 22 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: active ? AppColors.brandBlue : const Color(0xFFE2E8F0),
            borderRadius: BorderRadius.circular(999),
          ),
        );
      }),
    );
  }
}

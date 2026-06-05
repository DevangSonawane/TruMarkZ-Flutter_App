import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'dart:math' as math;

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/tmz_button.dart';

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
    final double systemBottomInset = MediaQuery.of(context).viewPadding.bottom;

    return Scaffold(
      backgroundColor: AppColors.deepNavy,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        child: SafeArea(
          top: false,
          bottom: false,
          child: Stack(
            children: <Widget>[
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: <Color>[AppColors.deepNavy, AppColors.brandBlue],
                    ),
                  ),
                ),
              ),
              Column(
                children: <Widget>[
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(bottom: 240 + systemBottomInset),
                      child: PageView(
                        controller: _pageController,
                        physics: const NeverScrollableScrollPhysics(),
                        onPageChanged: (int i) =>
                            setState(() => _pageIndex = i),
                        children: <Widget>[
                          _OnboardingHero(
                            badgeLabel: '',
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
                  ),
                ],
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child:
                    Container(
                          padding: EdgeInsets.fromLTRB(
                            AppSpacing.x6,
                            AppSpacing.x8,
                            AppSpacing.x6,
                            AppSpacing.x8 + systemBottomInset,
                          ),
                          constraints: const BoxConstraints(minHeight: 360),
                          decoration: BoxDecoration(
                            color: AppColors.cardSurface,
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
                              if (_pageIndex == 0)
                                RichText(
                                  textAlign: TextAlign.center,
                                  text: TextSpan(
                                    style: AppTypography.display2.copyWith(
                                      color: AppColors.textPrimary,
                                      fontSize: 30,
                                    ),
                                    children: <InlineSpan>[
                                      const TextSpan(text: 'Verify Anyone.\n'),
                                      TextSpan(
                                        text: 'Anything.',
                                        style: AppTypography.display2.copyWith(
                                          fontSize: 30,
                                          color: AppColors.brandBlue.withAlpha(
                                            190,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              else
                                Text(
                                  _pageIndex == 1
                                      ? 'Scan & Verify\nin Seconds.'
                                      : 'Built for\nTeams.',
                                  textAlign: TextAlign.center,
                                  style: AppTypography.display2.copyWith(
                                    color: AppColors.textPrimary,
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
                                  color: AppColors.textSecondary,
                                  height: 1.35,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.x4),
                              SizedBox(
                                width: double.infinity,
                                child: TMZButton(
                                  onPressed: () =>
                                      context.go(AppRouter.roleSelectionPath),
                                  label: 'Get Started',
                                ),
                              ),
                              const SizedBox(height: AppSpacing.x4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  Text(
                                    'Already have an account? ',
                                    style: AppTypography.body2.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () =>
                                        context.go(AppRouter.roleSelectionPath),
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
                        )
                        .animate()
                        .fadeIn(delay: 100.ms, duration: 220.ms)
                        .slideY(
                          begin: 0.04,
                          duration: 220.ms,
                          curve: Curves.easeOutCubic,
                        ),
              ),
            ],
          ),
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
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double availableHeight = constraints.maxHeight;
        return Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: <Widget>[
            Align(
              alignment: Alignment.center,
              child: Container(
                width: availableHeight * 0.3,
                height: availableHeight * 0.3,
                decoration: BoxDecoration(
                  color: scheme.primary.withAlpha(16),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Align(
              alignment: Alignment.center,
              child:
                  Image.asset(
                        'assets/onboadring/onboarding1.png',
                        height: availableHeight * 0.65,
                        fit: BoxFit.contain,
                      )
                      .animate()
                      .fadeIn(duration: 250.ms)
                      .scale(
                        begin: const Offset(0.96, 0.96),
                        end: const Offset(1, 1),
                        duration: 250.ms,
                      ),
            ),
            if (badgeLabel.trim().isNotEmpty)
              Positioned(
                bottom: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
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
              ),
          ],
        );
      },
    );
  }
}

class _FloatIcon extends StatefulWidget {
  const _FloatIcon({required this.icon, required this.phase});

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
          child: Transform.rotate(angle: rot, child: tile),
        );
      },
    );
  }
}

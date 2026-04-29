import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      context.go(AppRouter.onboardingPath);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
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
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: <Color>[
                      const Color(0xFF2B66FF),
                      AppColors.brandBlue,
                      const Color(0xFF1B4FD9),
                    ],
                  ),
                ),
              ),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  SvgPicture.asset(
                    'assets/icons/trumarkz_shield.svg',
                    height: 68,
                    colorFilter: const ColorFilter.mode(
                      Colors.white,
                      BlendMode.srcIn,
                    ),
                  ).animate().fadeIn(duration: 320.ms),
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/tmz_button.dart';
import '../../../../core/widgets/tmz_input.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: AppColors.pageBg,
      body: SafeArea(
        child: Stack(
          children: <Widget>[
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, -0.65),
                    radius: 1.2,
                    colors: <Color>[
                      AppColors.blueTint,
                      AppColors.pageBg,
                      AppColors.cardSurface,
                    ],
                  ),
                ),
              ),
            ),
            ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.x4,
                AppSpacing.x6,
                AppSpacing.x4,
                AppSpacing.x5,
              ),
              children: <Widget>[
                Center(
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.cardSurface,
                      shape: BoxShape.circle,
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: Colors.black.withAlpha(10),
                          blurRadius: 16,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: SvgPicture.asset(
                      'assets/icons/trumarkz_shield.svg',
                      height: 22,
                      colorFilter: const ColorFilter.mode(
                        AppColors.brandBlue,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ).animate().fadeIn(duration: 220.ms),
                const SizedBox(height: AppSpacing.x3),
                Text(
                  'TruMarkZ',
                  textAlign: TextAlign.center,
                  style: AppTypography.display2.copyWith(
                    fontSize: 30,
                    color: AppColors.textPrimary,
                  ),
                ).animate().fadeIn(delay: 40.ms, duration: 220.ms),
                const SizedBox(height: AppSpacing.x2),
                Text(
                  'THE STANDARD IN DIGITAL VERIFICATION',
                  textAlign: TextAlign.center,
                  style: AppTypography.label.copyWith(
                    color: AppColors.textSecondary,
                    letterSpacing: 1.4,
                  ),
                ).animate().fadeIn(delay: 80.ms, duration: 220.ms),
                const SizedBox(height: AppSpacing.x5),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.cardSurface,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: Colors.black.withAlpha(10),
                        blurRadius: 28,
                        offset: const Offset(0, 18),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(AppSpacing.x5),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Text(
                        'Welcome Back',
                        style: AppTypography.heading1.copyWith(fontSize: 18),
                      ),
                      const SizedBox(height: AppSpacing.x1),
                      Text(
                        'Sign in to your account',
                        style: AppTypography.body2.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.x5),
                      TMZInput(
                        label: 'Email',
                        hint: 'name@company.com',
                        keyboardType: TextInputType.emailAddress,
                        prefixIcon: Icons.mail_outline_rounded,
                      ),
                      const SizedBox(height: AppSpacing.x4),
                      Row(
                        children: <Widget>[
                          Text('Password', style: AppTypography.label),
                          const Spacer(),
                          TextButton(
                            onPressed: () {},
                            style: TextButton.styleFrom(
                              foregroundColor: scheme.primary,
                              padding: EdgeInsets.zero,
                            ),
                            child: const Text('Forgot Password?'),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.x2),
                      TMZInput(
                        label: '',
                        hint: '••••••••',
                        prefixIcon: Icons.lock_outline_rounded,
                        obscureText: true,
                      ),
                      const SizedBox(height: AppSpacing.x6),
                      TMZButton(
                        onPressed: () =>
                            context.go(AppRouter.roleSelectionPath),
                        label: 'Sign In',
                      ),
                      const SizedBox(height: AppSpacing.x6),
                      Row(
                        children: <Widget>[
                          Expanded(child: Divider(color: AppColors.divider)),
                          const SizedBox(width: AppSpacing.x3),
                          Text(
                            'or continue with',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.x3),
                          Expanded(child: Divider(color: AppColors.divider)),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.x4),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                          side: const BorderSide(color: AppColors.divider),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          foregroundColor: AppColors.textPrimary,
                        ),
                        onPressed: () {},
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Container(
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                color: AppColors.cardSurface,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: AppColors.divider),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'G',
                                style: AppTypography.caption.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Text('Sign in with Google'),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.x4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Text(
                            "Don't have an account? ",
                            style: AppTypography.body2.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          InkWell(
                            onTap: () => context.go(AppRouter.registerPath),
                            child: Text(
                              'Register',
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
                const SizedBox(height: AppSpacing.x6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Icon(
                          Icons.shield_outlined,
                          size: 14,
                          color: AppColors.textTertiary,
                        )
                        .animate(
                          onPlay: (AnimationController c) {
                            c.repeat(reverse: true, period: 900.ms);
                          },
                        )
                        .rotate(begin: -0.02, end: 0.02),
                    const SizedBox(width: AppSpacing.x2),
                    Flexible(
                      child: Text(
                        'SECURED BY TRUMARKZ IDENTITY PROTOCOL',
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.caption.copyWith(
                          letterSpacing: 1.3,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

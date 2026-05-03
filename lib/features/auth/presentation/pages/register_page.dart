import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/tmz_button.dart';
import '../../../../core/widgets/tmz_input.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final double systemBottomInset = MediaQuery.of(context).viewPadding.bottom;

    return Scaffold(
      backgroundColor: AppColors.pageBg,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.x6,
            AppSpacing.x8,
            AppSpacing.x6,
            AppSpacing.x6 + systemBottomInset,
          ),
          children: <Widget>[
            Center(
              child: Container(
                width: 64,
                height: 64,
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
                  height: 26,
                  colorFilter: const ColorFilter.mode(
                    AppColors.brandBlue,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.x4),
            Text(
              'TruMarkZ',
              textAlign: TextAlign.center,
              style: AppTypography.display2.copyWith(
                fontSize: 34,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.x2),
            Text(
              'CREATE YOUR ACCOUNT',
              textAlign: TextAlign.center,
              style: AppTypography.label.copyWith(
                color: AppColors.textSecondary,
                letterSpacing: 1.8,
              ),
            ),
            const SizedBox(height: AppSpacing.x6),
            Container(
              decoration: BoxDecoration(
                color: AppColors.cardSurface,
                borderRadius: BorderRadius.circular(26),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Colors.black.withAlpha(10),
                    blurRadius: 28,
                    offset: const Offset(0, 18),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(AppSpacing.x6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text('Create Account', style: AppTypography.heading1),
                  const SizedBox(height: AppSpacing.x1),
                  Text(
                    'Join the secure TruMarkZ network today.',
                    style: AppTypography.body2.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.x6),
                  TMZInput(
                    label: 'Full Name',
                    hint: 'John Doe',
                    prefixIcon: Icons.person_outline_rounded,
                  ),
                  const SizedBox(height: AppSpacing.x4),
                  TMZInput(
                    label: 'Email',
                    hint: 'name@company.com',
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: Icons.mail_outline_rounded,
                  ),
                  const SizedBox(height: AppSpacing.x4),
                  TMZInput(
                    label: 'Password',
                    hint: '••••••••',
                    prefixIcon: Icons.lock_outline_rounded,
                    obscureText: true,
                  ),
                  const SizedBox(height: AppSpacing.x6),
                  TMZButton(
                    onPressed: () => context.go(AppRouter.roleSelectionPath),
                    label: 'Register',
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
          ],
        ),
      ),
    );
  }
}

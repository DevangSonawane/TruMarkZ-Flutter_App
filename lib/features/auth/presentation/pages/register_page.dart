import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FF),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.x6,
            AppSpacing.x8,
            AppSpacing.x6,
            AppSpacing.x6,
          ),
          children: <Widget>[
            Center(
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.white,
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
                color: const Color(0xFF0B0F19),
              ),
            ),
            const SizedBox(height: AppSpacing.x2),
            Text(
              'CREATE YOUR ACCOUNT',
              textAlign: TextAlign.center,
              style: AppTypography.label.copyWith(
                color: const Color(0xFF64748B),
                letterSpacing: 1.8,
              ),
            ),
            const SizedBox(height: AppSpacing.x6),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
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
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.x6),
                  Text('Full Name', style: AppTypography.label),
                  const SizedBox(height: AppSpacing.x2),
                  TextField(
                    decoration: _inputDecoration(
                      hint: 'John Doe',
                      prefix: Icons.person_outline_rounded,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.x4),
                  Text('Email', style: AppTypography.label),
                  const SizedBox(height: AppSpacing.x2),
                  TextField(
                    keyboardType: TextInputType.emailAddress,
                    decoration: _inputDecoration(
                      hint: 'name@company.com',
                      prefix: Icons.mail_outline_rounded,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.x4),
                  Text('Password', style: AppTypography.label),
                  const SizedBox(height: AppSpacing.x2),
                  TextField(
                    obscureText: _obscure,
                    decoration: _inputDecoration(
                      hint: '••••••••',
                      prefix: Icons.lock_outline_rounded,
                      suffix: IconButton(
                        onPressed: () => setState(() => _obscure = !_obscure),
                        icon: Icon(
                          _obscure
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.x6),
                  SizedBox(
                    height: 56,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.brandBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        textStyle: AppTypography.button,
                      ),
                      onPressed: () => context.go(AppRouter.roleSelectionPath),
                      child: const Text('Register'),
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
          ],
        ),
      ),
    );
  }

  static InputDecoration _inputDecoration({
    required String hint,
    required IconData prefix,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(prefix),
      suffixIcon: suffix,
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.brandBlue, width: 1.5),
      ),
    );
  }
}


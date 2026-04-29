import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _obscure = true;

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
                    center: const Alignment(0, -0.65),
                    radius: 1.2,
                    colors: <Color>[
                      const Color(0xFFEAF1FF),
                      const Color(0xFFF3F6FF),
                      const Color(0xFFFFFFFF),
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
                      height: 22,
                      colorFilter: const ColorFilter.mode(
                        AppColors.brandBlue,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.x3),
                Text(
                  'TruMarkZ',
                  textAlign: TextAlign.center,
                  style: AppTypography.display2.copyWith(
                    fontSize: 30,
                    color: const Color(0xFF0B0F19),
                  ),
                ),
                const SizedBox(height: AppSpacing.x2),
                Text(
                  'THE STANDARD IN DIGITAL VERIFICATION',
                  textAlign: TextAlign.center,
                  style: AppTypography.label.copyWith(
                    color: const Color(0xFF64748B),
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(height: AppSpacing.x5),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
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
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.x5),
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
                        height: 52,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.brandBlue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            textStyle: AppTypography.button,
                          ),
                          onPressed: () => context.go(AppRouter.roleSelectionPath),
                          child: const Text('Sign In'),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.x6),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Divider(color: const Color(0xFFE2E8F0)),
                          ),
                          const SizedBox(width: AppSpacing.x3),
                          Text(
                            'or continue with',
                            style: AppTypography.caption.copyWith(
                              color: const Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.x3),
                          Expanded(
                            child: Divider(color: const Color(0xFFE2E8F0)),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.x4),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                          side: const BorderSide(color: Color(0xFFE2E8F0)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () {},
                        child: const Text('Sign in with Google'),
                      ),
                      const SizedBox(height: AppSpacing.x4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Text(
                            "Don't have an account? ",
                            style: AppTypography.body2.copyWith(
                              color: const Color(0xFF64748B),
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
                    const Icon(Icons.shield_outlined,
                        size: 14, color: Color(0xFF94A3B8)),
                    const SizedBox(width: AppSpacing.x2),
                    Flexible(
                      child: Text(
                        'SECURED BY TRUMARKZ IDENTITY PROTOCOL',
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.caption.copyWith(
                          letterSpacing: 1.3,
                          color: const Color(0xFF94A3B8),
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.brandBlue, width: 1.5),
      ),
    );
  }
}

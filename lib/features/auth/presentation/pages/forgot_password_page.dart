import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/tmz_button.dart';
import '../../../../core/widgets/tmz_input.dart';
import '../../data/auth_repository.dart';
import '../../../../core/network/api_client.dart';

class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _onSend() async {
    final String email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email or mobile.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ref.read(authRepositoryProvider).forgotPassword(email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('If this account exists, a reset link has been sent.'),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Something went wrong. Please try again.')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final double systemBottomInset = MediaQuery.of(context).viewPadding.bottom;

    return Scaffold(
      backgroundColor: AppColors.pageBg,
      body: SafeArea(
        bottom: false,
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
              padding: EdgeInsets.fromLTRB(
                AppSpacing.x4,
                AppSpacing.x6,
                AppSpacing.x4,
                AppSpacing.x5 + systemBottomInset,
              ),
              children: <Widget>[
                Row(
                  children: <Widget>[
                    IconButton(
                      onPressed: () => context.go(AppRouter.loginPath),
                      icon: const Icon(Icons.arrow_back_rounded),
                      color: scheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Forgot Password',
                      style: AppTypography.heading1.copyWith(fontSize: 18),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.x4),
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
                        'Reset your password',
                        style: AppTypography.heading1.copyWith(fontSize: 18),
                      ),
                      const SizedBox(height: AppSpacing.x1),
                      Text(
                        'Enter your email or mobile to receive a reset link/code.',
                        style: AppTypography.body2.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.x5),
                      TMZInput(
                        label: 'Email / Mobile',
                        hint: 'name@company.com',
                        keyboardType: TextInputType.emailAddress,
                        prefixIcon: Icons.mail_outline_rounded,
                        controller: _emailController,
                        enabled: !_isLoading,
                      ),
                      const SizedBox(height: AppSpacing.x6),
                      TMZButton(
                        onPressed: _isLoading ? null : _onSend,
                        label: 'Send Reset Link',
                        isLoading: _isLoading,
                      ),
                      const SizedBox(height: AppSpacing.x4),
                      TextButton(
                        onPressed: () => context.go(AppRouter.loginPath),
                        style: TextButton.styleFrom(
                          foregroundColor: scheme.primary,
                          padding: EdgeInsets.zero,
                        ),
                        child: const Text('Back to login'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}


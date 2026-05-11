import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/tmz_button.dart';
import '../../../../core/widgets/tmz_input.dart';
import '../../data/auth_repository.dart';

class ResetPasswordPage extends ConsumerStatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  ConsumerState<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends ConsumerState<ResetPasswordPage> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _onReset(String token) async {
    final String newPassword = _passwordController.text;
    final String confirm = _confirmController.text;

    if (newPassword.trim().length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 8 characters.')),
      );
      return;
    }
    if (newPassword != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ref
          .read(authRepositoryProvider)
          .resetPassword(token: token, newPassword: newPassword);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password reset successfully. Please log in.')),
      );
      context.go(AppRouter.loginPath);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
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
    final Map<String, String> qp = GoRouterState.of(context).uri.queryParameters;
    final String token = (qp['token'] ?? '').trim();
    final String loginType = (qp['type'] ?? '').trim();

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
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: _isLoading
                        ? null
                        : () => context.go(
                              loginType.isEmpty
                                  ? AppRouter.loginPath
                                  : '${AppRouter.loginPath}?type=${Uri.encodeComponent(loginType)}&force=true',
                            ),
                    icon: const Icon(Icons.arrow_back_rounded),
                    color: scheme.primary,
                  ),
                ),
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
                    child: Image.asset(
                      'assets/icons/headers_app_icon.png',
                      height: 26,
                      fit: BoxFit.contain,
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
                        'Reset Password',
                        style: AppTypography.heading1.copyWith(fontSize: 18),
                      ),
                      const SizedBox(height: AppSpacing.x1),
                      Text(
                        'Create a new password for your account.',
                        style: AppTypography.body2.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.x5),
                      TMZInput(
                        label: 'New Password',
                        hint: '••••••••',
                        prefixIcon: Icons.lock_outline_rounded,
                        obscureText: true,
                        controller: _passwordController,
                        enabled: !_isLoading,
                      ),
                      const SizedBox(height: AppSpacing.x4),
                      TMZInput(
                        label: 'Confirm Password',
                        hint: '••••••••',
                        prefixIcon: Icons.lock_outline_rounded,
                        obscureText: true,
                        controller: _confirmController,
                        enabled: !_isLoading,
                      ),
                      const SizedBox(height: AppSpacing.x6),
                      TMZButton(
                        onPressed: _isLoading || token.isEmpty ? null : () => _onReset(token),
                        label: 'Reset Password',
                        isLoading: _isLoading,
                      ),
                      if (token.isEmpty) ...<Widget>[
                        const SizedBox(height: AppSpacing.x3),
                        Text(
                          'Missing reset token. Please request a new reset link.',
                          textAlign: TextAlign.center,
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
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

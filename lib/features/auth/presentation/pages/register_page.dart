import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/models/auth_models.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/tmz_button.dart';
import '../../../../core/widgets/tmz_input.dart';
import '../../data/auth_repository.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _onRegister() async {
    final String fullName = _fullNameController.text.trim();
    final String email = _emailController.text.trim();
    final String address = _addressController.text.trim();
    final String password = _passwordController.text;

    if (fullName.isEmpty || email.isEmpty || address.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields.')),
      );
      return;
    }
    if (password.trim().length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 8 characters.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ref.read(authRepositoryProvider).registerIndividual(
            RegisterIndividualRequest(
              fullName: fullName,
              email: email,
              mobile: null,
              address: address,
              password: password,
            ),
          );
      if (!mounted) return;
      context.go(
        '${AppRouter.otpVerificationPath}?email=${Uri.encodeComponent(email)}&type=individual',
      );
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
                    controller: _fullNameController,
                    enabled: !_isLoading,
                  ),
                  const SizedBox(height: AppSpacing.x4),
                  TMZInput(
                    label: 'Email',
                    hint: 'name@company.com',
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: Icons.mail_outline_rounded,
                    controller: _emailController,
                    enabled: !_isLoading,
                  ),
                  const SizedBox(height: AppSpacing.x4),
                  TMZInput(
                    label: 'Address',
                    hint: 'Your full address',
                    prefixIcon: Icons.location_on_outlined,
                    controller: _addressController,
                    enabled: !_isLoading,
                  ),
                  const SizedBox(height: AppSpacing.x4),
                  TMZInput(
                    label: 'Password',
                    hint: '••••••••',
                    prefixIcon: Icons.lock_outline_rounded,
                    obscureText: true,
                    controller: _passwordController,
                    enabled: !_isLoading,
                  ),
                  const SizedBox(height: AppSpacing.x6),
                  TMZButton(
                    onPressed: _isLoading ? null : _onRegister,
                    label: 'Register',
                    isLoading: _isLoading,
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

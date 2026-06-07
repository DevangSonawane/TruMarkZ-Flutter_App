import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/services/google_sign_in_service.dart';
import '../../../../core/services/token_storage.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/tmz_button.dart';
import '../../../../core/widgets/tmz_input.dart';
import '../../application/auth_notifier.dart';
import '../../application/pending_auth.dart';
import '../../data/auth_repository.dart';
import '../../../../core/models/auth_models.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  bool _isLoading = false;
  bool _rememberMe = true;
  bool _isRegisterMode = false;

  String get _loginType {
    final String type =
        GoRouterState.of(context).uri.queryParameters['type']?.trim() ?? '';
    return type.toLowerCase() == 'organization' ? 'organization' : 'individual';
  }

  bool get _isOrg => _loginType == 'organization';

  Future<void> _onSignIn() async {
    final String emailOrMobile = _emailController.text.trim();
    final String password = _passwordController.text;

    if (emailOrMobile.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter email and password.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      if (kDebugMode) {
        debugPrint(
          '[Login] attempt type=$_loginType identifier=$emailOrMobile',
        );
      }

      if (_isOrg) {
        await ref
            .read(authNotifierProvider.notifier)
            .loginOrg(emailOrMobile, password);
      } else {
        await ref
            .read(authNotifierProvider.notifier)
            .loginIndividual(emailOrMobile, password);
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      final String msg = e.message.toLowerCase();
      final bool requiresOtp =
          (e.statusCode != 401) &&
          (msg.contains('not verified') ||
              msg.contains('verify your email') ||
              msg.contains('verify your otp') ||
              msg.contains('verify otp') ||
              msg.contains('registration already in progress') ||
              msg.contains('already in progress') ||
              (msg.contains('verify') && msg.contains('otp')));
      if (kDebugMode) {
        debugPrint(
          '[Login] ApiException status=${e.statusCode} message="${e.message}" requiresOtp=$requiresOtp',
        );
      }
      if (requiresOtp) {
        ref.read(pendingLoginProvider.notifier).state = PendingLogin(
          loginType: _loginType,
          emailOrMobile: emailOrMobile,
          password: password,
        );
        AppRouter.router.go(
          '${AppRouter.otpVerificationPath}?identifier=${Uri.encodeComponent(emailOrMobile)}&type=${Uri.encodeComponent(_loginType)}&after=login',
        );
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (_) {
      if (!mounted) return;
      if (kDebugMode) debugPrint('[Login] unknown error');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Something went wrong. Please try again.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    ({String? idToken, String? email}) googleResult = (idToken: null, email: null);

    setState(() => _isLoading = true);
    try {
      await ref.read(tokenStorageProvider).clearAll();

      googleResult = await GoogleSignInService.signIn();
      final String? idToken = googleResult.idToken;
      if (idToken == null || idToken.trim().isEmpty) {
        throw const ApiException(
          statusCode: null,
          message: 'Google sign-in was cancelled.',
        );
      }

      await ref.read(authNotifierProvider.notifier).loginWithGoogle(
            idToken: idToken,
            userType: _isOrg ? 'organization' : 'individual',
          );
    } on ApiException catch (e) {
      if (!mounted) return;
      final String msg = e.message.trim();
      if (msg.toLowerCase().contains('email already registered') &&
          msg.toLowerCase().contains('password')) {
        final String? email = googleResult.email;
        if (email != null && email.trim().isNotEmpty) {
          _emailController.text = email.trim();
        }
        messenger.showSnackBar(SnackBar(content: Text(msg)));
      } else {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              msg.isEmpty
                  ? 'Google sign-in failed. Please try again.'
                  : msg,
            ),
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Google sign-in failed. Please try again.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _fullNameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _setRegisterMode(bool value) {
    if (_isRegisterMode == value) return;
    setState(() => _isRegisterMode = value);
  }

  Future<void> _onRegister() async {
    final String fullName = _fullNameController.text.trim();
    final String email = _emailController.text.trim();
    final String address = _addressController.text.trim();
    final String password = _passwordController.text;

    final List<String> missing = <String>[
      if (fullName.isEmpty) 'Full Name',
      if (email.isEmpty) 'Email',
      if (password.isEmpty) 'Password',
    ];
    if (missing.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter: ${missing.join(', ')}.'),
        ),
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
              address: address.isEmpty ? null : address,
              password: password,
            ),
          );
      if (!mounted) return;
      context.go(
        '${AppRouter.otpVerificationPath}?email=${Uri.encodeComponent(email)}&type=individual',
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      final String msg = e.message.toLowerCase();
      final bool likelyOtpPending =
          msg.contains('already registered') ||
          msg.contains('already in progress') ||
          msg.contains('registration already') ||
          (msg.contains('verify') && msg.contains('otp'));
      if (likelyOtpPending) {
        context.go(
          '${AppRouter.otpVerificationPath}?email=${Uri.encodeComponent(email)}&type=individual',
        );
        return;
      }
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
    final double bottomInset = MediaQuery.of(context).viewPadding.bottom;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop) return;
        context.go(AppRouter.roleSelectionPath);
      },
      child: Scaffold(
        backgroundColor: AppColors.darkNavy,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: <Widget>[
              Expanded(
                flex: 1,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.x5,
                    AppSpacing.x3,
                    AppSpacing.x5,
                    AppSpacing.x4,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      IconButton(
                        onPressed: () =>
                            context.go(AppRouter.roleSelectionPath),
                        icon: const Icon(Icons.arrow_back_rounded),
                        color: Colors.white,
                        tooltip: 'Back',
                        padding: const EdgeInsets.all(4),
                        visualDensity: VisualDensity.compact,
                      ),
                      const SizedBox(height: AppSpacing.x2),
                      Text(
                        'Go ahead and set up\nyour account',
                        style: AppTypography.display1.copyWith(
                          fontSize: 30,
                          height: 1.15,
                          color: Colors.white,
                        ),
                      ).animate().fadeIn(duration: 220.ms),
                      const SizedBox(height: AppSpacing.x1),
                      Text(
                        'Sign in to continue with your account.',
                        style: AppTypography.body2.copyWith(
                          color: Colors.white.withAlpha(178),
                          height: 1.45,
                        ),
                      ).animate().fadeIn(delay: 40.ms, duration: 220.ms),
                    ],
                  ),
                ),
              ),
              Expanded(
                flex: _isRegisterMode ? 4 : 3,
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(
                    begin: _isRegisterMode ? -56 : 16,
                    end: _isRegisterMode ? -76 : 16,
                  ),
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOutCubic,
                  builder: (BuildContext context, double dy, Widget? child) {
                    return Transform.translate(
                      offset: Offset(0, dy),
                      child: child,
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(40),
                        topRight: Radius.circular(40),
                      ),
                    ),
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        AppSpacing.x5,
                        _isRegisterMode ? AppSpacing.x3 : AppSpacing.x2,
                        AppSpacing.x5,
                        AppSpacing.x3 + bottomInset,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          _AuthTabs(
                            isRegisterMode: _isRegisterMode,
                            onLogin: () => _setRegisterMode(false),
                            onRegister: () => _setRegisterMode(true),
                          ),
                          SizedBox(
                            height: _isRegisterMode ? AppSpacing.x3 : AppSpacing.x2,
                          ),
                          AnimatedSlide(
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeOutCubic,
                            offset: _isRegisterMode
                                ? const Offset(0, -0.03)
                                : Offset.zero,
                            child: AnimatedSize(
                              duration: const Duration(milliseconds: 220),
                              curve: Curves.easeOutCubic,
                              alignment: Alignment.topCenter,
                              child: _isRegisterMode
                                  ? _RegisterForm(
                                      isLoading: _isLoading,
                                      fullNameController: _fullNameController,
                                      emailController: _emailController,
                                      addressController: _addressController,
                                      passwordController: _passwordController,
                                      onSubmit: _onRegister,
                                    )
                                  : _LoginForm(
                                      isLoading: _isLoading,
                                      rememberMe: _rememberMe,
                                      onRememberMeChanged: () {
                                        setState(() {
                                          _rememberMe = !_rememberMe;
                                        });
                                      },
                                      emailController: _emailController,
                                      passwordController: _passwordController,
                                      onForgotPassword: () => context.go(
                                        AppRouter.forgotPasswordPath,
                                      ),
                                      onSubmit: _onSignIn,
                                      onGoogle: _signInWithGoogle,
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AuthTabs extends StatelessWidget {
  const _AuthTabs({
    required this.isRegisterMode,
    required this.onLogin,
    required this.onRegister,
  });

  final bool isRegisterMode;
  final VoidCallback onLogin;
  final VoidCallback onRegister;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: _AuthTabButton(
              label: 'Login',
              selected: !isRegisterMode,
              onTap: onLogin,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _AuthTabButton(
              label: 'Register',
              selected: isRegisterMode,
              onTap: onRegister,
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthTabButton extends StatelessWidget {
  const _AuthTabButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? Colors.white : Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            boxShadow: selected
                ? <BoxShadow>[
                    BoxShadow(
                      color: Colors.black.withAlpha(10),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : const <BoxShadow>[],
          ),
          child: Text(
            label,
            style: AppTypography.body2.copyWith(
              color: selected ? AppColors.textPrimary : AppColors.textTertiary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginForm extends StatelessWidget {
  const _LoginForm({
    required this.isLoading,
    required this.rememberMe,
    required this.onRememberMeChanged,
    required this.emailController,
    required this.passwordController,
    required this.onForgotPassword,
    required this.onSubmit,
    required this.onGoogle,
  });

  final bool isLoading;
  final bool rememberMe;
  final VoidCallback onRememberMeChanged;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final VoidCallback onForgotPassword;
  final VoidCallback onSubmit;
  final VoidCallback onGoogle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        TMZInput(
          label: 'Email Address',
          hint: 'Enter your email',
          keyboardType: TextInputType.emailAddress,
          prefixIcon: Icons.mail_outline_rounded,
          controller: emailController,
          enabled: !isLoading,
        ),
        const SizedBox(height: AppSpacing.x4),
        TMZInput(
          label: 'Password',
          hint: 'Enter your password',
          prefixIcon: Icons.lock_outline_rounded,
          obscureText: true,
          controller: passwordController,
          enabled: !isLoading,
        ),
        const SizedBox(height: AppSpacing.x4),
        Row(
          children: <Widget>[
            InkWell(
              onTap: isLoading ? null : onRememberMeChanged,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 4,
                  horizontal: 2,
                ),
                child: Row(
                  children: <Widget>[
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: rememberMe
                            ? AppColors.brandBlue
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: rememberMe
                              ? AppColors.brandBlue
                              : AppColors.border,
                          width: 1.2,
                        ),
                      ),
                      child: rememberMe
                          ? const Icon(
                              Icons.check_rounded,
                              size: 12,
                              color: Colors.white,
                            )
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Remember me',
                      style: AppTypography.body2.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: isLoading ? null : onForgotPassword,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textTertiary,
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Forgot Password?',
                style: AppTypography.body2.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.x5),
        TMZButton(
          onPressed: isLoading ? null : onSubmit,
          label: 'Sign In',
          isLoading: isLoading,
        ),
        const SizedBox(height: AppSpacing.x4),
        Row(
          children: <Widget>[
            const Expanded(child: Divider()),
            const SizedBox(width: AppSpacing.x3),
            Text(
              'Or continue with',
              style: AppTypography.body2.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: AppSpacing.x3),
            const Expanded(child: Divider()),
          ],
        ),
        const SizedBox(height: AppSpacing.x8),
        OutlinedButton(
          onPressed: isLoading ? null : onGoogle,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            side: const BorderSide(
              color: AppColors.border,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
            ),
            foregroundColor: AppColors.textPrimary,
            backgroundColor: Colors.white,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              SvgPicture.asset(
                'assets/icons/google-icon-logo-svgrepo-com.svg',
                width: 18,
                height: 18,
              ),
              const SizedBox(width: 10),
              const Text('Google'),
            ],
          ),
        ),
      ],
    );
  }
}

class _RegisterForm extends StatelessWidget {
  const _RegisterForm({
    required this.isLoading,
    required this.fullNameController,
    required this.emailController,
    required this.addressController,
    required this.passwordController,
    required this.onSubmit,
  });

  final bool isLoading;
  final TextEditingController fullNameController;
  final TextEditingController emailController;
  final TextEditingController addressController;
  final TextEditingController passwordController;
  final Future<void> Function() onSubmit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        TMZInput(
          label: 'Full Name',
          hint: 'John Doe',
          prefixIcon: Icons.person_outline_rounded,
          controller: fullNameController,
          enabled: !isLoading,
        ),
        const SizedBox(height: AppSpacing.x4),
        TMZInput(
          label: 'Email',
          hint: 'name@company.com',
          keyboardType: TextInputType.emailAddress,
          prefixIcon: Icons.mail_outline_rounded,
          controller: emailController,
          enabled: !isLoading,
        ),
        const SizedBox(height: AppSpacing.x4),
        TMZInput(
          label: 'Address (optional)',
          hint: 'Your full address',
          prefixIcon: Icons.location_on_outlined,
          controller: addressController,
          enabled: !isLoading,
        ),
        const SizedBox(height: AppSpacing.x4),
        TMZInput(
          label: 'Password',
          hint: '••••••••',
          prefixIcon: Icons.lock_outline_rounded,
          obscureText: true,
          controller: passwordController,
          enabled: !isLoading,
        ),
        const SizedBox(height: AppSpacing.x6),
        TMZButton(
          onPressed: isLoading ? null : onSubmit,
          label: 'Register',
          isLoading: isLoading,
        ),
        const SizedBox(height: AppSpacing.x3),
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
              onTap: () => context.go(
                '${AppRouter.loginPath}?type=individual&force=true',
              ),
              child: Text(
                'Sign In',
                style: AppTypography.body2.copyWith(
                  color: AppColors.brandBlue,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

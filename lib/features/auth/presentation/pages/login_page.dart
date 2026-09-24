import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/services/google_sign_in_service.dart';
import '../../../../core/services/token_storage.dart';
import '../../../../core/widgets/tmz_button.dart';
import '../../application/auth_notifier.dart';
import '../../application/pending_auth.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  String? _explicitLoginType() {
    final String? type = GoRouterState.of(context).uri.queryParameters['type'];
    final String normalized = (type ?? '').trim().toLowerCase();
    if (normalized == 'organization' || normalized == 'individual') {
      return normalized;
    }
    return null;
  }

  bool _shouldRetryWithOtherType(ApiException error) {
    final int? statusCode = error.statusCode;
    final String message = error.message.toLowerCase();

    return statusCode == 401 ||
        statusCode == 403 ||
        statusCode == 404 ||
        message.contains('invalid credentials') ||
        message.contains('not found') ||
        message.contains('account type') ||
        message.contains('user type') ||
        message.contains('login type');
  }

  Future<void> _loginWithType(
    String type,
    String emailOrMobile,
    String password,
  ) async {
    if (type == 'organization') {
      await ref
          .read(authNotifierProvider.notifier)
          .loginOrg(emailOrMobile, password);
      return;
    }

    await ref
        .read(authNotifierProvider.notifier)
        .loginIndividual(emailOrMobile, password);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

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
      final String? explicitType = _explicitLoginType();
      final String type = explicitType ?? 'individual';
      if (kDebugMode) {
        debugPrint(
          '[Login] attempt type=${explicitType ?? 'auto'} identifier=$emailOrMobile',
        );
      }
      await _loginWithType(type, emailOrMobile, password);
    } on ApiException catch (e) {
      final String? explicitType = _explicitLoginType();
      if (explicitType == null && _shouldRetryWithOtherType(e)) {
        try {
          if (kDebugMode) {
            debugPrint(
              '[Login] retry type=organization identifier=$emailOrMobile',
            );
          }
          await _loginWithType('organization', emailOrMobile, password);
          return;
        } on ApiException catch (retryError) {
          if (!mounted) return;
          await _handleLoginError(retryError, emailOrMobile);
          return;
        }
      }
      if (!mounted) return;
      await _handleLoginError(e, emailOrMobile);
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

  Future<void> _handleLoginError(ApiException e, String emailOrMobile) async {
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
      final String type = _explicitLoginType() ?? 'individual';
      ref.read(pendingLoginProvider.notifier).state = PendingLogin(
        loginType: type,
        emailOrMobile: emailOrMobile,
        password: _passwordController.text,
      );
      AppRouter.router.go(
        '${AppRouter.otpVerificationPath}?identifier=${Uri.encodeComponent(emailOrMobile)}&type=${Uri.encodeComponent(type)}&after=login',
      );
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(e.message)));
  }

  @override
  Widget build(BuildContext context) {
    final double systemBottomInset = MediaQuery.of(context).viewPadding.bottom;
    final String? explicitType = _explicitLoginType();
    final String type = explicitType ?? 'individual';
    final bool isOrg = type == 'organization';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop) return;
        context.go(AppRouter.onboardingPath);
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          bottom: false,
          child: Stack(
            children: <Widget>[
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(color: Colors.white),
                ),
              ),
              LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  return SingleChildScrollView(
                    padding: EdgeInsets.only(bottom: systemBottomInset),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 360),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(
                              AppSpacing.x8,
                              AppSpacing.x2,
                              AppSpacing.x8,
                              AppSpacing.x5,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: <Widget>[
                                Center(
                                  child: Image.asset(
                                    'assets/icons/headers_app_icon.png',
                                    height: 64,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.x5),
                                Text(
                                  'Welcome Back',
                                  textAlign: TextAlign.center,
                                  style: AppTypography.heading1.copyWith(
                                    fontSize: 24,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.x2),
                                Text(
                                  'Sign in to start your verification',
                                  textAlign: TextAlign.center,
                                  style: AppTypography.body2.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.x8),
                                _LoginTextField(
                                  label: 'Email',
                                  keyboardType: TextInputType.emailAddress,
                                  prefixIcon: Icons.mail_outline_rounded,
                                  controller: _emailController,
                                  enabled: !_isLoading,
                                ),
                                const SizedBox(height: AppSpacing.x4),
                                _LoginTextField(
                                  label: 'Password',
                                  prefixIcon: Icons.lock_outline_rounded,
                                  obscureText: true,
                                  controller: _passwordController,
                                  enabled: !_isLoading,
                                ),
                                const SizedBox(height: AppSpacing.x2),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: _isLoading
                                        ? null
                                        : () => context.go(
                                            AppRouter.forgotPasswordPath,
                                          ),
                                    style: TextButton.styleFrom(
                                      foregroundColor: const Color(0xFF1B3387),
                                      padding: EdgeInsets.zero,
                                      minimumSize: Size.zero,
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: Text(
                                      'Forgot Password?',
                                      style: AppTypography.caption.copyWith(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF1B3387),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.x6),
                                TMZButton(
                                  onPressed: _isLoading ? null : _onSignIn,
                                  label: 'Sign In',
                                  isLoading: _isLoading,
                                  borderRadius: 999,
                                  backgroundColor: const Color(0xFF1B3387),
                                  showShadow: false,
                                ),
                                const SizedBox(height: AppSpacing.x5),
                                Row(
                                  children: <Widget>[
                                    Expanded(
                                      child: Divider(color: AppColors.divider),
                                    ),
                                    const SizedBox(width: AppSpacing.x3),
                                    Text(
                                      'or',
                                      style: AppTypography.caption.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.x3),
                                    Expanded(
                                      child: Divider(color: AppColors.divider),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.x4),
                                OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    minimumSize: const Size.fromHeight(52),
                                    side: const BorderSide(
                                      color: AppColors.divider,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    backgroundColor: Colors.white.withAlpha(
                                      170,
                                    ),
                                    foregroundColor: AppColors.textPrimary,
                                  ),
                                  onPressed: _isLoading
                                      ? null
                                      : () async {
                                          final ScaffoldMessengerState
                                          messenger = ScaffoldMessenger.of(
                                            context,
                                          );
                                          ({String? idToken, String? email})
                                          googleResult = (
                                            idToken: null,
                                            email: null,
                                          );
                                          setState(() => _isLoading = true);
                                          try {
                                            // If the user was previously logged in (e.g. as an individual),
                                            // clear local session before starting a new org auth flow.
                                            await ref
                                                .read(tokenStorageProvider)
                                                .clearAll();

                                            googleResult =
                                                await GoogleSignInService.signIn();
                                            final String? idToken =
                                                googleResult.idToken;
                                            if (idToken == null ||
                                                idToken.trim().isEmpty) {
                                              throw const ApiException(
                                                statusCode: null,
                                                message:
                                                    'Google sign-in was cancelled.',
                                              );
                                            }
                                            await ref
                                                .read(
                                                  authNotifierProvider.notifier,
                                                )
                                                .loginWithGoogle(
                                                  idToken: idToken,
                                                  userType: isOrg
                                                      ? 'organization'
                                                      : 'individual',
                                                );
                                          } on ApiException catch (e) {
                                            if (!mounted) return;
                                            final String msg = e.message.trim();
                                            if (msg.toLowerCase().contains(
                                                  'email already registered',
                                                ) &&
                                                msg.toLowerCase().contains(
                                                  'password',
                                                )) {
                                              final String? email =
                                                  googleResult.email;
                                              if (email != null &&
                                                  email.trim().isNotEmpty) {
                                                _emailController.text = email
                                                    .trim();
                                              }
                                              messenger.showSnackBar(
                                                SnackBar(content: Text(msg)),
                                              );
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
                                                content: Text(
                                                  'Google sign-in failed. Please try again.',
                                                ),
                                              ),
                                            );
                                          } finally {
                                            if (mounted) {
                                              setState(
                                                () => _isLoading = false,
                                              );
                                            }
                                          }
                                        },
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: <Widget>[
                                      SvgPicture.asset(
                                        'assets/icons/google-icon-logo-svgrepo-com.svg',
                                        width: 18,
                                        height: 18,
                                      ),
                                      const SizedBox(width: 10),
                                      const Text('Sign in with Google'),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.x5),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    Text(
                                      isOrg
                                          ? "Don't have an org account? "
                                          : "Don't have an account? ",
                                      style: AppTypography.body2.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    InkWell(
                                      onTap: () => context.go(
                                        isOrg
                                            ? AppRouter
                                                  .organisationRegistrationPath
                                            : '${AppRouter.registerPath}?force=true',
                                      ),
                                      child: Text(
                                        'Register',
                                        style: AppTypography.body2.copyWith(
                                          color: const Color(0xFF1B3387),
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoginTextField extends StatefulWidget {
  const _LoginTextField({
    required this.label,
    required this.controller,
    this.keyboardType,
    this.prefixIcon,
    this.obscureText = false,
    this.enabled = true,
  });

  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final IconData? prefixIcon;
  final bool obscureText;
  final bool enabled;

  @override
  State<_LoginTextField> createState() => _LoginTextFieldState();
}

class _LoginTextFieldState extends State<_LoginTextField> {
  late final FocusNode _focusNode;
  bool _focused = false;
  bool _obscure = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode()..addListener(_handleFocusChange);
    _obscure = widget.obscureText;
  }

  @override
  void didUpdateWidget(_LoginTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.obscureText != widget.obscureText) {
      _obscure = widget.obscureText;
    }
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_handleFocusChange)
      ..dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    if (_focused == _focusNode.hasFocus) return;
    setState(() => _focused = _focusNode.hasFocus);
  }

  @override
  Widget build(BuildContext context) {
    final Color borderColor = _focused
        ? AppColors.brandBlue.withAlpha(178)
        : AppColors.border.withAlpha(145);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: AppColors.offWhite,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: const <BoxShadow>[],
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 38),
        child: Row(
          children: <Widget>[
            if (widget.prefixIcon != null) ...<Widget>[
              const SizedBox(width: 14),
              Icon(
                widget.prefixIcon,
                size: 15,
                color: _focused ? AppColors.brandBlue : AppColors.textTertiary,
              ),
            ],
            Expanded(
              child: TextField(
                focusNode: _focusNode,
                enabled: widget.enabled,
                controller: widget.controller,
                keyboardType: widget.keyboardType,
                obscureText: _obscure,
                style: AppTypography.body2.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  labelText: widget.label,
                  labelStyle: AppTypography.caption.copyWith(
                    color: _focused
                        ? AppColors.brandBlue
                        : AppColors.textTertiary,
                    fontWeight: FontWeight.w600,
                  ),
                  floatingLabelStyle: AppTypography.caption.copyWith(
                    color: AppColors.brandBlue,
                    fontWeight: FontWeight.w700,
                  ),
                  filled: false,
                  fillColor: Colors.transparent,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.fromLTRB(
                    widget.prefixIcon == null ? 16 : 10,
                    7,
                    6,
                    7,
                  ),
                ),
              ),
            ),
            if (widget.obscureText) ...<Widget>[
              IconButton(
                onPressed: widget.enabled
                    ? () => setState(() => _obscure = !_obscure)
                    : null,
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: Icon(
                  _obscure
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 16,
                ),
                color: AppColors.textTertiary,
                splashRadius: 16,
              ),
              const SizedBox(width: 10),
            ],
          ],
        ),
      ),
    );
  }
}

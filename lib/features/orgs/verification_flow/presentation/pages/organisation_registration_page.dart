import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../../../../../core/router/app_router.dart';
import '../../../../../core/models/auth_models.dart';
import '../../../../../core/network/api_client.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/widgets/tmz_button.dart';
import '../../../../auth/data/auth_repository.dart';
import '../../../onboarding/presentation/pages/org_onboarding_page.dart';

class OrganisationRegistrationPage extends ConsumerStatefulWidget {
  const OrganisationRegistrationPage({super.key});

  @override
  ConsumerState<OrganisationRegistrationPage> createState() =>
      _OrganisationRegistrationPageState();
}

class _OrganisationRegistrationPageState
    extends ConsumerState<OrganisationRegistrationPage> {
  bool _otpSent = false;
  bool _isSendingOtp = false;

  final TextEditingController _officialEmail = TextEditingController();
  final TextEditingController _password = TextEditingController();

  bool _looksLikeEmail(String value) {
    final String v = value.trim();
    if (!v.contains('@')) return false;
    final int at = v.indexOf('@');
    if (at <= 0 || at == v.length - 1) return false;
    return v.substring(at + 1).contains('.');
  }

  Future<void> _sendOtp() async {
    final String officialEmail = _officialEmail.text.trim();
    final String password = _password.text;

    if (officialEmail.isEmpty || !_looksLikeEmail(officialEmail)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email address.')),
      );
      return;
    }
    if (password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your password.')),
      );
      return;
    }
    if (password.trim().length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password must be at least 8 characters.'),
        ),
      );
      return;
    }

    setState(() => _isSendingOtp = true);
    try {
      final String orgName = officialEmail.split('@').first.trim().isEmpty
          ? officialEmail
          : officialEmail.split('@').first.trim();
      final SignupOrganizationRequest request = SignupOrganizationRequest(
        orgName: orgName,
        email: officialEmail,
        phoneNumber: '',
        password: password,
        serviceType: 'human',
      );

      await ref.read(authRepositoryProvider).signupOrganization(request);
      if (!mounted) return;
      setState(() => _otpSent = true);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('OTP sent to your email')));
      unawaited(_showOtpSentPopup());
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Something went wrong. Please try again.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSendingOtp = false);
    }
  }

  Future<void> _showOtpSentPopup() async {
    if (!mounted) return;

    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'OTP Sent',
      barrierColor: Colors.black.withAlpha(90),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder:
          (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
          ) {
            return Center(
              child: Material(
                color: Colors.transparent,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
                  decoration: BoxDecoration(
                    color: AppColors.cardSurface,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: Colors.black.withAlpha(18),
                        blurRadius: 24,
                        offset: const Offset(0, 14),
                      ),
                    ],
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.blueTint,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.mark_email_read_outlined,
                          color: AppColors.brandBlue,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              'OTP sent',
                              style: AppTypography.heading2.copyWith(
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Check your email for the code.',
                              style: AppTypography.body2.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
      transitionBuilder:
          (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
            Widget child,
          ) {
            final CurvedAnimation curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            );
            return FadeTransition(
              opacity: curved,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.96, end: 1).animate(curved),
                child: child,
              ),
            );
          },
    );

    // Auto-dismiss.
    unawaited(
      Future<void>.delayed(const Duration(seconds: 2), () {
        if (!mounted) return;
        final NavigatorState navigator = Navigator.of(context);
        if (navigator.canPop()) navigator.pop();
      }),
    );
  }

  @override
  void dispose() {
    _officialEmail.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double systemBottomInset = MediaQuery.of(context).viewPadding.bottom;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          onPressed: () => context.go(AppRouter.onboardingPath),
          icon: const Icon(LucideIcons.chevronLeft),
        ),
      ),
      body: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          return SingleChildScrollView(
            padding: EdgeInsets.only(bottom: systemBottomInset),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
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
                          'Register now',
                          textAlign: TextAlign.center,
                          style: AppTypography.heading1.copyWith(
                            fontSize: 20,
                            color: const Color(0xFF0B0F19),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.x2),
                        Text(
                          'Register to start your verification',
                          textAlign: TextAlign.center,
                          style: AppTypography.body2.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.x8),
                        _OrgTextField(
                          label: 'Email',
                          keyboardType: TextInputType.emailAddress,
                          prefixIcon: Icons.mail_outline_rounded,
                          controller: _officialEmail,
                          enabled: !_isSendingOtp,
                        ),
                        const SizedBox(height: AppSpacing.x5),
                        _OrgTextField(
                          label: 'Password',
                          prefixIcon: Icons.lock_outline_rounded,
                          obscureText: true,
                          controller: _password,
                          enabled: !_isSendingOtp,
                        ),
                        const SizedBox(height: AppSpacing.x6),
                        TMZButton(
                          label: _otpSent ? 'Continue' : 'Send OTP',
                          isLoading: _isSendingOtp,
                          borderRadius: 999,
                          backgroundColor: const Color(0xFF1B3387),
                          showShadow: false,
                          onPressed: _isSendingOtp
                              ? null
                              : () async {
                                  if (!_otpSent) {
                                    await _sendOtp();
                                    return;
                                  }
                                  if (!context.mounted) return;
                                  context.go(
                                    '${AppRouter.otpVerificationPath}?email=${Uri.encodeComponent(_officialEmail.text.trim())}&type=organization&after=register',
                                  );
                                },
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
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.x6,
            AppSpacing.x2,
            AppSpacing.x6,
            AppSpacing.x6,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              OutlinedButton(
                onPressed: () {
                  final String email = _officialEmail.text.trim().isEmpty
                      ? 'test@org.com'
                      : _officialEmail.text.trim();
                  context.go(
                    '${AppRouter.otpVerificationPath}?email=${Uri.encodeComponent(email)}&type=organization&after=register',
                  );
                },
                child: const Text('OTP (test)'),
              ),
              const SizedBox(height: AppSpacing.x3),
              OutlinedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const OrgOnboardingPage(),
                    ),
                  );
                },
                child: const Text('Onboarding (test)'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrgTextField extends StatefulWidget {
  const _OrgTextField({
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
  State<_OrgTextField> createState() => _OrgTextFieldState();
}

class _OrgTextFieldState extends State<_OrgTextField> {
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
  void didUpdateWidget(_OrgTextField oldWidget) {
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
        color: Colors.white,
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

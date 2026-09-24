import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/models/auth_models.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/tmz_button.dart';
import '../../data/auth_repository.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _onRegister() async {
    final String fullName = _fullNameController.text.trim();
    final String email = _emailController.text.trim();
    final String password = _passwordController.text;

    final List<String> missing = <String>[
      if (fullName.isEmpty) 'Full Name',
      if (email.isEmpty) 'Email',
      if (password.isEmpty) 'Password',
    ];
    if (missing.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter: ${missing.join(', ')}.')),
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

    setState(() => _isLoading = true);
    try {
      await ref
          .read(authRepositoryProvider)
          .registerIndividual(
            RegisterIndividualRequest(
              fullName: fullName,
              email: email,
              mobile: null,
              address: null,
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
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final double systemBottomInset = MediaQuery.of(context).viewPadding.bottom;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
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
                            'Create Account',
                            textAlign: TextAlign.center,
                            style: AppTypography.heading1.copyWith(
                              fontSize: 24,
                              color: AppColors.textPrimary,
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
                          _RegisterTextField(
                            label: 'Full Name',
                            prefixIcon: Icons.person_outline_rounded,
                            controller: _fullNameController,
                            enabled: !_isLoading,
                          ),
                          const SizedBox(height: AppSpacing.x5),
                          _RegisterTextField(
                            label: 'Email',
                            keyboardType: TextInputType.emailAddress,
                            prefixIcon: Icons.mail_outline_rounded,
                            controller: _emailController,
                            enabled: !_isLoading,
                          ),
                          const SizedBox(height: AppSpacing.x5),
                          _RegisterTextField(
                            label: 'Password',
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
                            borderRadius: 999,
                            backgroundColor: const Color(0xFF1B3387),
                            showShadow: false,
                          ),
                          const SizedBox(height: AppSpacing.x5),
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
      ),
    );
  }
}

class _RegisterTextField extends StatefulWidget {
  const _RegisterTextField({
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
  State<_RegisterTextField> createState() => _RegisterTextFieldState();
}

class _RegisterTextFieldState extends State<_RegisterTextField> {
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
  void didUpdateWidget(_RegisterTextField oldWidget) {
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

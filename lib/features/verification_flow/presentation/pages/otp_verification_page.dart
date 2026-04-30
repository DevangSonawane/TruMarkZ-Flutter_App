import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

class _OtpTokens {
  static const int otpLength = 6;

  static const Color pageBackground = Color(0xFFF0F4FF);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color otpFill = Color(0xFFF8FAFF);
  static const Color otpBorder = Color(0xFFE2E8F0);

  static const Color mutedText = Color(0xFF94A3B8);
  static const Color bodyText = Color(0xFF475569);
  static const Color titleText = Color(0xFF0F172A);
  static const Color outlineText = Color(0xFF737686);
  static const Color pillBackground = Color(0xFFEEF3FF);
}

class OtpVerificationPage extends StatefulWidget {
  const OtpVerificationPage({super.key});

  @override
  State<OtpVerificationPage> createState() => _OtpVerificationPageState();
}

class _OtpVerificationPageState extends State<OtpVerificationPage> {
  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _nodes;

  bool _isComplete = false;
  int _secondsLeft = 48;

  @override
  void initState() {
    super.initState();
    _controllers = List<TextEditingController>.generate(
      _OtpTokens.otpLength,
      (_) => TextEditingController(),
    );
    _nodes = List<FocusNode>.generate(_OtpTokens.otpLength, (_) => FocusNode());
    for (final TextEditingController controller in _controllers) {
      controller.addListener(_recomputeComplete);
    }
    _tickCountdown();
  }

  @override
  void dispose() {
    for (final TextEditingController controller in _controllers) {
      controller
        ..removeListener(_recomputeComplete)
        ..dispose();
    }
    for (final FocusNode node in _nodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _recomputeComplete() {
    final bool complete = _controllers.every(
      (TextEditingController c) => c.text.trim().length == 1,
    );
    if (complete == _isComplete) return;
    setState(() => _isComplete = complete);
  }

  Future<void> _tickCountdown() async {
    while (mounted && _secondsLeft > 0) {
      await Future<void>.delayed(const Duration(seconds: 1));
      if (!mounted) return;
      setState(() => _secondsLeft -= 1);
    }
  }

  void _resend() {
    setState(() => _secondsLeft = 48);
    _tickCountdown();
  }

  void _handleDigitChanged(int index, String value) {
    if (value.isNotEmpty) {
      if (index < _OtpTokens.otpLength - 1) {
        FocusScope.of(context).nextFocus();
      } else {
        FocusScope.of(context).unfocus();
      }
      return;
    }
    if (index > 0) FocusScope.of(context).previousFocus();
  }

  void _onVerify() {
    final Map<String, String> qp = Map<String, String>.from(
      GoRouterState.of(context).uri.queryParameters,
    );
    qp.putIfAbsent('status', () => 'waiting');
    final String qs = qp.entries
        .map(
          (MapEntry<String, String> e) =>
              '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}',
        )
        .join('&');
    context.go(
      qs.isEmpty
          ? AppRouter.pendingApprovalPath
          : '${AppRouter.pendingApprovalPath}?$qs',
    );
  }

  @override
  Widget build(BuildContext context) {
    final String email =
        GoRouterState.of(
              context,
            ).uri.queryParameters['email']?.trim().isNotEmpty ==
            true
        ? GoRouterState.of(context).uri.queryParameters['email']!.trim()
        : 'admin@org.com';
    final String displayEmail = _maskEmail(email);

    return Scaffold(
      backgroundColor: _OtpTokens.pageBackground,
      body: SafeArea(
        child: Stack(
          children: <Widget>[
            const Positioned.fill(child: _OtpBackground()),
            Positioned.fill(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.x5,
                  AppSpacing.x10,
                  AppSpacing.x5,
                  96,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 448),
                        child: Container(
                          padding: const EdgeInsets.all(40),
                          decoration: BoxDecoration(
                            color: _OtpTokens.cardBackground,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: <BoxShadow>[
                              BoxShadow(
                                color: AppColors.brandBlue.withAlpha(20),
                                blurRadius: 12,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            children: <Widget>[
                              Container(
                                width: 72,
                                height: 72,
                                decoration: const BoxDecoration(
                                  color: _OtpTokens.pillBackground,
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: const Icon(
                                  Icons.mail_rounded,
                                  size: 32,
                                  color: AppColors.brandBlue,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.x6),
                              Text(
                                'Verify your Email',
                                style: AppTypography.display2.copyWith(
                                  color: _OtpTokens.titleText,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: AppSpacing.x2),
                              Text(
                                'We sent a 6-digit OTP to $displayEmail',
                                style: AppTypography.body2.copyWith(
                                  color: _OtpTokens.bodyText,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 32),
                              _OtpInputRow(
                                controllers: _controllers,
                                nodes: _nodes,
                                onChanged: _handleDigitChanged,
                              ),
                              const SizedBox(height: AppSpacing.x6),
                              SizedBox(
                                width: double.infinity,
                                child: Column(
                                  children: <Widget>[
                                    Text(
                                      _secondsLeft > 0
                                          ? 'Resend code in 00:${_secondsLeft.toString().padLeft(2, '0')}'
                                          : 'Didn’t get a code?',
                                      style: AppTypography.body2.copyWith(
                                        color: _OtpTokens.mutedText,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    if (_secondsLeft == 0)
                                      TextButton(
                                        onPressed: _resend,
                                        child: Text(
                                          'Resend code',
                                          style: AppTypography.body2.copyWith(
                                            color: AppColors.brandBlue,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    const SizedBox(height: AppSpacing.x4),
                                    SizedBox(
                                      width: double.infinity,
                                      height: 54,
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.brandBlue,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          elevation: 0,
                                          textStyle: AppTypography.button,
                                        ),
                                        onPressed: _isComplete
                                            ? _onVerify
                                            : null,
                                        child: const Text('Verify'),
                                      ),
                                    ),
                                    const SizedBox(height: AppSpacing.x4),
                                    TextButton.icon(
                                      onPressed: () =>
                                          context.go(AppRouter.loginPath),
                                      icon: const Icon(
                                        Icons.arrow_back_rounded,
                                        size: 18,
                                        color: _OtpTokens.mutedText,
                                      ),
                                      label: Text(
                                        'Back to login',
                                        style: AppTypography.body2.copyWith(
                                          color: _OtpTokens.mutedText,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.x6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.x4,
                        vertical: AppSpacing.x2,
                      ),
                      decoration: BoxDecoration(
                        color: _OtpTokens.pillBackground,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          SvgPicture.asset(
                            'assets/icons/trumarkz_shield.svg',
                            height: 20,
                            colorFilter: const ColorFilter.mode(
                              AppColors.brandBlue,
                              BlendMode.srcIn,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.x2),
                          Text(
                            'TruMarkZ Verified',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.brandBlue,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.x3),
                    Text(
                      'Secured by TruMarkZ Identity Protocol',
                      style: AppTypography.caption.copyWith(
                        color: _OtpTokens.outlineText,
                        letterSpacing: 0.6,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _maskEmail(String email) {
    final int at = email.indexOf('@');
    if (at <= 1) return email;
    final String name = email.substring(0, at);
    final String domain = email.substring(at + 1);
    final String prefix = name.substring(0, 2);
    return '$prefix***@$domain';
  }
}

class _OtpInputRow extends StatelessWidget {
  const _OtpInputRow({
    required this.controllers,
    required this.nodes,
    required this.onChanged,
  });

  final List<TextEditingController> controllers;
  final List<FocusNode> nodes;
  final void Function(int index, String value) onChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        const double boxWidth = 48;
        const double boxHeight = 56;
        const double spacing = 8;

        return Align(
          alignment: Alignment.center,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List<Widget>.generate(_OtpTokens.otpLength, (int i) {
                return Padding(
                  padding: EdgeInsets.only(
                    right: i == _OtpTokens.otpLength - 1 ? 0 : spacing,
                  ),
                  child: SizedBox(
                    width: boxWidth,
                    height: boxHeight,
                    child: TextField(
                      controller: controllers[i],
                      focusNode: nodes[i],
                      autofocus: i == 0,
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      inputFormatters: <TextInputFormatter>[
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(1),
                      ],
                      style: AppTypography.heading2.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      decoration: InputDecoration(
                        counterText: '',
                        filled: true,
                        fillColor: _OtpTokens.otpFill,
                        contentPadding: EdgeInsets.zero,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: _OtpTokens.otpBorder,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: _OtpTokens.otpBorder,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: AppColors.brandBlue,
                            width: 2,
                          ),
                        ),
                      ),
                      onChanged: (String value) => onChanged(i, value),
                    ),
                  ),
                );
              }),
            ),
          ),
        );
      },
    );
  }
}

class _OtpBackground extends StatelessWidget {
  const _OtpBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Positioned(
          top: -140,
          left: -140,
          child: Container(
            width: 320,
            height: 320,
            decoration: BoxDecoration(
              color: AppColors.brandBlue.withAlpha(18),
              shape: BoxShape.circle,
            ),
          ),
        ),
        Positioned(
          bottom: -160,
          right: -160,
          child: Container(
            width: 340,
            height: 340,
            decoration: BoxDecoration(
              color: const Color(0xFF495C95).withAlpha(18),
              shape: BoxShape.circle,
            ),
          ),
        ),
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 120, sigmaY: 120),
            child: const SizedBox.shrink(),
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

class OtpVerificationPage extends StatefulWidget {
  const OtpVerificationPage({super.key});

  @override
  State<OtpVerificationPage> createState() => _OtpVerificationPageState();
}

class _OtpVerificationPageState extends State<OtpVerificationPage> {
  static const int _otpLength = 6;

  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _nodes;

  bool _isComplete = false;
  int _secondsLeft = 48;

  @override
  void initState() {
    super.initState();
    _controllers = List<TextEditingController>.generate(
      _otpLength,
      (_) => TextEditingController(),
    );
    _nodes = List<FocusNode>.generate(_otpLength, (_) => FocusNode());
    for (final TextEditingController c in _controllers) {
      c.addListener(_recomputeComplete);
    }
    _tickCountdown();
  }

  @override
  void dispose() {
    for (final TextEditingController c in _controllers) {
      c
        ..removeListener(_recomputeComplete)
        ..dispose();
    }
    for (final FocusNode n in _nodes) {
      n.dispose();
    }
    super.dispose();
  }

  void _recomputeComplete() {
    final bool complete = _controllers.every((c) => c.text.trim().length == 1);
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

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final String email =
        GoRouterState.of(
              context,
            ).uri.queryParameters['email']?.trim().isNotEmpty ==
            true
        ? GoRouterState.of(context).uri.queryParameters['email']!.trim()
        : 'admin@org.com';
    final String displayEmail = _maskEmail(email);

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
                AppSpacing.x6,
                AppSpacing.x8,
                AppSpacing.x6,
                AppSpacing.x6,
              ),
              children: <Widget>[
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
                    children: <Widget>[
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: scheme.primary.withAlpha(18),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.mail_outline_rounded,
                          color: scheme.primary,
                          size: 28,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.x4),
                      Text(
                        'Verify your Email',
                        style: AppTypography.heading1,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.x2),
                      Text(
                        'We sent a 6-digit OTP to\n$displayEmail',
                        textAlign: TextAlign.center,
                        style: AppTypography.body2.copyWith(
                          color: scheme.onSurface.withAlpha(160),
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.x6),
                      LayoutBuilder(
                        builder:
                            (BuildContext context, BoxConstraints constraints) {
                              double spacing = 10;
                              double boxWidth =
                                  (constraints.maxWidth -
                                      spacing * (_otpLength - 1)) /
                                  _otpLength;
                              if (boxWidth < 36) {
                                spacing = 6;
                                boxWidth =
                                    (constraints.maxWidth -
                                        spacing * (_otpLength - 1)) /
                                    _otpLength;
                              }
                              boxWidth = boxWidth.clamp(34, 44);

                              return Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List<Widget>.generate(_otpLength, (
                                  int i,
                                ) {
                                  return Padding(
                                    padding: EdgeInsets.only(
                                      right: i == _otpLength - 1 ? 0 : spacing,
                                    ),
                                    child: SizedBox(
                                      width: boxWidth,
                                      child: TextField(
                                        controller: _controllers[i],
                                        focusNode: _nodes[i],
                                        textAlign: TextAlign.center,
                                        keyboardType: TextInputType.number,
                                        maxLength: 1,
                                        decoration: InputDecoration(
                                          counterText: '',
                                          filled: true,
                                          fillColor: const Color(0xFFF8FAFC),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              14,
                                            ),
                                            borderSide: const BorderSide(
                                              color: Color(0xFFE2E8F0),
                                            ),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              14,
                                            ),
                                            borderSide: const BorderSide(
                                              color: Color(0xFFE2E8F0),
                                            ),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              14,
                                            ),
                                            borderSide: const BorderSide(
                                              color: AppColors.brandBlue,
                                              width: 1.5,
                                            ),
                                          ),
                                        ),
                                        onChanged: (String val) {
                                          if (val.isNotEmpty) {
                                            if (i < _otpLength - 1) {
                                              FocusScope.of(
                                                context,
                                              ).nextFocus();
                                            } else {
                                              FocusScope.of(context).unfocus();
                                            }
                                          } else {
                                            if (i > 0) {
                                              FocusScope.of(
                                                context,
                                              ).previousFocus();
                                            }
                                          }
                                        },
                                      ),
                                    ),
                                  );
                                }),
                              );
                            },
                      ),
                      const SizedBox(height: AppSpacing.x4),
                      Text(
                        _secondsLeft > 0
                            ? 'Resend code in 00:${_secondsLeft.toString().padLeft(2, '0')}'
                            : 'Didn’t get a code?',
                        style: AppTypography.body2.copyWith(
                          color: scheme.onSurface.withAlpha(150),
                        ),
                      ),
                      if (_secondsLeft == 0)
                        TextButton(
                          onPressed: _resend,
                          child: const Text('Resend code'),
                        ),
                      const SizedBox(height: AppSpacing.x4),
                      SizedBox(
                        width: double.infinity,
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
                          onPressed: _isComplete
                              ? () {
                                  final Map<String, String> qp =
                                      Map<String, String>.from(
                                        GoRouterState.of(
                                          context,
                                        ).uri.queryParameters,
                                      );
                                  qp.putIfAbsent('status', () => 'waiting');
                                  final String qs = qp.entries
                                      .map(
                                        (e) =>
                                            '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}',
                                      )
                                      .join('&');
                                  context.go(
                                    qs.isEmpty
                                        ? AppRouter.pendingApprovalPath
                                        : '${AppRouter.pendingApprovalPath}?$qs',
                                  );
                                }
                              : null,
                          child: const Text('Verify'),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.x4),
                      TextButton.icon(
                        onPressed: () => context.go(AppRouter.loginPath),
                        icon: const Icon(Icons.arrow_back_rounded, size: 18),
                        label: const Text('Back to login'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.x6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    SvgPicture.asset(
                      'assets/icons/trumarkz_shield.svg',
                      height: 16,
                      colorFilter: ColorFilter.mode(
                        scheme.primary,
                        BlendMode.srcIn,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.x2),
                    Text(
                      'TruMarkZ Verified',
                      style: AppTypography.body2.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.x3),
                Text(
                  'Secured by TruMarkZ Identity Protocol',
                  textAlign: TextAlign.center,
                  style: AppTypography.caption.copyWith(
                    color: scheme.onSurface.withAlpha(140),
                    letterSpacing: 0.8,
                  ),
                ),
              ],
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

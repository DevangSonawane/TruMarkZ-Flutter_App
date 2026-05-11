import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/network/api_client.dart';
import '../../../../../core/router/app_router.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/widgets/tmz_button.dart';
import '../../../../auth/data/auth_repository.dart';
import '../../../../auth/application/auth_notifier.dart';
import '../../../../auth/application/pending_auth.dart';

class _OtpTokens {
  static const int otpLength = 6;
  static const int totalSeconds = 600;
}

class OtpVerificationPage extends ConsumerStatefulWidget {
  const OtpVerificationPage({super.key});

  @override
  ConsumerState<OtpVerificationPage> createState() => _OtpVerificationPageState();
}

class _OtpVerificationPageState extends ConsumerState<OtpVerificationPage> {
  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _nodes;
  Timer? _timer;

  bool _isComplete = false;
  int _secondsLeft = _OtpTokens.totalSeconds;
  bool _hasError = false;
  int _shake = 0;
  bool _isVerifying = false;
  bool _isResending = false;

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
    _startCountdown();
  }

  @override
  void dispose() {
    _timer?.cancel();
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

  void _startCountdown() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      if (!mounted) return;
      if (_secondsLeft <= 0) {
        t.cancel();
        return;
      }
      setState(() => _secondsLeft -= 1);
    });
  }

  String _formatCountdown(int seconds) {
    final int m = seconds ~/ 60;
    final int s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Future<void> _resend(String email) async {
    if (_isResending) return;
    setState(() => _isResending = true);
    try {
      await ref.read(authRepositoryProvider).forgotPassword(email);
      if (!mounted) return;
      setState(() => _secondsLeft = _OtpTokens.totalSeconds);
      _startCountdown();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('New code sent')),
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
      if (mounted) setState(() => _isResending = false);
    }
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

  Future<void> _onVerify(String email, String type) async {
    if (!_isComplete) {
      setState(() {
        _hasError = true;
        _shake += 1;
      });
      return;
    }
    if (_isVerifying) return;
    final String otp = _controllers.map((TextEditingController c) => c.text).join();
    if (otp.trim().length != _OtpTokens.otpLength) {
      setState(() {
        _hasError = true;
        _shake += 1;
      });
      return;
    }

    setState(() => _isVerifying = true);
    try {
      await ref.read(authRepositoryProvider).verifyOtp(
            identifier: email,
            otpCode: otp,
            purpose: 'registration',
          );
      if (!mounted) return;

      if (type == 'organization') {
        context.go(AppRouter.pendingApprovalPath);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Email verified! Please log in.')),
        );
        context.go('${AppRouter.loginPath}?verified=true');
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      for (final TextEditingController c in _controllers) {
        c.clear();
      }
      _nodes.first.requestFocus();
      setState(() {
        _hasError = true;
        _shake += 1;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Something went wrong. Please try again.')),
      );
      for (final TextEditingController c in _controllers) {
        c.clear();
      }
      _nodes.first.requestFocus();
      setState(() {
        _hasError = true;
        _shake += 1;
      });
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, String> qp = GoRouterState.of(context).uri.queryParameters;
    final String identifier =
        (qp['identifier'] ?? qp['email'] ?? '').trim().isNotEmpty
            ? (qp['identifier'] ?? qp['email'])!.trim()
            : 'admin@org.com';
    final String type = (qp['type'] ?? 'organization').trim();
    final String after = (qp['after'] ?? '').trim();
    final String displayIdentifier =
        identifier.contains('@') ? _maskEmail(identifier) : identifier;

    return Scaffold(
      backgroundColor: AppColors.pageBg,
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
                            color: AppColors.cardSurface,
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
                                  color: AppColors.blueTint,
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: const Icon(
                                  Icons.mark_email_unread_outlined,
                                  size: 32,
                                  color: AppColors.brandBlue,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.x6),
                              Text(
                                'Verify your Email',
                                style: AppTypography.display2.copyWith(
                                  color: AppColors.textPrimary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: AppSpacing.x2),
                              Text(
                                'We sent a 6-digit OTP to $displayIdentifier',
                                style: AppTypography.body2.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 32),
                              Animate(
                                target: _shake.toDouble(),
                                effects: <Effect>[
                                  ShakeEffect(
                                    hz: 4,
                                    offset: const Offset(4, 0),
                                    duration: 400.ms,
                                  ),
                                ],
                                child: _OtpInputRow(
                                  controllers: _controllers,
                                  nodes: _nodes,
                                  hasError: _hasError,
                                  onChanged: (int i, String v) {
                                    if (_hasError) {
                                      setState(() => _hasError = false);
                                    }
                                    _handleDigitChanged(i, v);
                                  },
                                ),
                              ),
                              const SizedBox(height: AppSpacing.x6),
                              SizedBox(
                                width: double.infinity,
                                child: Column(
                                  children: <Widget>[
                                    if (_secondsLeft > 0)
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: <Widget>[
                                          SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: Stack(
                                              alignment: Alignment.center,
                                              children: <Widget>[
                                                CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  value:
                                                      1 -
                                                      (_secondsLeft /
                                                          _OtpTokens
                                                              .totalSeconds),
                                                  color: AppColors.brandBlue,
                                                  backgroundColor:
                                                      AppColors.blueTint,
                                                ),
                                                Text(
                                                  _formatCountdown(_secondsLeft),
                                                  style: AppTypography.caption
                                                      .copyWith(
                                                        color: AppColors
                                                            .textSecondary,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                      ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: AppSpacing.x2),
                                          Text(
                                            'Resend code',
                                            style: AppTypography.body2.copyWith(
                                              color: AppColors.textTertiary,
                                            ),
                                          ),
                                        ],
                                      )
                                    else
                                      Text(
                                        'Didn’t get a code?',
                                        style: AppTypography.body2.copyWith(
                                          color: AppColors.textTertiary,
                                        ),
                                      ),
                                    if (_secondsLeft == 0)
                                      TextButton(
                                        onPressed: _isResending
                                            ? null
                                            : () => _resend(identifier),
                                        child: Text(
                                          'Resend code',
                                          style: AppTypography.body2.copyWith(
                                            color: AppColors.brandBlue,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    const SizedBox(height: AppSpacing.x4),
                                    TMZButton(
                                      label: 'Verify',
                                      onPressed: _isVerifying
                                          ? null
                                          : () async {
                                              final ScaffoldMessengerState messenger =
                                                  ScaffoldMessenger.of(context);
                                              final String encodedType =
                                                  Uri.encodeComponent(type);
                                              await _onVerify(identifier, type);
                                              if (!mounted) return;
                                              if (after != 'login') return;

                                              final PendingLogin? pending =
                                                  ref.read(pendingLoginProvider);
                                              if (pending == null) {
                                                AppRouter.router.go(
                                                  '${AppRouter.loginPath}?type=$encodedType&force=true',
                                                );
                                                return;
                                              }

                                              try {
                                                if (pending.loginType ==
                                                    'organization') {
                                                  await ref
                                                      .read(
                                                        authNotifierProvider
                                                            .notifier,
                                                      )
                                                      .loginOrg(
                                                        pending.emailOrMobile,
                                                        pending.password,
                                                      );
                                                } else {
                                                  await ref
                                                      .read(
                                                        authNotifierProvider
                                                            .notifier,
                                                      )
                                                      .loginIndividual(
                                                        pending.emailOrMobile,
                                                        pending.password,
                                                      );
                                                }
                                                ref
                                                    .read(
                                                      pendingLoginProvider
                                                          .notifier,
                                                    )
                                                    .state = null;
                                              } on ApiException catch (e) {
                                                ref
                                                    .read(
                                                      pendingLoginProvider
                                                          .notifier,
                                                    )
                                                    .state = null;
                                                messenger.showSnackBar(
                                                  SnackBar(
                                                    content: Text(e.message),
                                                  ),
                                                );
                                                AppRouter.router.go(
                                                  '${AppRouter.loginPath}?type=$encodedType&force=true',
                                                );
                                              } catch (_) {
                                                ref
                                                    .read(
                                                      pendingLoginProvider
                                                          .notifier,
                                                    )
                                                    .state = null;
                                                messenger.showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      'Something went wrong. Please try again.',
                                                    ),
                                                  ),
                                                );
                                                AppRouter.router.go(
                                                  '${AppRouter.loginPath}?type=$encodedType&force=true',
                                                );
                                              }
                                            },
                                      isLoading: _isVerifying,
                                    ),
                                    const SizedBox(height: AppSpacing.x4),
                                    TextButton.icon(
                                      onPressed: () =>
                                          context.go(AppRouter.loginPath),
                                      icon: const Icon(
                                        Icons.arrow_back_rounded,
                                        size: 18,
                                        color: AppColors.textTertiary,
                                      ),
                                      label: Text(
                                        'Back to login',
                                        style: AppTypography.body2.copyWith(
                                          color: AppColors.textTertiary,
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
                        color: AppColors.blueTint,
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
                        color: AppColors.textSecondary,
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
    required this.hasError,
    required this.onChanged,
  });

  final List<TextEditingController> controllers;
  final List<FocusNode> nodes;
  final bool hasError;
  final void Function(int index, String value) onChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        const double maxBox = 56;
        const double absoluteMinBox = 28;
        const double maxSpacing = 8;
        const double minSpacing = 4;

        final double availableWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;

        // Compute a size/spacing that ALWAYS fits on a single line (no overflow).
        final int count = _OtpTokens.otpLength;
        final int gaps = count - 1;

        double boxSize;
        double spacing;

        if (gaps <= 0) {
          boxSize = availableWidth.clamp(absoluteMinBox, maxBox);
          spacing = 0;
        } else {
          // Start with the largest spacing; shrink spacing/boxes as needed.
          spacing = maxSpacing;
          boxSize = (availableWidth - spacing * gaps) / count;

          if (boxSize > maxBox) {
            boxSize = maxBox;
            spacing = ((availableWidth - boxSize * count) / gaps).clamp(
              minSpacing,
              maxSpacing,
            );
          } else if (boxSize < absoluteMinBox) {
            // Try shrinking spacing down to zero before shrinking boxes further.
            spacing = ((availableWidth - absoluteMinBox * count) / gaps).clamp(
              0,
              maxSpacing,
            );
            boxSize = (availableWidth - spacing * gaps) / count;

            // If it's still too small, allow smaller boxes with zero spacing.
            if (boxSize < absoluteMinBox) {
              spacing = 0;
              boxSize = availableWidth / count;
            }
          } else {
            boxSize = boxSize.clamp(absoluteMinBox, maxBox);
            spacing = spacing.clamp(minSpacing, maxSpacing);
          }
        }

        final Widget row = Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List<Widget>.generate(_OtpTokens.otpLength, (int i) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (i != 0) SizedBox(width: spacing),
                SizedBox(
                  width: boxSize,
                  height: boxSize,
                  child: AnimatedBuilder(
                    animation: Listenable.merge(<Listenable>[
                      controllers[i],
                      nodes[i],
                    ]),
                    builder: (BuildContext context, Widget? child) {
                      final bool focused = nodes[i].hasFocus;
                      final bool filled = controllers[i].text.trim().isNotEmpty;

                      final Color borderColor = hasError
                          ? AppColors.error
                          : filled
                          ? AppColors.brandBlue
                          : AppColors.divider;
                      final Color fillColor = filled
                          ? AppColors.blueTint
                          : AppColors.cardSurface;

                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        curve: Curves.easeOut,
                        decoration: BoxDecoration(
                          color: fillColor,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: borderColor,
                            width: focused ? 2 : 1,
                          ),
                          // Keep a single visible border (no outer focus ring).
                          boxShadow: null,
                        ),
                        child: Center(child: child),
                      );
                    },
                    child: TextField(
                      controller: controllers[i],
                      focusNode: nodes[i],
                      autofocus: i == 0,
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      cursorColor: AppColors.brandBlue,
                      cursorWidth: 2,
                      inputFormatters: <TextInputFormatter>[
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(1),
                      ],
                      style: AppTypography.heading2.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      decoration: const InputDecoration(
                        counterText: '',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onChanged: (String value) => onChanged(i, value),
                    ),
                  ),
                ),
              ],
            );
          }),
        );

        return Center(child: row);
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
              color: AppColors.deepNavy.withAlpha(18),
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

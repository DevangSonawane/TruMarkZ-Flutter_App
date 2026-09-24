import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
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
  ConsumerState<OtpVerificationPage> createState() =>
      _OtpVerificationPageState();
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

  String _backLocation({required String type, required String after}) {
    final String encodedType = Uri.encodeComponent(type);
    if (after == 'register') {
      return type == 'organization'
          ? AppRouter.organisationRegistrationPath
          : '${AppRouter.registerPath}?force=true';
    }
    return '${AppRouter.loginPath}?type=$encodedType&force=true';
  }

  Future<void> _resend(String email) async {
    if (_isResending) return;
    setState(() => _isResending = true);
    try {
      await ref.read(authRepositoryProvider).resendOtp(email: email);
      if (!mounted) return;
      setState(() => _secondsLeft = _OtpTokens.totalSeconds);
      _startCountdown();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('New code sent')));
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

  Future<bool> _onVerify(String email) async {
    if (!_isComplete) {
      setState(() {
        _hasError = true;
        _shake += 1;
      });
      return false;
    }
    if (_isVerifying) return false;
    final String otp = _controllers
        .map((TextEditingController c) => c.text)
        .join();
    if (otp.trim().length != _OtpTokens.otpLength) {
      setState(() {
        _hasError = true;
        _shake += 1;
      });
      return false;
    }

    setState(() => _isVerifying = true);
    try {
      await ref
          .read(authRepositoryProvider)
          .verifyOtp(email: email, otpCode: otp);
      if (!mounted) return false;
      return true;
    } on ApiException catch (e) {
      if (!mounted) return false;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
      for (final TextEditingController c in _controllers) {
        c.clear();
      }
      _nodes.first.requestFocus();
      setState(() {
        _hasError = true;
        _shake += 1;
      });
      return false;
    } catch (_) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Something went wrong. Please try again.'),
        ),
      );
      for (final TextEditingController c in _controllers) {
        c.clear();
      }
      _nodes.first.requestFocus();
      setState(() {
        _hasError = true;
        _shake += 1;
      });
      return false;
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, String> qp = GoRouterState.of(
      context,
    ).uri.queryParameters;
    final String identifier =
        (qp['identifier'] ?? qp['email'] ?? '').trim().isNotEmpty
        ? (qp['identifier'] ?? qp['email'])!.trim()
        : 'admin@org.com';
    final String type = (qp['type'] ?? 'organization').trim();
    final String after = (qp['after'] ?? '').trim();
    final String displayIdentifier = identifier.contains('@')
        ? _maskEmail(identifier)
        : identifier;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.x6,
                      AppSpacing.x5,
                      AppSpacing.x6,
                      AppSpacing.x5,
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 340),
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
                          const SizedBox(height: AppSpacing.x8),
                          Text(
                            'OTP Verification',
                            textAlign: TextAlign.center,
                            style: AppTypography.heading1.copyWith(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.x2),
                          Text(
                            'We sent a 6-digit code to $displayIdentifier',
                            style: AppTypography.body2.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppSpacing.x8),
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
                          const SizedBox(height: AppSpacing.x3),
                          if (_secondsLeft > 0)
                            Center(
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 220),
                                child: Text(
                                  'Resend in ${_formatCountdown(_secondsLeft)}',
                                  key: ValueKey<int>(_secondsLeft),
                                  textAlign: TextAlign.center,
                                  style: AppTypography.body2.copyWith(
                                    color: AppColors.textTertiary,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            )
                          else
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Text(
                                  'Didn’t get a code?',
                                  style: AppTypography.body2.copyWith(
                                    color: AppColors.textTertiary,
                                    fontSize: 11,
                                  ),
                                ),
                                TextButton(
                                  onPressed: _isResending
                                      ? null
                                      : () => _resend(identifier),
                                  child: Text(
                                    'Resend code',
                                    style: AppTypography.body2.copyWith(
                                      color: const Color(0xFF1B3387),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          const SizedBox(height: AppSpacing.x6),
                          TMZButton(
                            label: 'Verify',
                            isLoading: _isVerifying,
                            borderRadius: 999,
                            backgroundColor: const Color(0xFF1B3387),
                            showShadow: false,
                            onPressed: _isVerifying
                                ? null
                                : () async {
                                    final ScaffoldMessengerState messenger =
                                        ScaffoldMessenger.of(context);
                                    final String encodedType =
                                        Uri.encodeComponent(type);
                                    final bool ok = await _onVerify(identifier);
                                    if (!mounted) return;
                                    if (!ok) return;

                                    if (after != 'login') {
                                      messenger.showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Email verified! Please log in.',
                                          ),
                                        ),
                                      );
                                      AppRouter.router.go(
                                        '${AppRouter.loginPath}?type=$encodedType&verified=true&force=true',
                                      );
                                      return;
                                    }
                                    final PendingLogin? pending = ref.read(
                                      pendingLoginProvider,
                                    );
                                    if (pending == null) {
                                      AppRouter.router.go(
                                        '${AppRouter.loginPath}?type=$encodedType&force=true',
                                      );
                                      return;
                                    }

                                    try {
                                      if (pending.loginType == 'organization') {
                                        await ref
                                            .read(authNotifierProvider.notifier)
                                            .loginOrg(
                                              pending.emailOrMobile,
                                              pending.password,
                                            );
                                      } else {
                                        await ref
                                            .read(authNotifierProvider.notifier)
                                            .loginIndividual(
                                              pending.emailOrMobile,
                                              pending.password,
                                            );
                                      }
                                      ref
                                              .read(
                                                pendingLoginProvider.notifier,
                                              )
                                              .state =
                                          null;
                                    } on ApiException catch (e) {
                                      ref
                                              .read(
                                                pendingLoginProvider.notifier,
                                              )
                                              .state =
                                          null;
                                      messenger.showSnackBar(
                                        SnackBar(content: Text(e.message)),
                                      );
                                      AppRouter.router.go(
                                        '${AppRouter.loginPath}?type=$encodedType&force=true',
                                      );
                                    } catch (_) {
                                      ref
                                              .read(
                                                pendingLoginProvider.notifier,
                                              )
                                              .state =
                                          null;
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
                          ),
                          const SizedBox(height: AppSpacing.x5),
                          Center(
                            child: TextButton.icon(
                              onPressed: () {
                                context.go(
                                  _backLocation(type: type, after: after),
                                );
                              },
                              icon: const Icon(
                                Icons.arrow_back_rounded,
                                size: 18,
                                color: AppColors.textTertiary,
                              ),
                              label: Text(
                                after == 'register'
                                    ? 'Back to register'
                                    : 'Back to login',
                                style: AppTypography.body2.copyWith(
                                  color: AppColors.textTertiary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List<Widget>.generate(_OtpTokens.otpLength, (int i) {
        return Padding(
          padding: EdgeInsets.only(left: i == 0 ? 0 : 6),
          child: _OtpBox(
            controller: controllers[i],
            node: nodes[i],
            hasError: hasError,
            autofocus: i == 0,
            onChanged: (String value) => onChanged(i, value),
          ),
        );
      }),
    );
  }
}

class _OtpBox extends StatefulWidget {
  const _OtpBox({
    required this.controller,
    required this.node,
    required this.hasError,
    required this.autofocus,
    required this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode node;
  final bool hasError;
  final bool autofocus;
  final ValueChanged<String> onChanged;

  @override
  State<_OtpBox> createState() => _OtpBoxState();
}

class _OtpBoxState extends State<_OtpBox> {
  @override
  void initState() {
    super.initState();
    widget.node.addListener(_refresh);
    widget.controller.addListener(_refresh);
  }

  @override
  void dispose() {
    widget.node.removeListener(_refresh);
    widget.controller.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final bool focused = widget.node.hasFocus;
    final bool filled = widget.controller.text.trim().isNotEmpty;
    final Color borderColor = widget.hasError
        ? AppColors.error
        : focused
        ? const Color(0xFF1B3387)
        : filled
        ? const Color(0xFF94A3B8)
        : AppColors.divider;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      width: 44,
      height: 52,
      decoration: BoxDecoration(
        color: focused ? Colors.white : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: focused ? 1.6 : 1),
        boxShadow: <BoxShadow>[
          if (focused)
            BoxShadow(
              color: const Color(0xFF1B3387).withAlpha(18),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
        ],
      ),
      alignment: Alignment.center,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: TextField(
          controller: widget.controller,
          focusNode: widget.node,
          autofocus: widget.autofocus,
          expands: true,
          minLines: null,
          maxLines: null,
          textAlign: TextAlign.center,
          textAlignVertical: TextAlignVertical.center,
          keyboardType: TextInputType.number,
          cursorColor: const Color(0xFF1B3387),
          cursorWidth: 1.4,
          inputFormatters: <TextInputFormatter>[
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(1),
          ],
          style: AppTypography.heading1.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            height: 1,
            color: AppColors.textPrimary,
          ),
          decoration: const InputDecoration(
            counterText: '',
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            disabledBorder: InputBorder.none,
            isCollapsed: true,
            contentPadding: EdgeInsets.zero,
          ),
          onChanged: widget.onChanged,
        ),
      ),
    );
  }
}

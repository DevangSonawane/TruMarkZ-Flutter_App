import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/router/app_router.dart';
import '../../../../../core/models/auth_models.dart';
import '../../../../../core/network/api_client.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/widgets/tmz_button.dart';
import '../../../../../core/widgets/tmz_input.dart';
import '../../../../../core/widgets/tmz_select.dart';
import '../../../../auth/data/auth_repository.dart';

class OrganisationRegistrationPage extends ConsumerStatefulWidget {
  const OrganisationRegistrationPage({super.key});

  @override
  ConsumerState<OrganisationRegistrationPage> createState() =>
      _OrganisationRegistrationPageState();
}

class _OrganisationRegistrationPageState
    extends ConsumerState<OrganisationRegistrationPage> {
  String? _industry;
  bool _otpSent = false;
  bool _isSendingOtp = false;

  final TextEditingController _orgName = TextEditingController();
  final TextEditingController _address = TextEditingController();
  final TextEditingController _gst = TextEditingController();
  final TextEditingController _businessRegNumber = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _officialEmail = TextEditingController();
  final TextEditingController _mobile = TextEditingController();

  bool _looksLikeEmail(String value) {
    final String v = value.trim();
    if (!v.contains('@')) return false;
    final int at = v.indexOf('@');
    if (at <= 0 || at == v.length - 1) return false;
    return v.substring(at + 1).contains('.');
  }

  Future<void> _sendOtp() async {
    final String orgName = _orgName.text.trim();
    final String address = _address.text.trim();
    final String gst = _gst.text.trim();
    final String brn = _businessRegNumber.text.trim();
    final String officialEmail = _officialEmail.text.trim();
    final String password = _password.text;
    final String mobile = _mobile.text.trim();

    if (officialEmail.isEmpty || !_looksLikeEmail(officialEmail)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email address.')),
      );
      return;
    }
    if (orgName.isEmpty || address.isEmpty || gst.isEmpty || brn.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields.')),
      );
      return;
    }
    if (password.trim().length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 8 characters.')),
      );
      return;
    }

    setState(() => _isSendingOtp = true);
    try {
      // TODO(dev): API currently has no field for industry; keep collecting it but do not send.
      await ref.read(authRepositoryProvider).registerOrg(
            RegisterOrgRequest(
              organizationName: orgName,
              gstNumber: gst,
              businessRegistrationNumber: brn,
              address: address,
              email: officialEmail,
              mobile: mobile.isEmpty ? null : mobile,
              password: password,
            ),
          );
      if (!mounted) return;
      setState(() => _otpSent = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('OTP sent to your email')),
      );
      unawaited(_showOtpSentPopup());
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Something went wrong. Please try again.')),
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
    _orgName.dispose();
    _address.dispose();
    _gst.dispose();
    _businessRegNumber.dispose();
    _password.dispose();
    _officialEmail.dispose();
    _mobile.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final double systemBottomInset = MediaQuery.of(context).viewPadding.bottom;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 12,
        leading: IconButton(
          onPressed: () => context.go(AppRouter.roleSelectionPath),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.x4,
          AppSpacing.x4,
          AppSpacing.x4,
          AppSpacing.x4 + systemBottomInset,
        ),
        children: <Widget>[
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: 1 / 3,
              minHeight: 4,
              backgroundColor: scheme.outlineVariant.withAlpha(90),
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.brandBlue,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.x6),
          Text(
            'Register your Organisation',
            style: AppTypography.heading1.copyWith(
              fontSize: 20,
              color: const Color(0xFF0B0F19),
            ),
          ),
          const SizedBox(height: AppSpacing.x3),
          Container(
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: scheme.outlineVariant),
            ),
            padding: const EdgeInsets.all(AppSpacing.x4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                TMZInput(
                  label: 'Organisation Name',
                  hint: 'Legal Name of Business',
                  controller: _orgName,
                ),
                const SizedBox(height: AppSpacing.x3),
                _label('Address'),
                const SizedBox(height: AppSpacing.x2),
                TextField(
                  controller: _address,
                  minLines: 3,
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText: 'Registered Office Address',
                    filled: true,
                    fillColor: scheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: scheme.outlineVariant),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: scheme.outlineVariant),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppColors.brandBlue,
                        width: 1.5,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                  style: AppTypography.body2,
                ),
                const SizedBox(height: AppSpacing.x3),
                TMZSelect<String>(
                  label: 'Industry',
                  value: _industry,
                  hint: 'Select Industry Type',
                  options: const <TMZSelectOption<String>>[
                    TMZSelectOption(value: 'Transport', label: 'Transport'),
                    TMZSelectOption(value: 'Healthcare', label: 'Healthcare'),
                    TMZSelectOption(value: 'Education', label: 'Education'),
                    TMZSelectOption(
                      value: 'Manufacturing',
                      label: 'Manufacturing',
                    ),
                    TMZSelectOption(value: 'Security', label: 'Security'),
                    TMZSelectOption(value: 'Agriculture', label: 'Agriculture'),
                    TMZSelectOption(
                      value: 'Products/Services',
                      label: 'Products/Services',
                    ),
                    TMZSelectOption(value: 'Others', label: 'Others'),
                  ],
                  onChanged: (String? value) =>
                      setState(() => _industry = value),
                ),
                const SizedBox(height: AppSpacing.x3),
                TMZInput(
                  label: 'GST Number',
                  hint: '22AAAAA0000A1Z5',
                  controller: _gst,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: AppSpacing.x3),
                TMZInput(
                  label: 'Business Registration Number',
                  hint: 'Registration / CIN / License',
                  controller: _businessRegNumber,
                ),
                const SizedBox(height: AppSpacing.x3),
                TMZInput(
                  label: 'Password',
                  hint: '••••••••',
                  controller: _password,
                  obscureText: true,
                ),
                const SizedBox(height: AppSpacing.x3),
                _label('Official Email'),
                const SizedBox(height: AppSpacing.x2),
                TextField(
                  controller: _officialEmail,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: 'contact@organisation.com',
                    prefixIcon: const Icon(Icons.mail_outline_rounded),
                    suffixIcon: TextButton(
                      onPressed: _isSendingOtp ? null : _sendOtp,
                      child: _isSendingOtp
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Send OTP'),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: scheme.outlineVariant),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: scheme.outlineVariant),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppColors.brandBlue,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.x3),
                TMZInput(
                  label: 'Mobile Number',
                  hint: '+91 98765 43210',
                  controller: _mobile,
                  keyboardType: TextInputType.phone,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.x6),
          TMZButton(
            label: 'Continue',
            onPressed: _otpSent
                ? () => context.go(
                    '${AppRouter.otpVerificationPath}?email=${Uri.encodeComponent(_officialEmail.text.trim())}&org=${Uri.encodeComponent(_orgName.text.trim())}&type=organization',
                  )
                : null,
          ),
        ],
      ),
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: AppTypography.caption.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: 0.4,
        color: const Color(0xFF0B0F19),
      ),
    );
  }
}

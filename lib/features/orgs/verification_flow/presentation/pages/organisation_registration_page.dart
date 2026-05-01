import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/router/app_router.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/widgets/tmz_button.dart';
import '../../../../../core/widgets/tmz_input.dart';
import '../../../../../core/widgets/tmz_select.dart';

class OrganisationRegistrationPage extends StatefulWidget {
  const OrganisationRegistrationPage({super.key});

  @override
  State<OrganisationRegistrationPage> createState() =>
      _OrganisationRegistrationPageState();
}

class _OrganisationRegistrationPageState
    extends State<OrganisationRegistrationPage> {
  String? _industry;
  bool _otpSent = false;

  final TextEditingController _orgName = TextEditingController();
  final TextEditingController _address = TextEditingController();
  final TextEditingController _gst = TextEditingController();
  final TextEditingController _businessReg = TextEditingController();
  final TextEditingController _officialEmail = TextEditingController();
  final TextEditingController _mobile = TextEditingController();

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
    _businessReg.dispose();
    _officialEmail.dispose();
    _mobile.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 12,
        title: Row(
          children: <Widget>[
            SvgPicture.asset(
              'assets/icons/trumarkz_shield.svg',
              height: 18,
              colorFilter: ColorFilter.mode(scheme.primary, BlendMode.srcIn),
            ),
            const SizedBox(width: AppSpacing.x2),
            Text('TruMarkZ', style: AppTypography.heading2),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.x4),
        children: <Widget>[
          Row(
            children: <Widget>[
              IconButton(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.arrow_back_rounded),
              ),
              const Spacer(),
              const SizedBox(width: 48),
            ],
          ),
          const SizedBox(height: AppSpacing.x2),
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
                  hint: 'U12345DL2023PTC',
                  controller: _businessReg,
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
                      onPressed: () {
                        setState(() => _otpSent = true);
                        unawaited(_showOtpSentPopup());
                      },
                      child: const Text('Send OTP'),
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
                    '${AppRouter.otpVerificationPath}?email=${Uri.encodeComponent(_officialEmail.text.trim())}&org=${Uri.encodeComponent(_orgName.text.trim())}',
                  )
                : null,
          ),
          const SizedBox(height: AppSpacing.x3),
          Center(
            child: InkWell(
              onTap: () => context.go(AppRouter.skillTreePath),
              child: Text(
                'Registering as an Individual instead?',
                style: AppTypography.body2.copyWith(
                  color: scheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
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

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
import '../../../../auth/data/auth_repository.dart';

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
  double _progress = 0;

  final TextEditingController _orgName = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _officialEmail = TextEditingController();
  final TextEditingController _phoneNumber = TextEditingController();
  final TextEditingController _humanSpaceId = TextEditingController();
  final TextEditingController _productSpaceId = TextEditingController();
  final TextEditingController _warrantySpaceId = TextEditingController();
  final TextEditingController _humanSchemaId = TextEditingController();
  final TextEditingController _productSchemaId = TextEditingController();
  final TextEditingController _warrantySchemaId = TextEditingController();
  String? _serviceType;

  bool _looksLikeEmail(String value) {
    final String v = value.trim();
    if (!v.contains('@')) return false;
    final int at = v.indexOf('@');
    if (at <= 0 || at == v.length - 1) return false;
    return v.substring(at + 1).contains('.');
  }

  @override
  void initState() {
    super.initState();
    _orgName.addListener(_recomputeProgress);
    _officialEmail.addListener(_recomputeProgress);
    _phoneNumber.addListener(_recomputeProgress);
    _password.addListener(_recomputeProgress);
    _progress = _computeProgress();
  }

  void _recomputeProgress() {
    final double next = _computeProgress();
    if (next == _progress) return;
    setState(() => _progress = next);
  }

  double _computeProgress() {
    if (_otpSent) return 1;

    int filled = 0;
    if (_orgName.text.trim().isNotEmpty) filled += 1;
    if (_looksLikeEmail(_officialEmail.text)) filled += 1;
    if (_phoneNumber.text.trim().isNotEmpty) filled += 1;
    if ((_serviceType ?? '').trim().isNotEmpty) filled += 1;
    if (_password.text.trim().length >= 8) filled += 1;
    return filled / 5;
  }

  void _setServiceType(String? value) {
    if (_serviceType == value) return;
    setState(() => _serviceType = value);
    _recomputeProgress();
  }

  Future<void> _sendOtp() async {
    final String orgName = _orgName.text.trim();
    final String officialEmail = _officialEmail.text.trim();
    final String password = _password.text;
    final String phoneNumber = _phoneNumber.text.trim();
    final String serviceType = (_serviceType ?? '').trim().toLowerCase();

    if (officialEmail.isEmpty || !_looksLikeEmail(officialEmail)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email address.')),
      );
      return;
    }

    final List<String> missing = <String>[
      if (orgName.isEmpty) 'Organisation Name',
      if (phoneNumber.isEmpty) 'Phone Number',
      if (serviceType.isEmpty) 'Service Type',
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

    setState(() => _isSendingOtp = true);
    try {
      final SignupOrganizationRequest request = SignupOrganizationRequest(
        orgName: orgName,
        email: officialEmail,
        phoneNumber: phoneNumber,
        password: password,
        serviceType: serviceType,
        humanSpaceId: serviceType == 'human' ? _humanSpaceId.text : null,
        humanSchemaId: serviceType == 'human' ? _humanSchemaId.text : null,
        productSpaceId: serviceType == 'product' ? _productSpaceId.text : null,
        productSchemaId: serviceType == 'product'
            ? _productSchemaId.text
            : null,
        warrantySpaceId: serviceType == 'product'
            ? _warrantySpaceId.text
            : null,
        warrantySchemaId: serviceType == 'product'
            ? _warrantySchemaId.text
            : null,
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
    _orgName.removeListener(_recomputeProgress);
    _officialEmail.removeListener(_recomputeProgress);
    _phoneNumber.removeListener(_recomputeProgress);
    _password.removeListener(_recomputeProgress);
    _orgName.dispose();
    _password.dispose();
    _officialEmail.dispose();
    _phoneNumber.dispose();
    _humanSpaceId.dispose();
    _productSpaceId.dispose();
    _warrantySpaceId.dispose();
    _humanSchemaId.dispose();
    _productSchemaId.dispose();
    _warrantySchemaId.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final double systemBottomInset = MediaQuery.of(context).viewPadding.bottom;
    const Color inputBg = Color(0xFFE9EEF3);

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
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: _progress),
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              builder: (BuildContext context, double value, _) {
                return LinearProgressIndicator(
                  value: value.clamp(0, 1),
                  minHeight: 4,
                  backgroundColor: scheme.outlineVariant.withAlpha(90),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.brandBlue,
                  ),
                );
              },
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
                  backgroundColor: inputBg,
                ),
                const SizedBox(height: AppSpacing.x3),
                TMZInput(
                  label: 'Official Email',
                  hint: 'contact@organisation.com',
                  controller: _officialEmail,
                  keyboardType: TextInputType.emailAddress,
                  backgroundColor: inputBg,
                ),
                const SizedBox(height: AppSpacing.x3),
                TMZInput(
                  label: 'Phone Number',
                  hint: '98765 43210',
                  controller: _phoneNumber,
                  keyboardType: TextInputType.phone,
                  backgroundColor: inputBg,
                ),
                const SizedBox(height: AppSpacing.x3),
                _ServiceTypeField(
                  value: _serviceType,
                  onChanged: _setServiceType,
                ),
                if ((_serviceType ?? '').trim().isNotEmpty) ...<Widget>[
                  const SizedBox(height: AppSpacing.x3),
                  _ServiceDetailsSection(
                    serviceType: _serviceType!,
                    humanSpaceId: _humanSpaceId,
                    productSpaceId: _productSpaceId,
                    warrantySpaceId: _warrantySpaceId,
                    humanSchemaId: _humanSchemaId,
                    productSchemaId: _productSchemaId,
                    warrantySchemaId: _warrantySchemaId,
                    backgroundColor: inputBg,
                  ),
                ],
                const SizedBox(height: AppSpacing.x3),
                TMZInput(
                  label: 'Password',
                  hint: '••••••••',
                  controller: _password,
                  obscureText: true,
                  backgroundColor: inputBg,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.x6),
          TMZButton(
            label: _otpSent ? 'Continue' : 'Send OTP',
            isLoading: _isSendingOtp,
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
    );
  }
}

class _ServiceTypeField extends StatelessWidget {
  const _ServiceTypeField({required this.value, required this.onChanged});

  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'SERVICE TYPE',
          style: AppTypography.caption.copyWith(
            fontWeight: FontWeight.w500,
            color: AppColors.textTertiary,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: value,
          onChanged: onChanged,
          items: const <DropdownMenuItem<String>>[
            DropdownMenuItem<String>(value: 'human', child: Text('Human')),
            DropdownMenuItem<String>(value: 'product', child: Text('Product')),
          ],
          decoration: InputDecoration(
            hintText: 'Select service type',
            filled: true,
            fillColor: AppColors.offWhite,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.brandBlue),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'This controls which verification flow your organisation can use. You can fill the service-specific IDs later in settings if needed.',
          style: AppTypography.body2.copyWith(color: AppColors.textTertiary),
        ),
      ],
    );
  }
}

class _ServiceDetailsSection extends StatelessWidget {
  const _ServiceDetailsSection({
    required this.serviceType,
    required this.humanSpaceId,
    required this.productSpaceId,
    required this.warrantySpaceId,
    required this.humanSchemaId,
    required this.productSchemaId,
    required this.warrantySchemaId,
    required this.backgroundColor,
  });

  final String serviceType;
  final TextEditingController humanSpaceId;
  final TextEditingController productSpaceId;
  final TextEditingController warrantySpaceId;
  final TextEditingController humanSchemaId;
  final TextEditingController productSchemaId;
  final TextEditingController warrantySchemaId;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    final String normalized = serviceType.trim().toLowerCase();
    switch (normalized) {
      case 'human':
        return _ServicePair(
          title: 'Human Service Details',
          primaryLabel: 'Human Space ID (optional)',
          primaryHint: 'Enter human space ID later in settings if needed',
          primaryController: humanSpaceId,
          secondaryLabel: 'Human Schema ID (optional)',
          secondaryHint: 'Enter human schema ID later in settings if needed',
          secondaryController: humanSchemaId,
          backgroundColor: backgroundColor,
        );
      case 'product':
        return _ServiceStack(
          title: 'Product Service Details',
          firstLabel: 'Product Space ID (optional)',
          firstHint: 'Enter product space ID later in settings if needed',
          firstController: productSpaceId,
          secondLabel: 'Product Schema ID (optional)',
          secondHint: 'Enter product schema ID later in settings if needed',
          secondController: productSchemaId,
          thirdLabel: 'Warranty Space ID (optional)',
          thirdHint: 'Enter warranty space ID later in settings if needed',
          thirdController: warrantySpaceId,
          fourthLabel: 'Warranty Schema ID (optional)',
          fourthHint: 'Enter warranty schema ID later in settings if needed',
          fourthController: warrantySchemaId,
          backgroundColor: backgroundColor,
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

class _ServicePair extends StatelessWidget {
  const _ServicePair({
    required this.title,
    required this.primaryLabel,
    required this.primaryHint,
    required this.primaryController,
    required this.secondaryLabel,
    required this.secondaryHint,
    required this.secondaryController,
    required this.backgroundColor,
  });

  final String title;
  final String primaryLabel;
  final String primaryHint;
  final TextEditingController primaryController;
  final String secondaryLabel;
  final String secondaryHint;
  final TextEditingController secondaryController;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(title, style: AppTypography.heading2),
        const SizedBox(height: AppSpacing.x2),
        Text(
          'These fields are optional during signup and can be added later in settings.',
          style: AppTypography.body2.copyWith(color: AppColors.textTertiary),
        ),
        const SizedBox(height: AppSpacing.x3),
        TMZInput(
          label: primaryLabel,
          hint: primaryHint,
          controller: primaryController,
          backgroundColor: backgroundColor,
        ),
        const SizedBox(height: AppSpacing.x3),
        TMZInput(
          label: secondaryLabel,
          hint: secondaryHint,
          controller: secondaryController,
          backgroundColor: backgroundColor,
        ),
      ],
    );
  }
}

class _ServiceStack extends StatelessWidget {
  const _ServiceStack({
    required this.title,
    required this.firstLabel,
    required this.firstHint,
    required this.firstController,
    required this.secondLabel,
    required this.secondHint,
    required this.secondController,
    required this.thirdLabel,
    required this.thirdHint,
    required this.thirdController,
    required this.fourthLabel,
    required this.fourthHint,
    required this.fourthController,
    required this.backgroundColor,
  });

  final String title;
  final String firstLabel;
  final String firstHint;
  final TextEditingController firstController;
  final String secondLabel;
  final String secondHint;
  final TextEditingController secondController;
  final String thirdLabel;
  final String thirdHint;
  final TextEditingController thirdController;
  final String fourthLabel;
  final String fourthHint;
  final TextEditingController fourthController;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(title, style: AppTypography.heading2),
        const SizedBox(height: AppSpacing.x2),
        Text(
          'These fields are optional during signup and can be added later in settings.',
          style: AppTypography.body2.copyWith(color: AppColors.textTertiary),
        ),
        const SizedBox(height: AppSpacing.x3),
        TMZInput(
          label: firstLabel,
          hint: firstHint,
          controller: firstController,
          backgroundColor: backgroundColor,
        ),
        const SizedBox(height: AppSpacing.x3),
        TMZInput(
          label: secondLabel,
          hint: secondHint,
          controller: secondController,
          backgroundColor: backgroundColor,
        ),
        const SizedBox(height: AppSpacing.x3),
        TMZInput(
          label: thirdLabel,
          hint: thirdHint,
          controller: thirdController,
          backgroundColor: backgroundColor,
        ),
        const SizedBox(height: AppSpacing.x3),
        TMZInput(
          label: fourthLabel,
          hint: fourthHint,
          controller: fourthController,
          backgroundColor: backgroundColor,
        ),
      ],
    );
  }
}

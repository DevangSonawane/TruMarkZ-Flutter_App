import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/models/auth_models.dart';
import '../../../../../core/network/api_client.dart';
import '../../../../../core/router/app_router.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/widgets/tmz_button.dart';
import '../../../../auth/application/auth_notifier.dart';
import '../../../../auth/data/auth_repository.dart';

class OrgOnboardingPage extends ConsumerStatefulWidget {
  const OrgOnboardingPage({super.key});

  @override
  ConsumerState<OrgOnboardingPage> createState() => _OrgOnboardingPageState();
}

class _OrgOnboardingPageState extends ConsumerState<OrgOnboardingPage> {
  final TextEditingController _businessName = TextEditingController();
  final TextEditingController _gstin = TextEditingController();
  bool _isSubmitting = false;
  bool _gstVerified = false;

  @override
  void initState() {
    super.initState();
    final UserProfile? profile = ref
        .read(authNotifierProvider)
        .valueOrNull
        ?.userProfile;
    _businessName.text = profile?.organizationName?.trim() ?? '';
    _gstin.text = profile?.gstin?.trim() ?? '';
    _gstVerified = _gstin.text.trim().isNotEmpty;
  }

  @override
  void dispose() {
    _businessName.dispose();
    _gstin.dispose();
    super.dispose();
  }

  Future<void> _verifyGst() async {
    final String businessName = _businessName.text.trim();
    final String gstin = _gstin.text.trim().toUpperCase();

    if (businessName.isEmpty || gstin.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter business name and GST number.'),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final VerifyGstResponse verification = await ref
          .read(authRepositoryProvider)
          .verifyOrganizationGst(gstin: gstin);
      if (verification.organizationName.trim().isNotEmpty) {
        _businessName.text = verification.organizationName.trim();
      }
      await ref
          .read(authRepositoryProvider)
          .completeOrgOnboarding(OrgOnboardingRequest(gstin: gstin));
      await ref.read(authNotifierProvider.notifier).refreshCurrentUser();

      if (!mounted) return;
      setState(() => _gstVerified = true);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('GST verified')));
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
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final double systemBottomInset = MediaQuery.of(context).viewPadding.bottom;
    final bool canVerify = !_isSubmitting && !_gstVerified;

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
                            'Onboarding',
                            textAlign: TextAlign.center,
                            style: AppTypography.heading1.copyWith(
                              fontSize: 24,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.x2),
                          Text(
                            'Add your business details to get verified',
                            textAlign: TextAlign.center,
                            style: AppTypography.body2.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.x8),
                          _OnboardingTextField(
                            label: 'Business Name',
                            prefixIcon: Icons.business_outlined,
                            controller: _businessName,
                            enabled: !_isSubmitting && !_gstVerified,
                          ),
                          const SizedBox(height: AppSpacing.x4),
                          _OnboardingTextField(
                            label: 'GST Number',
                            hint: '27AABCU9603R1ZM',
                            prefixIcon: Icons.receipt_long_outlined,
                            controller: _gstin,
                            enabled: !_isSubmitting && !_gstVerified,
                          ),
                          const SizedBox(height: AppSpacing.x6),
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: TMZButton(
                                  label: _gstVerified
                                      ? 'GST Verified'
                                      : 'Verify GST',
                                  isLoading: _isSubmitting,
                                  borderRadius: 999,
                                  backgroundColor: _gstVerified
                                      ? AppColors.textTertiary.withAlpha(120)
                                      : const Color(0xFF1B3387),
                                  showShadow: false,
                                  onPressed: canVerify ? _verifyGst : null,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.x3),
                              Expanded(
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    minimumSize: const Size.fromHeight(52),
                                    side: const BorderSide(
                                      color: AppColors.divider,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    backgroundColor: Colors.white,
                                    foregroundColor: AppColors.textPrimary,
                                  ),
                                  onPressed: _isSubmitting
                                      ? null
                                      : () => context.go(
                                          AppRouter.orgInterestSelectionPath,
                                        ),
                                  child: Text(_gstVerified ? 'Next' : 'Skip'),
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

class _OnboardingTextField extends StatefulWidget {
  const _OnboardingTextField({
    required this.label,
    required this.controller,
    this.hint,
    this.prefixIcon,
    this.enabled = true,
  });

  final String label;
  final TextEditingController controller;
  final String? hint;
  final IconData? prefixIcon;
  final bool enabled;

  @override
  State<_OnboardingTextField> createState() => _OnboardingTextFieldState();
}

class _OnboardingTextFieldState extends State<_OnboardingTextField> {
  late final FocusNode _focusNode;
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode()..addListener(_handleFocusChange);
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
                style: AppTypography.body2.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  labelText: widget.label,
                  hintText: widget.hint,
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
          ],
        ),
      ),
    );
  }
}

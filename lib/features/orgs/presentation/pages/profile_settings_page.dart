import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/models/auth_models.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/widgets/tmz_button.dart';
import '../../../../core/widgets/tmz_input.dart';
import '../../../auth/application/auth_notifier.dart';
import '../../../auth/application/auth_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

class ProfileSettingsPage extends ConsumerStatefulWidget {
  const ProfileSettingsPage({super.key});

  @override
  ConsumerState<ProfileSettingsPage> createState() =>
      _ProfileSettingsPageState();
}

class _ProfileSettingsPageState extends ConsumerState<ProfileSettingsPage> {
  static const double _referenceWidth = 402;
  static const Color _panelBg = Color(0xFFF7F9FC);
  static const double _orgBottomNavBarHeight = 71.016;
  static const List<String> _serviceTypeOptions = <String>['human', 'product'];

  Future<void> _showOrgProfileDialog(UserProfile? profile) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) =>
            _OrgEditPage(profile: profile, mode: _OrgEditMode.profile),
      ),
    );
  }

  Future<void> _showServiceIdsDialog(UserProfile? profile) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) =>
            _OrgEditPage(profile: profile, mode: _OrgEditMode.serviceIds),
      ),
    );
  }

  Future<void> _showServiceTypeDialog(UserProfile? profile) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) =>
            _OrgEditPage(profile: profile, mode: _OrgEditMode.serviceType),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final AsyncValue<AuthState> authAsync = ref.watch(authNotifierProvider);
    final profile = authAsync.value?.userProfile;
    final String displayName = profile?.fullName?.trim().isNotEmpty == true
        ? profile!.fullName!.trim()
        : (profile?.organizationName?.trim().isNotEmpty == true
              ? profile!.organizationName!.trim()
              : 'User');
    final String email = profile?.email ?? '';
    final String phoneNumber = profile?.phoneNumber ?? '';
    final bool isVerified = profile?.isVerified == true;

    return Scaffold(
      backgroundColor: AppColors.brandBlue,
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final double scale = (constraints.maxWidth / _referenceWidth).clamp(
              0.0,
              1.0,
            );
            double s(double v) => v * scale;

            return _FigmaScaleScope(
              scale: scale,
              child: Column(
                children: <Widget>[
                  Padding(
                    padding: EdgeInsets.fromLTRB(s(16), s(12), s(16), s(12)),
                    child: Row(
                      children: <Widget>[
                        Text(
                          'Account',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: s(21),
                            fontWeight: FontWeight.w600,
                            height: 19.5 / 21,
                            color: Colors.white,
                          ),
                        ),
                        const Spacer(),
                        SvgPicture.asset(
                          'assets/icons/figma/all_batches_bell.svg',
                          width: s(24),
                          height: s(24),
                          colorFilter: const ColorFilter.mode(
                            Colors.white,
                            BlendMode.srcIn,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: s(16)),
                  Expanded(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: _panelBg,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(s(20)),
                        ),
                      ),
                      child: SingleChildScrollView(
                        padding: EdgeInsets.fromLTRB(
                          s(16),
                          s(37),
                          s(16),
                          s(24) + bottomInset + _orgBottomNavBarHeight,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            _OrgProfileHeader(
                              onEdit: () => _showOrgProfileDialog(profile),
                              displayName: displayName,
                              email: email,
                              phoneNumber: phoneNumber,
                              isVerified: isVerified,
                            ),
                            SizedBox(height: s(24)),
                            _GeneralInfoCard(profile: profile),
                            SizedBox(height: s(24)),
                            _OrganisationDetailsCard(
                              profile: profile,
                              onEditServiceType: () =>
                                  _showServiceTypeDialog(profile),
                            ),
                            SizedBox(height: s(24)),
                            _SpaceIdsCard(
                              profile: profile,
                              onEditSpaceIds: () =>
                                  _showServiceIdsDialog(profile),
                            ),
                            SizedBox(height: s(24)),
                            _AddressAndRecordsCard(profile: profile),
                            SizedBox(height: s(24)),
                            _AccountStatusCard(profile: profile),
                            SizedBox(height: s(24)),
                            const _TeamAccessCard(),
                            SizedBox(height: s(24)),
                            _LogoutCard(
                              onLogout: () async {
                                await ref
                                    .read(authNotifierProvider.notifier)
                                    .logout();
                                if (context.mounted) {
                                  context.go(AppRouter.roleSelectionPath);
                                }
                              },
                            ),
                            SizedBox(height: s(24)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

enum _OrgEditMode { profile, serviceIds, serviceType }

class _OrgEditPage extends ConsumerStatefulWidget {
  const _OrgEditPage({required this.profile, required this.mode});

  final UserProfile? profile;
  final _OrgEditMode mode;

  @override
  ConsumerState<_OrgEditPage> createState() => _OrgEditPageState();
}

class _OrgEditPageState extends ConsumerState<_OrgEditPage> {
  final TextEditingController _organizationNameController =
      TextEditingController();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _gstinController = TextEditingController();
  final TextEditingController _brnController = TextEditingController();
  final TextEditingController _address1Controller = TextEditingController();
  final TextEditingController _address2Controller = TextEditingController();
  final TextEditingController _address3Controller = TextEditingController();
  final TextEditingController _humanSpaceController = TextEditingController();
  final TextEditingController _productSpaceController = TextEditingController();
  final TextEditingController _warrantySpaceController =
      TextEditingController();
  final TextEditingController _humanSchemaController = TextEditingController();
  final TextEditingController _productSchemaController =
      TextEditingController();
  final TextEditingController _warrantySchemaController =
      TextEditingController();
  String _serviceType = 'human';
  bool _isSaving = false;
  String? _errorText;

  bool get _isHuman => _serviceType == 'human';
  bool get _isProduct => _serviceType == 'product';

  @override
  void initState() {
    super.initState();
    final UserProfile? profile = widget.profile;
    _organizationNameController.text = profile?.organizationName?.trim() ?? '';
    _fullNameController.text = profile?.fullName?.trim() ?? '';
    _phoneController.text = profile?.phoneNumber?.trim() ?? '';
    _gstinController.text = profile?.gstin?.trim() ?? '';
    _brnController.text = profile?.businessRegNumber?.trim() ?? '';
    _address1Controller.text = profile?.addressLine1?.trim() ?? '';
    _address2Controller.text = profile?.addressLine2?.trim() ?? '';
    _address3Controller.text = profile?.addressLine3?.trim() ?? '';
    _humanSpaceController.text =
        profile?.humanSpaceId?.trim() ?? profile?.dhiwaySpaceId?.trim() ?? '';
    _productSpaceController.text =
        profile?.productSpaceId?.trim() ?? profile?.dhiwaySpaceId?.trim() ?? '';
    _warrantySpaceController.text =
        profile?.warrantySpaceId?.trim() ??
        profile?.dhiwaySpaceId?.trim() ??
        '';
    _humanSchemaController.text = profile?.humanSchemaId?.trim() ?? '';
    _productSchemaController.text = profile?.productSchemaId?.trim() ?? '';
    _warrantySchemaController.text = profile?.warrantySchemaId?.trim() ?? '';

    final String currentServiceType =
        profile?.serviceType?.trim().toLowerCase() ?? '';
    if (widget.mode == _OrgEditMode.serviceIds) {
      _serviceType = currentServiceType == 'human' ? 'human' : 'product';
    } else if (currentServiceType == 'human' ||
        currentServiceType == 'product') {
      _serviceType = currentServiceType;
    }
  }

  @override
  void dispose() {
    _organizationNameController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    _gstinController.dispose();
    _brnController.dispose();
    _address1Controller.dispose();
    _address2Controller.dispose();
    _address3Controller.dispose();
    _humanSpaceController.dispose();
    _productSpaceController.dispose();
    _warrantySpaceController.dispose();
    _humanSchemaController.dispose();
    _productSchemaController.dispose();
    _warrantySchemaController.dispose();
    super.dispose();
  }

  String _title() {
    switch (widget.mode) {
      case _OrgEditMode.profile:
        return 'Edit Profile';
      case _OrgEditMode.serviceIds:
        return 'Edit Space IDs';
      case _OrgEditMode.serviceType:
        return 'Update Service Type';
    }
  }

  String _subtitle() {
    switch (widget.mode) {
      case _OrgEditMode.profile:
        return 'Only the fields you change will be updated.';
      case _OrgEditMode.serviceIds:
        return _isHuman
            ? 'Save the human credential space shared by the superadmin.'
            : 'Save the product and warranty credential spaces shared by the superadmin.';
      case _OrgEditMode.serviceType:
        return 'Choose whether your organization is human-focused or product-focused. You can change this anytime.';
    }
  }

  Future<void> _save() async {
    setState(() {
      _isSaving = true;
      _errorText = null;
    });

    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final NavigatorState navigator = Navigator.of(context);

    try {
      switch (widget.mode) {
        case _OrgEditMode.profile:
          await ref
              .read(authNotifierProvider.notifier)
              .updateOrganizationProfile(
                organizationName: _organizationNameController.text,
                fullName: _fullNameController.text,
                phoneNumber: _phoneController.text,
                gstin: _gstinController.text,
                businessRegNumber: _brnController.text,
                addressLine1: _address1Controller.text,
                addressLine2: _address2Controller.text,
                addressLine3: _address3Controller.text,
                serviceType: _serviceType,
                humanSpaceId: _isHuman ? _humanSpaceController.text : null,
                productSpaceId: _isProduct
                    ? _productSpaceController.text
                    : null,
                warrantySpaceId: _isProduct
                    ? _warrantySpaceController.text
                    : null,
                humanSchemaId: _isHuman ? _humanSchemaController.text : null,
                productSchemaId: _isProduct
                    ? _productSchemaController.text
                    : null,
                warrantySchemaId: _isProduct
                    ? _warrantySchemaController.text
                    : null,
              );
          break;
        case _OrgEditMode.serviceIds:
          final String humanSpaceId = _humanSpaceController.text.trim();
          final String productSpaceId = _productSpaceController.text.trim();
          final String warrantySpaceId = _warrantySpaceController.text.trim();
          if (_isHuman && humanSpaceId.isEmpty) {
            setState(() {
              _errorText = 'Please enter a Human Space ID.';
            });
            return;
          }
          if (_isProduct && productSpaceId.isEmpty && warrantySpaceId.isEmpty) {
            setState(() {
              _errorText = 'Please enter at least one Product Space ID.';
            });
            return;
          }
          await ref
              .read(authNotifierProvider.notifier)
              .updateOrganizationProfile(
                humanSpaceId: _isHuman ? humanSpaceId : null,
                productSpaceId: _isProduct ? productSpaceId : null,
                warrantySpaceId: _isProduct ? warrantySpaceId : null,
                humanSchemaId: _isHuman
                    ? _humanSchemaController.text.trim()
                    : null,
                productSchemaId: _isProduct
                    ? _productSchemaController.text.trim()
                    : null,
                warrantySchemaId: _isProduct
                    ? _warrantySchemaController.text.trim()
                    : null,
              );
          break;
        case _OrgEditMode.serviceType:
          await ref
              .read(authNotifierProvider.notifier)
              .updateOrganizationProfile(serviceType: _serviceType);
          break;
      }

      if (!mounted) return;
      navigator.pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            widget.mode == _OrgEditMode.serviceType
                ? 'Service type updated to ${_serviceType.toUpperCase()}.'
                : 'Profile updated successfully.',
          ),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorText = e.message;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Widget _buildServiceTypeOption(String option) {
    final bool isSelected = _serviceType == option;
    final String title = option == 'human' ? 'Human' : 'Product';
    final String description = option == 'human'
        ? 'For people, credentials, and human verification flows.'
        : 'For product batches, registry, certificates, and the related warranty IDs.';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: _isSaving
            ? null
            : () => setState(() {
                _serviceType = option;
                _errorText = null;
              }),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? AppColors.brandBlue : const Color(0xFFE2E8F0),
              width: 1,
            ),
          ),
          child: Row(
            children: <Widget>[
              Icon(
                isSelected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: isSelected
                    ? AppColors.brandBlue
                    : const Color(0xFF94A3B8),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                        height: 1.35,
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
  }

  Widget _buildBody(BuildContext context) {
    switch (widget.mode) {
      case _OrgEditMode.profile:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(_subtitle(), style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 16),
            TMZInput(
              label: 'Organization Name',
              hint: 'Enter organization name',
              controller: _organizationNameController,
              enabled: !_isSaving,
            ),
            const SizedBox(height: 12),
            TMZInput(
              label: 'Full Name',
              hint: 'Enter full name',
              controller: _fullNameController,
              enabled: !_isSaving,
            ),
            const SizedBox(height: 12),
            TMZInput(
              label: 'Phone Number',
              hint: 'Enter phone number',
              controller: _phoneController,
              enabled: !_isSaving,
            ),
            const SizedBox(height: 12),
            TMZInput(
              label: 'GSTIN',
              hint: 'Enter GSTIN',
              controller: _gstinController,
              enabled: !_isSaving,
            ),
            const SizedBox(height: 12),
            TMZInput(
              label: 'Business Reg. Number',
              hint: 'Enter business reg. number',
              controller: _brnController,
              enabled: !_isSaving,
            ),
            const SizedBox(height: 12),
            TMZInput(
              label: 'Address Line 1',
              hint: 'Enter address line 1',
              controller: _address1Controller,
              enabled: !_isSaving,
            ),
            const SizedBox(height: 12),
            TMZInput(
              label: 'Address Line 2',
              hint: 'Enter address line 2',
              controller: _address2Controller,
              enabled: !_isSaving,
            ),
            const SizedBox(height: 12),
            TMZInput(
              label: 'Address Line 3',
              hint: 'Enter address line 3',
              controller: _address3Controller,
              enabled: !_isSaving,
            ),
            const SizedBox(height: 12),
            _ServiceTypeField(
              value: _serviceType,
              onChanged: _isSaving
                  ? null
                  : (String? value) {
                      if (value == null) return;
                      setState(() {
                        _serviceType = value;
                        _errorText = null;
                      });
                    },
            ),
            if (_serviceType.isNotEmpty) ...<Widget>[
              const SizedBox(height: 12),
              _serviceType == 'human'
                  ? _ServicePair(
                      title: 'Human Service Details',
                      primaryLabel: 'Human Space ID (optional)',
                      primaryHint:
                          'Enter human space ID later in settings if needed',
                      primaryController: _humanSpaceController,
                      secondaryLabel: 'Human Schema ID (optional)',
                      secondaryHint:
                          'Enter human schema ID later in settings if needed',
                      secondaryController: _humanSchemaController,
                      backgroundColor: const Color(0xFFE9EEF3),
                    )
                  : _ServiceStack(
                      title: 'Product Service Details',
                      firstLabel: 'Product Space ID (optional)',
                      firstHint:
                          'Enter product space ID later in settings if needed',
                      firstController: _productSpaceController,
                      secondLabel: 'Product Schema ID (optional)',
                      secondHint:
                          'Enter product schema ID later in settings if needed',
                      secondController: _productSchemaController,
                      thirdLabel: 'Warranty Space ID (optional)',
                      thirdHint:
                          'Enter warranty space ID later in settings if needed',
                      thirdController: _warrantySpaceController,
                      fourthLabel: 'Warranty Schema ID (optional)',
                      fourthHint:
                          'Enter warranty schema ID later in settings if needed',
                      fourthController: _warrantySchemaController,
                      backgroundColor: const Color(0xFFE9EEF3),
                    ),
            ],
          ],
        );
      case _OrgEditMode.serviceIds:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(_subtitle(), style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 16),
            if (_isHuman) ...<Widget>[
              TMZInput(
                label: 'Human Space ID',
                hint: 'Enter human space id',
                controller: _humanSpaceController,
                enabled: !_isSaving,
                errorText: _errorText,
              ),
              const SizedBox(height: 12),
              TMZInput(
                label: 'Human Schema ID',
                hint: 'Enter human schema id',
                controller: _humanSchemaController,
                enabled: !_isSaving,
                errorText: _errorText,
              ),
            ] else ...<Widget>[
              TMZInput(
                label: 'Product Space ID',
                hint: 'Enter product space id',
                controller: _productSpaceController,
                enabled: !_isSaving,
                errorText: _errorText,
              ),
              const SizedBox(height: 12),
              TMZInput(
                label: 'Product Schema ID',
                hint: 'Enter product schema id',
                controller: _productSchemaController,
                enabled: !_isSaving,
                errorText: _errorText,
              ),
              const SizedBox(height: 12),
              TMZInput(
                label: 'Warranty Space ID',
                hint: 'Enter warranty space id',
                controller: _warrantySpaceController,
                enabled: !_isSaving,
                errorText: _errorText,
              ),
              const SizedBox(height: 12),
              TMZInput(
                label: 'Warranty Schema ID',
                hint: 'Enter warranty schema id',
                controller: _warrantySchemaController,
                enabled: !_isSaving,
                errorText: _errorText,
              ),
            ],
          ],
        );
      case _OrgEditMode.serviceType:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(_subtitle(), style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 16),
            ..._ProfileSettingsPageState._serviceTypeOptions.map(
              _buildServiceTypeOption,
            ),
            if (_errorText != null) ...<Widget>[
              const SizedBox(height: 4),
              Text(
                _errorText!,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ],
          ],
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final double bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      appBar: AppBar(title: Text(_title())),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 24 + bottomInset),
          children: <Widget>[
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              padding: const EdgeInsets.all(16),
              child: _buildBody(context),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: TMZButton(
                label: 'Save',
                onPressed: _isSaving ? null : _save,
                isLoading: _isSaving,
                fullWidth: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ServiceTypeField extends StatelessWidget {
  const _ServiceTypeField({required this.value, required this.onChanged});

  final String? value;
  final ValueChanged<String?>? onChanged;

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

class _FigmaScaleScope extends InheritedWidget {
  const _FigmaScaleScope({required this.scale, required super.child});

  final double scale;

  static double of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<_FigmaScaleScope>();
    return scope?.scale ?? 1.0;
  }

  @override
  bool updateShouldNotify(_FigmaScaleScope oldWidget) =>
      oldWidget.scale != scale;
}

class _OrgProfileHeader extends StatelessWidget {
  const _OrgProfileHeader({
    required this.onEdit,
    required this.displayName,
    required this.email,
    required this.phoneNumber,
    required this.isVerified,
  });

  final VoidCallback onEdit;
  final String displayName;
  final String email;
  final String phoneNumber;
  final bool isVerified;

  @override
  Widget build(BuildContext context) {
    final double scale = _FigmaScaleScope.of(context);
    double s(double v) => v * scale;

    return Column(
      children: <Widget>[
        _FigmaOrgAvatar(isVerified: isVerified, scale: scale),
        SizedBox(height: s(14)),
        Text(
          displayName,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: s(24),
            fontWeight: FontWeight.w700,
            height: 32 / 24,
            color: Color(0xFF0F172A),
          ),
        ),
        if (email.trim().isNotEmpty) ...<Widget>[
          SizedBox(height: s(6)),
          Text(
            email,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: s(14),
              fontWeight: FontWeight.w400,
              letterSpacing: 0.02734375,
              height: 20 / 14,
              color: Color(0xFF64748B),
            ),
          ),
        ],
        if (phoneNumber.trim().isNotEmpty) ...<Widget>[
          SizedBox(height: s(2)),
          Text(
            phoneNumber,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: s(13),
              fontWeight: FontWeight.w500,
              letterSpacing: 0.0234375,
              height: 18 / 13,
              color: Color(0xFF334155),
            ),
          ),
        ],
        SizedBox(height: s(10)),
        _VerificationPill(isVerified: isVerified),
        SizedBox(height: s(24)),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onEdit,
            borderRadius: BorderRadius.circular(16),
            child: Ink(
              height: s(60),
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.brandBlue,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    SvgPicture.asset(
                      'assets/icons/figma/account_edit_profile_icon.svg',
                      width: s(24),
                      height: s(24),
                      colorFilter: const ColorFilter.mode(
                        Colors.white,
                        BlendMode.srcIn,
                      ),
                    ),
                    SizedBox(width: s(12)),
                    Text(
                      'Edit Profile',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: s(18),
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.03515625,
                        height: 28 / 18,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _VerificationPill extends StatelessWidget {
  const _VerificationPill({required this.isVerified});

  final bool isVerified;

  @override
  Widget build(BuildContext context) {
    final double scale = _FigmaScaleScope.of(context);
    double s(double v) => v * scale;

    final Color bg = isVerified
        ? const Color(0xFFECFDF5)
        : const Color(0xFFEFF6FF);
    final Color border = isVerified
        ? const Color(0x3316A34A)
        : const Color(0xFF2563EB);
    final Color fg = isVerified
        ? const Color(0xFF16A34A)
        : const Color(0xFF2563EB);
    final String text = isVerified ? 'Verified' : 'Pending';

    return Container(
      padding: EdgeInsets.symmetric(horizontal: s(12), vertical: s(4)),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(9999),
        border: Border.all(color: border, width: 1),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: s(12),
          fontWeight: FontWeight.w600,
          letterSpacing: 0.05859375,
          height: 16 / 12,
          color: fg,
        ),
      ),
    );
  }
}

class _FigmaOrgAvatar extends StatelessWidget {
  const _FigmaOrgAvatar({required this.isVerified, required this.scale});

  final bool isVerified;
  final double scale;

  @override
  Widget build(BuildContext context) {
    double s(double v) => v * scale;
    final double size = s(129);
    final double borderWidth = s(4.03125);

    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: const Color(0xFFEFF3FF),
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.brandBlue, width: borderWidth),
          ),
          alignment: Alignment.center,
          child: SvgPicture.asset(
            'assets/icons/figma/org_avatar_user_outline.svg',
            width: s(62),
            height: s(62),
          ),
        ),
        Positioned(
          right: 0,
          bottom: 0,
          child: Container(
            width: s(40),
            height: s(40),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Color(0x40000000),
                  blurRadius: 2,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: SvgPicture.asset(
              'assets/icons/figma/account_verified_rounded.svg',
              width: s(23.33),
              height: s(22.37),
              colorFilter: isVerified
                  ? null
                  : const ColorFilter.mode(Color(0xFF2563EB), BlendMode.srcIn),
            ),
          ),
        ),
      ],
    );
  }
}

class _LogoutCard extends StatelessWidget {
  const _LogoutCard({required this.onLogout});

  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final double scale = _FigmaScaleScope.of(context);
    double s(double v) => v * scale;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onLogout,
        borderRadius: BorderRadius.circular(s(16)),
        child: Ink(
          height: s(60),
          width: double.infinity,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(s(16))),
          child: Stack(
            children: <Widget>[
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0x00FFFFFF),
                    borderRadius: BorderRadius.circular(s(16)),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: Color(0x332563EB),
                        blurRadius: s(15),
                        spreadRadius: s(-3),
                        offset: Offset(0, s(10)),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    // Equivalent to rgba(220, 38, 38, 0.05) over #F7F9FC.
                    // Use a baked solid color so the button doesn't pick up any
                    // underlying blue tint from what's behind it.
                    color: const Color(0xFFF6EEF1),
                    borderRadius: BorderRadius.circular(s(16)),
                    border: Border.all(
                      // Equivalent to rgba(220, 38, 38, 0.2) over #F7F9FC.
                      color: const Color(0xFFF2CFD1),
                      width: 2,
                    ),
                  ),
                ),
              ),
              Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: s(16)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      SvgPicture.asset(
                        'assets/icons/figma/account_logout_figma.svg',
                        width: s(24),
                        height: s(24),
                      ),
                      SizedBox(width: s(12)),
                      Text(
                        'Logout',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: s(18),
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.03515625,
                          height: 28 / 18,
                          color: Color(0xFFDC2626),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GeneralInfoCard extends StatelessWidget {
  const _GeneralInfoCard({required this.profile});

  final UserProfile? profile;

  @override
  Widget build(BuildContext context) {
    final double scale = _FigmaScaleScope.of(context);
    double s(double v) => v * scale;

    final String orgName = profile?.organizationName?.trim().isNotEmpty == true
        ? profile!.organizationName!.trim()
        : (profile?.fullName?.trim().isNotEmpty == true
              ? profile!.fullName!.trim()
              : '—');
    final String email = profile?.email.trim().isNotEmpty == true
        ? profile!.email.trim()
        : '—';
    final String phoneNumber = profile?.phoneNumber?.trim().isNotEmpty == true
        ? profile!.phoneNumber!.trim()
        : '—';
    final String accountType = profile?.userType.trim().isNotEmpty == true
        ? profile!.userType.trim()
        : (profile?.loginType.trim().isNotEmpty == true
              ? profile!.loginType.trim()
              : '—');
    final bool isActive = profile?.isActive == true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            Text(
              'GENERAL INFORMATION',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: s(12),
                fontWeight: FontWeight.w600,
                letterSpacing: 1.1833819,
                height: 17.7507286 / 12,
                color: Color(0xFF323232),
              ),
            ),
            const Spacer(),
            if (isActive)
              Container(
                padding: EdgeInsets.fromLTRB(s(10), s(4), s(10), s(4)),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(s(4)),
                ),
                child: Text(
                  'Status: Active',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: s(10),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.1171875,
                    height: 15 / 10,
                    color: Color(0xFF16A34A),
                  ),
                ),
              ),
          ],
        ),
        SizedBox(height: s(12)),
        _FigmaInfoCard(
          rows: <_InfoRow>[
            _InfoRow(label: 'Official Name', value: orgName),
            _InfoRow(label: 'Official Email', value: email),
            _InfoRow(label: 'Phone Number', value: phoneNumber),
            _InfoRow(label: 'Account Type', value: accountType),
            _InfoRow(label: 'Profile ID', value: profile?.id ?? '—'),
          ],
        ),
      ],
    );
  }
}

class _OrganisationDetailsCard extends StatelessWidget {
  const _OrganisationDetailsCard({
    required this.profile,
    required this.onEditServiceType,
  });

  final UserProfile? profile;
  final VoidCallback onEditServiceType;

  @override
  Widget build(BuildContext context) {
    final double scale = _FigmaScaleScope.of(context);
    double s(double v) => v * scale;

    final String gstin = profile?.gstin?.trim().isNotEmpty == true
        ? profile!.gstin!.trim()
        : '—';
    final String businessRegNumber =
        profile?.businessRegNumber?.trim().isNotEmpty == true
        ? profile!.businessRegNumber!.trim()
        : '—';
    final String serviceType = profile?.serviceType?.trim().toLowerCase() ?? '';
    final bool hasServiceType = serviceType.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          'ORGANISATION DETAILS',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: s(12),
            fontWeight: FontWeight.w600,
            letterSpacing: 1.1833819,
            height: 17.7507286 / 12,
            color: Color(0xFF323232),
          ),
        ),
        SizedBox(height: s(12)),
        _FigmaInfoCard(
          rows: <_InfoRow>[
            _InfoRow(label: 'GSTIN', value: gstin),
            _InfoRow(label: 'Business Reg. Number', value: businessRegNumber),
            _InfoRow(
              label: 'Service Type',
              value: hasServiceType ? serviceType : '—',
              trailing: TextButton.icon(
                onPressed: onEditServiceType,
                icon: Icon(
                  hasServiceType ? Icons.edit_outlined : Icons.add_rounded,
                  size: s(16),
                ),
                label: Text(hasServiceType ? 'Edit' : 'Set'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.brandBlue,
                  visualDensity: VisualDensity.compact,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  minimumSize: Size.zero,
                  padding: EdgeInsets.zero,
                  textStyle: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: s(12),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.05859375,
                    height: 16 / 12,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _AddressAndRecordsCard extends StatelessWidget {
  const _AddressAndRecordsCard({required this.profile});

  final UserProfile? profile;

  @override
  Widget build(BuildContext context) {
    final double scale = _FigmaScaleScope.of(context);
    double s(double v) => v * scale;

    final String addressLine1 = profile?.addressLine1?.trim().isNotEmpty == true
        ? profile!.addressLine1!.trim()
        : '—';
    final String addressLine2 = profile?.addressLine2?.trim().isNotEmpty == true
        ? profile!.addressLine2!.trim()
        : '—';
    final String addressLine3 = profile?.addressLine3?.trim().isNotEmpty == true
        ? profile!.addressLine3!.trim()
        : '—';
    final String createdAt = profile?.createdAt == null
        ? '—'
        : _formatDateTime(profile!.createdAt!);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          'ADDRESS & RECORDS',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: s(12),
            fontWeight: FontWeight.w600,
            letterSpacing: 1.1833819,
            height: 17.7507286 / 12,
            color: Color(0xFF323232),
          ),
        ),
        SizedBox(height: s(12)),
        _FigmaInfoCard(
          rows: <_InfoRow>[
            _InfoRow(label: 'Address Line 1', value: addressLine1),
            _InfoRow(label: 'Address Line 2', value: addressLine2),
            _InfoRow(label: 'Address Line 3', value: addressLine3),
            _InfoRow(label: 'Created At', value: createdAt),
          ],
        ),
      ],
    );
  }
}

class _SpaceIdsCard extends StatelessWidget {
  const _SpaceIdsCard({required this.profile, required this.onEditSpaceIds});

  final UserProfile? profile;
  final VoidCallback onEditSpaceIds;

  @override
  Widget build(BuildContext context) {
    final double scale = _FigmaScaleScope.of(context);
    double s(double v) => v * scale;

    final String serviceType = profile?.serviceType?.trim().toLowerCase() ?? '';
    final bool isHuman = serviceType == 'human';
    final bool isProduct = serviceType == 'product';
    final String humanSpaceId = profile?.humanSpaceId?.trim().isNotEmpty == true
        ? profile!.humanSpaceId!.trim()
        : '—';
    final String humanSchemaId =
        profile?.humanSchemaId?.trim().isNotEmpty == true
        ? profile!.humanSchemaId!.trim()
        : '—';
    final String productSpaceId =
        profile?.productSpaceId?.trim().isNotEmpty == true
        ? profile!.productSpaceId!.trim()
        : '—';
    final String productSchemaId =
        profile?.productSchemaId?.trim().isNotEmpty == true
        ? profile!.productSchemaId!.trim()
        : '—';
    final String warrantySpaceId =
        profile?.warrantySpaceId?.trim().isNotEmpty == true
        ? profile!.warrantySpaceId!.trim()
        : '—';
    final String warrantySchemaId =
        profile?.warrantySchemaId?.trim().isNotEmpty == true
        ? profile!.warrantySchemaId!.trim()
        : '—';
    final bool hasHumanSpaceId =
        profile?.humanSpaceId?.trim().isNotEmpty == true;
    final bool hasHumanSchemaId =
        profile?.humanSchemaId?.trim().isNotEmpty == true;
    final bool hasProductSpaceId =
        profile?.productSpaceId?.trim().isNotEmpty == true;
    final bool hasProductSchemaId =
        profile?.productSchemaId?.trim().isNotEmpty == true;
    final bool hasWarrantySpaceId =
        profile?.warrantySpaceId?.trim().isNotEmpty == true;
    final bool hasWarrantySchemaId =
        profile?.warrantySchemaId?.trim().isNotEmpty == true;
    final bool showHumanSection = serviceType.isEmpty || isHuman;
    final bool showProductSection = serviceType.isEmpty || isProduct;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          'SPACE IDS',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: s(12),
            fontWeight: FontWeight.w600,
            letterSpacing: 1.1833819,
            height: 17.7507286 / 12,
            color: Color(0xFF323232),
          ),
        ),
        SizedBox(height: s(12)),
        _FigmaInfoCard(
          rows: <_InfoRow>[
            if (showHumanSection)
              _InfoRow(
                label: 'Human Space ID',
                value: humanSpaceId,
                trailing: TextButton.icon(
                  onPressed: onEditSpaceIds,
                  icon: Icon(
                    hasHumanSpaceId ? Icons.edit_outlined : Icons.add_rounded,
                    size: s(16),
                  ),
                  label: Text(hasHumanSpaceId ? 'Edit' : 'Add'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.brandBlue,
                    visualDensity: VisualDensity.compact,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    minimumSize: Size.zero,
                    padding: EdgeInsets.zero,
                    textStyle: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: s(12),
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.05859375,
                      height: 16 / 12,
                    ),
                  ),
                ),
              ),
            if (showHumanSection)
              _InfoRow(
                label: 'Human Schema ID',
                value: humanSchemaId,
                trailing: TextButton.icon(
                  onPressed: onEditSpaceIds,
                  icon: Icon(
                    hasHumanSchemaId ? Icons.edit_outlined : Icons.add_rounded,
                    size: s(16),
                  ),
                  label: Text(hasHumanSchemaId ? 'Edit' : 'Add'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.brandBlue,
                    visualDensity: VisualDensity.compact,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    minimumSize: Size.zero,
                    padding: EdgeInsets.zero,
                    textStyle: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: s(12),
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.05859375,
                      height: 16 / 12,
                    ),
                  ),
                ),
              ),
            if (showProductSection) ...<_InfoRow>[
              _InfoRow(
                label: 'Product Space ID',
                value: productSpaceId,
                trailing: TextButton.icon(
                  onPressed: onEditSpaceIds,
                  icon: Icon(
                    hasProductSpaceId ? Icons.edit_outlined : Icons.add_rounded,
                    size: s(16),
                  ),
                  label: Text(hasProductSpaceId ? 'Edit' : 'Add'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.brandBlue,
                    visualDensity: VisualDensity.compact,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    minimumSize: Size.zero,
                    padding: EdgeInsets.zero,
                    textStyle: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: s(12),
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.05859375,
                      height: 16 / 12,
                    ),
                  ),
                ),
              ),
              _InfoRow(
                label: 'Product Schema ID',
                value: productSchemaId,
                trailing: TextButton.icon(
                  onPressed: onEditSpaceIds,
                  icon: Icon(
                    hasProductSchemaId
                        ? Icons.edit_outlined
                        : Icons.add_rounded,
                    size: s(16),
                  ),
                  label: Text(hasProductSchemaId ? 'Edit' : 'Add'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.brandBlue,
                    visualDensity: VisualDensity.compact,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    minimumSize: Size.zero,
                    padding: EdgeInsets.zero,
                    textStyle: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: s(12),
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.05859375,
                      height: 16 / 12,
                    ),
                  ),
                ),
              ),
            ],
            if (showProductSection) ...<_InfoRow>[
              _InfoRow(
                label: 'Warranty Space ID',
                value: warrantySpaceId,
                trailing: TextButton.icon(
                  onPressed: onEditSpaceIds,
                  icon: Icon(
                    hasWarrantySpaceId
                        ? Icons.edit_outlined
                        : Icons.add_rounded,
                    size: s(16),
                  ),
                  label: Text(hasWarrantySpaceId ? 'Edit' : 'Add'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.brandBlue,
                    visualDensity: VisualDensity.compact,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    minimumSize: Size.zero,
                    padding: EdgeInsets.zero,
                    textStyle: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: s(12),
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.05859375,
                      height: 16 / 12,
                    ),
                  ),
                ),
              ),
              _InfoRow(
                label: 'Warranty Schema ID',
                value: warrantySchemaId,
                trailing: TextButton.icon(
                  onPressed: onEditSpaceIds,
                  icon: Icon(
                    hasWarrantySchemaId
                        ? Icons.edit_outlined
                        : Icons.add_rounded,
                    size: s(16),
                  ),
                  label: Text(hasWarrantySchemaId ? 'Edit' : 'Add'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.brandBlue,
                    visualDensity: VisualDensity.compact,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    minimumSize: Size.zero,
                    padding: EdgeInsets.zero,
                    textStyle: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: s(12),
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.05859375,
                      height: 16 / 12,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _AccountStatusCard extends StatelessWidget {
  const _AccountStatusCard({required this.profile});

  final UserProfile? profile;

  @override
  Widget build(BuildContext context) {
    final double scale = _FigmaScaleScope.of(context);
    double s(double v) => v * scale;
    final String accountType = profile?.userType.trim().isNotEmpty == true
        ? profile!.userType.trim().toLowerCase()
        : profile?.loginType.trim().toLowerCase() ?? '';
    final bool isOrgAccount =
        accountType.isEmpty || accountType == 'organization';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          'ACCOUNT STATUS',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: s(12),
            fontWeight: FontWeight.w600,
            letterSpacing: 1.1833819,
            height: 17.7507286 / 12,
            color: Color(0xFF323232),
          ),
        ),
        SizedBox(height: s(12)),
        _FigmaInfoCard(
          rows: <_InfoRow>[
            _InfoRow(
              label: 'Active',
              value: profile?.isActive == true ? 'Yes' : 'No',
            ),
            _InfoRow(
              label: 'Email Verified',
              value: profile?.emailVerified == true ? 'Yes' : 'No',
            ),
            _InfoRow(
              label: 'Onboarding Completed',
              value: profile?.onboardingCompleted == true ? 'Yes' : 'No',
            ),
            if (!isOrgAccount)
              _InfoRow(
                label: 'Skill Tree Initiated',
                value: profile?.skillTreeInitiated == true ? 'Yes' : 'No',
              ),
            if (!isOrgAccount)
              _InfoRow(
                label: 'Mobile Verified',
                value: profile?.mobileVerified == true ? 'Yes' : 'No',
              ),
          ],
        ),
      ],
    );
  }
}

class _InfoRow {
  const _InfoRow({required this.label, required this.value, this.trailing});

  final String label;
  final String value;
  final Widget? trailing;
}

class _FigmaCard extends StatelessWidget {
  const _FigmaCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final double scale = _FigmaScaleScope.of(context);
    double s(double v) => v * scale;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(s(16)),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _FigmaInfoCard extends StatelessWidget {
  const _FigmaInfoCard({required this.rows});

  final List<_InfoRow> rows;

  @override
  Widget build(BuildContext context) {
    return _FigmaCard(
      child: Column(
        children: <Widget>[
          for (int i = 0; i < rows.length; i++) ...<Widget>[
            _InfoRowTile(row: rows[i]),
            if (i != rows.length - 1)
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
          ],
        ],
      ),
    );
  }
}

class _InfoRowTile extends StatelessWidget {
  const _InfoRowTile({required this.row});

  final _InfoRow row;

  @override
  Widget build(BuildContext context) {
    final double scale = _FigmaScaleScope.of(context);
    double s(double v) => v * scale;

    final Widget labelValue = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(
          row.label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: s(12),
            fontWeight: FontWeight.w500,
            height: 16 / 12,
            color: Color(0xFF94A3B8),
          ),
        ),
        Text(
          row.value,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: s(14),
            fontWeight: FontWeight.w600,
            height: 20 / 14,
            color: Color(0xFF323232),
          ),
        ),
      ],
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(s(16), s(16), s(16), s(16)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Expanded(child: labelValue),
          if (row.trailing != null) ...<Widget>[
            SizedBox(width: s(12)),
            row.trailing!,
          ],
        ],
      ),
    );
  }
}

class _MemberLine extends StatelessWidget {
  const _MemberLine({required this.name, required this.role});

  final String name;
  final String role;

  @override
  Widget build(BuildContext context) {
    final double scale = _FigmaScaleScope.of(context);
    double s(double v) => v * scale;

    return Padding(
      padding: EdgeInsets.fromLTRB(s(16), s(14), s(16), s(14)),
      child: Row(
        children: <Widget>[
          Container(
            width: s(36),
            height: s(36),
            decoration: const BoxDecoration(
              color: Color(0xFFEFF6FF),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.person_rounded,
              color: AppColors.brandBlue,
              size: s(20),
            ),
          ),
          SizedBox(width: s(12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  name,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: s(14),
                    fontWeight: FontWeight.w600,
                    height: 20 / 14,
                    color: Color(0xFF1E293B),
                  ),
                ),
                SizedBox(height: s(2)),
                Text(
                  role,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: s(12),
                    fontWeight: FontWeight.w500,
                    height: 16 / 12,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.more_horiz_rounded,
            size: s(24),
            color: const Color(0xFF94A3B8),
          ),
        ],
      ),
    );
  }
}

class _TeamAccessCard extends StatelessWidget {
  const _TeamAccessCard();

  @override
  Widget build(BuildContext context) {
    final double scale = _FigmaScaleScope.of(context);
    double s(double v) => v * scale;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            Text(
              'TEAM MEMBERS',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: s(12),
                fontWeight: FontWeight.w600,
                letterSpacing: 1.1833819,
                height: 17.7507286 / 12,
                color: Color(0xFF323232),
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: () {},
              icon: Icon(Icons.add_rounded, size: s(16)),
              label: Text('Invite'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.brandBlue,
                visualDensity: VisualDensity.compact,
                textStyle: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: s(12),
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.05859375,
                  height: 16 / 12,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: s(12)),
        _FigmaCard(
          child: Column(
            children: <Widget>[
              const _MemberLine(
                name: 'Alex Rivera',
                role: 'Owner • Full Access',
              ),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              const _MemberLine(name: 'Sarah Chen', role: 'Admin • Operations'),
              SizedBox(height: s(10)),
              Center(
                child: Text(
                  'View all 12 members',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: s(12),
                    fontWeight: FontWeight.w600,
                    height: 16 / 12,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
              SizedBox(height: s(10)),
            ],
          ),
        ),
      ],
    );
  }
}

String _formatDateTime(DateTime value) {
  final DateTime local = value.toLocal();
  String twoDigits(int n) => n.toString().padLeft(2, '0');
  return '${local.year}-${twoDigits(local.month)}-${twoDigits(local.day)} '
      '${twoDigits(local.hour)}:${twoDigits(local.minute)}';
}

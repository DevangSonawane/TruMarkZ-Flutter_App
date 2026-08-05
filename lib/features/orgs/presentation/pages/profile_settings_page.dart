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
  static const List<String> _serviceTypeOptions = <String>['product', 'human'];

  Future<void> _showDhiwaySpaceIdDialog(UserProfile? profile) async {
    final String serviceType = profile?.serviceType?.trim().toLowerCase() ?? '';
    final bool isHuman = serviceType == 'human';
    final bool isProduct = serviceType == 'product';
    final TextEditingController humanController = TextEditingController(
      text: profile?.humanSpaceId?.trim().isNotEmpty == true
          ? profile!.humanSpaceId!.trim()
          : profile?.dhiwaySpaceId?.trim() ?? '',
    );
    final TextEditingController productController = TextEditingController(
      text: profile?.productSpaceId?.trim().isNotEmpty == true
          ? profile!.productSpaceId!.trim()
          : profile?.dhiwaySpaceId?.trim() ?? '',
    );
    final TextEditingController warrantyController = TextEditingController(
      text: profile?.warrantySpaceId?.trim().isNotEmpty == true
          ? profile!.warrantySpaceId!.trim()
          : profile?.dhiwaySpaceId?.trim() ?? '',
    );

    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        bool isSaving = false;
        String? errorText;

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            Future<void> save() async {
              final String humanSpaceId = humanController.text.trim();
              final String productSpaceId = productController.text.trim();
              final String warrantySpaceId = warrantyController.text.trim();

              if (isHuman && humanSpaceId.isEmpty) {
                setDialogState(() {
                  errorText = 'Please enter a Human Space ID.';
                });
                return;
              }
              if (isProduct &&
                  productSpaceId.isEmpty &&
                  warrantySpaceId.isEmpty) {
                setDialogState(() {
                  errorText =
                      'Please enter at least one Product or Warranty Space ID.';
                });
                return;
              }
              setDialogState(() {
                isSaving = true;
                errorText = null;
              });
              final NavigatorState navigator = Navigator.of(dialogContext);
              final ScaffoldMessengerState messenger = ScaffoldMessenger.of(
                dialogContext,
              );
              try {
                await ref
                    .read(authNotifierProvider.notifier)
                    .updateDhiwaySpaces(
                      humanSpaceId: isHuman ? humanSpaceId : null,
                      productSpaceId: isProduct ? productSpaceId : null,
                      warrantySpaceId: isProduct ? warrantySpaceId : null,
                    );
                if (!mounted) return;
                navigator.pop();
                final String successMessage = isHuman
                    ? 'Human Space ID updated successfully.'
                    : 'Product and Warranty Space IDs updated successfully.';
                messenger.showSnackBar(SnackBar(content: Text(successMessage)));
              } on ApiException catch (e) {
                if (!mounted) return;
                setDialogState(() {
                  errorText = e.message;
                });
              } finally {
                if (mounted) {
                  setDialogState(() {
                    isSaving = false;
                  });
                }
              }
            }

            return AlertDialog(
              title: Text(
                isHuman
                    ? 'Update Human Space ID'
                    : isProduct
                    ? 'Update Product Space IDs'
                    : 'Update Dhiway Space IDs',
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    isHuman
                        ? 'Save the human credential space shared by the superadmin.'
                        : isProduct
                        ? 'Save the product and warranty spaces shared by the superadmin.'
                        : 'Save the space ids shared by the superadmin for this organization.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  if (isHuman) ...<Widget>[
                    TMZInput(
                      label: 'Human Space ID',
                      hint: 'Enter human space id',
                      controller: humanController,
                      enabled: !isSaving,
                      errorText: errorText,
                    ),
                  ] else if (isProduct) ...<Widget>[
                    TMZInput(
                      label: 'Product Space ID',
                      hint: 'Enter product space id',
                      controller: productController,
                      enabled: !isSaving,
                      errorText: errorText,
                    ),
                    const SizedBox(height: 12),
                    TMZInput(
                      label: 'Warranty Space ID',
                      hint: 'Enter warranty space id',
                      controller: warrantyController,
                      enabled: !isSaving,
                      errorText: errorText,
                    ),
                  ] else ...<Widget>[
                    TMZInput(
                      label: 'Dhiway Space ID',
                      hint: 'Enter space id',
                      controller: humanController,
                      enabled: !isSaving,
                      errorText: errorText,
                    ),
                  ],
                ],
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: isSaving
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                SizedBox(
                  width: 140,
                  child: TMZButton(
                    label: 'Save',
                    onPressed: isSaving ? null : save,
                    isLoading: isSaving,
                    fullWidth: true,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
    humanController.dispose();
    productController.dispose();
    warrantyController.dispose();
  }

  Future<void> _showServiceTypeDialog(UserProfile? profile) async {
    final String currentServiceType =
        profile?.serviceType?.trim().toLowerCase() ?? '';
    final String initialValue = _serviceTypeOptions.contains(currentServiceType)
        ? currentServiceType
        : _serviceTypeOptions.first;

    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        bool isSaving = false;
        String selectedServiceType = initialValue;
        String? errorText;

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            Future<void> save() async {
              setDialogState(() {
                isSaving = true;
                errorText = null;
              });
              final NavigatorState navigator = Navigator.of(dialogContext);
              final ScaffoldMessengerState messenger = ScaffoldMessenger.of(
                dialogContext,
              );
              try {
                await ref
                    .read(authNotifierProvider.notifier)
                    .updateServiceType(selectedServiceType);
                if (!mounted) return;
                navigator.pop();
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      'Service type updated to ${selectedServiceType.toUpperCase()}.',
                    ),
                  ),
                );
              } on ApiException catch (e) {
                if (!mounted) return;
                setDialogState(() {
                  errorText = e.message;
                });
              } finally {
                if (mounted) {
                  setDialogState(() {
                    isSaving = false;
                  });
                }
              }
            }

            return AlertDialog(
              title: const Text('Update Service Type'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    'Choose what your organization deals in. You can change this anytime.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  ..._serviceTypeOptions.map((String option) {
                    final bool isSelected = selectedServiceType == option;
                    final String title = option == 'product'
                        ? 'Product'
                        : 'Human';
                    final String description = option == 'product'
                        ? 'For product batches, registry, and certificate flows.'
                        : 'For people, credentials, and human verification flows.';

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        onTap: isSaving
                            ? null
                            : () {
                                setDialogState(() {
                                  selectedServiceType = option;
                                  errorText = null;
                                });
                              },
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFFEFF6FF)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.brandBlue
                                  : const Color(0xFFE2E8F0),
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
                  }),
                  if (errorText != null) ...<Widget>[
                    const SizedBox(height: 4),
                    Text(
                      errorText!,
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ],
                ],
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: isSaving
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                SizedBox(
                  width: 140,
                  child: TMZButton(
                    label: 'Save',
                    onPressed: isSaving ? null : save,
                    isLoading: isSaving,
                    fullWidth: true,
                  ),
                ),
              ],
            );
          },
        );
      },
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
                              onEdit: () {},
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
                                  _showDhiwaySpaceIdDialog(profile),
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
        : profile?.dhiwaySpaceId?.trim().isNotEmpty == true
        ? profile!.dhiwaySpaceId!.trim()
        : '—';
    final String productSpaceId =
        profile?.productSpaceId?.trim().isNotEmpty == true
        ? profile!.productSpaceId!.trim()
        : profile?.dhiwaySpaceId?.trim().isNotEmpty == true
        ? profile!.dhiwaySpaceId!.trim()
        : '—';
    final String warrantySpaceId =
        profile?.warrantySpaceId?.trim().isNotEmpty == true
        ? profile!.warrantySpaceId!.trim()
        : '—';
    final bool hasHumanSpaceId =
        profile?.humanSpaceId?.trim().isNotEmpty == true ||
        profile?.dhiwaySpaceId?.trim().isNotEmpty == true;
    final bool hasProductSpaceId =
        profile?.productSpaceId?.trim().isNotEmpty == true ||
        profile?.dhiwaySpaceId?.trim().isNotEmpty == true;
    final bool hasWarrantySpaceId =
        profile?.warrantySpaceId?.trim().isNotEmpty == true;

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
            if (isHuman || serviceType.isEmpty)
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
            if (isProduct || serviceType.isEmpty) ...<_InfoRow>[
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

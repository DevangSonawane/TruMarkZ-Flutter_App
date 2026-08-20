import 'dart:convert';

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
import '../../../../../core/widgets/tmz_input.dart';
import '../../../../auth/application/auth_notifier.dart';
import '../../../../auth/data/auth_repository.dart';

class OrgOnboardingPage extends ConsumerStatefulWidget {
  const OrgOnboardingPage({super.key});

  @override
  ConsumerState<OrgOnboardingPage> createState() => _OrgOnboardingPageState();
}

class _OrgOnboardingPageState extends ConsumerState<OrgOnboardingPage> {
  final TextEditingController _useCases = TextEditingController();
  final TextEditingController _gstin = TextEditingController();
  final TextEditingController _businessRegNumber = TextEditingController();
  final TextEditingController _address1 = TextEditingController();
  final TextEditingController _address2 = TextEditingController();
  final TextEditingController _address3 = TextEditingController();
  final TextEditingController _spaceId = TextEditingController();
  final TextEditingController _schemaId = TextEditingController();
  final List<_DhiwayDetailDraft> _extraDhiwayDetails = <_DhiwayDetailDraft>[];

  static const List<String> _industryOptions = <String>[
    'Transport',
    'Healthcare',
    'Education',
    'Manufacturing',
    'Security',
    'Agriculture',
    'Beauty & Cosmetics',
    'Consumer Goods',
    'Electronics & Appliances',
    'EV & Automotive',
    'Healthcare Products',
    'Industrial Equipment',
    'Insurance Policies',
    'Agriculture Products',
    'Luxury Products',
    'Others',
  ];

  String? _industryType;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final UserProfile? profile = ref
        .read(authNotifierProvider)
        .valueOrNull
        ?.userProfile;
    final String? profileIndustry = profile?.industry?.trim();
    if (_industryOptions.contains(profileIndustry)) {
      _industryType = profileIndustry;
    }
    if (profile?.useCases.isNotEmpty == true) {
      _useCases.text = jsonEncode(profile!.useCases);
    }
    _gstin.text = profile?.gstin?.trim() ?? '';
    _businessRegNumber.text = profile?.businessRegNumber?.trim() ?? '';
    _address1.text = profile?.addressLine1?.trim() ?? '';
    _address2.text = profile?.addressLine2?.trim() ?? '';
    _address3.text = profile?.addressLine3?.trim() ?? '';
    _seedDhiwayDetails(profile);
    if (_extraDhiwayDetails.isEmpty) {
      _extraDhiwayDetails.add(_DhiwayDetailDraft());
    }
  }

  @override
  void dispose() {
    _useCases.dispose();
    _gstin.dispose();
    _businessRegNumber.dispose();
    _address1.dispose();
    _address2.dispose();
    _address3.dispose();
    _spaceId.dispose();
    _schemaId.dispose();
    for (final _DhiwayDetailDraft detail in _extraDhiwayDetails) {
      detail.dispose();
    }
    super.dispose();
  }

  void _seedDhiwayDetails(UserProfile? profile) {
    final List<DhiwayDetail> details =
        profile?.dhiwaysDetails ?? <DhiwayDetail>[];
    if (details.isNotEmpty) {
      _spaceId.text = details.first.spaceId.trim();
      _schemaId.text = details.first.schemaId.trim();
      _extraDhiwayDetails.addAll(
        details.skip(1).map(_DhiwayDetailDraft.fromModel),
      );
      return;
    }

    final String legacySpaceId =
        profile?.dhiwaySpaceId?.trim() ??
        profile?.humanSpaceId?.trim() ??
        profile?.productSpaceId?.trim() ??
        profile?.warrantySpaceId?.trim() ??
        '';
    final String legacySchemaId =
        profile?.humanSchemaId?.trim() ??
        profile?.productSchemaId?.trim() ??
        profile?.warrantySchemaId?.trim() ??
        '';
    _spaceId.text = legacySpaceId;
    _schemaId.text = legacySchemaId;
  }

  void _addDhiwayDetail() {
    setState(() {
      _extraDhiwayDetails.add(_DhiwayDetailDraft());
    });
  }

  void _removeDhiwayDetail(int index) {
    if (index < 0 || index >= _extraDhiwayDetails.length) return;
    setState(() {
      final _DhiwayDetailDraft detail = _extraDhiwayDetails.removeAt(index);
      detail.dispose();
    });
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;

    final String primarySpaceId = _spaceId.text.trim();
    final String primarySchemaId = _schemaId.text.trim();
    final List<DhiwayDetail> extraDhiwayDetails = _extraDhiwayDetails
        .map(
          (detail) => DhiwayDetail(
            spaceId: detail.spaceController.text.trim(),
            schemaId: detail.schemaController.text.trim(),
          ),
        )
        .where(
          (DhiwayDetail detail) =>
              detail.spaceId.isNotEmpty || detail.schemaId.isNotEmpty,
        )
        .toList();

    final OrgOnboardingRequest request = OrgOnboardingRequest(
      gstin: _gstin.text,
      businessRegNumber: _businessRegNumber.text,
      addressLine1: _address1.text,
      addressLine2: _address2.text,
      addressLine3: _address3.text,
      industryType: _industryType,
      spaceId: primarySpaceId,
      schemaId: primarySchemaId,
      useCases: _parseUseCases(_useCases.text),
      dhiwaysDetails: extraDhiwayDetails.isEmpty ? null : extraDhiwayDetails,
    );

    setState(() => _isSubmitting = true);
    try {
      await ref.read(authRepositoryProvider).completeOrgOnboarding(request);
      await ref.read(authNotifierProvider.notifier).refreshCurrentUser();

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Onboarding completed')));
      context.go(AppRouter.dashboardPath);
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

  Map<String, dynamic> _parseUseCases(String raw) {
    final String value = raw.trim();
    if (value.isEmpty) return <String, dynamic>{};
    try {
      final dynamic decoded = jsonDecode(value);
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
      if (decoded is List) {
        return <String, dynamic>{'items': decoded};
      }
    } catch (_) {
      // Fall back to a simple summary object so the backend still receives
      // the required `use_cases` key even when the user enters plain text.
    }
    return <String, dynamic>{'summary': value};
  }

  void _setIndustryType(String? value) {
    setState(() {
      _industryType = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final double systemBottomInset = MediaQuery.of(context).viewPadding.bottom;
    const Color inputBg = Color(0xFFE9EEF3);

    return Scaffold(
      backgroundColor: AppColors.pageBg,
      appBar: AppBar(
        title: const Text('Complete Onboarding'),
        leading: IconButton(
          onPressed: () =>
              context.go('${AppRouter.loginPath}?type=organization&force=true'),
          icon: const Icon(Icons.close_rounded),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.x5,
          AppSpacing.x4,
          AppSpacing.x5,
          AppSpacing.x6 + systemBottomInset,
        ),
        children: <Widget>[
          Text(
            'Tell us about your organisation',
            style: AppTypography.heading1.copyWith(fontSize: 20),
          ),
          const SizedBox(height: AppSpacing.x2),
          Text(
            'Add the details you want to save now. The app will submit the full onboarding payload even if some fields are left blank.',
            style: AppTypography.body2.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.x5),
          Container(
            padding: const EdgeInsets.all(AppSpacing.x4),
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: scheme.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                TMZInput(
                  label: 'GSTIN (optional)',
                  hint: '27AABCU9603R1ZM',
                  controller: _gstin,
                  enabled: !_isSubmitting,
                  backgroundColor: inputBg,
                ),
                const SizedBox(height: AppSpacing.x3),
                TMZInput(
                  label: 'Business Reg Number (optional)',
                  hint: 'U12345MH2024PTC123456',
                  controller: _businessRegNumber,
                  enabled: !_isSubmitting,
                  backgroundColor: inputBg,
                ),
                const SizedBox(height: AppSpacing.x3),
                TMZInput(
                  label: 'Address Line 1 (optional)',
                  hint: 'Street, building, etc.',
                  controller: _address1,
                  enabled: !_isSubmitting,
                  backgroundColor: inputBg,
                ),
                const SizedBox(height: AppSpacing.x3),
                TMZInput(
                  label: 'Address Line 2 (optional)',
                  hint: 'Area / locality',
                  controller: _address2,
                  enabled: !_isSubmitting,
                  backgroundColor: inputBg,
                ),
                const SizedBox(height: AppSpacing.x3),
                TMZInput(
                  label: 'Address Line 3 (optional)',
                  hint: 'City / state',
                  controller: _address3,
                  enabled: !_isSubmitting,
                  backgroundColor: inputBg,
                ),
                const SizedBox(height: AppSpacing.x3),
                Text(
                  'Primary Dhiway Pair',
                  style: AppTypography.body2.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.x2),
                TMZInput(
                  label: 'Space ID (optional)',
                  hint: 'Enter space id',
                  controller: _spaceId,
                  enabled: !_isSubmitting,
                  backgroundColor: inputBg,
                ),
                const SizedBox(height: AppSpacing.x3),
                TMZInput(
                  label: 'Schema ID (optional)',
                  hint: 'Enter schema id',
                  controller: _schemaId,
                  enabled: !_isSubmitting,
                  backgroundColor: inputBg,
                ),
                const SizedBox(height: AppSpacing.x3),
                _DhiwayDetailsEditor(
                  details: _extraDhiwayDetails,
                  enabled: !_isSubmitting,
                  onAdd: _addDhiwayDetail,
                  onRemove: _removeDhiwayDetail,
                ),
                const SizedBox(height: AppSpacing.x3),
                DropdownButtonFormField<String>(
                  initialValue: _industryType,
                  onChanged: _isSubmitting ? null : _setIndustryType,
                  items: _industryOptions
                      .map(
                        (String option) => DropdownMenuItem<String>(
                          value: option,
                          child: Text(option),
                        ),
                      )
                      .toList(),
                  decoration: InputDecoration(
                    labelText: 'Industry Type',
                    hintText: 'Select industry type',
                    filled: true,
                    fillColor: inputBg,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: scheme.outlineVariant),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: scheme.outlineVariant),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.brandBlue),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.x3),
                TMZInput(
                  label: 'Use Cases (JSON or short text)',
                  hint: '{"primary":"customer onboarding"}',
                  controller: _useCases,
                  enabled: !_isSubmitting,
                  backgroundColor: inputBg,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.x5),
          TMZButton(
            label: 'Finish',
            isLoading: _isSubmitting,
            onPressed: _isSubmitting ? null : _submit,
          ),
        ],
      ),
    );
  }
}

class _DhiwayDetailsEditor extends StatelessWidget {
  const _DhiwayDetailsEditor({
    required this.details,
    required this.enabled,
    required this.onAdd,
    required this.onRemove,
  });

  final List<_DhiwayDetailDraft> details;
  final bool enabled;
  final VoidCallback onAdd;
  final void Function(int index) onRemove;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                'Additional Dhiway Pairs',
                style: AppTypography.body2.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: enabled ? onAdd : null,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add pair'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.x2),
        Text(
          'Optional extra space and schema pairs. The first pair above is treated as the primary onboarding pair.',
          style: AppTypography.body2.copyWith(color: AppColors.textTertiary),
        ),
        const SizedBox(height: AppSpacing.x2),
        for (int index = 0; index < details.length; index++) ...<Widget>[
          _DhiwayDetailCard(
            detail: details[index],
            index: index,
            detailsCount: details.length,
            enabled: enabled,
            onAdd: onAdd,
            onRemove: () => onRemove(index),
          ),
          if (index != details.length - 1)
            const SizedBox(height: AppSpacing.x3),
        ],
      ],
    );
  }
}

class _DhiwayDetailCard extends StatelessWidget {
  const _DhiwayDetailCard({
    required this.detail,
    required this.index,
    required this.detailsCount,
    required this.enabled,
    required this.onAdd,
    required this.onRemove,
  });

  final _DhiwayDetailDraft detail;
  final int index;
  final int detailsCount;
  final bool enabled;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    const Color inputBg = Color(0xFFE9EEF3);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.x3),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Text(
                'Pair ${index + 1}',
                style: AppTypography.body1.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: enabled ? onAdd : null,
                icon: const Icon(Icons.add_circle_outline_rounded),
                color: AppColors.brandBlue,
                tooltip: 'Add another pair',
              ),
              if (enabled && detailsCount > 1)
                IconButton(
                  onPressed: onRemove,
                  icon: const Icon(Icons.delete_outline_rounded),
                  color: AppColors.error,
                  tooltip: 'Remove this pair',
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.x2),
          TMZInput(
            label: 'Space ID',
            hint: 'Enter space id',
            controller: detail.spaceController,
            enabled: enabled,
            backgroundColor: inputBg,
          ),
          const SizedBox(height: AppSpacing.x3),
          TMZInput(
            label: 'Schema ID',
            hint: 'Enter schema id',
            controller: detail.schemaController,
            enabled: enabled,
            backgroundColor: inputBg,
          ),
        ],
      ),
    );
  }
}

class _DhiwayDetailDraft {
  _DhiwayDetailDraft({String spaceId = '', String schemaId = ''})
    : spaceController = TextEditingController(text: spaceId),
      schemaController = TextEditingController(text: schemaId);

  factory _DhiwayDetailDraft.fromModel(DhiwayDetail detail) {
    return _DhiwayDetailDraft(
      spaceId: detail.spaceId,
      schemaId: detail.schemaId,
    );
  }

  final TextEditingController spaceController;
  final TextEditingController schemaController;

  void dispose() {
    spaceController.dispose();
    schemaController.dispose();
  }
}

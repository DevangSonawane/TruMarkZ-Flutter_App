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
import '../../../../auth/data/auth_repository.dart';

enum _IndustryMode { human, products, both }

class OrgOnboardingPage extends ConsumerStatefulWidget {
  const OrgOnboardingPage({super.key});

  @override
  ConsumerState<OrgOnboardingPage> createState() => _OrgOnboardingPageState();
}

class _OrgOnboardingPageState extends ConsumerState<OrgOnboardingPage> {
  _IndustryMode _mode = _IndustryMode.human;
  final Set<String> _selectedIndustries = <String>{};

  final TextEditingController _gstin = TextEditingController();
  final TextEditingController _businessRegNumber = TextEditingController();
  final TextEditingController _address1 = TextEditingController();
  final TextEditingController _address2 = TextEditingController();
  final TextEditingController _address3 = TextEditingController();

  bool _isSubmitting = false;

  static const List<String> _humanIndustries = <String>[
    'Transport',
    'Healthcare',
    'Education',
    'Manufacturing',
    'Security',
    'Agriculture',
    'Others',
  ];

  static const List<String> _productCategories = <String>[
    'Consumer Goods',
    'Beauty & Cosmetics',
    'Electronics & Appliances',
    'EV & Automotive',
    'Insurance Policies',
    'Healthcare Products',
    'Industrial Equipment',
    'Agriculture Products',
    'Luxury Products',
    'Others',
  ];

  List<String> get _industryOptions {
    switch (_mode) {
      case _IndustryMode.human:
        return _humanIndustries;
      case _IndustryMode.products:
        return _productCategories;
      case _IndustryMode.both:
        return <String>{..._humanIndustries, ..._productCategories}.toList()
          ..sort();
    }
  }

  @override
  void dispose() {
    _gstin.dispose();
    _businessRegNumber.dispose();
    _address1.dispose();
    _address2.dispose();
    _address3.dispose();
    super.dispose();
  }

  String get _modeLabel {
    switch (_mode) {
      case _IndustryMode.human:
        return 'Human verification';
      case _IndustryMode.products:
        return 'Products';
      case _IndustryMode.both:
        return 'Both';
    }
  }

  Future<void> _pickIndustrySource() async {
    final _IndustryMode? picked = await showModalBottomSheet<_IndustryMode>(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext ctx) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: Material(
            color: AppColors.cardSurface,
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    title: const Text('Human verification'),
                    leading: const Icon(Icons.verified_user_outlined),
                    onTap: () => Navigator.of(ctx).pop(_IndustryMode.human),
                  ),
                  ListTile(
                    title: const Text('Products'),
                    leading: const Icon(Icons.inventory_2_outlined),
                    onTap: () => Navigator.of(ctx).pop(_IndustryMode.products),
                  ),
                  ListTile(
                    title: const Text('Both'),
                    leading: const Icon(Icons.auto_awesome_mosaic_outlined),
                    onTap: () => Navigator.of(ctx).pop(_IndustryMode.both),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (!mounted || picked == null) return;
    setState(() {
      _mode = picked;
      _selectedIndustries.removeWhere(
        (String v) => !_industryOptions.contains(v),
      );
    });
  }

  Future<void> _pickIndustries() async {
    final List<String> options = _industryOptions;
    final Set<String> temp = <String>{..._selectedIndustries}
      ..removeWhere((String v) => !options.contains(v));

    final Set<String>? result = await showModalBottomSheet<Set<String>>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext ctx) {
        return _MultiSelectSheet(
          title: 'Select Industry Types',
          options: options,
          initial: temp,
        );
      },
    );

    if (!mounted || result == null) return;
    setState(() {
      _selectedIndustries
        ..clear()
        ..addAll(result);
    });
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    final List<String> industries = _selectedIndustries.toList()..sort();
    final String gstin = _gstin.text.trim();
    final String brn = _businessRegNumber.text.trim();
    final String a1 = _address1.text.trim();
    final String a2 = _address2.text.trim();
    final String a3 = _address3.text.trim();

    final List<String> missing = <String>[
      if (industries.isEmpty) 'Industry Type',
      if (gstin.isEmpty) 'GSTIN',
      if (brn.isEmpty) 'Business Registration Number',
      if (a1.isEmpty) 'Address Line 1',
    ];
    if (missing.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter: ${missing.join(', ')}.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await ref
          .read(authRepositoryProvider)
          .completeOrgOnboarding(
            OrgOnboardingRequest(
              industryType: industries,
              gstin: gstin,
              businessRegNumber: brn,
              addressLine1: a1,
              addressLine2: a2,
              addressLine3: a3,
              useCases: const <String, dynamic>{},
            ),
          );
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

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final double systemBottomInset = MediaQuery.of(context).viewPadding.bottom;
    const Color inputBg = Color(0xFFE9EEF3);

    final List<String> chips = _selectedIndustries.toList()..sort();
    final String industriesLabel = chips.isEmpty
        ? 'Select'
        : '${chips.length} selected';

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
            'This helps configure your dashboard and verification capabilities.',
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
                  label: 'GSTIN',
                  hint: '27AABCU9603R1ZM',
                  controller: _gstin,
                  enabled: !_isSubmitting,
                  backgroundColor: inputBg,
                ),
                const SizedBox(height: AppSpacing.x3),
                TMZInput(
                  label: 'Business Reg Number',
                  hint: 'U12345MH2024PTC123456',
                  controller: _businessRegNumber,
                  enabled: !_isSubmitting,
                  backgroundColor: inputBg,
                ),
                const SizedBox(height: AppSpacing.x3),
                TMZInput(
                  label: 'Address Line 1',
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
                const SizedBox(height: AppSpacing.x4),
                Text('Industry Source', style: AppTypography.heading2),
                const SizedBox(height: AppSpacing.x2),
                TMZButton(
                  label: _modeLabel,
                  variant: TMZButtonVariant.secondary,
                  icon: Icons.keyboard_arrow_down_rounded,
                  onPressed: _pickIndustrySource,
                ),
                const SizedBox(height: AppSpacing.x4),
                Text('Industry Type', style: AppTypography.heading2),
                const SizedBox(height: AppSpacing.x2),
                TMZButton(
                  label: industriesLabel,
                  variant: TMZButtonVariant.secondary,
                  icon: Icons.tune_rounded,
                  onPressed: _pickIndustries,
                ),
                if (chips.isNotEmpty) ...<Widget>[
                  const SizedBox(height: AppSpacing.x3),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: <Widget>[
                      for (final String c in chips)
                        Chip(
                          label: Text(c),
                          onDeleted: () =>
                              setState(() => _selectedIndustries.remove(c)),
                        ),
                    ],
                  ),
                ],
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

class _MultiSelectSheet extends StatefulWidget {
  const _MultiSelectSheet({
    required this.title,
    required this.options,
    required this.initial,
  });

  final String title;
  final List<String> options;
  final Set<String> initial;

  @override
  State<_MultiSelectSheet> createState() => _MultiSelectSheetState();
}

class _MultiSelectSheetState extends State<_MultiSelectSheet> {
  late final Set<String> _selected = <String>{...widget.initial};

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: Material(
        color: AppColors.cardSurface,
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(widget.title, style: AppTypography.heading2),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(_selected),
                      child: const Text('Done'),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
                  itemCount: widget.options.length,
                  itemBuilder: (BuildContext context, int i) {
                    final String opt = widget.options[i];
                    final bool checked = _selected.contains(opt);
                    return CheckboxListTile(
                      value: checked,
                      title: Text(opt),
                      controlAffinity: ListTileControlAffinity.leading,
                      onChanged: (bool? v) {
                        setState(() {
                          if (v == true) {
                            _selected.add(opt);
                          } else {
                            _selected.remove(opt);
                          }
                        });
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

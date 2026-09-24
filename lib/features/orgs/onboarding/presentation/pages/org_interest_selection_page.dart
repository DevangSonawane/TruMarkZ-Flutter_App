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
import '../../../data/verification_repository.dart';

class OrgInterestSelectionPage extends ConsumerStatefulWidget {
  const OrgInterestSelectionPage({super.key});

  @override
  ConsumerState<OrgInterestSelectionPage> createState() =>
      _OrgInterestSelectionPageState();
}

class _OrgInterestSelectionPageState
    extends ConsumerState<OrgInterestSelectionPage> {
  static const List<String> _serviceTypes = <String>['Human', 'Product'];

  String _serviceType = 'Human';
  Set<String> _selectedIndustries = <String>{};
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final UserProfile? profile = ref
        .read(authNotifierProvider)
        .valueOrNull
        ?.userProfile;
    final String profileServiceType =
        profile?.serviceType?.trim().toLowerCase() ?? '';
    if (profileServiceType == 'product') {
      _serviceType = 'Product';
    }
    _selectedIndustries =
        profile?.industryTypes
            .map((String value) => value.trim())
            .where((String value) => value.isNotEmpty)
            .toSet() ??
        <String>{};
  }

  void _setServiceType(String selected) {
    if (selected.isEmpty || selected == _serviceType) return;
    setState(() {
      _serviceType = selected;
      _selectedIndustries = <String>{};
    });
  }

  void _toggleIndustry(String industry) {
    final String value = industry.trim();
    if (value.isEmpty) return;
    setState(() {
      _selectedIndustries = <String>{value};
    });
  }

  Future<void> _continue() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      final String industryType = _selectedIndustries.join(', ');
      if (industryType.trim().isNotEmpty) {
        await ref
            .read(authRepositoryProvider)
            .completeOrgOnboarding(
              OrgOnboardingRequest(industryType: industryType),
            );
      }
      await ref
          .read(authNotifierProvider.notifier)
          .updateServiceType(_serviceType.toLowerCase());
      if (!mounted) return;
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
          content: Text('Could not save your preferences. Please try again.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final double bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final AsyncValue<List<String>> industriesAsync = ref.watch(
      industryTypeNamesForCategoryProvider(_serviceType.toLowerCase()),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.x5,
                AppSpacing.x4,
                AppSpacing.x5,
                AppSpacing.x5 + bottomInset,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      const SizedBox(height: AppSpacing.x4),
                      Text(
                        'Select your interests',
                        textAlign: TextAlign.left,
                        style: AppTypography.heading1.copyWith(
                          fontSize: 22,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.x2),
                      Text(
                        'Choose what your organisation verifies. This helps us set up the right checks for you.',
                        style: AppTypography.body2.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 12.5,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.x6),
                      _SectionLabel(
                        label: 'Service type',
                        helper: 'Pick one verification flow.',
                      ),
                      const SizedBox(height: AppSpacing.x2),
                      _PillWrap(
                        options: _serviceTypes,
                        selected: <String>{_serviceType},
                        onTap: _setServiceType,
                        iconFor: _serviceIconFor,
                      ),
                      const SizedBox(height: AppSpacing.x5),
                      _SectionLabel(
                        label: 'Industry type',
                        helper:
                            'Loaded from ${_serviceType.toLowerCase()} verification checks.',
                      ),
                      const SizedBox(height: AppSpacing.x2),
                      industriesAsync.when(
                        loading: () => const _LoadingIndustries(),
                        error: (Object error, StackTrace stackTrace) =>
                            _IndustryError(
                              onRetry: () => ref.invalidate(
                                industryTypeNamesForCategoryProvider(
                                  _serviceType.toLowerCase(),
                                ),
                              ),
                            ),
                        data: (List<String> options) {
                          if (options.isEmpty) {
                            return const _EmptyIndustries();
                          }
                          return _PillWrap(
                            options: options,
                            selected: _selectedIndustries,
                            onTap: _toggleIndustry,
                            iconFor: _industryIconFor,
                          );
                        },
                      ),
                      const SizedBox(height: AppSpacing.x6),
                      TMZButton(
                        label: 'Continue',
                        isLoading: _isSaving,
                        borderRadius: 999,
                        backgroundColor: const Color(0xFF1B3387),
                        showShadow: false,
                        onPressed: _isSaving ? null : _continue,
                      ),
                      const SizedBox(height: AppSpacing.x1),
                      TextButton(
                        onPressed: _isSaving
                            ? null
                            : () => context.go(AppRouter.dashboardPath),
                        child: Text(
                          'Skip for now',
                          style: AppTypography.body2.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
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

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label, required this.helper});

  final String label;
  final String helper;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: AppTypography.heading2.copyWith(
            fontSize: 14,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          helper,
          style: AppTypography.caption.copyWith(
            color: AppColors.textTertiary,
            fontSize: 11,
            height: 1.25,
          ),
        ),
      ],
    );
  }
}

class _LoadingIndustries extends StatelessWidget {
  const _LoadingIndustries();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 52,
      child: Align(
        alignment: Alignment.centerLeft,
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}

class _IndustryError extends StatelessWidget {
  const _IndustryError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onRetry,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
      child: const Text('Could not load industries. Retry'),
    );
  }
}

class _EmptyIndustries extends StatelessWidget {
  const _EmptyIndustries();

  @override
  Widget build(BuildContext context) {
    return Text(
      'No industry types are available right now.',
      style: AppTypography.body2.copyWith(color: AppColors.textSecondary),
    );
  }
}

class _PillWrap extends StatelessWidget {
  const _PillWrap({
    required this.options,
    required this.selected,
    required this.onTap,
    required this.iconFor,
  });

  final List<String> options;
  final Set<String> selected;
  final ValueChanged<String> onTap;
  final IconData Function(String label) iconFor;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        for (final String option in options)
          _InterestPill(
            label: option,
            icon: iconFor(option),
            selected: selected.contains(option),
            onTap: () => onTap(option),
          ),
      ],
    );
  }
}

class _InterestPill extends StatelessWidget {
  const _InterestPill({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 190),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOut,
            constraints: const BoxConstraints(minHeight: 36),
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
            decoration: BoxDecoration(
              color: selected ? const Color(0xFF1B3387) : Colors.white,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: selected ? const Color(0xFF1B3387) : AppColors.divider,
              ),
              boxShadow: selected
                  ? <BoxShadow>[
                      BoxShadow(
                        color: const Color(0xFF1B3387).withAlpha(24),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : const <BoxShadow>[],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(
                  icon,
                  size: 14,
                  color: selected ? Colors.white : AppColors.textTertiary,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.body2.copyWith(
                      color: selected ? Colors.white : AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

IconData _serviceIconFor(String label) {
  return label.trim().toLowerCase() == 'product'
      ? Icons.inventory_2_outlined
      : Icons.person_outline_rounded;
}

IconData _industryIconFor(String label) {
  final String value = label.trim().toLowerCase();
  if (value.contains('drug')) return Icons.science_outlined;
  if (value.contains('company')) return Icons.business_center_outlined;
  if (value.contains('health')) return Icons.local_hospital_outlined;
  if (value.contains('transport') || value.contains('logistics')) {
    return Icons.local_shipping_outlined;
  }
  if (value.contains('it') || value.contains('electronics')) {
    return Icons.devices_outlined;
  }
  if (value.contains('real estate')) return Icons.apartment_outlined;
  if (value.contains('beauty') || value.contains('cosmetic')) {
    return Icons.spa_outlined;
  }
  if (value.contains('automotive') || value.contains('ev')) {
    return Icons.directions_car_outlined;
  }
  if (value.contains('insurance')) return Icons.policy_outlined;
  if (value.contains('agriculture')) return Icons.agriculture_outlined;
  if (value.contains('industrial')) return Icons.precision_manufacturing;
  if (value.contains('luxury')) return Icons.diamond_outlined;
  if (value.contains('consumer')) return Icons.shopping_bag_outlined;
  return Icons.category_outlined;
}

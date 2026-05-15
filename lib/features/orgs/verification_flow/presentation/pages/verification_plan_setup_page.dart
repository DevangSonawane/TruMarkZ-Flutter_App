import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/router/app_router.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';

enum _Industry {
  transport,
  healthcare,
  education,
  manufacturing,
  securityServices,
  blueCollarWorkforce,
  gigEconomyWorkers,
  recruitmentStudents,
  insuranceAgents,
  agricultureWorkforce,
  individualVerification,
  others,
}

enum _AccessType { publicSearchable, permissionBased }

class _VerificationCheck {
  const _VerificationCheck({
    required this.id,
    required this.title,
    required this.mode,
    required this.subtitle,
    required this.costInr,
    this.defaultSelected = false,
  });

  final String id;
  final String title;
  final String mode;
  final String subtitle;
  final int costInr;
  final bool defaultSelected;
}

class VerificationPlanSetupPage extends StatefulWidget {
  const VerificationPlanSetupPage({super.key});

  @override
  State<VerificationPlanSetupPage> createState() =>
      _VerificationPlanSetupPageState();
}

class _VerificationPlanSetupPageState extends State<VerificationPlanSetupPage> {
  bool _didInitFromRoute = false;
  bool _singleFlow = false;
  int _stepIndex = 0;
  _Industry? _selectedIndustry;
  int _lastStepIndex = 0;

  late final List<_VerificationCheck> _checks = <_VerificationCheck>[
    const _VerificationCheck(
      id: 'identity',
      title: 'Identity Verification',
      mode: 'API (auto)',
      subtitle: 'KYC/Aadhaar Link',
      costInr: 120,
      defaultSelected: true,
    ),
    const _VerificationCheck(
      id: 'address',
      title: 'Address History',
      mode: 'Human (manual)',
      subtitle: 'Physical Check',
      costInr: 240,
      defaultSelected: true,
    ),
    const _VerificationCheck(
      id: 'criminal',
      title: 'Criminal Record Search',
      mode: 'API (auto)',
      subtitle: 'National Database',
      costInr: 185,
      defaultSelected: true,
    ),
    const _VerificationCheck(
      id: 'education',
      title: 'Education Verification',
      mode: 'Human (manual)',
      subtitle: 'Institute Check',
      costInr: 300,
    ),
    const _VerificationCheck(
      id: 'employment',
      title: 'Employment History',
      mode: 'Human (manual)',
      subtitle: 'Previous HR Contact',
      costInr: 450,
    ),
  ];

  late final Set<String> _selectedCheckIds = <String>{
    for (final _VerificationCheck check in _checks)
      if (check.defaultSelected) check.id,
  };

  bool _agreedToCosts = false;
  _AccessType _accessType = _AccessType.publicSearchable;
  bool _whatsAppConsent = true;
  bool _emailConsent = false;

  static const Color _deepBlue = AppColors.deepNavy;

  LinearGradient get _primaryGradient => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[AppColors.brandBlue, _deepBlue],
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInitFromRoute) return;
    _didInitFromRoute = true;
    final String flow =
        (GoRouterState.of(context).uri.queryParameters['flow'] ?? '')
            .trim()
            .toLowerCase();
    _singleFlow = flow == 'single';
  }

  static const int _totalSteps = 4;

  void _goBack(BuildContext context) {
    if (_stepIndex == 0) {
      final GoRouter router = GoRouter.of(context);
      if (router.canPop()) {
        context.pop();
      } else {
        context.go(AppRouter.dashboardPath);
      }
      return;
    }
    setState(() {
      _lastStepIndex = _stepIndex;
      _stepIndex -= 1;
    });
  }

  void _goNext(BuildContext context) {
    if (_stepIndex == 0) {
      if (_selectedIndustry == null) return;
      setState(() {
        _lastStepIndex = _stepIndex;
        _stepIndex = 1;
      });
      return;
    }

    if (_stepIndex == 1) {
      if (_selectedCheckIds.isEmpty) return;
      setState(() {
        _lastStepIndex = _stepIndex;
        _stepIndex = 2;
      });
      return;
    }

    if (_stepIndex == 2) {
      if (!_agreedToCosts) return;
      setState(() {
        _lastStepIndex = _stepIndex;
        _stepIndex = 3;
      });
      return;
    }

    // Finalize.
    final Map<String, String> qp = <String, String>{};
    if (_singleFlow) qp['flow'] = 'single';
    if (_selectedIndustry != null) {
      qp['industry'] = _selectedIndustry!.name;
    }
    if (_selectedCheckIds.isNotEmpty) {
      final List<String> sortedCheckIds = _selectedCheckIds.toList()..sort();
      qp['checks'] = sortedCheckIds.join(',');
    }
    qp['access'] = _accessType.name;
    if (_accessType == _AccessType.permissionBased) {
      final List<String> channels = <String>[
        if (_whatsAppConsent) 'whatsapp',
        if (_emailConsent) 'email',
      ];
      qp['consent'] = channels.join(',');
    }

    final String qs = qp.entries
        .where((MapEntry<String, String> e) => e.value.trim().isNotEmpty)
        .map(
          (MapEntry<String, String> e) =>
              '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}',
        )
        .join('&');
    final String target = _singleFlow
        ? AppRouter.singleHumanUploadPath
        : AppRouter.bulkUploadPath;
    context.push(qs.isEmpty ? target : '$target?$qs');
  }

  int get _totalCostInr {
    int total = 0;
    for (final _VerificationCheck check in _checks) {
      if (_selectedCheckIds.contains(check.id)) {
        total += check.costInr;
      }
    }
    return total;
  }

  String _formatInr(int amount) => '₹$amount';

  String get _stepTitle => switch (_stepIndex) {
    0 => 'Industry',
    1 => 'Checks',
    2 => 'Cost',
    _ => 'Permissions',
  };

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final bool movingForward = _stepIndex >= _lastStepIndex;

    final Widget content = switch (_stepIndex) {
      0 => _IndustryStep(
        selectedIndustry: _selectedIndustry,
        onSelect: (value) => setState(() => _selectedIndustry = value),
      ),
      1 => _ChecksStep(
        checks: _checks,
        selectedCheckIds: _selectedCheckIds,
        formatInr: _formatInr,
        onToggleCheck: (String id, bool selected) {
          setState(() {
            if (selected) {
              _selectedCheckIds.add(id);
            } else {
              _selectedCheckIds.remove(id);
            }
          });
        },
      ),
      2 => _CostStep(
        checks: <_VerificationCheck>[
          for (final _VerificationCheck check in _checks)
            if (_selectedCheckIds.contains(check.id)) check,
        ],
        totalCostInr: _totalCostInr,
        formatInr: _formatInr,
        agreedToCosts: _agreedToCosts,
        onAgreedChanged: (bool value) => setState(() => _agreedToCosts = value),
      ),
      _ => _PermissionsStep(
        accessType: _accessType,
        whatsAppConsent: _whatsAppConsent,
        emailConsent: _emailConsent,
        onAccessTypeChanged: (value) => setState(() => _accessType = value),
        onWhatsAppConsentChanged: (value) =>
            setState(() => _whatsAppConsent = value),
        onEmailConsentChanged: (value) => setState(() => _emailConsent = value),
      ),
    };

    final bool canContinue = switch (_stepIndex) {
      0 => _selectedIndustry != null,
      1 => _selectedCheckIds.isNotEmpty,
      2 => _agreedToCosts,
      _ =>
        _accessType == _AccessType.permissionBased
            ? (_whatsAppConsent || _emailConsent)
            : true,
    };

    final String ctaLabel = switch (_stepIndex) {
      0 => 'Continue',
      1 => _singleFlow ? 'Continue' : 'Continue',
      2 => 'Continue',
      _ => 'Upload',
    };

    final IconData ctaIcon = switch (_stepIndex) {
      0 => Icons.arrow_forward_rounded,
      1 => Icons.arrow_forward_rounded,
      2 => Icons.arrow_forward_rounded,
      _ => Icons.upload_file_rounded,
    };

    return Scaffold(
      backgroundColor: AppColors.pageBg,
      appBar: AppBar(
        backgroundColor: AppColors.pageBg,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () => _goBack(context),
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: AppColors.brandBlue,
          ),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Image.asset('assets/icons/headers_app_icon.png', height: 20),
            const SizedBox(width: AppSpacing.x2),
            Text(
              _stepTitle,
              style: AppTypography.heading1.copyWith(
                color: scheme.onSurface,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.x4,
                AppSpacing.x2,
                AppSpacing.x4,
                AppSpacing.x2,
              ),
              child: _CreateBatchStepper(
                stepIndex: _stepIndex,
                gradient: _primaryGradient,
                totalSteps: _totalSteps,
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.x4,
                  0,
                  AppSpacing.x4,
                  120,
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 260),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (Widget child, Animation<double> anim) {
                    final Animation<Offset> offset =
                        Tween<Offset>(
                          begin: Offset(movingForward ? 0.08 : -0.08, 0),
                          end: Offset.zero,
                        ).animate(
                          CurvedAnimation(parent: anim, curve: Curves.easeOut),
                        );
                    return FadeTransition(
                      opacity: anim,
                      child: SlideTransition(position: offset, child: child),
                    );
                  },
                  child: KeyedSubtree(
                    key: ValueKey<int>(_stepIndex),
                    child: content,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.x4,
            AppSpacing.x2,
            AppSpacing.x4,
            AppSpacing.x4,
          ),
          child: _GradientCtaButton(
            label: ctaLabel,
            icon: ctaIcon,
            gradient: _primaryGradient,
            enabled: canContinue,
            onPressed: () => _goNext(context),
          ),
        ),
      ),
    );
  }
}

class _CreateBatchStepper extends StatelessWidget {
  const _CreateBatchStepper({
    required this.stepIndex,
    required this.gradient,
    this.totalSteps = 4,
  });

  final int stepIndex;
  final Gradient gradient;
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    final int safeTotalSteps = totalSteps < 2 ? 2 : totalSteps;
    final double progress = stepIndex / (safeTotalSteps - 1);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.brandBlue.withAlpha(14),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _FlowingProgressBar(
            value: progress,
            gradient: gradient,
            seed: stepIndex,
          ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              for (int i = 0; i < safeTotalSteps; i++) ...<Widget>[
                _MinimalStepDot(
                  active: i == stepIndex,
                  completed: i < stepIndex,
                  gradient: gradient,
                ),
                if (i != safeTotalSteps - 1) const Spacer(),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _MinimalStepDot extends StatelessWidget {
  const _MinimalStepDot({
    required this.active,
    required this.completed,
    required this.gradient,
  });

  final bool active;
  final bool completed;
  final Gradient gradient;

  @override
  Widget build(BuildContext context) {
    final double size = active ? 12 : 10;
    final Color fill = completed
        ? AppColors.brandBlue
        : const Color(0xFFEFF3FF);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: active || completed ? gradient : null,
        color: active || completed ? null : fill,
        boxShadow: active
            ? <BoxShadow>[
                BoxShadow(
                  color: AppColors.brandBlue.withAlpha(26),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ]
            : const <BoxShadow>[],
      ),
    );
  }
}

class _FlowingProgressBar extends StatelessWidget {
  const _FlowingProgressBar({
    required this.value,
    required this.gradient,
    required this.seed,
  });

  final double value;
  final Gradient gradient;
  final int seed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 8,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints c) {
          final double width = c.maxWidth;
          return Stack(
            children: <Widget>[
              Container(
                width: width,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: value.clamp(0, 1)),
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                builder: (BuildContext context, double t, Widget? child) {
                  return Container(
                    width: width * t,
                    decoration: BoxDecoration(
                      gradient: gradient,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  );
                },
              ),
              // A subtle flowing highlight on each step change.
              Positioned.fill(
                child: IgnorePointer(
                  child: TweenAnimationBuilder<double>(
                    key: ValueKey<int>(seed),
                    tween: Tween<double>(begin: -0.3, end: 1.1),
                    duration: const Duration(milliseconds: 650),
                    curve: Curves.easeInOutCubic,
                    builder: (BuildContext context, double x, Widget? child) {
                      return FractionalTranslation(
                        translation: Offset(x, 0),
                        child: child,
                      );
                    },
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        width: 72,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(99),
                          gradient: LinearGradient(
                            colors: <Color>[
                              Colors.white.withAlpha(0),
                              Colors.white.withAlpha(90),
                              Colors.white.withAlpha(0),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _IndustryStep extends StatelessWidget {
  const _IndustryStep({required this.selectedIndustry, required this.onSelect});

  final _Industry? selectedIndustry;
  final ValueChanged<_Industry> onSelect;

  @override
  Widget build(BuildContext context) {
    final List<(_Industry, String, IconData)> industries =
        <(_Industry, String, IconData)>[
          (
            _Industry.transport,
            'Transport & Logistics',
            Icons.local_shipping_rounded,
          ),
          (_Industry.healthcare, 'Healthcare', Icons.medical_services_rounded),
          (_Industry.education, 'Education', Icons.school_rounded),
          (_Industry.manufacturing, 'Manufacturing', Icons.factory_rounded),
          (
            _Industry.securityServices,
            'Security Services',
            Icons.shield_rounded,
          ),
          (
            _Industry.blueCollarWorkforce,
            'Blue Collar Workforce',
            Icons.engineering_rounded,
          ),
          (
            _Industry.gigEconomyWorkers,
            'Gig Economy Workers',
            Icons.delivery_dining_rounded,
          ),
          (
            _Industry.recruitmentStudents,
            'Recruitment & Students',
            Icons.school_outlined,
          ),
          (
            _Industry.insuranceAgents,
            'Insurance Agents',
            Icons.health_and_safety_rounded,
          ),
          (
            _Industry.agricultureWorkforce,
            'Agriculture Workforce',
            Icons.agriculture_rounded,
          ),
          (
            _Industry.individualVerification,
            'Individual Verification',
            Icons.person_search_rounded,
          ),
          (_Industry.others, 'Others', Icons.widgets_rounded),
        ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('Select Industry', style: AppTypography.display2),
        const SizedBox(height: AppSpacing.x2),
        Text(
          'Choose the industry category that best fits this credential batch for optimized verification workflows.',
          style: AppTypography.body2.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.x5),
        LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final int columns = constraints.maxWidth >= 800 ? 4 : 2;
            return GridView.builder(
              itemCount: industries.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                mainAxisSpacing: AppSpacing.x3,
                crossAxisSpacing: AppSpacing.x3,
                childAspectRatio: 1,
              ),
              itemBuilder: (BuildContext context, int index) {
                final (_Industry id, String label, IconData icon) =
                    industries[index];
                final bool isSelected = selectedIndustry == id;
                return _IndustryCard(
                  label: label,
                  icon: icon,
                  selected: isSelected,
                  onTap: () => onSelect(id),
                );
              },
            );
          },
        ),
      ],
    );
  }
}

class _IndustryCard extends StatelessWidget {
  const _IndustryCard({
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
    final BorderSide borderSide = selected
        ? const BorderSide(color: AppColors.brandBlue, width: 2)
        : BorderSide(color: Colors.transparent.withAlpha(0));

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.fromBorderSide(borderSide),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: AppColors.brandBlue.withAlpha(18),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          padding: const EdgeInsets.all(AppSpacing.x5),
          child: Stack(
            children: <Widget>[
              Positioned.fill(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.brandBlue.withAlpha(24)
                              : const Color(0xFFEFF3FF),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Icon(icon, color: AppColors.brandBlue, size: 30),
                      ),
                      const SizedBox(height: AppSpacing.x4),
                      Text(
                        label,
                        style: AppTypography.body2.copyWith(
                          fontWeight: FontWeight.w700,
                          color: selected
                              ? AppColors.brandBlue
                              : AppColors.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
              if (selected)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: <Color>[AppColors.brandBlue, Color(0xFF004AC6)],
                      ),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      size: 16,
                      color: Colors.white,
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

class _ChecksStep extends StatelessWidget {
  const _ChecksStep({
    required this.checks,
    required this.selectedCheckIds,
    required this.formatInr,
    required this.onToggleCheck,
  });

  final List<_VerificationCheck> checks;
  final Set<String> selectedCheckIds;
  final String Function(int) formatInr;
  final void Function(String id, bool selected) onToggleCheck;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('Select Verification Checks', style: AppTypography.display2),
        const SizedBox(height: AppSpacing.x2),
        Text(
          'Pick the checks needed for this batch. Costs are per person (per unit).',
          style: AppTypography.body2.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.x5),
        Column(
          children: <Widget>[
            for (final _VerificationCheck check in checks) ...<Widget>[
              _CheckTile(
                check: check,
                selected: selectedCheckIds.contains(check.id),
                onChanged: (bool value) => onToggleCheck(check.id, value),
                formatInr: formatInr,
              ),
              const SizedBox(height: AppSpacing.x3),
            ],
          ],
        ),
      ],
    );
  }
}

class _CostStep extends StatelessWidget {
  const _CostStep({
    required this.checks,
    required this.totalCostInr,
    required this.formatInr,
    required this.agreedToCosts,
    required this.onAgreedChanged,
  });

  final List<_VerificationCheck> checks;
  final int totalCostInr;
  final String Function(int) formatInr;
  final bool agreedToCosts;
  final ValueChanged<bool> onAgreedChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('Per-unit Cost Breakdown', style: AppTypography.display2),
        const SizedBox(height: AppSpacing.x2),
        Text(
          'Review the per-person pricing for your selected checks before continuing.',
          style: AppTypography.body2.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.x5),
        _CostSummaryCard(
          checks: checks,
          totalCostInr: totalCostInr,
          formatInr: formatInr,
          agreedToCosts: agreedToCosts,
          onAgreedChanged: onAgreedChanged,
        ),
      ],
    );
  }
}

class _CheckTile extends StatelessWidget {
  const _CheckTile({
    required this.check,
    required this.selected,
    required this.onChanged,
    required this.formatInr,
  });

  final _VerificationCheck check;
  final bool selected;
  final ValueChanged<bool> onChanged;
  final String Function(int) formatInr;

  bool get _isAutomatic {
    final String mode = check.mode.toLowerCase();
    return mode.contains('api') || mode.contains('auto');
  }

  IconData get _icon {
    switch (check.id) {
      case 'identity':
        return Icons.badge_outlined;
      case 'criminal':
        return Icons.gavel_outlined;
      case 'employment':
        return Icons.work_outline;
      case 'address':
        return Icons.home_work_outlined;
      case 'education':
        return Icons.school_outlined;
      default:
        return Icons.fact_check_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color borderColor = selected
        ? AppColors.brandBlue.withAlpha(28)
        : Colors.transparent;
    final Color statusFg = _isAutomatic
        ? AppColors.brandBlue
        : AppColors.textTertiary;
    final Color statusBg = _isAutomatic
        ? const Color(0xFFD6E2FF)
        : const Color(0xFFF1F5F9);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => onChanged(!selected),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.x5,
            vertical: AppSpacing.x4,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: AppColors.brandBlue.withAlpha(20),
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: AppColors.blueTint,
                  shape: BoxShape.circle,
                ),
                child: Icon(_icon, color: AppColors.brandBlue, size: 22),
              ),
              const SizedBox(width: AppSpacing.x4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      check.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.heading2.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _isAutomatic ? 'AUTOMATIC' : 'MANUAL',
                        style: AppTypography.caption.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.0,
                          color: statusFg,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.x3),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  Text(
                    formatInr(check.costInr),
                    style: AppTypography.body2.copyWith(
                      color: AppColors.brandBlue,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOut,
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: selected ? AppColors.brandBlue : Colors.white,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: selected ? Colors.transparent : AppColors.border,
                      ),
                      boxShadow: selected
                          ? <BoxShadow>[
                              BoxShadow(
                                color: AppColors.brandBlue.withAlpha(35),
                                blurRadius: 10,
                                offset: const Offset(0, 6),
                              ),
                            ]
                          : const <BoxShadow>[],
                    ),
                    child: Icon(
                      Icons.check_rounded,
                      size: 16,
                      color: selected ? Colors.white : Colors.transparent,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CostSummaryCard extends StatelessWidget {
  const _CostSummaryCard({
    required this.checks,
    required this.totalCostInr,
    required this.formatInr,
    required this.agreedToCosts,
    required this.onAgreedChanged,
  });

  final List<_VerificationCheck> checks;
  final int totalCostInr;
  final String Function(int) formatInr;
  final bool agreedToCosts;
  final ValueChanged<bool> onAgreedChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.brandBlue.withAlpha(18),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppSpacing.x5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(
                Icons.receipt_long_rounded,
                color: AppColors.brandBlue,
              ),
              const SizedBox(width: AppSpacing.x2),
              Text(
                'Cost Summary',
                style: AppTypography.heading2.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.x4),
          if (checks.isEmpty)
            Text(
              'Select at least one check to see the cost breakdown.',
              style: AppTypography.body2.copyWith(
                color: AppColors.textSecondary,
              ),
            )
          else ...<Widget>[
            for (final _VerificationCheck check in checks) ...<Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      check.title,
                      style: AppTypography.body2.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  Text(
                    formatInr(check.costInr),
                    style: AppTypography.body2.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.x2),
            ],
            const SizedBox(height: AppSpacing.x2),
            Container(height: 1, color: AppColors.divider),
            const SizedBox(height: AppSpacing.x3),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'TOTAL PER UNIT',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formatInr(totalCostInr),
                        style: AppTypography.display2.copyWith(
                          color: AppColors.brandBlue,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE7F0FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${checks.length} Checks',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.brandBlue,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.x4),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFEFF3FF),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFD9E3FF)),
              ),
              padding: const EdgeInsets.all(AppSpacing.x4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Checkbox.adaptive(
                    value: agreedToCosts,
                    onChanged: (bool? value) => onAgreedChanged(value ?? false),
                    activeColor: AppColors.brandBlue,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  const SizedBox(width: AppSpacing.x1),
                  Expanded(
                    child: Text(
                      'I agree to the per-unit cost breakdown and the terms of service for these verification checks.',
                      style: AppTypography.body2.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PermissionsStep extends StatelessWidget {
  const _PermissionsStep({
    required this.accessType,
    required this.whatsAppConsent,
    required this.emailConsent,
    required this.onAccessTypeChanged,
    required this.onWhatsAppConsentChanged,
    required this.onEmailConsentChanged,
  });

  final _AccessType accessType;
  final bool whatsAppConsent;
  final bool emailConsent;
  final ValueChanged<_AccessType> onAccessTypeChanged;
  final ValueChanged<bool> onWhatsAppConsentChanged;
  final ValueChanged<bool> onEmailConsentChanged;

  @override
  Widget build(BuildContext context) {
    final bool permissionBased = accessType == _AccessType.permissionBased;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('Configure Permissions', style: AppTypography.display2),
        const SizedBox(height: AppSpacing.x4),
        _PermissionCard(
          title: 'Public Searchable',
          description:
              'Results will be visible in the public registry for instant verification.',
          icon: Icons.public_rounded,
          selected: accessType == _AccessType.publicSearchable,
          onTap: () => onAccessTypeChanged(_AccessType.publicSearchable),
          child: null,
        ),
        const SizedBox(height: AppSpacing.x3),
        _PermissionCard(
          title: 'Permission-Based Access',
          description:
              'Requires explicit consent via WhatsApp or Email from the individual before data access.',
          icon: Icons.lock_person_rounded,
          selected: permissionBased,
          onTap: () => onAccessTypeChanged(_AccessType.permissionBased),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: !permissionBased
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.x4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Container(height: 1, color: AppColors.divider),
                        const SizedBox(height: AppSpacing.x4),
                        Text(
                          'CONSENT CHANNELS',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.brandBlue,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.1,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.x3),
                        _ConsentToggle(
                          icon: Icons.chat_bubble_outline_rounded,
                          title: 'WhatsApp Consent',
                          value: whatsAppConsent,
                          onChanged: onWhatsAppConsentChanged,
                        ),
                        const SizedBox(height: AppSpacing.x2),
                        _ConsentToggle(
                          icon: Icons.mail_outline_rounded,
                          title: 'Email Consent',
                          value: emailConsent,
                          onChanged: onEmailConsentChanged,
                        ),
                      ],
                    ),
                  ),
          ),
        ),
        const SizedBox(height: AppSpacing.x4),
        Container(
          padding: const EdgeInsets.all(AppSpacing.x4),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF3FF),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFD9E3FF)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Icon(
                Icons.info_outline_rounded,
                color: AppColors.brandBlue,
              ),
              const SizedBox(width: AppSpacing.x3),
              Expanded(
                child: Text(
                  'TruMarkZ uses cryptographic signing for every consent request. Selecting Permission-Based Access ensures GDPR and SOC2 compliance for sensitive professional data.',
                  style: AppTypography.body2.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PermissionCard extends StatelessWidget {
  const _PermissionCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.selected,
    required this.onTap,
    required this.child,
  });

  final String title;
  final String description;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.x5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? AppColors.brandBlue : Colors.transparent,
              width: 2,
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: AppColors.brandBlue.withAlpha(18),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE7F0FF),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icon, color: AppColors.brandBlue),
                  ),
                  const SizedBox(width: AppSpacing.x3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          title,
                          style: AppTypography.heading2.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          description,
                          style: AppTypography.body2.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.x3),
                  _RadioIndicator(selected: selected),
                ],
              ),
              child ?? const SizedBox.shrink(),
            ],
          ),
        ),
      ),
    );
  }
}

class _RadioIndicator extends StatelessWidget {
  const _RadioIndicator({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? AppColors.brandBlue : AppColors.silverGray,
          width: 2,
        ),
        color: selected ? AppColors.brandBlue : Colors.transparent,
      ),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 150),
        opacity: selected ? 1 : 0,
        child: const Center(
          child: SizedBox(
            width: 10,
            height: 10,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ConsentToggle extends StatelessWidget {
  const _ConsentToggle({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.x4,
        vertical: AppSpacing.x3,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F6FF),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: <Widget>[
          Icon(icon, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.x3),
          Expanded(
            child: Text(
              title,
              style: AppTypography.body1.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeTrackColor: AppColors.brandBlue,
            activeThumbColor: Colors.white,
          ),
        ],
      ),
    );
  }
}

class _GradientCtaButton extends StatefulWidget {
  const _GradientCtaButton({
    required this.label,
    required this.icon,
    required this.gradient,
    required this.enabled,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final Gradient gradient;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  State<_GradientCtaButton> createState() => _GradientCtaButtonState();
}

class _GradientCtaButtonState extends State<_GradientCtaButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final Widget content = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(
          widget.label,
          style: AppTypography.button.copyWith(color: Colors.white),
        ),
        const SizedBox(width: 10),
        Icon(widget.icon, color: Colors.white, size: 18),
      ],
    );

    final Widget button = AnimatedOpacity(
      duration: const Duration(milliseconds: 150),
      opacity: widget.enabled ? 1 : 0.45,
      child: SizedBox(
        height: 54,
        width: double.infinity,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: widget.gradient,
            borderRadius: BorderRadius.circular(999),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: AppColors.brandBlue.withAlpha(40),
                blurRadius: 22,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: widget.enabled ? widget.onPressed : null,
              onHighlightChanged: (bool value) =>
                  setState(() => _isPressed = value),
              child: AnimatedScale(
                duration: const Duration(milliseconds: 90),
                scale: _isPressed ? 0.985 : 1,
                child: Center(child: content),
              ),
            ),
          ),
        ),
      ),
    );

    return button;
  }
}

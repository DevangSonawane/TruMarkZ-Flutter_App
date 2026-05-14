import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/router/app_router.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';

class ProductSectorSelectorPage extends StatefulWidget {
  const ProductSectorSelectorPage({super.key});

  @override
  State<ProductSectorSelectorPage> createState() =>
      _ProductSectorSelectorPageState();
}

class _ProductSectorSelectorPageState extends State<ProductSectorSelectorPage> {
  String? _selectedSector;

  static const Color _deepBlue = AppColors.deepNavy;

  LinearGradient get _primaryGradient => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[AppColors.brandBlue, _deepBlue],
  );

  void _goBack(BuildContext context) {
    final GoRouter router = GoRouter.of(context);
    if (router.canPop()) {
      context.pop();
    } else {
      context.go(AppRouter.dashboardPath);
    }
  }

  void _continue(BuildContext context) {
    final String? sector = _selectedSector;
    if (sector == null) return;
    context.push(AppRouter.productBatchSetupPath, extra: sector);
  }

  @override
  Widget build(BuildContext context) {
    final List<(_Sector, bool)> sectors = <(_Sector, bool)>[
      (
        const _Sector(
          title: 'Consumer Goods',
          description:
              'Digital certificates for everyday products and warranties',
          icon: Icons.inventory_rounded,
        ),
        _selectedSector == 'Consumer Goods',
      ),
      (
        const _Sector(
          title: 'Beauty & Cosmetics',
          description:
              'Authenticity certificates with lab reports and batch proofs',
          icon: Icons.spa_rounded,
        ),
        _selectedSector == 'Beauty & Cosmetics',
      ),
      (
        const _Sector(
          title: 'Electronics & Appliances',
          description:
              'Warranty + serial based certificates for devices and appliances',
          icon: Icons.electrical_services_rounded,
        ),
        _selectedSector == 'Electronics & Appliances',
      ),
      (
        const _Sector(
          title: 'EV & Automotive',
          description: 'Vehicle, battery, and component certificates on-chain',
          icon: Icons.electric_car_rounded,
        ),
        _selectedSector == 'EV & Automotive',
      ),
      (
        const _Sector(
          title: 'Insurance Policies',
          description: 'Policy certificates and agent-issued proofs',
          icon: Icons.policy_rounded,
        ),
        _selectedSector == 'Insurance Policies',
      ),
      (
        const _Sector(
          title: 'Healthcare Products',
          description:
              'Certificates for pharma, devices, and lab-linked proofs',
          icon: Icons.medical_services_rounded,
        ),
        _selectedSector == 'Healthcare Products',
      ),
      (
        const _Sector(
          title: 'Industrial Equipment',
          description: 'Asset certificates for tools, machines, and parts',
          icon: Icons.precision_manufacturing_rounded,
        ),
        _selectedSector == 'Industrial Equipment',
      ),
      (
        const _Sector(
          title: 'Agriculture Products',
          description: 'Origin and quality certificates for agri goods',
          icon: Icons.agriculture_rounded,
        ),
        _selectedSector == 'Agriculture Products',
      ),
      (
        const _Sector(
          title: 'Luxury Products',
          description: 'Anti-counterfeit certificates for premium goods',
          icon: Icons.diamond_rounded,
        ),
        _selectedSector == 'Luxury Products',
      ),
      (
        const _Sector(
          title: 'Others',
          description: 'Create a custom product certificate batch',
          icon: Icons.widgets_rounded,
        ),
        _selectedSector == 'Others',
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.pageBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () => _goBack(context),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text('Select Sector'),
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.x4,
                  AppSpacing.x3,
                  AppSpacing.x4,
                  AppSpacing.x4,
                ),
                children: <Widget>[
                  _ProductFlowStepper(
                    stepIndex: 0,
                    gradient: _primaryGradient,
                    labels: const <String>[
                      'Sector',
                      'Product Details',
                      'Upload',
                    ],
                  ),
                  const SizedBox(height: AppSpacing.x5),
                  Text('Select Product Sector', style: AppTypography.display2),
                  const SizedBox(height: AppSpacing.x2),
                  Text(
                    'Choose the sector category for this product verification batch.',
                    style: AppTypography.body2.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.x5),
                  LayoutBuilder(
                    builder:
                        (BuildContext context, BoxConstraints constraints) {
                          final int columns = constraints.maxWidth >= 800
                              ? 3
                              : 2;
                          return GridView.builder(
                            itemCount: sectors.length,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: columns,
                                  mainAxisSpacing: AppSpacing.x3,
                                  crossAxisSpacing: AppSpacing.x3,
                                  childAspectRatio: 1,
                                ),
                            itemBuilder: (BuildContext context, int index) {
                              final (_Sector sector, bool selected) =
                                  sectors[index];
                              return _SectorCard(
                                title: sector.title,
                                description: sector.description,
                                icon: sector.icon,
                                selected: selected,
                                onTap: () => setState(
                                  () => _selectedSector = sector.title,
                                ),
                              );
                            },
                          );
                        },
                  ),
                ],
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.x4,
                  AppSpacing.x2,
                  AppSpacing.x4,
                  AppSpacing.x4,
                ),
                child: _GradientCtaButton(
                  label: 'Continue',
                  icon: Icons.arrow_forward_rounded,
                  gradient: _primaryGradient,
                  enabled: _selectedSector != null,
                  onPressed: () => _continue(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Sector {
  const _Sector({
    required this.title,
    required this.description,
    required this.icon,
  });

  final String title;
  final String description;
  final IconData icon;
}

class _SectorCard extends StatelessWidget {
  const _SectorCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String description;
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
          padding: const EdgeInsets.all(AppSpacing.x4),
          child: Stack(
            children: <Widget>[
              Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.brandBlue.withAlpha(24)
                          : const Color(0xFFEFF3FF),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: AppColors.brandBlue, size: 26),
                  ),
                  const SizedBox(height: AppSpacing.x2),
                  Text(
                    title,
                    style: AppTypography.body2.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 13.5,
                      height: 1.1,
                      color: selected
                          ? AppColors.brandBlue
                          : AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.2,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
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

class _ProductFlowStepper extends StatelessWidget {
  const _ProductFlowStepper({
    required this.stepIndex,
    required this.gradient,
    required this.labels,
  });

  final int stepIndex;
  final Gradient gradient;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    const int totalSteps = 3;
    final double progress = stepIndex / (totalSteps - 1);

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
          SizedBox(
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
                      tween: Tween<double>(begin: 0, end: progress.clamp(0, 1)),
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
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              for (int i = 0; i < totalSteps; i++) ...<Widget>[
                _MinimalStepDot(
                  active: i == stepIndex,
                  completed: i < stepIndex,
                  gradient: gradient,
                ),
                if (i != totalSteps - 1) const Spacer(),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              for (int i = 0; i < labels.length; i++) ...<Widget>[
                Expanded(
                  child: Text(
                    labels[i],
                    textAlign: i == 0
                        ? TextAlign.left
                        : (i == labels.length - 1
                              ? TextAlign.right
                              : TextAlign.center),
                    style: AppTypography.caption.copyWith(
                      color: i == stepIndex
                          ? AppColors.brandBlue
                          : AppColors.textTertiary,
                      fontWeight: i == stepIndex
                          ? FontWeight.w800
                          : FontWeight.w600,
                    ),
                  ),
                ),
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

    return AnimatedOpacity(
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
  }
}

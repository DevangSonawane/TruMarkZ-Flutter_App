import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/router/app_router.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/widgets/tmz_card.dart';

enum ProductServiceType { verification, warranty }

class ProductServiceTypeSelectorPage extends StatefulWidget {
  const ProductServiceTypeSelectorPage({super.key});

  @override
  State<ProductServiceTypeSelectorPage> createState() =>
      _ProductServiceTypeSelectorPageState();
}

class _ProductServiceTypeSelectorPageState
    extends State<ProductServiceTypeSelectorPage> {
  bool _didInit = false;
  String _sector = '';
  ProductServiceType? _selected;

  static const Color _deepBlue = AppColors.deepNavy;

  LinearGradient get _primaryGradient => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[AppColors.brandBlue, _deepBlue],
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInit) return;
    _didInit = true;
    final GoRouterState state = GoRouterState.of(context);
    final Object? extra = state.extra;
    final String? extraSector = extra is String ? extra : null;
    _sector = (extraSector ?? state.uri.queryParameters['sector'] ?? '').trim();
  }

  void _goBack(BuildContext context) {
    final GoRouter router = GoRouter.of(context);
    if (router.canPop()) {
      context.pop();
    } else {
      context.go(AppRouter.dashboardPath);
    }
  }

  void _continue(BuildContext context) {
    final ProductServiceType? selected = _selected;
    if (selected == null) return;

    final Uri uri = Uri(
      path: AppRouter.productBatchSetupPath,
      queryParameters: <String, String>{'mode': selected.name},
    );
    context.push(uri.toString(), extra: _sector);
  }

  @override
  Widget build(BuildContext context) {
    final String title = _sector.trim().isEmpty ? 'Select Flow' : _sector;
    final bool hasSector = _sector.trim().isNotEmpty;

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
        title: const Text('Select Service'),
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
                  Text(title, style: AppTypography.display2),
                  const SizedBox(height: AppSpacing.x2),
                  Text(
                    'Choose what you want to create for this batch.',
                    style: AppTypography.body2.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (!hasSector) ...<Widget>[
                    const SizedBox(height: AppSpacing.x3),
                    TMZCard(
                      padding: const EdgeInsets.all(AppSpacing.x4),
                      child: Text(
                        'Missing sector information. Please go back and select a sector again.',
                        style: AppTypography.body2.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.25,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.x5),
                  _ServiceCard(
                    title: 'Product Verification',
                    subtitle:
                        'Issue authenticity / compliance certificates for products.',
                    icon: Icons.verified_user_rounded,
                    selected: _selected == ProductServiceType.verification,
                    gradient: _primaryGradient,
                    onTap: hasSector
                        ? () => setState(
                            () => _selected = ProductServiceType.verification,
                          )
                        : () {},
                  ),
                  const SizedBox(height: AppSpacing.x3),
                  _ServiceCard(
                    title: 'Warranty',
                    subtitle:
                        'Create warranty certificates linked to serial numbers.',
                    icon: Icons.verified_outlined,
                    selected: _selected == ProductServiceType.warranty,
                    gradient: _primaryGradient,
                    onTap: hasSector
                        ? () => setState(
                            () => _selected = ProductServiceType.warranty,
                          )
                        : () {},
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
                  enabled: hasSector && _selected != null,
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

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.gradient,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final Gradient gradient;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final BorderSide borderSide = selected
        ? const BorderSide(color: AppColors.brandBlue, width: 2)
        : BorderSide(color: Colors.transparent.withAlpha(0));

    return TMZCard(
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: SizedBox(
        height: 120,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.fromBorderSide(borderSide),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Container(
                width: 10,
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(18),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.x4),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.brandBlue.withAlpha(20),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: AppColors.brandBlue),
              ),
              const SizedBox(width: AppSpacing.x3),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    0,
                    AppSpacing.x4,
                    AppSpacing.x4,
                    AppSpacing.x4,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        title,
                        style: AppTypography.heading1.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        style: AppTypography.body2.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.25,
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

class _GradientCtaButton extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: enabled
              ? gradient
              : LinearGradient(
                  colors: <Color>[Colors.grey.shade300, Colors.grey.shade300],
                ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: ElevatedButton(
          onPressed: enabled ? onPressed : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                label,
                style: AppTypography.body1.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 10),
              Icon(icon, color: Colors.white, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

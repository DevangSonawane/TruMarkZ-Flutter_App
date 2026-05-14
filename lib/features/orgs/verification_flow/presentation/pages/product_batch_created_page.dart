import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/router/app_router.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/widgets/tmz_button.dart';
import '../../../../../core/widgets/tmz_card.dart';

class ProductBatchCreatedPage extends StatelessWidget {
  const ProductBatchCreatedPage({super.key});

  static int _tryParseInt(String? value, {required int fallback}) {
    if (value == null) return fallback;
    final int? parsed = int.tryParse(value);
    return parsed ?? fallback;
  }

  static const Color _deepBlue = AppColors.deepNavy;

  static LinearGradient get _primaryGradient => const LinearGradient(
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

  @override
  Widget build(BuildContext context) {
    final Map<String, String> qp = GoRouterState.of(
      context,
    ).uri.queryParameters;

    final String sector = (qp['sector']?.trim().isNotEmpty ?? false)
        ? qp['sector']!.trim()
        : 'Product';
    final int records = _tryParseInt(qp['records'], fallback: 120);
    final int skipped = _tryParseInt(qp['skipped'], fallback: 0);
    final String batchId = (qp['batchId'] ?? '').trim();

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
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.x4,
                  36,
                  AppSpacing.x4,
                  AppSpacing.x4,
                ),
                children: <Widget>[
                  Center(
                    child: TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0.9, end: 1),
                      duration: const Duration(milliseconds: 420),
                      curve: Curves.easeOutBack,
                      builder: (BuildContext context, double t, Widget? child) {
                        return Transform.scale(scale: t, child: child);
                      },
                      child: Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          color: AppColors.successBg,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.success.withAlpha(40),
                            width: 4,
                          ),
                          boxShadow: <BoxShadow>[
                            BoxShadow(
                              color: AppColors.success.withAlpha(22),
                              blurRadius: 24,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.check_rounded,
                          size: 54,
                          color: AppColors.success,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.x6),
                  Text(
                    'Batch Created!',
                    textAlign: TextAlign.center,
                    style: AppTypography.display2.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.x2),
                  Text(
                    'Your product verification batch has been queued. Certificates will be generated and stored on blockchain.',
                    textAlign: TextAlign.center,
                    style: AppTypography.body2.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.x6),
                  TMZCard(
                    padding: const EdgeInsets.all(AppSpacing.x4),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                '$records Products',
                                style: AppTypography.heading1.copyWith(
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Chip(
                                label: Text(sector),
                                backgroundColor: AppColors.brandBlue.withAlpha(
                                  14,
                                ),
                                labelStyle: AppTypography.caption.copyWith(
                                  color: AppColors.brandBlue,
                                  fontWeight: FontWeight.w800,
                                ),
                                side: BorderSide(
                                  color: AppColors.brandBlue.withAlpha(24),
                                ),
                              ),
                              if (skipped > 0) ...<Widget>[
                                const SizedBox(height: 10),
                                Text(
                                  '$skipped skipped',
                                  style: AppTypography.body2.copyWith(
                                    color: const Color(0xFFF59E0B),
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: AppColors.brandBlue.withAlpha(12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.inventory_2_rounded,
                            color: AppColors.brandBlue,
                          ),
                        ),
                      ],
                    ),
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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    _GradientCtaButton(
                      label: 'View Batch',
                      icon: Icons.arrow_forward_rounded,
                      gradient: _primaryGradient,
                      enabled: true,
                      onPressed: () => batchId.trim().isEmpty
                          ? context.go(AppRouter.appBatchesPath)
                          : context.go(
                              '${AppRouter.appBatchTrackingDetailPath}?batch_id=${Uri.encodeQueryComponent(batchId)}',
                            ),
                    ),
                    const SizedBox(height: AppSpacing.x3),
                    TMZButton(
                      label: 'Back to Dashboard',
                      icon: Icons.dashboard_rounded,
                      variant: TMZButtonVariant.secondary,
                      onPressed: () => context.go(AppRouter.dashboardPath),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
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

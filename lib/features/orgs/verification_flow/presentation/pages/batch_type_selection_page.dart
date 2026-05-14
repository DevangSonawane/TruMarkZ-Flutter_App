import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/router/app_router.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';

enum _BatchType { human, product }

class BatchTypeSelectionPage extends StatefulWidget {
  const BatchTypeSelectionPage({super.key});

  @override
  State<BatchTypeSelectionPage> createState() => _BatchTypeSelectionPageState();
}

class _BatchTypeSelectionPageState extends State<BatchTypeSelectionPage> {
  _BatchType? _selected;

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
    final _BatchType? selected = _selected;
    if (selected == null) return;

    final String target = switch (selected) {
      _BatchType.human => AppRouter.verificationPlanSetupPath,
      _BatchType.product => AppRouter.productSectorSelectorPath,
    };
    context.push(target);
  }

  @override
  Widget build(BuildContext context) {
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
        title: Row(
          children: <Widget>[
            Image.asset('assets/icons/headers_app_icon.png', height: 22),
            const SizedBox(width: AppSpacing.x2),
            const Text('New Batch'),
          ],
        ),
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
                  Text('Choose Batch Type', style: AppTypography.display2),
                  const SizedBox(height: AppSpacing.x2),
                  Text(
                    'Start a verification flow for people or products.',
                    style: AppTypography.body2.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.x5),
                  _BatchTypeCard(
                    icon: Icons.person_search_rounded,
                    title: 'Human Verification',
                    subtitle:
                        'Verify identities of individuals — workers, agents, drivers, students & more',
                    tags: const <String>[
                      'Blue Collar Workforce',
                      'Gig Economy',
                      'Insurance Agents',
                      'Recruitment & Students',
                    ],
                    selected: _selected == _BatchType.human,
                    gradient: _primaryGradient,
                    onTap: () {
                      if (_selected == _BatchType.human) {
                        _continue(context);
                        return;
                      }
                      setState(() => _selected = _BatchType.human);
                    },
                  ),
                  const SizedBox(height: AppSpacing.x4),
                  _BatchTypeCard(
                    icon: Icons.inventory_2_rounded,
                    title: 'Product Verification',
                    subtitle:
                        'Issue digital certificates for products stored on blockchain',
                    tags: const <String>[
                      'Consumer Goods',
                      'Cosmetics',
                      'Electronics',
                      'EV & Automotive',
                    ],
                    selected: _selected == _BatchType.product,
                    gradient: _primaryGradient,
                    onTap: () {
                      if (_selected == _BatchType.product) {
                        _continue(context);
                        return;
                      }
                      setState(() => _selected = _BatchType.product);
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
                  enabled: _selected != null,
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

class _BatchTypeCard extends StatelessWidget {
  const _BatchTypeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.tags,
    required this.selected,
    required this.gradient,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final List<String> tags;
  final bool selected;
  final Gradient gradient;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final BorderSide borderSide = selected
        ? const BorderSide(color: AppColors.brandBlue, width: 2)
        : BorderSide(color: Colors.transparent.withAlpha(0));

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 180),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.fromBorderSide(borderSide),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: AppColors.brandBlue.withAlpha(18),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            children: <Widget>[
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Container(
                      width: 10,
                      decoration: BoxDecoration(
                        gradient: gradient,
                        borderRadius: const BorderRadius.horizontal(
                          left: Radius.circular(22),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.x4),
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
                            Row(
                              children: <Widget>[
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
                                  child: Text(
                                    title,
                                    style: AppTypography.heading1.copyWith(
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.x3),
                            Text(
                              subtitle,
                              style: AppTypography.body2.copyWith(
                                color: AppColors.textSecondary,
                                height: 1.25,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.x3),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: <Widget>[
                                for (final String tag in tags)
                                  Chip(
                                    label: Text(tag),
                                    backgroundColor: AppColors.brandBlue
                                        .withAlpha(14),
                                    labelStyle: AppTypography.caption.copyWith(
                                      color: AppColors.brandBlue,
                                      fontWeight: FontWeight.w700,
                                    ),
                                    side: BorderSide(
                                      color: AppColors.brandBlue.withAlpha(20),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      gradient: gradient,
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: AppColors.brandBlue.withAlpha(30),
                          blurRadius: 14,
                          offset: const Offset(0, 8),
                        ),
                      ],
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

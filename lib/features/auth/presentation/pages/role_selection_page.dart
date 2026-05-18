import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

enum _Role { organisation, individual }

class RoleSelectionPage extends StatefulWidget {
  const RoleSelectionPage({super.key});

  @override
  State<RoleSelectionPage> createState() => _RoleSelectionPageState();
}

class _RoleSelectionPageState extends State<RoleSelectionPage> {
  _Role? _selected;

  void _onContinuePressed(BuildContext context) {
    final _Role? selected = _selected;
    if (selected == null) return;
    switch (selected) {
      case _Role.organisation:
        context.go('${AppRouter.loginPath}?type=organization&force=true');
      case _Role.individual:
        context.go('${AppRouter.loginPath}?type=individual&force=true');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      appBar: null,
      body: SafeArea(
        child: Stack(
          children: <Widget>[
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, -0.8),
                    radius: 1.2,
                    colors: <Color>[
                      AppColors.blueTint,
                      AppColors.pageBg,
                      AppColors.cardSurface,
                    ],
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.center,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.x6,
                  AppSpacing.x10,
                  AppSpacing.x6,
                  AppSpacing.x10,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Image.asset(
                        'assets/icons/logo icon.png',
                        height: 44,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: AppSpacing.x4),
                      Text(
                        'Who are you?',
                        textAlign: TextAlign.center,
                        style: AppTypography.display2.copyWith(
                          fontSize: 28,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.x6),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: _ChoiceCard(
                              selected: _selected == _Role.organisation,
                              icon: Image.asset(
                                'assets/icons/teamwork.png',
                                width: 34,
                                height: 34,
                                fit: BoxFit.contain,
                              ),
                              label: 'Organisation',
                              onTap: () => setState(
                                () => _selected = _Role.organisation,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.x4),
                          Expanded(
                            child: _ChoiceCard(
                              selected: _selected == _Role.individual,
                              icon: Image.asset(
                                'assets/icons/user (2).png',
                                width: 34,
                                height: 34,
                                fit: BoxFit.contain,
                              ),
                              label: 'Individual',
                              onTap: () =>
                                  setState(() => _selected = _Role.individual),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.x8),
                      SizedBox(
                        height: 54,
                        width: double.infinity,
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 160),
                          opacity: _selected == null ? 0.55 : 1.0,
                          child: Material(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(999),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(999),
                              onTap: _selected == null
                                  ? null
                                  : () => _onContinuePressed(context),
                              child: Ink(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(999),
                                  color: _selected == null
                                      ? const Color(0xFFE2E8F0)
                                      : AppColors.brandBlue,
                                ),
                                child: Center(
                                  child: Text(
                                    'Continue',
                                    style: AppTypography.button.copyWith(
                                      color: _selected == null
                                          ? AppColors.textSecondary
                                          : Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    required this.selected,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final bool selected;
  final Widget icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return AspectRatio(
      aspectRatio: 1.05,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: selected ? scheme.primary : Colors.transparent,
                width: 1.2,
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withAlpha(10),
                  blurRadius: 22,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: scheme.primary.withAlpha(14),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: IconTheme(
                      data: IconThemeData(color: scheme.primary, size: 34),
                      child: icon,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.x3),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: AppTypography.heading2.copyWith(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

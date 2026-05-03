import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

enum _Role { organisation, individual, verifying }

class RoleSelectionPage extends StatefulWidget {
  const RoleSelectionPage({super.key});

  @override
  State<RoleSelectionPage> createState() => _RoleSelectionPageState();
}

class _RoleSelectionPageState extends State<RoleSelectionPage> {
  _Role? _selected;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: AppColors.pageBg,
      appBar: AppBar(
        titleSpacing: 12,
        title: Row(
          children: <Widget>[
            SvgPicture.asset(
              'assets/icons/trumarkz_shield.svg',
              height: 18,
              colorFilter: ColorFilter.mode(scheme.primary, BlendMode.srcIn),
            ),
            const SizedBox(width: AppSpacing.x2),
            Text('TruMarkZ', style: AppTypography.heading2),
          ],
        ),
        actions: <Widget>[],
      ),
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
            ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.x6,
                AppSpacing.x6,
                AppSpacing.x6,
                150,
              ),
              children: <Widget>[
                Text(
                  'How will you use TruMarkZ?',
                  style: AppTypography.display2.copyWith(
                    fontSize: 28,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.x2),
                Text(
                  'Choose the account type that best fits your\nneeds to get started.',
                  style: AppTypography.body2.copyWith(
                    height: 1.35,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.x6),
                _ChoiceCard(
                  selected: _selected == _Role.organisation,
                  icon: Icons.shield_rounded,
                  title: 'I represent an Organisation',
                  subtitle: 'Verify workers, products &\nservices in bulk',
                  onTap: () => setState(() => _selected = _Role.organisation),
                ),
                const SizedBox(height: AppSpacing.x4),
                _ChoiceCard(
                  selected: _selected == _Role.individual,
                  icon: Icons.person_outline_rounded,
                  title: 'I am an Individual',
                  subtitle: 'Build your verified skill tree\ncredential',
                  onTap: () => setState(() => _selected = _Role.individual),
                ),
                const SizedBox(height: AppSpacing.x6),
                _PromoCard(
                  onTap: () => setState(() => _selected = _Role.verifying),
                ),
              ],
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: SafeArea(
                top: false,
                minimum: const EdgeInsets.fromLTRB(
                  AppSpacing.x6,
                  AppSpacing.x2,
                  AppSpacing.x6,
                  AppSpacing.x6,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      child: _selected == null
                          ? const SizedBox.shrink()
                          : SizedBox(
                              key: const ValueKey<String>('continue_button'),
                              height: 54,
                              width: double.infinity,
                              child: Material(
                                color: Colors.transparent,
                                borderRadius: BorderRadius.circular(999),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(999),
                                  onTap: () {
                                    switch (_selected!) {
                                      case _Role.organisation:
                                        context.go(
                                          AppRouter
                                              .organisationRegistrationPath,
                                        );
                                      case _Role.individual:
                                        context.go(
                                          AppRouter.individualIdentityPath,
                                        );
                                      case _Role.verifying:
                                        context.go(AppRouter.appRegistryPath);
                                    }
                                  },
                                  splashColor: Colors.white.withAlpha(31),
                                  highlightColor: Colors.white.withAlpha(18),
                                  child: SizedBox.expand(
                                    child: Ink(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                        gradient: const LinearGradient(
                                          begin: Alignment.centerLeft,
                                          end: Alignment.centerRight,
                                          colors: <Color>[
                                            AppColors.brandBlue,
                                            AppColors.deepNavy,
                                          ],
                                        ),
                                        boxShadow: <BoxShadow>[
                                          BoxShadow(
                                            color: AppColors.brandBlue
                                                .withAlpha(0x59),
                                            blurRadius: 16,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Center(
                                        child: Text(
                                          'Continue',
                                          style: AppTypography.button.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                    ),
                    const SizedBox(height: AppSpacing.x3),
                    Text(
                      'You can change this later in settings.',
                      style: AppTypography.caption.copyWith(
                        color: const Color(0xFF94A3B8),
                      ),
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

class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    required this.selected,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.x4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
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
          child: Row(
            children: <Widget>[
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: scheme.primary.withAlpha(16),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: scheme.primary),
              ),
              const SizedBox(width: AppSpacing.x4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: AppTypography.heading2.copyWith(
                        color: const Color(0xFF0B0F19),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.x1),
                    Text(
                      subtitle,
                      style: AppTypography.body2.copyWith(
                        color: const Color(0xFF64748B),
                        height: 1.3,
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
  }
}

class _PromoCard extends StatelessWidget {
  const _PromoCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        height: 130,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            colors: <Color>[
              scheme.primary.withAlpha(28),
              scheme.primary.withAlpha(10),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: scheme.outlineVariant),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withAlpha(8),
              blurRadius: 20,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Stack(
          children: <Widget>[
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: CustomPaint(
                  painter: _WavePainter(color: scheme.primary.withAlpha(22)),
                ),
              ),
            ),
            Positioned(
              left: AppSpacing.x4,
              top: AppSpacing.x4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Just Verifying',
                    style: AppTypography.heading2.copyWith(
                      color: const Color(0xFF0B0F19),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Scan a QR code or\nsearch the registry',
                    style: AppTypography.body2.copyWith(
                      color: const Color(0xFF64748B),
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              right: 14,
              top: 14,
              child: Opacity(
                opacity: 0.25,
                child: SvgPicture.asset(
                  'assets/icons/trumarkz_shield.svg',
                  height: 52,
                  colorFilter: ColorFilter.mode(
                    scheme.primary,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
            Positioned(
              right: AppSpacing.x4,
              bottom: AppSpacing.x4,
              child: Icon(Icons.qr_code_scanner_rounded, color: scheme.primary),
            ),
          ],
        ),
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  const _WavePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10;

    for (int i = 0; i < 3; i++) {
      final Path path = Path();
      final double y = size.height * (0.25 + i * 0.25);
      path.moveTo(-20, y);
      path.cubicTo(
        size.width * 0.25,
        y - 18,
        size.width * 0.55,
        y + 18,
        size.width + 20,
        y,
      );
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _WavePainter oldDelegate) =>
      oldDelegate.color != color;
}

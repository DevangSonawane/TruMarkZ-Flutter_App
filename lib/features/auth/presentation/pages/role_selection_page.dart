import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';

enum _Role { organisation, individual }

class RoleSelectionPage extends StatefulWidget {
  const RoleSelectionPage({super.key});

  @override
  State<RoleSelectionPage> createState() => _RoleSelectionPageState();
}

class _RoleSelectionPageState extends State<RoleSelectionPage> {
  static const double _referenceWidth = 402;
  static const Color _panelBg = Color(0xFFF7F9FC);

  _Role? _selected = _Role.individual;

  void _continue(BuildContext context, _Role role) {
    setState(() => _selected = role);

    if (role == _Role.organisation) {
      context.go('${AppRouter.loginPath}?type=organization&force=true');
      return;
    }

    context.go('${AppRouter.loginPath}?type=individual&force=true');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.brandBlue,
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final double contentWidth = math.min(
              constraints.maxWidth,
              _referenceWidth,
            );
            final double scale = contentWidth / _referenceWidth;
            double s(double value) => value * scale;

            return Center(
              child: SizedBox(
                width: contentWidth,
                height: constraints.maxHeight,
                child: Column(
                  children: <Widget>[
                    Padding(
                      padding: EdgeInsets.fromLTRB(s(16), s(10), s(16), 0),
                      child: SizedBox(
                        height: s(32),
                        child: Stack(
                          alignment: Alignment.center,
                          children: <Widget>[
                            Align(
                              alignment: Alignment.centerLeft,
                              child: InkWell(
                                onTap: () => context.go(AppRouter.onboardingPath),
                                borderRadius: BorderRadius.circular(999),
                                child: SizedBox(
                                  width: s(28),
                                  height: s(28),
                                  child: Icon(
                                    Icons.arrow_back_ios_new_rounded,
                                    color: Colors.white,
                                    size: s(18),
                                  ),
                                ),
                              ),
                            ),
                            Text(
                              'Select your preference',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: s(18),
                                height: 1.2,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: s(12)),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: s(16)),
                      child: SizedBox(
                        height: s(208),
                        child: Center(
                          child: Transform.translate(
                            offset: Offset(0, s(48)),
                            child: _HeroImagePane(
                              scale: scale,
                              selected: _selected,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: s(52)),
                    Expanded(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: _panelBg,
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(s(26)),
                          ),
                        ),
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: EdgeInsets.fromLTRB(
                            s(14),
                            s(16),
                            s(14),
                            s(16) + MediaQuery.viewPaddingOf(context).bottom,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[
                              _RolePlanCard(
                                scale: scale,
                                role: _Role.individual,
                                title: 'Individual',
                                subtitle: 'Personal records and vault access',
                                accentColor: const Color(0xFF243B6B),
                                badgeLabel: 'Prime',
                                footerLabel: 'PERSONAL ACCESS',
                                icon: Icons.person_rounded,
                                features: const <String>[
                                  'Secure document storage',
                                  'Simple one-user experience',
                                ],
                                selected: _selected == _Role.individual,
                                isAccent: false,
                                onTap: () => setState(
                                  () => _selected = _Role.individual,
                                ),
                                onPressed: () =>
                                    _continue(context, _Role.individual),
                              ),
                              SizedBox(height: s(10)),
                              _RolePlanCard(
                                scale: scale,
                                role: _Role.organisation,
                                title: 'Organisation',
                                subtitle: 'Team workflows and shared control',
                                accentColor: AppColors.brandBlue,
                                badgeLabel: 'Royale',
                                footerLabel: 'ENTERPRISE TIER',
                                icon: Icons.apartment_rounded,
                                features: const <String>[
                                  'Centralised team dashboard',
                                  'Verification workflow management',
                                ],
                                selected: _selected == _Role.organisation,
                                isAccent: true,
                                onTap: () => setState(
                                  () => _selected = _Role.organisation,
                                ),
                                onPressed: () =>
                                    _continue(context, _Role.organisation),
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
          },
        ),
      ),
    );
  }
}

class _HeroImagePane extends StatelessWidget {
  const _HeroImagePane({required this.scale, required this.selected});

  final double scale;
  final _Role? selected;

  @override
  Widget build(BuildContext context) {
    double s(double value) => value * scale;
    final bool isOrganisation = selected == _Role.organisation;
    final String assetPath = isOrganisation
        ? 'assets/images_role/org.png'
        : 'assets/images_role/indv.png';

    return SizedBox(
      width: s(344),
      height: s(352),
      child: Transform.translate(
        offset: Offset(
          s(isOrganisation ? -32 : -24),
          s(isOrganisation ? 20 : 18),
        ),
        child: Image.asset(
          assetPath,
          fit: BoxFit.contain,
          alignment: Alignment.centerRight,
          width: s(isOrganisation ? 292 : 284),
        ),
      ),
    );
  }
}

class _RolePlanCard extends StatelessWidget {
  const _RolePlanCard({
    required this.scale,
    required this.role,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.badgeLabel,
    required this.footerLabel,
    required this.icon,
    required this.features,
    required this.selected,
    required this.isAccent,
    required this.onTap,
    required this.onPressed,
  });

  final double scale;
  final _Role role;
  final String title;
  final String subtitle;
  final Color accentColor;
  final String badgeLabel;
  final String footerLabel;
  final IconData icon;
  final List<String> features;
  final bool selected;
  final bool isAccent;
  final VoidCallback onTap;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    double s(double value) => value * scale;
    final Color background = isAccent ? AppColors.brandBlue : const Color(0xFF2D3440);
    final Color foreground = Colors.white;
    final Color bodyText = isAccent
        ? Colors.white.withAlpha(210)
        : Colors.white.withAlpha(220);
    final Color dividerColor = isAccent
        ? Colors.white.withAlpha(45)
        : Colors.white.withAlpha(24);
    final Color badgeBg = isAccent
        ? Colors.white.withAlpha(18)
        : Colors.white.withAlpha(10);
    final Color iconBg = isAccent
        ? Colors.white.withAlpha(12)
        : Colors.white.withAlpha(8);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(s(24)),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: EdgeInsets.fromLTRB(s(14), s(14), s(14), s(12)),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(s(24)),
            border: Border.all(
              color: selected
                  ? Colors.white.withAlpha(isAccent ? 55 : 28)
                  : Colors.transparent,
              width: s(1.2),
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withAlpha(isAccent ? 28 : 20),
                blurRadius: s(18),
                offset: Offset(0, s(8)),
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
                    width: s(36),
                    height: s(36),
                    decoration: BoxDecoration(
                      color: iconBg,
                      borderRadius: BorderRadius.circular(s(12)),
                    ),
                    child: Icon(
                      icon,
                      color: foreground,
                      size: s(20),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: s(10),
                      vertical: s(6),
                    ),
                    decoration: BoxDecoration(
                      color: badgeBg,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      badgeLabel,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: s(9.5),
                        fontWeight: FontWeight.w600,
                        color: foreground,
                        letterSpacing: 0.35,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: s(10)),
              Text(
                title,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: s(15.5),
                  fontWeight: FontWeight.w700,
                  color: foreground,
                ),
              ),
              SizedBox(height: s(4)),
              Text(
                subtitle,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: s(11),
                  height: 16 / 11,
                  fontWeight: FontWeight.w400,
                  color: bodyText,
                ),
              ),
              SizedBox(height: s(10)),
              Divider(
                height: s(1),
                thickness: s(1),
                color: dividerColor,
              ),
              SizedBox(height: s(10)),
              for (final String feature in features) ...<Widget>[
                _FeatureRow(
                  scale: scale,
                  text: feature,
                  color: foreground,
                ),
                if (feature != features.last) SizedBox(height: s(6)),
              ],
              SizedBox(height: s(10)),
              Container(
                padding: EdgeInsets.only(top: s(10)),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: dividerColor, width: s(1)),
                  ),
                ),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        footerLabel,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: s(9.5),
                          fontWeight: FontWeight.w500,
                          color: bodyText,
                          letterSpacing: 0.45,
                        ),
                      ),
                    ),
                    SizedBox(
                      height: s(32),
                      child: TextButton(
                        onPressed: onPressed,
                        style: TextButton.styleFrom(
                          backgroundColor: isAccent ? Colors.white : AppColors.brandBlue,
                          foregroundColor: isAccent ? AppColors.brandBlue : Colors.white,
                          padding: EdgeInsets.symmetric(
                            horizontal: s(14),
                            vertical: s(6),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        child: Text(
                          selected ? 'Continue' : 'Select',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: s(10.5),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
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

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({
    required this.scale,
    required this.text,
    required this.color,
  });

  final double scale;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    double s(double value) => value * scale;

    return Row(
      children: <Widget>[
        Icon(
          Icons.stars_rounded,
          size: s(13),
          color: color.withAlpha(235),
        ),
        SizedBox(width: s(8)),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: s(10.5),
              fontWeight: FontWeight.w500,
              color: color.withAlpha(230),
            ),
          ),
        ),
      ],
    );
  }
}

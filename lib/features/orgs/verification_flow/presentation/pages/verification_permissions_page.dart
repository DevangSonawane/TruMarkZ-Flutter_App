import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/router/app_router.dart';
import '../../../../../core/theme/app_colors.dart';

class VerificationPermissionsPage extends StatefulWidget {
  const VerificationPermissionsPage({super.key});

  @override
  State<VerificationPermissionsPage> createState() =>
      _VerificationPermissionsPageState();
}

class _VerificationPermissionsPageState
    extends State<VerificationPermissionsPage> {
  static const double _referenceWidth = 402;
  static const Color _panelBg = Color(0xFFF7F9FC);

  _AccessMode _mode = _AccessMode.publicSearchable;

  List<String> get _checksFromRoute {
    final Map<String, String> qp = GoRouterState.of(
      context,
    ).uri.queryParameters;
    final String raw = (qp['checks'] ?? '').trim();
    if (raw.isEmpty) return const <String>[];
    return raw
        .split(',')
        .map((String e) => e.trim())
        .where((String e) => e.isNotEmpty)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.brandBlue,
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final double contentWidth = constraints.maxWidth < _referenceWidth
                ? constraints.maxWidth
                : _referenceWidth;
            final double scale = contentWidth / _referenceWidth;
            double s(double v) => v * scale;

            final EdgeInsets panelPadding = EdgeInsets.fromLTRB(
              s(16),
              s(32),
              s(16),
              0,
            );

            return Center(
              child: SizedBox(
                width: contentWidth,
                height: constraints.maxHeight,
                child: Column(
                  children: <Widget>[
                    Padding(
                      padding: EdgeInsets.fromLTRB(s(16), s(8), s(16), 0),
                      child: Row(
                        children: <Widget>[
                          InkResponse(
                            onTap: () => context.pop(),
                            radius: s(22),
                            child: SvgPicture.asset(
                              'assets/icons/figma/new_batch_back.svg',
                              width: s(24),
                              height: s(24),
                              colorFilter: const ColorFilter.mode(
                                Colors.white,
                                BlendMode.srcIn,
                              ),
                            ),
                          ),
                          SizedBox(width: s(12)),
                          Text(
                            'Permissions',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: s(21),
                              fontWeight: FontWeight.w600,
                              height: 19.5 / 21,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: s(21)),
                    Expanded(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: _panelBg,
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(s(20)),
                          ),
                        ),
                        child: Column(
                          children: <Widget>[
                            Expanded(
                              child: SingleChildScrollView(
                                padding: panelPadding.copyWith(bottom: s(24)),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Row(
                                      children: <Widget>[
                                        Text(
                                          'STEP 3 OF 6',
                                          style: TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: s(10),
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: s(1),
                                            height: 15 / 10,
                                            color: const Color(0xFF94A3B8),
                                          ),
                                        ),
                                        const Spacer(),
                                        Text(
                                          '50%',
                                          style: TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: s(10),
                                            fontWeight: FontWeight.w700,
                                            height: 15 / 10,
                                            color: AppColors.brandBlue,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: s(8)),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(
                                        s(9999),
                                      ),
                                      child: SizedBox(
                                        height: s(4),
                                        child: Stack(
                                          fit: StackFit.expand,
                                          children: <Widget>[
                                            const DecoratedBox(
                                              decoration: BoxDecoration(
                                                color: Color(0xFFE5E7EB),
                                              ),
                                            ),
                                            FractionallySizedBox(
                                              alignment: Alignment.centerLeft,
                                              widthFactor: 0.5,
                                              child: const DecoratedBox(
                                                decoration: BoxDecoration(
                                                  color: AppColors.brandBlue,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: s(24)),
                                    Text(
                                      'Configure Permissions',
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: s(24),
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: s(1.1833819),
                                        height: 22.6 / 24,
                                        color: const Color(0xFF3A3A3A),
                                      ),
                                    ),
                                    SizedBox(height: s(12)),
                                    Text(
                                      'Determine how verification data will be accessed and who\ncan view the finalized reports.',
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: s(12),
                                        fontWeight: FontWeight.w500,
                                        letterSpacing: s(1.1833819),
                                        height: 17.75 / 12,
                                        color: const Color(0xFF94A3B8),
                                      ),
                                    ),
                                    SizedBox(height: s(24)),
                                    _PermissionCard(
                                      scale: scale,
                                      selected:
                                          _mode == _AccessMode.publicSearchable,
                                      title: 'Public Searchable',
                                      subtitle:
                                          'Results will be visible in the public registry\nfor instant verification by third parties.',
                                      svgIconPath:
                                          'assets/icons/figma/permissions_icon_public.svg',
                                      onTap: () => setState(() {
                                        _mode = _AccessMode.publicSearchable;
                                      }),
                                    ),
                                    SizedBox(height: s(16)),
                                    _PermissionCard(
                                      scale: scale,
                                      selected:
                                          _mode ==
                                          _AccessMode.permissionBasedAccess,
                                      title: 'Permission-Based Access',
                                      subtitle:
                                          'Requires explicit consent via WhatsApp or\nEmail from the individual before data\naccess.',
                                      svgIconPath:
                                          'assets/icons/figma/permissions_icon_permission.svg',
                                      onTap: () => setState(() {
                                        _mode =
                                            _AccessMode.permissionBasedAccess;
                                      }),
                                    ),
                                    SizedBox(height: s(24)),
                                    _InfoBox(scale: scale),
                                  ],
                                ),
                              ),
                            ),
                            _BottomNav(
                              scale: scale,
                              child: _BottomContinue(
                                scale: scale,
                                onTap: () {
                                  final List<String> checks = _checksFromRoute;
                                  final String industry =
                                      (GoRouterState.of(context)
                                                  .uri
                                                  .queryParameters['industry'] ??
                                              '')
                                          .trim();
                                  final Map<String, String> qp =
                                      <String, String>{};
                                  if (checks.isNotEmpty) {
                                    qp['checks'] = checks.join(',');
                                  }
                                  qp['access'] = _mode.name;
                                  if (industry.isNotEmpty) {
                                    qp['industry'] = industry;
                                  }

                                  final Uri uri = Uri(
                                    path: AppRouter.bulkUploadPath,
                                    queryParameters: qp,
                                  );
                                  context.push(uri.toString());
                                },
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
          },
        ),
      ),
    );
  }
}

class _PermissionCard extends StatelessWidget {
  const _PermissionCard({
    required this.scale,
    required this.selected,
    required this.title,
    required this.subtitle,
    required this.svgIconPath,
    required this.onTap,
  });

  final double scale;
  final bool selected;
  final String title;
  final String subtitle;
  final String svgIconPath;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    double s(double v) => v * scale;

    final Color bg = Colors.white;
    final Color border = selected
        ? AppColors.brandBlue
        : const Color(0xFFE2E8F0);
    final double borderWidth = selected ? s(2) : s(1);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(s(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(s(16)),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.all(s(20)),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(s(16)),
            border: Border.all(color: border, width: borderWidth),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Color(0x0D000000),
                blurRadius: 2,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Container(
                    width: s(48),
                    height: s(48),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F7FF),
                      borderRadius: BorderRadius.circular(s(12)),
                      border: Border.all(color: const Color(0xFFE0EFFE)),
                    ),
                    alignment: Alignment.center,
                    child: SvgPicture.asset(
                      svgIconPath,
                      width: s(22),
                      height: s(22),
                      colorFilter: const ColorFilter.mode(
                        AppColors.brandBlue,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                  const Spacer(),
                  _RadioIndicator(scale: scale, selected: selected),
                ],
              ),
              SizedBox(height: s(16)),
              Text(
                title,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: s(16),
                  fontWeight: FontWeight.w700,
                  height: 24 / 16,
                  color: const Color(0xFF0F172A),
                ),
              ),
              SizedBox(height: s(8)),
              Text(
                subtitle,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: s(14),
                  fontWeight: FontWeight.w400,
                  height: 21 / 14,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RadioIndicator extends StatelessWidget {
  const _RadioIndicator({required this.scale, required this.selected});

  final double scale;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    double s(double v) => v * scale;

    if (selected) {
      return Container(
        width: s(24),
        height: s(24),
        decoration: BoxDecoration(
          color: AppColors.brandBlue,
          borderRadius: BorderRadius.circular(s(9999)),
          border: Border.all(color: AppColors.brandBlue, width: s(2)),
        ),
        alignment: Alignment.center,
        child: Container(
          width: s(6),
          height: s(6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(s(9999)),
          ),
        ),
      );
    }

    return Container(
      width: s(24),
      height: s(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(s(9999)),
        border: Border.all(color: const Color(0xFFCBD5E1), width: s(2)),
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  const _InfoBox({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    double s(double v) => v * scale;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(s(16)),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(s(12)),
        border: Border.all(color: const Color(0xFFCBD5E1).withAlpha(204)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: s(16),
            height: s(16),
            decoration: BoxDecoration(
              color: AppColors.brandBlue,
              borderRadius: BorderRadius.circular(s(9999)),
            ),
            alignment: Alignment.center,
            child: SvgPicture.asset(
              'assets/icons/figma/permissions_icon_info.svg',
              width: s(10),
              height: s(10),
              colorFilter: const ColorFilter.mode(
                Colors.white,
                BlendMode.srcIn,
              ),
            ),
          ),
          SizedBox(width: s(8)),
          Expanded(
            child: Text(
              'TruMarkZ uses cryptographic signing for every consent request. \nSelecting Permission-Based Access ensures GDPR and SOC2 compliance for sensitive professional data.',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: s(14),
                fontWeight: FontWeight.w400,
                height: 21 / 14,
                color: const Color(0xFF0F172A),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomContinue extends StatelessWidget {
  const _BottomContinue({required this.scale, required this.onTap});

  final double scale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    double s(double v) => v * scale;

    return Container(
      height: s(60),
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.brandBlue,
        borderRadius: BorderRadius.circular(s(16)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.brandBlue.withAlpha(51),
            blurRadius: s(6),
            spreadRadius: s(-4),
            offset: Offset(0, s(4)),
          ),
          BoxShadow(
            color: AppColors.brandBlue.withAlpha(51),
            blurRadius: s(15),
            spreadRadius: s(-3),
            offset: Offset(0, s(10)),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(s(16)),
          onTap: onTap,
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  'Continue',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: s(18),
                    fontWeight: FontWeight.w700,
                    height: 28 / 18,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: s(10)),
                SvgPicture.asset(
                  'assets/icons/figma/new_batch_continue_arrow.svg',
                  width: s(16),
                  height: s(16),
                  colorFilter: const ColorFilter.mode(
                    Colors.white,
                    BlendMode.srcIn,
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

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.scale, required this.child});

  final double scale;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    double s(double v) => v * scale;

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: s(12.864), sigmaY: s(12.864)),
        child: Container(
          padding: EdgeInsets.fromLTRB(
            s(13.604),
            s(12.864),
            s(13.668),
            s(12.864),
          ),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(204),
            border: Border(
              top: BorderSide(color: const Color(0xFFF3F4F6), width: s(1.072)),
            ),
          ),
          child: SafeArea(top: false, child: child),
        ),
      ),
    );
  }
}

enum _AccessMode { publicSearchable, permissionBasedAccess }

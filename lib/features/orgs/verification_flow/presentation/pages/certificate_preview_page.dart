import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/router/app_router.dart';
import '../../../../../core/theme/app_colors.dart';

class CertificatePreviewPage extends StatefulWidget {
  const CertificatePreviewPage({super.key});

  @override
  State<CertificatePreviewPage> createState() => _CertificatePreviewPageState();
}

class _CertificatePreviewPageState extends State<CertificatePreviewPage> {
  static const double _referenceWidth = 402;
  static const Color _panelBg = Color(0xFFF7F9FC);

  int _selectedTemplateIndex = 0;

  String? _checksParam(BuildContext context) =>
      GoRouterState.of(context).uri.queryParameters['checks'];

  String _industryLabel(BuildContext context) {
    final Map<String, String> qp = GoRouterState.of(
      context,
    ).uri.queryParameters;
    final String label = (qp['industry_label'] ?? '').trim();
    if (label.isNotEmpty) return label;
    final String raw = (qp['industry'] ?? '').trim();
    return raw.isEmpty ? '—' : raw;
  }

  String _identityTypeLabel(BuildContext context) {
    final Map<String, String> qp = GoRouterState.of(
      context,
    ).uri.queryParameters;
    final String label = (qp['identity_type'] ?? '').trim();
    if (label.isNotEmpty) return label;
    return '—';
  }

  Future<void> _onContinue(BuildContext context) async {
    final String? checks = _checksParam(context);
    final Uri uri = Uri(
      path: AppRouter.perUnitCostBreakdownPath,
      queryParameters: <String, String>{
        if (checks != null && checks.trim().isNotEmpty) 'checks': checks.trim(),
      },
    );
    final Object? res = await context.push(uri.toString());
    if (!context.mounted) return;
    context.pop(res == true);
  }

  @override
  Widget build(BuildContext context) {
    final String industryLabel = _industryLabel(context);
    final String identityTypeLabel = _identityTypeLabel(context);

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

            return Center(
              child: SizedBox(
                width: contentWidth,
                height: constraints.maxHeight,
                child: Column(
                  children: <Widget>[
                    Padding(
                      padding: EdgeInsets.fromLTRB(s(16), s(10), s(16), 0),
                      child: Row(
                        children: <Widget>[
                          InkResponse(
                            onTap: () => context.pop(false),
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
                            'Certificate Preview',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: s(20),
                              fontWeight: FontWeight.w600,
                              height: 19.5 / 20,
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
                        child: Stack(
                          children: <Widget>[
                            Positioned.fill(
                              child: SingleChildScrollView(
                                padding: EdgeInsets.fromLTRB(
                                  0,
                                  s(32),
                                  0,
                                  s(24) + s(85.728),
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: s(16),
                                      ),
                                      child: _StepProgress(scale: scale),
                                    ),
                                    SizedBox(height: s(24)),
                                    Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: s(16),
                                      ),
                                      child: Text(
                                        'Choose Identity Credential',
                                        style: TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: s(22),
                                          fontWeight: FontWeight.w800,
                                          height: 26 / 22,
                                          color: const Color(0xFF323232),
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: s(8)),
                                    Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: s(16),
                                      ),
                                      child: Text(
                                        'Select a secure visual template for your verified digital\nidentity.',
                                        style: TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: s(12),
                                          fontWeight: FontWeight.w400,
                                          height: 18 / 12,
                                          color: const Color(0xFF94A3B8),
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: s(20)),
                                    _SwipeableCertificateCards(
                                      scale: scale,
                                      selectedIndex: _selectedTemplateIndex,
                                      onSelected: (int i) => setState(() {
                                        _selectedTemplateIndex = i;
                                      }),
                                    ),
                                    SizedBox(height: s(24)),
                                    Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: s(16),
                                      ),
                                      child: Row(
                                        children: <Widget>[
                                          Expanded(
                                            child: _MiniInfoCard(
                                              scale: scale,
                                              label: 'INDUSTRY',
                                              value: industryLabel,
                                              icon: SvgPicture.asset(
                                                'assets/icons/figma/checks_industry_building.svg',
                                                width: s(14),
                                                height: s(12),
                                              ),
                                            ),
                                          ),
                                          SizedBox(width: s(12)),
                                          Expanded(
                                            child: _MiniInfoCard(
                                              scale: scale,
                                              label: 'IDENTITY TYPE',
                                              value: identityTypeLabel,
                                              icon: SvgPicture.asset(
                                                'assets/icons/figma/new_batch_human.svg',
                                                width: s(14),
                                                height: s(12),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(height: s(16)),
                                    Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: s(16),
                                      ),
                                      child: _ComplianceCard(scale: scale),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: 0,
                              child: _BottomNav(
                                scale: scale,
                                child: SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: () => _onContinue(context),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.brandBlue,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      padding: EdgeInsets.symmetric(
                                        vertical: s(16),
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          s(16),
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
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

class _StepProgress extends StatelessWidget {
  const _StepProgress({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    double s(double v) => v * scale;

    return Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            Padding(
              padding: EdgeInsets.only(left: s(4)),
              child: Text(
                'STEP 5 OF 6',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: s(10),
                  fontWeight: FontWeight.w600,
                  height: 15 / 10,
                  letterSpacing: 0.8,
                  color: const Color(0xFF94A3B8),
                ),
              ),
            ),
            const Spacer(),
            Text(
              '90%',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: s(10),
                fontWeight: FontWeight.w600,
                height: 15 / 10,
                letterSpacing: 0.2,
                color: const Color(0xFF2563EB),
              ),
            ),
          ],
        ),
        SizedBox(height: s(8)),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: SizedBox(
            height: s(4),
            child: Stack(
              children: <Widget>[
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: s(333),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SwipeableCertificateCards extends StatelessWidget {
  const _SwipeableCertificateCards({
    required this.scale,
    required this.selectedIndex,
    required this.onSelected,
  });

  final double scale;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  static const List<({String asset, double aspectRatio})> _images =
      <({String asset, double aspectRatio})>[
        (asset: 'assets/images/driver.png', aspectRatio: 1054 / 1492),
        (
          asset: 'assets/images/certificate_preview_sample.png',
          aspectRatio: 866 / 1230,
        ),
        (asset: 'assets/images/warehouse.png', aspectRatio: 1054 / 1492),
      ];

  @override
  Widget build(BuildContext context) {
    double s(double v) => v * scale;

    final double h = s(220);
    final double sidePadding = s(16);
    final double gap = s(12);
    final double radius = s(14);

    return SizedBox(
      height: h,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: DecoratedBox(
          // Prevent underlying background from peeking through while swiping.
          decoration: const BoxDecoration(color: Colors.white),
          child: Row(
            children: <Widget>[
              SizedBox(width: sidePadding),
              ...List<Widget>.generate(_images.length, (int index) {
                final ({String asset, double aspectRatio}) item = _images[index];
                final bool isSelected = index == selectedIndex;
                return Padding(
                  padding: EdgeInsets.only(
                    right: index == _images.length - 1 ? sidePadding : gap,
                  ),
                  child: GestureDetector(
                    onTap: () => onSelected(index),
                    child: SizedBox(
                      height: h,
                      child: AspectRatio(
                        aspectRatio: item.aspectRatio,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          curve: Curves.easeOut,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(radius),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.brandBlue
                                  : const Color(0xFFE2E8F0),
                              width: isSelected ? s(2) : s(1),
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(radius),
                            child: Stack(
                              fit: StackFit.expand,
                              children: <Widget>[
                                Image.asset(item.asset, fit: BoxFit.cover),
                                if (isSelected)
                                  Positioned(
                                    top: s(10),
                                    right: s(10),
                                    child: Container(
                                      width: s(24),
                                      height: s(24),
                                      decoration: const BoxDecoration(
                                        color: AppColors.brandBlue,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Icon(
                                          Icons.check,
                                          size: s(16),
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniInfoCard extends StatelessWidget {
  const _MiniInfoCard({
    required this.scale,
    required this.label,
    required this.value,
    required this.icon,
  });

  final double scale;
  final String label;
  final String value;
  final Widget icon;

  @override
  Widget build(BuildContext context) {
    double s(double v) => v * scale;

    return Container(
      height: s(72),
      padding: EdgeInsets.all(s(16)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(s(12)),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 1,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: s(10),
              fontWeight: FontWeight.w600,
              height: 15 / 10,
              letterSpacing: -0.25,
              color: const Color(0xFF323232),
            ),
          ),
          const Spacer(),
          Row(
            children: <Widget>[
              icon,
              SizedBox(width: s(8)),
              Text(
                value,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: s(14),
                  fontWeight: FontWeight.w600,
                  height: 21 / 14,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ComplianceCard extends StatelessWidget {
  const _ComplianceCard({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    double s(double v) => v * scale;

    return Container(
      padding: EdgeInsets.all(s(16)),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(s(12)),
        border: Border.all(color: const Color(0xCCE5E7EB), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: EdgeInsets.only(top: s(2)),
            child: SvgPicture.asset(
              'assets/icons/figma/permissions_icon_info.svg',
              width: s(16),
              height: s(16),
            ),
          ),
          SizedBox(width: s(8)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  'Security Standards Compliance',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: s(10),
                    fontWeight: FontWeight.w600,
                    height: 15 / 10,
                    color: const Color(0xFF323232),
                  ),
                ),
                SizedBox(height: s(4)),
                Text(
                  'Secured via biometric binding and government-grade\nAES-256 encryption. Supports ISO/IEC 18013-5 mobile ID\nstandards.',
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: s(11),
                    fontWeight: FontWeight.w400,
                    height: 17.88 / 11,
                    letterSpacing: 0.0215,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
        ],
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

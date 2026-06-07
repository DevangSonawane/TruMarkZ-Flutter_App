import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/router/app_router.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../orgs/verification_flow/presentation/pages/flow_step_progress.dart';

class IndividualCertificatePreviewPage extends StatefulWidget {
  const IndividualCertificatePreviewPage({super.key});

  @override
  State<IndividualCertificatePreviewPage> createState() =>
      _IndividualCertificatePreviewPageState();
}

class _IndividualCertificatePreviewPageState
    extends State<IndividualCertificatePreviewPage> {
  static const double _referenceWidth = 402;
  static const Color _panelBg = Color(0xFFF7F9FC);

  int _selectedTemplateIndex = 0;

  void _continue(BuildContext context) {
    final Map<String, String> qp = GoRouterState.of(context).uri.queryParameters;
    final Uri uri = Uri(
      path: AppRouter.individualVerificationCostBreakdownPath,
      queryParameters: <String, String>{
        'flow': 'individual',
        for (final MapEntry<String, String> entry in qp.entries)
          if (entry.value.trim().isNotEmpty) entry.key: entry.value.trim(),
      },
    );
    context.push(uri.toString());
  }

  @override
  Widget build(BuildContext context) {
    final String industryLabel =
        (GoRouterState.of(context).uri.queryParameters['industry_label'] ?? '')
            .trim();

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
                        child: Column(
                          children: <Widget>[
                            Expanded(
                              child: SingleChildScrollView(
                                padding: EdgeInsets.fromLTRB(
                                  s(16),
                                  s(32),
                                  s(16),
                                  s(24) + s(85.728),
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: <Widget>[
                                    Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: s(16),
                                      ),
                                      child: FlowStepProgress(
                                        scale: scale,
                                        stepLabel: 'STEP 4 OF 5',
                                        progressLabel: '80%',
                                        fillFactor: 0.8,
                                      ),
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
                                        'Select a secure visual template for the verified individual credential.',
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
                                    _TemplateCarousel(
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
                                      child: _MiniInfoCard(
                                        scale: scale,
                                        label: 'INDUSTRY',
                                        value: industryLabel.isEmpty
                                            ? 'Individual'
                                            : industryLabel,
                                        icon: SvgPicture.asset(
                                          'assets/icons/figma/checks_industry_building.svg',
                                          width: s(14),
                                          height: s(12),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            _BottomNav(
                              scale: scale,
                              child: SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () => _continue(context),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.brandBlue,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    padding: EdgeInsets.symmetric(
                                      vertical: s(16),
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(s(16)),
                                    ),
                                  ),
                                  child: Text(
                                    'Continue',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: s(16),
                                      fontWeight: FontWeight.w700,
                                      height: 24 / 16,
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

class _TemplateCarousel extends StatelessWidget {
  const _TemplateCarousel({
    required this.scale,
    required this.selectedIndex,
    required this.onSelected,
  });

  final double scale;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    double s(double v) => v * scale;
    return SizedBox(
      height: s(300),
      child: PageView.builder(
        itemCount: 3,
        controller: PageController(viewportFraction: 0.86),
        itemBuilder: (BuildContext context, int index) {
          final bool selected = index == selectedIndex;
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: s(6)),
            child: GestureDetector(
              onTap: () => onSelected(index),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(s(20)),
                  border: Border.all(
                    color: selected ? AppColors.brandBlue : const Color(0xFFE5E7EB),
                    width: selected ? s(2) : s(1),
                  ),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: <Color>[Color(0xFFF8FBFF), Colors.white],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(
                        Icons.badge_rounded,
                        size: s(64),
                        color: AppColors.brandBlue,
                      ),
                      SizedBox(height: s(12)),
                      Text(
                        'Template ${index + 1}',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: s(18),
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      SizedBox(height: s(6)),
                      Text(
                        'Individual verified credential',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: s(12),
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
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
      padding: EdgeInsets.all(s(14)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(s(16)),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: <Widget>[
          icon,
          SizedBox(width: s(10)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: s(10),
                    fontWeight: FontWeight.w700,
                    letterSpacing: s(0.8),
                    color: const Color(0xFF94A3B8),
                  ),
                ),
                SizedBox(height: s(3)),
                Text(
                  value,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: s(13),
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
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
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(s(16), s(14), s(16), s(14)),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFF1F5F9)),
        ),
      ),
      child: child,
    );
  }
}

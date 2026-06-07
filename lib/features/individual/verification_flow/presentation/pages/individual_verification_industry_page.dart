import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/router/app_router.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../orgs/verification_flow/presentation/pages/flow_step_progress.dart';

class IndividualVerificationIndustryPage extends StatefulWidget {
  const IndividualVerificationIndustryPage({super.key});

  @override
  State<IndividualVerificationIndustryPage> createState() =>
      _IndividualVerificationIndustryPageState();
}

class _IndividualVerificationIndustryPageState
    extends State<IndividualVerificationIndustryPage> {
  static const double _referenceWidth = 402;
  static const Color _panelBg = Color(0xFFF7F9FC);

  static const List<_IndustryOption> _industries = <_IndustryOption>[
    _IndustryOption(
      id: 'education',
      title: 'Education',
      subtitle: 'Students, trainees and academic records',
      icon: Icons.school_rounded,
    ),
    _IndustryOption(
      id: 'employment',
      title: 'Employment',
      subtitle: 'Workers, staff and professional records',
      icon: Icons.work_history_rounded,
    ),
    _IndustryOption(
      id: 'finance',
      title: 'Finance',
      subtitle: 'Loan, KYC and financial verification',
      icon: Icons.account_balance_rounded,
    ),
    _IndustryOption(
      id: 'healthcare',
      title: 'Healthcare',
      subtitle: 'Medical professionals and credentials',
      icon: Icons.local_hospital_rounded,
    ),
    _IndustryOption(
      id: 'transport',
      title: 'Transport',
      subtitle: 'Drivers, fleet and license checks',
      icon: Icons.local_shipping_rounded,
    ),
    _IndustryOption(
      id: 'others',
      title: 'Others',
      subtitle: 'Any custom individual verification need',
      icon: Icons.more_horiz_rounded,
    ),
  ];

  final Set<String> _selectedIndustryIds = <String>{'education'};

  void _goBack(BuildContext context) {
    final GoRouter router = GoRouter.of(context);
    if (router.canPop()) {
      context.pop();
    } else {
      context.go(AppRouter.individualIdentityPath);
    }
  }

  void _continue(BuildContext context) {
    final List<_IndustryOption> selected = _industries
        .where((_IndustryOption e) => _selectedIndustryIds.contains(e.id))
        .toList();
    if (selected.isEmpty) return;
    final String selectedIds = selected.map((e) => e.id).join(',');
    final String selectedLabels = selected.map((e) => e.title).join(', ');
    final Uri uri = Uri(
      path: AppRouter.individualVerificationChecksPath,
      queryParameters: <String, String>{
        'flow': 'individual',
        'industry': selectedIds,
        'industry_label': selectedLabels,
        'stage': 'checks',
      },
    );
    context.push(uri.toString());
  }

  @override
  Widget build(BuildContext context) {
    final double safeBottom = MediaQuery.viewPaddingOf(context).bottom;
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
                      padding: EdgeInsets.fromLTRB(s(16), s(8), s(16), 0),
                      child: Row(
                        children: <Widget>[
                          InkResponse(
                            onTap: () => _goBack(context),
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
                            'Create Verification',
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
                    SizedBox(height: s(24)),
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
                                  s(24),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    FlowStepProgress(
                                      scale: scale,
                                      stepLabel: 'STEP 1 OF 5',
                                      progressLabel: '20%',
                                      fillFactor: 0.2,
                                    ),
                                    SizedBox(height: s(24)),
                                    Text(
                                      'Select Industry',
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: s(24),
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: s(1.18),
                                        height: 17.7507286 / 24,
                                        color: const Color(0xFF323232),
                                      ),
                                    ),
                                    SizedBox(height: s(12)),
                                    Text(
                                      'Choose the industry that best matches the individual verification you want to create.',
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: s(12),
                                        fontWeight: FontWeight.w500,
                                        letterSpacing: s(1.18),
                                        height: 17.7507286 / 12,
                                        color: const Color(0xFF94A3B8),
                                      ),
                                    ),
                                    SizedBox(height: s(24)),
                                    for (int i = 0; i < _industries.length; i++) ...<Widget>[
                                      _IndustryCard(
                                        scale: scale,
                                        option: _industries[i],
                                        selected: _selectedIndustryIds
                                            .contains(_industries[i].id),
                                        onTap: () => setState(() {
                                          if (_selectedIndustryIds.contains(
                                            _industries[i].id,
                                          )) {
                                            _selectedIndustryIds.remove(
                                              _industries[i].id,
                                            );
                                          } else {
                                            _selectedIndustryIds.add(
                                              _industries[i].id,
                                            );
                                          }
                                        }),
                                      ),
                                      if (i != _industries.length - 1)
                                        SizedBox(height: s(14)),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                            _BottomNav(
                              scale: scale,
                              bottomInset: safeBottom,
                              child: _ContinueButton(
                                scale: scale,
                                enabled: _selectedIndustryIds.isNotEmpty,
                                onTap: () => _continue(context),
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

class _IndustryOption {
  const _IndustryOption({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
}

class _IndustryCard extends StatelessWidget {
  const _IndustryCard({
    required this.scale,
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final double scale;
  final _IndustryOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    double s(double v) => v * scale;
    final Color border = selected
        ? AppColors.brandBlue
        : const Color(0xFFE5E7EB);
    final Color bg = selected ? const Color(0xFFF0F7FF) : Colors.white;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(s(16)),
        child: Container(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(s(16)),
            border: Border.all(color: border, width: selected ? s(2) : s(1)),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: EdgeInsets.all(s(16)),
          child: Row(
            children: <Widget>[
              Container(
                width: s(44),
                height: s(44),
                decoration: BoxDecoration(
                  color: AppColors.brandBlue.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(s(14)),
                ),
                alignment: Alignment.center,
                child: Icon(option.icon, color: AppColors.brandBlue, size: s(22)),
              ),
              SizedBox(width: s(14)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      option.title,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: s(14),
                        fontWeight: FontWeight.w700,
                        height: 20 / 14,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    SizedBox(height: s(3)),
                    Text(
                      option.subtitle,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: s(11),
                        fontWeight: FontWeight.w500,
                        height: 16 / 11,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                selected ? Icons.check_circle_rounded : Icons.chevron_right_rounded,
              color: selected ? AppColors.brandBlue : const Color(0xFFCBD5E1),
              size: s(24),
            ),
          ],
          ),
        ),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({
    required this.scale,
    required this.bottomInset,
    required this.child,
  });

  final double scale;
  final double bottomInset;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    double s(double v) => v * scale;
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: s(12.864), sigmaY: s(12.864)),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(
            s(13.604),
            s(12.864),
            s(13.668),
            s(12.864) + bottomInset,
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

class _ContinueButton extends StatelessWidget {
  const _ContinueButton({
    required this.scale,
    required this.enabled,
    required this.onTap,
  });

  final double scale;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    double s(double v) => v * scale;
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 150),
      opacity: enabled ? 1 : 0.45,
      child: SizedBox(
        height: s(60),
        width: double.infinity,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.brandBlue,
            borderRadius: BorderRadius.circular(s(16)),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(s(16)),
              onTap: enabled ? onTap : null,
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
        ),
      ),
    );
  }
}

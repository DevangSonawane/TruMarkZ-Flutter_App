import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/router/app_router.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../orgs/verification_flow/presentation/pages/flow_step_progress.dart';
import '../../../../orgs/verification_flow/presentation/pages/human_verification_checks_catalog.dart';
import 'individual_industry_label_utils.dart';

class IndividualVerificationChecksPage extends StatefulWidget {
  const IndividualVerificationChecksPage({super.key});

  @override
  State<IndividualVerificationChecksPage> createState() =>
      _IndividualVerificationChecksPageState();
}

class _IndividualVerificationChecksPageState
    extends State<IndividualVerificationChecksPage> {
  static const double _referenceWidth = 402;
  static const Color _panelBg = Color(0xFFF7F9FC);

  final Set<String> _selected = <String>{};

  String _industryLabel(BuildContext context) {
    final Map<String, String> qp = GoRouterState.of(context).uri.queryParameters;
    final String label = (qp['industry_label'] ?? '').trim();
    if (label.isNotEmpty) {
      return summarizeIndividualIndustryLabel(
        label,
        fallback: 'Industry',
      );
    }
    final String raw = (qp['industry'] ?? '').trim();
    return summarizeIndividualIndustryLabel(raw, fallback: 'Industry');
  }

  void _continue(BuildContext context) {
    final List<String> ids = _selected.toList()..sort();
    final Uri uri = Uri(
      path: AppRouter.individualVerificationUploadPath,
      queryParameters: <String, String>{
        'flow': 'individual',
        'industry': GoRouterState.of(context).uri.queryParameters['industry'] ??
            '',
        'industry_label':
            GoRouterState.of(context).uri.queryParameters['industry_label'] ??
            '',
        if (ids.isNotEmpty) 'checks': ids.join(','),
      },
    );
    context.push(uri.toString());
  }

  @override
  Widget build(BuildContext context) {
    final String industryLabel = _industryLabel(context);
    final List<HumanVerificationCheckDefinition> items =
        HumanVerificationChecksCatalog.items;

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
                            'Verification Checks',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: s(21),
                              fontWeight: FontWeight.w600,
                              height: 19.5 / 21,
                              color: Colors.white,
                            ),
                          ),
                          const Spacer(),
                          _IndustryPill(label: industryLabel, scale: scale),
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
                                  s(24),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    FlowStepProgress(
                                      scale: scale,
                                      stepLabel: 'STEP 2 OF 5',
                                      progressLabel: '40%',
                                      fillFactor: 0.4,
                                    ),
                                    SizedBox(height: s(24)),
                                    Text(
                                      'Select Verification Checks',
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: s(24),
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: s(1.18),
                                        height: 22.6 / 24,
                                        color: const Color(0xFF3A3A3A),
                                      ),
                                    ),
                                    SizedBox(height: s(12)),
                                    Text(
                                      'Choose the checks that should be included in this individual verification flow.',
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: s(12),
                                        fontWeight: FontWeight.w500,
                                        letterSpacing: s(1.18),
                                        height: 17.75 / 12,
                                        color: const Color(0xFF94A3B8),
                                      ),
                                    ),
                                    SizedBox(height: s(24)),
                                    for (int i = 0; i < items.length; i++) ...<Widget>[
                                      _CheckTile(
                                        scale: scale,
                                        item: items[i],
                                        selected: _selected.contains(items[i].id),
                                        onTap: () {
                                          setState(() {
                                            if (_selected.contains(items[i].id)) {
                                              _selected.remove(items[i].id);
                                            } else {
                                              _selected.add(items[i].id);
                                            }
                                          });
                                        },
                                      ),
                                      if (i != items.length - 1)
                                        SizedBox(height: s(14)),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                            _BottomNav(
                              scale: scale,
                              child: _ContinueButton(
                                scale: scale,
                                enabled: _selected.isNotEmpty,
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

class _IndustryPill extends StatelessWidget {
  const _IndustryPill({required this.label, required this.scale});

  final String label;
  final double scale;

  @override
  Widget build(BuildContext context) {
    double s(double v) => v * scale;
    return Container(
      height: s(29),
      padding: EdgeInsets.symmetric(horizontal: s(12), vertical: s(6)),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F7FF),
        borderRadius: BorderRadius.circular(s(10)),
        border: Border.all(color: const Color(0xFFE0EFFE)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SvgPicture.asset(
            'assets/icons/figma/checks_industry_building.svg',
            width: s(12),
            height: s(10),
            colorFilter: const ColorFilter.mode(
              AppColors.brandBlue,
              BlendMode.srcIn,
            ),
          ),
          SizedBox(width: s(8)),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: s(11),
              fontWeight: FontWeight.w600,
              letterSpacing: s(0.0644531),
              height: 16.5 / 11,
              color: AppColors.brandBlue,
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckTile extends StatelessWidget {
  const _CheckTile({
    required this.scale,
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final double scale;
  final HumanVerificationCheckDefinition item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    double s(double v) => v * scale;
    final Color border = selected ? AppColors.brandBlue : const Color(0xFFF1F5F9);
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
                child: Icon(item.icon, color: AppColors.brandBlue, size: s(22)),
              ),
              SizedBox(width: s(14)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      item.title,
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
                      item.subtitle,
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
    required this.child,
  });

  final double scale;
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

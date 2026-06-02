import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/app_colors.dart';
import 'verification_flow_action.dart';

class PerUnitCostBreakdownPage extends StatefulWidget {
  const PerUnitCostBreakdownPage({super.key});

  @override
  State<PerUnitCostBreakdownPage> createState() =>
      _PerUnitCostBreakdownPageState();
}

class _PerUnitCostBreakdownPageState extends State<PerUnitCostBreakdownPage> {
  static const double _referenceWidth = 402;
  static const Color _panelBg = Color(0xFFF7F9FC);
  static const Color _panelText = Color(0xFF3A3A3A);

  bool _agreed = false;
  bool _isSubmitting = false;

  static const Map<String, _CheckPricing> _pricing = <String, _CheckPricing>{
    'identity': _CheckPricing('Identity Verification', 120),
    'address': _CheckPricing('Address History', 240),
    'criminal': _CheckPricing('Criminal Record Search', 185),
    'education': _CheckPricing('Education Verification', 300),
    'employment': _CheckPricing('Employment History', 450),
  };

  static const Map<String, _CheckPricing> _productPricing =
      <String, _CheckPricing>{
    'authenticity': _CheckPricing('Authenticity Check', 140),
    'serial': _CheckPricing('Serial Number Match', 180),
    'model': _CheckPricing('Model Verification', 120),
    'compliance': _CheckPricing('Compliance Check', 220),
    'warranty': _CheckPricing('Warranty Eligibility', 260),
    'warranty_registration':
        _CheckPricing('Warranty Registration', 140),
    'purchase_proof': _CheckPricing('Proof of Purchase', 160),
    'activation': _CheckPricing('Activation Status', 120),
    'claim': _CheckPricing('Claim Eligibility', 220),
  };

  List<String> _selectedChecks(BuildContext context) {
    final Map<String, String> qp = GoRouterState.of(
      context,
    ).uri.queryParameters;
    final String raw = (qp['checks'] ?? '').trim();
    if (raw.isEmpty) return const <String>[];
    final List<String> ids = raw
        .split(',')
        .map((String e) => e.trim())
        .where((String e) => e.isNotEmpty)
        .toList();
    ids.sort();
    return ids;
  }

  int _totalCostInr(Iterable<String> ids) {
    int total = 0;
    final bool isProductFlow = _isProductFlow();
    final Map<String, _CheckPricing> pricing = isProductFlow
        ? _productPricing
        : _pricing;
    for (final String id in ids) {
      total += pricing[id]?.costInr ?? 0;
    }
    return total;
  }

  bool _isProductFlow() {
    return (GoRouterState.of(context).uri.queryParameters['flow'] ?? '')
            .trim()
            .toLowerCase() ==
        'product';
  }

  Future<void> _confirmAndSubmit(
    VerificationFlowConfirmAction? action,
  ) async {
    if (_isSubmitting) return;
    if (!_agreed) return;

    setState(() => _isSubmitting = true);
    try {
      if (action != null) {
        await action();
      } else if (mounted) {
        context.pop(true);
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<String> ids = _selectedChecks(context);
    final int total = _totalCostInr(ids);
    final bool isProductFlow = _isProductFlow();
    final Map<String, _CheckPricing> pricing = isProductFlow
        ? _productPricing
        : _pricing;
    final Object? extra = GoRouterState.of(context).extra;
    final VerificationFlowConfirmAction? action =
        extra is VerificationFlowConfirmAction ? extra : null;
    final String stepText = isProductFlow ? 'STEP 4 OF 4' : 'STEP 4 OF 6';

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
                            'Costing',
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
                    SizedBox(height: s(18)),
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
                                  s(140),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    _ProductStyleStepper(
                                      scale: scale,
                                      stepLabel: stepText,
                                      progressLabel: '100%',
                                      progress: 1,
                                    ),
                                    SizedBox(height: s(24)),
                                    Text(
                                      'Per-unit Cost Breakdown',
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: s(24),
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: s(1.1),
                                        height: 22.6 / 24,
                                        color: _panelText,
                                      ),
                                    ),
                                    SizedBox(height: s(12)),
                                    Text(
                                      'Determine how verification data will be accessed and who\ncan view the finalized reports.',
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
                                    _CostSummaryCard(
                                      scale: scale,
                                      rows: <_CostRow>[
                                        for (final String id in ids)
                                          _CostRow(
                                            title: pricing[id]?.title ?? id,
                                            valueInr: pricing[id]?.costInr ?? 0,
                                          ),
                                      ],
                                      totalInr: total,
                                      checksCount: ids.length,
                                    ),
                                    SizedBox(height: s(18)),
                                    _AgreementTile(
                                      scale: scale,
                                      agreed: _agreed,
                                      onToggle: () =>
                                          setState(() => _agreed = !_agreed),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            _BottomNav(
                              scale: scale,
                              child: _ConfirmButton(
                                scale: scale,
                                enabled:
                                    _agreed &&
                                    ids.isNotEmpty &&
                                    !_isSubmitting,
                                isLoading: _isSubmitting,
                                onTap: () => _confirmAndSubmit(action),
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

class _CostRow {
  const _CostRow({required this.title, required this.valueInr});

  final String title;
  final int valueInr;
}

class _ProductStyleStepper extends StatelessWidget {
  const _ProductStyleStepper({
    required this.scale,
    required this.stepLabel,
    required this.progressLabel,
    required this.progress,
  });

  final double scale;
  final String stepLabel;
  final String progressLabel;
  final double progress;

  @override
  Widget build(BuildContext context) {
    double s(double v) => v * scale;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: s(14), vertical: s(12)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(s(16)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.brandBlue.withAlpha(14),
            blurRadius: s(14),
            offset: Offset(0, s(8)),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SizedBox(
            height: s(8),
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints c) {
                final double width = c.maxWidth;
                return Stack(
                  children: <Widget>[
                    Container(
                      width: width,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(s(99)),
                      ),
                    ),
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: progress.clamp(0, 1)),
                      duration: const Duration(milliseconds: 260),
                      curve: Curves.easeOutCubic,
                      builder: (BuildContext context, double t, Widget? child) {
                        return Container(
                          width: width * t,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: <Color>[
                                AppColors.brandBlue,
                                AppColors.deepNavy,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(s(99)),
                          ),
                        );
                      },
                    ),
                  ],
                );
              },
            ),
          ),
          SizedBox(height: s(10)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                stepLabel,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: s(10),
                  fontWeight: FontWeight.w700,
                  letterSpacing: s(1),
                  height: 15 / 10,
                  color: const Color(0xFF94A3B8),
                ),
              ),
              Text(
                progressLabel,
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
        ],
      ),
    );
  }
}

class _CostSummaryCard extends StatelessWidget {
  const _CostSummaryCard({
    required this.scale,
    required this.rows,
    required this.totalInr,
    required this.checksCount,
  });

  final double scale;
  final List<_CostRow> rows;
  final int totalInr;
  final int checksCount;

  @override
  Widget build(BuildContext context) {
    double s(double v) => v * scale;

    final List<_CostRow> safeRows = rows.isEmpty
        ? const <_CostRow>[
            _CostRow(title: 'Identity Verification', valueInr: 0),
          ]
        : rows;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(s(16), s(16), s(16), s(16)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(s(20)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withAlpha(18),
            blurRadius: s(18),
            offset: Offset(0, s(10)),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: s(40),
                height: s(40),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF3FF),
                  borderRadius: BorderRadius.circular(s(12)),
                ),
                alignment: Alignment.center,
                child: SvgPicture.asset(
                  'assets/icons/figma/per_unit_cost_summary_icon.svg',
                  width: s(16),
                  height: s(18),
                  colorFilter: const ColorFilter.mode(
                    AppColors.brandBlue,
                    BlendMode.srcIn,
                  ),
                ),
              ),
              SizedBox(width: s(12)),
              Text(
                'Cost Summary',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: s(16),
                  fontWeight: FontWeight.w700,
                  height: 24 / 16,
                  color: const Color(0xFF111827),
                ),
              ),
            ],
          ),
          SizedBox(height: s(16)),
          for (int i = 0; i < safeRows.length; i++) ...<Widget>[
            _SummaryRow(scale: scale, row: safeRows[i]),
            if (i != safeRows.length - 1) ...<Widget>[
              SizedBox(height: s(12)),
              Divider(height: s(1), color: const Color(0xFFF1F5F9)),
              SizedBox(height: s(12)),
            ],
          ],
          SizedBox(height: s(16)),
          Divider(height: s(1), color: const Color(0xFFF1F5F9)),
          SizedBox(height: s(14)),
          Text(
            'TOTAL PER UNIT',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: s(10),
              fontWeight: FontWeight.w700,
              letterSpacing: s(1),
              height: 15 / 10,
              color: const Color(0xFF94A3B8),
            ),
          ),
          SizedBox(height: s(10)),
          Row(
            children: <Widget>[
              Text(
                '₹$totalInr',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: s(28),
                  fontWeight: FontWeight.w800,
                  height: 32 / 28,
                  color: AppColors.brandBlue,
                ),
              ),
              const Spacer(),
              Container(
                padding: EdgeInsets.fromLTRB(s(12), s(6), s(12), s(6)),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF3FF),
                  borderRadius: BorderRadius.circular(s(999)),
                ),
                child: Text(
                  '$checksCount Checks',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: s(12),
                    fontWeight: FontWeight.w600,
                    height: 16 / 12,
                    color: AppColors.brandBlue,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.scale, required this.row});

  final double scale;
  final _CostRow row;

  @override
  Widget build(BuildContext context) {
    double s(double v) => v * scale;

    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            row.title,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: s(14),
              fontWeight: FontWeight.w500,
              height: 20 / 14,
              color: const Color(0xFF334155),
            ),
          ),
        ),
        Text(
          '₹${row.valueInr}',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: s(16),
            fontWeight: FontWeight.w700,
            height: 24 / 16,
            color: const Color(0xFF111827),
          ),
        ),
      ],
    );
  }
}

class _CheckPricing {
  const _CheckPricing(this.title, this.costInr);

  final String title;
  final int costInr;
}

class _AgreementTile extends StatelessWidget {
  const _AgreementTile({
    required this.scale,
    required this.agreed,
    required this.onToggle,
  });

  final double scale;
  final bool agreed;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    double s(double v) => v * scale;

    return InkWell(
      onTap: onToggle,
      borderRadius: BorderRadius.circular(s(16)),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(s(14), s(14), s(14), s(14)),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F8FF),
          borderRadius: BorderRadius.circular(s(16)),
          border: Border.all(color: const Color(0xFFD7E7FF), width: s(1)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              width: s(22),
              height: s(22),
              decoration: BoxDecoration(
                color: agreed ? AppColors.brandBlue : Colors.transparent,
                borderRadius: BorderRadius.circular(s(6)),
                border: Border.all(
                  color: agreed ? AppColors.brandBlue : const Color(0xFFCBD5E1),
                  width: s(1.6),
                ),
              ),
              alignment: Alignment.center,
              child: agreed
                  ? Icon(Icons.check_rounded, size: s(16), color: Colors.white)
                  : null,
            ),
            SizedBox(width: s(12)),
            Expanded(
              child: Text(
                'I agree to the per-unit cost breakdown and\nthe terms of service for these verification\nchecks.',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: s(12),
                  fontWeight: FontWeight.w500,
                  height: 18 / 12,
                  color: const Color(0xFF334155),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConfirmButton extends StatelessWidget {
  const _ConfirmButton({
    required this.scale,
    required this.enabled,
    required this.isLoading,
    required this.onTap,
  });

  final double scale;
  final bool enabled;
  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    double s(double v) => v * scale;

    return SizedBox(
      width: double.infinity,
        child: ElevatedButton(
          onPressed: enabled ? onTap : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.brandBlue,
          disabledBackgroundColor: AppColors.brandBlue.withAlpha(90),
          foregroundColor: Colors.white,
          disabledForegroundColor: Colors.white.withAlpha(180),
          elevation: 0,
          padding: EdgeInsets.symmetric(vertical: s(18)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(s(20)),
          ),
        ),
          child: isLoading
              ? SizedBox(
                  width: s(20),
                  height: s(20),
                  child: CircularProgressIndicator(
                    strokeWidth: s(2),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.white,
                    ),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      'Confirm',
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

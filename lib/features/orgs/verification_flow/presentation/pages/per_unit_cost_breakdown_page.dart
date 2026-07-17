import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/models/verification_models.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../data/verification_repository.dart';
import 'human_verification_checks_catalog.dart';
import 'product_verification_checks_catalog.dart';
import 'verification_flow_action.dart';
import 'flow_step_progress.dart';

class PerUnitCostBreakdownPage extends ConsumerStatefulWidget {
  const PerUnitCostBreakdownPage({super.key});

  @override
  ConsumerState<PerUnitCostBreakdownPage> createState() =>
      _PerUnitCostBreakdownPageState();
}

class _PerUnitCostBreakdownPageState
    extends ConsumerState<PerUnitCostBreakdownPage> {
  static const double _referenceWidth = 402;
  static const Color _panelBg = Color(0xFFF7F9FC);
  static const Color _panelText = Color(0xFF3A3A3A);

  bool _agreed = false;
  bool _isSubmitting = false;

  int _userCount(BuildContext context) {
    final Map<String, String> qp = GoRouterState.of(
      context,
    ).uri.queryParameters;
    final int parsed = int.tryParse((qp['users_count'] ?? '').trim()) ?? 1;
    return parsed > 0 ? parsed : 1;
  }

  Map<String, _CheckPricing> _pricingFromTypes(
    List<VerificationTypeDefinition> types,
    List<String> ids,
    bool isProductFlow,
  ) {
    final Map<String, VerificationTypeDefinition> apiById =
        <String, VerificationTypeDefinition>{
          for (final VerificationTypeDefinition item in types) item.id: item,
        };
    final Map<String, _CheckPricing> pricing = <String, _CheckPricing>{};

    for (final String id in ids) {
      final VerificationTypeDefinition? apiItem = apiById[id];
      if (apiItem != null) {
        pricing[id] = _CheckPricing(
          apiItem.name,
          _resolvedPrice(apiItem, isProductFlow: isProductFlow),
        );
        continue;
      }

      final ProductVerificationCheckDefinition? productItem =
          ProductVerificationChecksCatalog.byId[id];
      if (productItem != null) {
        pricing[id] = _CheckPricing(
          productItem.title,
          ProductVerificationChecksCatalog.pricesInr[id] ??
              productItem.priceMinInr,
        );
        continue;
      }

      final HumanVerificationCheckDefinition? humanItem =
          HumanVerificationChecksCatalog.byId[id];
      if (humanItem != null) {
        pricing[id] = _CheckPricing(
          humanItem.title,
          HumanVerificationChecksCatalog.humanPricesInr[id] ??
              humanItem.priceMinInr,
        );
        continue;
      }

      pricing[id] = _CheckPricing(id, 0);
    }

    return pricing;
  }

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

  int _totalCostInr(Iterable<String> ids, Map<String, _CheckPricing> pricing) {
    int total = 0;
    for (final String id in ids) {
      total += pricing[id]?.costInr ?? 0;
    }
    return total;
  }

  int _lineTotalInr(int unitCostInr, int userCount) {
    return unitCostInr * userCount;
  }

  int _resolvedPrice(
    VerificationTypeDefinition item, {
    required bool isProductFlow,
  }) {
    final int? apiPrice = item.price;
    if (apiPrice != null && apiPrice > 0) return apiPrice;
    if (isProductFlow) {
      return ProductVerificationChecksCatalog.pricesInr[item.id] ?? 0;
    }
    return HumanVerificationChecksCatalog.humanPricesInr[item.id] ?? 0;
  }

  bool _isProductFlow() {
    return (GoRouterState.of(context).uri.queryParameters['flow'] ?? '')
            .trim()
            .toLowerCase() ==
        'product';
  }

  Future<void> _confirmAndSubmit(VerificationFlowConfirmAction? action) async {
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
    final Map<String, String> qp = GoRouterState.of(
      context,
    ).uri.queryParameters;
    final bool isProductFlow = _isProductFlow();
    final String industry = (qp['industry'] ?? '').trim();
    final bool isWarrantyFlow =
        isProductFlow && (qp['mode'] ?? '').trim().toLowerCase() == 'warranty';
    final List<String> ids = isWarrantyFlow
        ? const <String>[]
        : _selectedChecks(context);
    final int userCount = _userCount(context);
    final String verificationFilter = industry.isNotEmpty
        ? '${isProductFlow ? 'product' : 'human'}::$industry'
        : (isProductFlow ? 'product' : 'human');
    final AsyncValue<List<VerificationTypeDefinition>> typesAsync = ref.watch(
      verificationTypesProvider(verificationFilter),
    );
    final Map<String, _CheckPricing> pricing = _pricingFromTypes(
      typesAsync.valueOrNull ?? <VerificationTypeDefinition>[],
      ids,
      isProductFlow,
    );
    final int total = isWarrantyFlow
        ? 0
        : _totalCostInr(ids, pricing) * userCount;
    final Object? extra = GoRouterState.of(context).extra;
    final VerificationFlowConfirmAction? action =
        extra is VerificationFlowConfirmAction ? extra : null;
    final String stepText = isProductFlow
        ? (isWarrantyFlow ? 'STEP 5 OF 5' : 'STEP 6 OF 6')
        : 'STEP 5 OF 6';

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
                                    FlowStepProgress(
                                      scale: scale,
                                      stepLabel: stepText,
                                      progressLabel: isProductFlow
                                          ? '100%'
                                          : '67%',
                                      fillFactor: isProductFlow ? 1 : 0.67,
                                    ),
                                    SizedBox(height: s(24)),
                                    Text(
                                      'Total Cost Breakdown',
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
                                      isWarrantyFlow
                                          ? 'Warranty batches do not use verification checks, so the cost breakdown stays at zero and you can continue.'
                                          : 'Determine the total verification cost for all users in the Excel file.',
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
                                            unitCostInr:
                                                pricing[id]?.costInr ?? 0,
                                            totalInr: _lineTotalInr(
                                              pricing[id]?.costInr ?? 0,
                                              userCount,
                                            ),
                                          ),
                                      ],
                                      totalInr: total,
                                      checksCount: ids.length,
                                      userCount: userCount,
                                      hasWarrantyChecksDisabled: isWarrantyFlow,
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
                                    (isWarrantyFlow || ids.isNotEmpty) &&
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
  const _CostRow({
    required this.title,
    required this.unitCostInr,
    required this.totalInr,
  });

  final String title;
  final int unitCostInr;
  final int totalInr;
}

class _CostSummaryCard extends StatelessWidget {
  const _CostSummaryCard({
    required this.scale,
    required this.rows,
    required this.totalInr,
    required this.checksCount,
    required this.userCount,
    required this.hasWarrantyChecksDisabled,
  });

  final double scale;
  final List<_CostRow> rows;
  final int totalInr;
  final int checksCount;
  final int userCount;
  final bool hasWarrantyChecksDisabled;

  @override
  Widget build(BuildContext context) {
    double s(double v) => v * scale;

    final bool hasRows = rows.isNotEmpty;

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
          if (hasRows)
            for (int i = 0; i < rows.length; i++) ...<Widget>[
              _SummaryRow(scale: scale, row: rows[i], userCount: userCount),
              if (i != rows.length - 1) ...<Widget>[
                SizedBox(height: s(12)),
                Divider(height: s(1), color: const Color(0xFFF1F5F9)),
                SizedBox(height: s(12)),
              ],
            ]
          else
            Text(
              hasWarrantyChecksDisabled
                  ? 'Warranty uploads do not include verification checks.'
                  : 'No cost items selected.',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: s(13),
                fontWeight: FontWeight.w500,
                height: 18 / 13,
                color: const Color(0xFF64748B),
              ),
            ),
          SizedBox(height: s(16)),
          Divider(height: s(1), color: const Color(0xFFF1F5F9)),
          SizedBox(height: s(14)),
          Text(
            'TOTAL COST',
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  Container(
                    padding: EdgeInsets.fromLTRB(s(12), s(6), s(12), s(6)),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF3FF),
                      borderRadius: BorderRadius.circular(s(999)),
                    ),
                    child: Text(
                      hasWarrantyChecksDisabled
                          ? 'No Checks'
                          : '$checksCount Checks',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: s(12),
                        fontWeight: FontWeight.w600,
                        height: 16 / 12,
                        color: AppColors.brandBlue,
                      ),
                    ),
                  ),
                  SizedBox(height: s(8)),
                  Container(
                    padding: EdgeInsets.fromLTRB(s(12), s(6), s(12), s(6)),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(s(999)),
                    ),
                    child: Text(
                      '$userCount Users',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: s(12),
                        fontWeight: FontWeight.w600,
                        height: 16 / 12,
                        color: const Color(0xFF334155),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.scale,
    required this.row,
    required this.userCount,
  });

  final double scale;
  final _CostRow row;
  final int userCount;

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
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            Text(
              '₹${row.unitCostInr} × $userCount',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: s(11),
                fontWeight: FontWeight.w600,
                height: 16 / 11,
                color: const Color(0xFF64748B),
              ),
            ),
            SizedBox(height: s(2)),
            Text(
              '₹${row.totalInr}',
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
                'I agree to the total cost breakdown and\nthe terms of service for this flow.',
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
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
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

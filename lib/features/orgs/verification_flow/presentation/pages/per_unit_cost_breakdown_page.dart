import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/app_colors.dart';

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

  static const Map<String, _CheckPricing> _pricing = <String, _CheckPricing>{
    'identity': _CheckPricing('Identity Verification', 120),
    'address': _CheckPricing('Address History', 240),
    'criminal': _CheckPricing('Criminal Record Search', 185),
    'education': _CheckPricing('Education Verification', 300),
    'employment': _CheckPricing('Employment History', 450),
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
    for (final String id in ids) {
      total += _pricing[id]?.costInr ?? 0;
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final List<String> ids = _selectedChecks(context);
    final int total = _totalCostInr(ids);

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
                                    Row(
                                      children: <Widget>[
                                        Text(
                                          'STEP 4 OF 4',
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
                                          '100%',
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
                                        child: const DecoratedBox(
                                          decoration: BoxDecoration(
                                            color: AppColors.brandBlue,
                                          ),
                                        ),
                                      ),
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
                                            title: _pricing[id]?.title ?? id,
                                            valueInr:
                                                _pricing[id]?.costInr ?? 0,
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
                                enabled: _agreed && ids.isNotEmpty,
                                onTap: () => context.pop(true),
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
    required this.onTap,
  });

  final double scale;
  final bool enabled;
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
        child: Row(
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

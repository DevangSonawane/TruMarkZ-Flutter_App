import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/router/app_router.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../orgs/verification_flow/presentation/pages/flow_step_progress.dart';
import '../../../../orgs/verification_flow/presentation/pages/human_verification_checks_catalog.dart';

class IndividualCostBreakdownPage extends StatefulWidget {
  const IndividualCostBreakdownPage({super.key});

  @override
  State<IndividualCostBreakdownPage> createState() =>
      _IndividualCostBreakdownPageState();
}

class _IndividualCostBreakdownPageState
    extends State<IndividualCostBreakdownPage> {
  static const double _referenceWidth = 402;
  static const Color _panelBg = Color(0xFFF7F9FC);
  static const Color _panelText = Color(0xFF3A3A3A);

  bool _agreed = false;
  bool _isSubmitting = false;

  List<String> _selectedChecks(BuildContext context) {
    final Map<String, String> qp = GoRouterState.of(context).uri.queryParameters;
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
      final HumanVerificationCheckDefinition? item =
          HumanVerificationChecksCatalog.byId[id];
      if (item == null) continue;
      total += item.priceMinInr;
    }
    return total;
  }

  Future<void> _finish() async {
    if (_isSubmitting || !_agreed) return;
    setState(() => _isSubmitting = true);
    try {
      if (!mounted) return;
      context.go(AppRouter.individualIdentityPath);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<String> ids = _selectedChecks(context);
    final Map<String, String> qp = GoRouterState.of(context).uri.queryParameters;
    final String industryLabel = (qp['industry_label'] ?? '').trim();

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

            final int total = _totalCostInr(ids);

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
                                      stepLabel: 'STEP 5 OF 5',
                                      progressLabel: '100%',
                                      fillFactor: 1.0,
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
                                      'Determine the total verification cost for this individual verification request.',
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
                                            title:
                                                HumanVerificationChecksCatalog
                                                    .byId[id]
                                                    ?.title ??
                                                id,
                                            unitCostInr:
                                                HumanVerificationChecksCatalog
                                                        .byId[id]
                                                        ?.priceMinInr ??
                                                    0,
                                            totalInr:
                                                HumanVerificationChecksCatalog
                                                        .byId[id]
                                                        ?.priceMinInr ??
                                                    0,
                                          ),
                                      ],
                                      totalInr: total,
                                      checksCount: ids.length,
                                      industryLabel:
                                          industryLabel.isEmpty
                                              ? 'Individual'
                                              : industryLabel,
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
                                enabled: _agreed && ids.isNotEmpty && !_isSubmitting,
                                isLoading: _isSubmitting,
                                onTap: _finish,
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
    required this.industryLabel,
  });

  final double scale;
  final List<_CostRow> rows;
  final int totalInr;
  final int checksCount;
  final String industryLabel;

  @override
  Widget build(BuildContext context) {
    double s(double v) => v * scale;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(s(20)),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: <Widget>[
          Padding(
            padding: EdgeInsets.all(s(16)),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    industryLabel,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: s(16),
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ),
                Text(
                  '$checksCount checks',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: s(11),
                    fontWeight: FontWeight.w700,
                    color: AppColors.brandBlue,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          for (int i = 0; i < rows.length; i++) ...<Widget>[
            Padding(
              padding: EdgeInsets.all(s(16)),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      rows[i].title,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: s(14),
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF334155),
                      ),
                    ),
                  ),
                  Text(
                    '₹${rows[i].unitCostInr}',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: s(13),
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF334155),
                    ),
                  ),
                ],
              ),
            ),
            if (i != rows.length - 1)
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
          ],
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(s(16)),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFF),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    'Total',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: s(14),
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ),
                Text(
                  '₹$totalInr',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: s(16),
                    fontWeight: FontWeight.w800,
                    color: AppColors.brandBlue,
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
        padding: EdgeInsets.all(s(16)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(s(16)),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              width: s(22),
              height: s(22),
              decoration: BoxDecoration(
                color: agreed ? AppColors.brandBlue : Colors.white,
                borderRadius: BorderRadius.circular(s(6)),
                border: Border.all(color: AppColors.brandBlue),
              ),
              child: agreed
                  ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
                  : null,
            ),
            SizedBox(width: s(12)),
            Expanded(
              child: Text(
                'I agree to the total cost breakdown and\nthe terms of service for this verification request.',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: s(12),
                  fontWeight: FontWeight.w500,
                  height: 18 / 12,
                  color: const Color(0xFF475569),
                ),
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
          foregroundColor: Colors.white,
          elevation: 0,
          padding: EdgeInsets.symmetric(vertical: s(16)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(s(16)),
          ),
        ),
        child: isLoading
            ? SizedBox(
                width: s(18),
                height: s(18),
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                'Confirm & Finish',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: s(16),
                  fontWeight: FontWeight.w700,
                  height: 24 / 16,
                ),
              ),
      ),
    );
  }
}

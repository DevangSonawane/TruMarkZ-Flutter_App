import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';

class PerUnitCostBreakdownPage extends StatefulWidget {
  const PerUnitCostBreakdownPage({super.key});

  @override
  State<PerUnitCostBreakdownPage> createState() =>
      _PerUnitCostBreakdownPageState();
}

class _PerUnitCostBreakdownPageState extends State<PerUnitCostBreakdownPage> {
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
      backgroundColor: AppColors.pageBg,
      appBar: AppBar(
        backgroundColor: AppColors.pageBg,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () => context.pop(false),
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: AppColors.brandBlue,
          ),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Image.asset('assets/icons/headers_app_icon.png', height: 20),
            const SizedBox(width: AppSpacing.x2),
            Text(
              'Cost',
              style: AppTypography.heading1.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.x4,
                  AppSpacing.x3,
                  AppSpacing.x4,
                  AppSpacing.x4,
                ),
                children: <Widget>[
                  Text(
                    'Per-unit Cost Breakdown',
                    style: AppTypography.display2,
                  ),
                  const SizedBox(height: AppSpacing.x2),
                  Text(
                    'Review the per-person pricing for your selected checks before uploading.',
                    style: AppTypography.body2.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.x4),
                  if (ids.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.x4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: Text(
                        'No checks selected.',
                        style: AppTypography.body2.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.x4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.divider),
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: AppColors.brandBlue.withAlpha(18),
                            blurRadius: 18,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        children: <Widget>[
                          for (final String id in ids) ...<Widget>[
                            _BreakdownRow(
                              title: _pricing[id]?.title ?? id,
                              value: '₹${_pricing[id]?.costInr ?? 0}',
                            ),
                            const SizedBox(height: AppSpacing.x2),
                            const Divider(height: 1),
                            const SizedBox(height: AppSpacing.x2),
                          ],
                          Row(
                            children: <Widget>[
                              Text(
                                'TOTAL PER UNIT',
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.6,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '₹$total',
                                style: AppTypography.heading1.copyWith(
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: AppSpacing.x4),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.x3),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Checkbox(
                          value: _agreed,
                          onChanged: (bool? v) =>
                              setState(() => _agreed = v ?? false),
                        ),
                        const SizedBox(width: AppSpacing.x2),
                        Expanded(
                          child: Text(
                            'I agree to the per-unit cost breakdown and the terms of service for these verification checks.',
                            style: AppTypography.body2.copyWith(
                              color: AppColors.textSecondary,
                              height: 1.25,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.x4,
                  AppSpacing.x2,
                  AppSpacing.x4,
                  AppSpacing.x4,
                ),
                child: SizedBox(
                  height: 54,
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: (_agreed && ids.isNotEmpty)
                        ? () => context.pop(true)
                        : null,
                    icon: const Icon(Icons.check_rounded),
                    label: const Text('Continue'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brandBlue,
                      foregroundColor: Colors.white,
                      shape: const StadiumBorder(),
                      textStyle: AppTypography.button,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            title,
            style: AppTypography.body2.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        Text(
          value,
          style: AppTypography.body2.copyWith(
            fontWeight: FontWeight.w900,
            color: AppColors.textPrimary,
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

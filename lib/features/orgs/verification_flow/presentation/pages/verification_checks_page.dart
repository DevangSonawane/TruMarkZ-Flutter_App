import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/router/app_router.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../auth/application/auth_notifier.dart';

class VerificationChecksPage extends ConsumerStatefulWidget {
  const VerificationChecksPage({super.key});

  @override
  ConsumerState<VerificationChecksPage> createState() =>
      _VerificationChecksPageState();
}

class _VerificationChecksPageState
    extends ConsumerState<VerificationChecksPage> {
  static const double _referenceWidth = 402;
  static const Color _panelBg = Color(0xFFF7F9FC);

  String? _lastRouteSignature;
  String _industry = '';

  final List<_CheckItem> _items = const <_CheckItem>[
    _CheckItem(
      id: 'identity',
      title: 'Identity Verification',
      subtitle: 'PAN, Aadhar & Face Match',
      mode: _CheckMode.auto,
      costInr: 120,
      svgIconPath: 'assets/icons/figma/checks_icon_identity.svg',
    ),
    _CheckItem(
      id: 'address',
      title: 'Address History',
      subtitle: 'Physical site verification',
      mode: _CheckMode.manual,
      costInr: 240,
      svgIconPath: 'assets/icons/figma/checks_icon_address.svg',
    ),
    _CheckItem(
      id: 'criminal',
      title: 'Criminal Record',
      subtitle: 'Global/National database search',
      mode: _CheckMode.auto,
      costInr: 180,
      svgIconPath: 'assets/icons/figma/checks_icon_criminal.svg',
    ),
    _CheckItem(
      id: 'education',
      title: 'Education Check',
      subtitle: 'Highest qualification check',
      mode: _CheckMode.manual,
      costInr: 350,
      svgIconPath: 'assets/icons/figma/checks_icon_education.svg',
    ),
    _CheckItem(
      id: 'employment',
      title: 'Employment History',
      subtitle: 'Last 2 employers verification',
      mode: _CheckMode.manual,
      costInr: 420,
      svgIconPath: 'assets/icons/figma/checks_icon_employment.svg',
    ),
  ];

  final Set<String> _selected = <String>{'identity'};

  static const List<String> _industryOptions = <String>[
    'All',
    'Transport',
    'Healthcare',
    'Education',
    'Manufacturing',
    'Security',
    'Agriculture',
    'Consumer Goods',
    'Beauty & Cosmetics',
    'Electronics & Appliances',
    'EV & Automotive',
    'Insurance Policies',
    'Healthcare Products',
    'Industrial Equipment',
    'Agriculture Products',
    'Luxury Products',
    'Others',
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final Uri uri = GoRouterState.of(context).uri;
    final String signature = uri.query;
    if (_lastRouteSignature == signature) return;
    _lastRouteSignature = signature;

    final Map<String, String> qp = uri.queryParameters;
    final String fromRoute = (qp['industry'] ?? '').trim();
    final String fromProfile =
        (ref.read(authNotifierProvider).value?.userProfile?.industry ?? '')
            .trim();

    final String next = fromRoute.isNotEmpty
        ? fromRoute
        : _normalizeIndustry(fromProfile);

    if (next != _industry) {
      setState(() => _industry = next);
    }
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
                            'Checks',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: s(21),
                              fontWeight: FontWeight.w600,
                              height: 19.5 / 21,
                              color: Colors.white,
                            ),
                          ),
                          const Spacer(),
                          _IndustryPill(
                            scale: scale,
                            label: _industry.trim().isEmpty
                                ? 'Real Estate'
                                : _industry.trim(),
                            onTap: () async {
                              final String? picked = await _pickIndustry(
                                scale: scale,
                                current: _industry.trim(),
                              );
                              if (!mounted || picked == null) return;
                              setState(() => _industry = picked);
                            },
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
                              child: Padding(
                                padding: EdgeInsets.fromLTRB(
                                  s(16),
                                  s(32),
                                  s(16),
                                  0,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Row(
                                      children: <Widget>[
                                        Text(
                                          'STEP 2 OF 6',
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
                                          '25%',
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
                                              widthFactor: 0.25,
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
                                      'Select Verification Checks',
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
                                      'Customize your verification flow by selecting the\nnecessary checks for your candidates.',
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
                                    Expanded(
                                      child: ListView.separated(
                                        padding: EdgeInsets.only(bottom: s(16)),
                                        itemBuilder:
                                            (BuildContext context, int i) {
                                              final _CheckItem item = _items[i];
                                              final bool selected = _selected
                                                  .contains(item.id);
                                              return _CheckTile(
                                                scale: scale,
                                                item: item,
                                                selected: selected,
                                                onTap: () {
                                                  setState(() {
                                                    if (selected) {
                                                      _selected.remove(item.id);
                                                    } else {
                                                      _selected.add(item.id);
                                                    }
                                                  });
                                                },
                                              );
                                            },
                                        separatorBuilder:
                                            (BuildContext context, int i) =>
                                                SizedBox(height: s(16)),
                                        itemCount: _items.length,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            _BottomNav(
                              scale: scale,
                              child: _BottomContinue(
                                scale: scale,
                                onTap: () {
                                  final Map<String, String> qp =
                                      <String, String>{};
                                  if (_selected.isNotEmpty) {
                                    final List<String> ids = _selected.toList()
                                      ..sort();
                                    qp['checks'] = ids.join(',');
                                  }
                                  if (_industry.trim().isNotEmpty) {
                                    qp['industry'] = _industry.trim();
                                  }
                                  final Uri uri = Uri(
                                    path: AppRouter.verificationPermissionsPath,
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

  Future<String?> _pickIndustry({
    required double scale,
    required String current,
  }) async {
    double s(double v) => v * scale;
    final String selected = current.trim();

    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          insetPadding: EdgeInsets.fromLTRB(s(18), s(18), s(18), s(18)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(s(16)),
            side: BorderSide(color: const Color(0xFFE5E7EB), width: s(1)),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: s(480)),
            child: Padding(
              padding: EdgeInsets.fromLTRB(s(16), s(16), s(16), s(16)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Text(
                        'Select Industry',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: s(16),
                          fontWeight: FontWeight.w700,
                          height: 24 / 16,
                          color: const Color(0xFF111827),
                        ),
                      ),
                      const Spacer(),
                      InkResponse(
                        onTap: () => Navigator.of(context).pop(),
                        radius: s(18),
                        child: Icon(
                          Icons.close_rounded,
                          size: s(20),
                          color: const Color(0xFF9CA3AF),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: s(10)),
                  Expanded(
                    child: ListView.separated(
                      itemCount: _industryOptions.length,
                      separatorBuilder: (BuildContext context, int index) =>
                          Divider(height: s(1), color: const Color(0xFFF1F5F9)),
                      itemBuilder: (BuildContext context, int index) {
                        final String label = _industryOptions[index];
                        final bool isSelected = label == selected;
                        return InkWell(
                          onTap: () => Navigator.of(context).pop(label),
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              vertical: s(12),
                              horizontal: s(2),
                            ),
                            child: Row(
                              children: <Widget>[
                                Container(
                                  width: s(10),
                                  height: s(10),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isSelected
                                        ? AppColors.brandBlue
                                        : const Color(0xFFE5E7EB),
                                  ),
                                ),
                                SizedBox(width: s(12)),
                                Expanded(
                                  child: Text(
                                    label,
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: s(14),
                                      fontWeight: FontWeight.w600,
                                      height: 20 / 14,
                                      color: isSelected
                                          ? AppColors.brandBlue
                                          : const Color(0xFF334155),
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
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _normalizeIndustry(String raw) {
    final String v = raw.trim();
    if (v.isEmpty) return '';
    if (v.toLowerCase() == 'all') return 'All';
    if (v.toLowerCase() == 'both') return 'All';

    // Backend may return JSON array-like strings for multi-select.
    List<String> parts = <String>[];
    if (v.startsWith('[') && v.endsWith(']')) {
      final String inner = v.substring(1, v.length - 1);
      parts = inner
          .split(',')
          .map((String s) => s.replaceAll('"', '').trim())
          .where((String s) => s.isNotEmpty)
          .toList();
    } else if (v.contains(',')) {
      parts = v
          .split(',')
          .map((String s) => s.trim())
          .where((String s) => s.isNotEmpty)
          .toList();
    }

    if (parts.isNotEmpty) {
      final Set<String> normalized = parts
          .map((String e) => e.toLowerCase())
          .toSet();
      final Set<String> all = _industryOptions
          .where((String e) => e != 'All')
          .map((String e) => e.toLowerCase())
          .toSet();
      if (normalized.containsAll(all)) return 'All';
      // If not all, keep the raw string for now (picker can refine).
      return v;
    }

    return v;
  }
}

class _IndustryPill extends StatelessWidget {
  const _IndustryPill({
    required this.scale,
    required this.label,
    required this.onTap,
  });

  final double scale;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    double s(double v) => v * scale;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(s(10)),
      child: Container(
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
            SizedBox(width: s(8)),
            Container(
              width: s(1),
              height: s(12),
              color: const Color(0xFFE2E8F0),
            ),
            SizedBox(width: s(8)),
            Text(
              'EDIT',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: s(10),
                fontWeight: FontWeight.w600,
                letterSpacing: s(0.25),
                height: 15 / 10,
                color: AppColors.brandBlue,
              ),
            ),
          ],
        ),
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
  final _CheckItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    double s(double v) => v * scale;

    final Color cardBg = selected ? const Color(0xFFF0F7FF) : Colors.white;
    final Color cardBorder = selected
        ? AppColors.brandBlue
        : const Color(0xFFF1F5F9);
    final double borderWidth = selected ? s(2) : s(1);
    final BoxShadow shadow = selected
        ? const BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 2,
            offset: Offset(0, 1),
          )
        : const BoxShadow(
            color: Color(0x05000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          );

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(s(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(s(16)),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.all(s(20)),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(s(16)),
            border: Border.all(color: cardBorder, width: borderWidth),
            boxShadow: <BoxShadow>[shadow],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Container(
                width: s(48),
                height: s(48),
                decoration: BoxDecoration(
                  color: selected ? Colors.white : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(s(12)),
                  border: Border.all(
                    color: selected
                        ? const Color(0xFFE0EFFE)
                        : const Color(0xFFF1F5F9),
                  ),
                  boxShadow: selected
                      ? const <BoxShadow>[
                          BoxShadow(
                            color: Color(0x0D000000),
                            blurRadius: 2,
                            offset: Offset(0, 1),
                          ),
                        ]
                      : const <BoxShadow>[],
                ),
                alignment: Alignment.center,
                child: SvgPicture.asset(
                  item.svgIconPath,
                  width: s(22),
                  height: s(18),
                ),
              ),
              SizedBox(width: s(16)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            item.title,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: s(16),
                              fontWeight: FontWeight.w600,
                              height: 24 / 16,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        SizedBox(width: s(12)),
                        _ModePill(scale: scale, mode: item.mode),
                      ],
                    ),
                    SizedBox(height: s(4)),
                    Text(
                      item.subtitle,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: s(12),
                        fontWeight: FontWeight.w400,
                        height: 15 / 12,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: s(16)),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  _SelectIndicator(scale: scale, selected: selected),
                  SizedBox(height: s(12)),
                  Text(
                    '₹${item.costInr}',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: s(14),
                      fontWeight: FontWeight.w700,
                      letterSpacing: s(-0.1230469),
                      height: 21 / 14,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModePill extends StatelessWidget {
  const _ModePill({required this.scale, required this.mode});

  final double scale;
  final _CheckMode mode;

  @override
  Widget build(BuildContext context) {
    double s(double v) => v * scale;

    final bool auto = mode == _CheckMode.auto;
    final Color bg = auto ? AppColors.brandBlue : const Color(0xFFEFF3F7);
    final Color fg = auto ? Colors.white : const Color(0xFF64748B);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: s(6), vertical: s(2)),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(s(4)),
      ),
      child: Text(
        auto ? 'AUTO' : 'MANUAL',
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: s(9),
          fontWeight: FontWeight.w700,
          letterSpacing: s(0.45),
          height: 13.5 / 9,
          color: fg,
        ),
      ),
    );
  }
}

class _SelectIndicator extends StatelessWidget {
  const _SelectIndicator({required this.scale, required this.selected});

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
        ),
        alignment: Alignment.center,
        child: SvgPicture.asset(
          'assets/icons/figma/checks_checkmark.svg',
          width: s(9),
          height: s(7),
        ),
      );
    }

    return Container(
      width: s(24),
      height: s(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(s(9999)),
        border: Border.all(color: const Color(0xFFE2E8F0), width: s(2)),
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

enum _CheckMode { auto, manual }

class _CheckItem {
  const _CheckItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.mode,
    required this.costInr,
    required this.svgIconPath,
  });

  final String id;
  final String title;
  final String subtitle;
  final _CheckMode mode;
  final int costInr;
  final String svgIconPath;
}

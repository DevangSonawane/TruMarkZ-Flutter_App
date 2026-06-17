import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../../core/router/app_router.dart';
import '../../../../../core/theme/app_colors.dart';

enum ProductServiceType { verification, warranty }

class ProductServiceTypeSelectorPage extends StatefulWidget {
  const ProductServiceTypeSelectorPage({super.key});

  @override
  State<ProductServiceTypeSelectorPage> createState() =>
      _ProductServiceTypeSelectorPageState();
}

class _ProductServiceTypeSelectorPageState
    extends State<ProductServiceTypeSelectorPage> {
  bool _didInit = false;
  String _sector = '';
  String _categoryId = '';
  String _warrantySupport = '';
  bool _supportsWarranty = true;
  ProductServiceType? _selected;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInit) return;
    _didInit = true;
    final GoRouterState state = GoRouterState.of(context);
    final Object? extra = state.extra;
    final String? extraSector = extra is String ? extra : null;
    _sector =
        (extraSector ??
                state.uri.queryParameters['sector'] ??
                state.uri.queryParameters['industry'] ??
                '')
            .trim();
    _categoryId = (state.uri.queryParameters['category_id'] ?? '').trim();
    _warrantySupport = (state.uri.queryParameters['warranty_support'] ?? '')
        .trim();
    final String supports =
        (state.uri.queryParameters['supports_warranty'] ?? '').trim();
    if (supports.isNotEmpty) {
      _supportsWarranty = supports.toLowerCase() == 'true';
    } else {
      _supportsWarranty = _warrantySupport.toLowerCase() != 'disabled';
    }
  }

  void _goBack(BuildContext context) {
    final GoRouter router = GoRouter.of(context);
    if (router.canPop()) {
      context.pop();
    } else {
      context.go(AppRouter.dashboardPath);
    }
  }

  void _continue(BuildContext context) {
    final ProductServiceType? selected = _selected;
    if (selected == null) return;
    final Map<String, String> queryParameters = <String, String>{
      'flow': 'product',
      'mode': selected.name,
      if (_sector.trim().isNotEmpty) 'industry': _sector.trim(),
      if (_categoryId.trim().isNotEmpty) 'category_id': _categoryId.trim(),
      if (_warrantySupport.trim().isNotEmpty)
        'warranty_support': _warrantySupport.trim(),
      if (_supportsWarranty) 'supports_warranty': 'true',
    };
    final Uri uri = Uri(
      path: selected == ProductServiceType.verification
          ? AppRouter.verificationChecksPath
          : AppRouter.productBulkUploadPath,
      queryParameters: queryParameters,
    );
    context.push(uri.toString(), extra: _sector);
  }

  @override
  Widget build(BuildContext context) {
    final int totalSteps = 6;
    final int currentStep = 2;
    final String stepText = 'STEP $currentStep OF $totalSteps';
    final String progressText =
        '${((currentStep / totalSteps) * 100).round()}%';
    final double progressFactor = currentStep / totalSteps;

    return Scaffold(
      backgroundColor: AppColors.brandBlue,
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            const double referenceWidth = 402;
            final double contentWidth = constraints.maxWidth < referenceWidth
                ? constraints.maxWidth
                : referenceWidth;
            final double scale = contentWidth / referenceWidth;
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
                          Expanded(
                            child: Text(
                              'Product Service',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: s(21),
                                fontWeight: FontWeight.w600,
                                height: 19.5 / 21,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          SizedBox(width: s(8)),
                          ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: constraints.maxWidth * 0.42,
                            ),
                            child: _OrgTypePill(
                              scale: scale,
                              label: _sector.trim().isEmpty
                                  ? 'Product'
                                  : _sector.trim(),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: s(21)),
                    Expanded(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7F9FC),
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
                                  s(0),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Row(
                                      children: <Widget>[
                                        Text(
                                          stepText,
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
                                          progressText,
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
                                              widthFactor: progressFactor,
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
                                      'Product Service',
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: s(32),
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: s(1.18),
                                        height: 34 / 32,
                                        color: const Color(0xFF3A3A3A),
                                      ),
                                    ),
                                    SizedBox(height: s(14)),
                                    Text(
                                      'Choose the product certification type for this batch.',
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
                                    _ServiceCard(
                                      scale: scale,
                                      title: 'Product Verification',
                                      subtitle:
                                          'Issue authenticity / compliance certificates for products.',
                                      icon: Icons.verified_user_rounded,
                                      selected:
                                          _selected ==
                                          ProductServiceType.verification,
                                      onTap: () => setState(
                                        () => _selected =
                                            ProductServiceType.verification,
                                      ),
                                    ),
                                    if (_supportsWarranty) ...<Widget>[
                                      SizedBox(height: s(16)),
                                      _ServiceCard(
                                        scale: scale,
                                        title: 'Warranty',
                                        subtitle:
                                            'Create warranty certificates linked to serial numbers.',
                                        icon: Icons.verified_outlined,
                                        selected:
                                            _selected ==
                                            ProductServiceType.warranty,
                                        onTap: () => setState(
                                          () => _selected =
                                              ProductServiceType.warranty,
                                        ),
                                      ),
                                    ] else ...<Widget>[
                                      SizedBox(height: s(14)),
                                      Text(
                                        'Warranty is not available for this sector.',
                                        style: TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: s(12),
                                          fontWeight: FontWeight.w500,
                                          color: const Color(0xFF94A3B8),
                                          height: 17.75 / 12,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                            _BottomNav(
                              scale: scale,
                              child: _GradientCtaButton(
                                scale: scale,
                                label: 'Continue',
                                icon: Icons.arrow_forward_rounded,
                                enabled: _selected != null,
                                onPressed: () => _continue(context),
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

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({
    required this.scale,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final double scale;
  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    double s(double v) => v * scale;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(s(16)),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(s(16)),
            border: Border.all(color: const Color(0xFFDBEAFE)),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: const Color(0xFF3B82F6).withAlpha(20),
                blurRadius: s(20),
                spreadRadius: s(-2),
                offset: Offset(0, s(4)),
              ),
            ],
          ),
          child: Stack(
            children: <Widget>[
              if (selected)
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: s(6),
                    decoration: BoxDecoration(
                      color: AppColors.brandBlue,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(s(16)),
                        bottomLeft: Radius.circular(s(16)),
                      ),
                    ),
                  ),
                ),
              Padding(
                padding: EdgeInsets.fromLTRB(s(24), s(24), s(24), s(24)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Container(
                          width: s(48),
                          height: s(48),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEEF6FF),
                            borderRadius: BorderRadius.circular(s(12)),
                            border: Border.all(color: const Color(0xFFDBEAFE)),
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            icon,
                            size: s(30),
                            color: AppColors.brandBlue,
                          ),
                        ),
                        const Spacer(),
                        if (selected)
                          Container(
                            width: s(24),
                            height: s(24),
                            decoration: BoxDecoration(
                              color: AppColors.brandBlue,
                              borderRadius: BorderRadius.circular(s(9999)),
                            ),
                            alignment: Alignment.center,
                            child: SvgPicture.asset(
                              'assets/icons/figma/new_batch_check.svg',
                              width: s(10.5),
                              height: s(7.5),
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: s(16)),
                    Text(
                      title,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: s(20),
                        fontWeight: FontWeight.w600,
                        height: 28 / 20,
                        color: const Color(0xFF111827),
                      ),
                    ),
                    SizedBox(height: s(12)),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: s(14),
                        fontWeight: FontWeight.w400,
                        height: 22.75 / 14,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrgTypePill extends StatelessWidget {
  const _OrgTypePill({required this.scale, required this.label});

  final double scale;
  final String label;

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
            'assets/icons/figma/bulk_industry_building.svg',
            width: s(12),
            height: s(10),
            colorFilter: const ColorFilter.mode(
              AppColors.brandBlue,
              BlendMode.srcIn,
            ),
          ),
          SizedBox(width: s(8)),
          Flexible(
            child: Text(
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
          ),
          SizedBox(width: s(8)),
          Container(width: s(1), height: s(12), color: const Color(0xFFE2E8F0)),
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

class _GradientCtaButton extends StatelessWidget {
  const _GradientCtaButton({
    required this.scale,
    required this.label,
    required this.icon,
    required this.enabled,
    required this.onPressed,
  });

  final double scale;
  final String label;
  final IconData icon;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    double s(double v) => v * scale;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: enabled ? onPressed : null,
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
              label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: s(18),
                fontWeight: FontWeight.w700,
                height: 28 / 18,
                color: Colors.white,
              ),
            ),
            SizedBox(width: s(10)),
            Icon(icon, color: Colors.white, size: s(18)),
          ],
        ),
      ),
    );
  }
}

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/router/app_router.dart';
import '../../../../../core/theme/app_colors.dart';

enum _BatchType { human, product }

class BatchTypeSelectionPage extends StatefulWidget {
  const BatchTypeSelectionPage({super.key});

  @override
  State<BatchTypeSelectionPage> createState() => _BatchTypeSelectionPageState();
}

class _BatchTypeSelectionPageState extends State<BatchTypeSelectionPage> {
  _BatchType? _selected = _BatchType.human;

  static const double _referenceWidth = 402;
  static const Color _panelBg = Color(0xFFF7F9FC);
  static const Color _cardBorder = Color(0xFFDBEAFE);
  static const Color _chipBorder = Color(0xFFF3F4F6);
  static const Color _chipBg = Color(0xFFF9FAFB);

  void _goBack(BuildContext context) {
    final GoRouter router = GoRouter.of(context);
    if (router.canPop()) {
      context.pop();
    } else {
      context.go(AppRouter.dashboardPath);
    }
  }

  void _continue(BuildContext context) {
    final _BatchType? selected = _selected;
    if (selected == null) return;

    switch (selected) {
      case _BatchType.human:
        context.push(AppRouter.verificationChecksPath);
      case _BatchType.product:
        context.push(AppRouter.productSectorSelectorPath);
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
            double s(double value) => value * scale;

            final EdgeInsets panelPadding = EdgeInsets.fromLTRB(
              s(16),
              s(32),
              s(16),
              0,
            );

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
                            'New Batch',
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
                                padding: panelPadding.copyWith(bottom: s(24)),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    SizedBox(height: s(12)),
                                    Text(
                                      'Choose Batch Type',
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: s(24),
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: s(1.18),
                                        height: 17.7507286 / 24,
                                        color: const Color(0xFF323232),
                                      ),
                                    ),
                                    SizedBox(height: s(16)),
                                    Text(
                                      'Select the type of verification you want to perform.',
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: s(12),
                                        fontWeight: FontWeight.w500,
                                        letterSpacing: s(1.18),
                                        height: 17.7507286 / 12,
                                        color: const Color(0xFF9CA3AF),
                                      ),
                                    ),
                                    SizedBox(height: s(24)),
                                    _FigmaBatchTypeCard(
                                      scale: scale,
                                      title: 'Human Verification',
                                      subtitle:
                                          'Verify identities of individuals - workers, agents, drivers, students & more',
                                      subtitleFontSize: 12,
                                      svgAssetPath:
                                          'assets/icons/figma/new_batch_human.svg',
                                      tags: const <String>[
                                        'Workforce',
                                        'Gig Economy',
                                        'Insurance',
                                        'Recruitment',
                                      ],
                                      selected: _selected == _BatchType.human,
                                      showLeftStrip:
                                          _selected == _BatchType.human,
                                      onTap: () => setState(
                                        () => _selected = _BatchType.human,
                                      ),
                                    ),
                                    SizedBox(height: s(16)),
                                    _FigmaBatchTypeCard(
                                      scale: scale,
                                      title: 'Product Verification',
                                      subtitle:
                                          'Issue digital certificates for products stored on blockchain',
                                      subtitleFontSize: 14,
                                      svgAssetPath:
                                          'assets/icons/figma/new_batch_product.svg',
                                      tags: const <String>[
                                        'Consumer Goods',
                                        'Beauty & Cosmetics',
                                        'Electronics & Appliances',
                                        'EV & Automotive',
                                      ],
                                      selected: _selected == _BatchType.product,
                                      showLeftStrip:
                                          _selected == _BatchType.product,
                                      onTap: () => setState(
                                        () => _selected = _BatchType.product,
                                      ),
                                    ),
                                    SizedBox(height: s(24)),
                                  ],
                                ),
                              ),
                            ),
                            _BottomNav(
                              scale: scale,
                              child: _ContinueButton(
                                scale: scale,
                                enabled: _selected != null,
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

class _FigmaBatchTypeCard extends StatelessWidget {
  const _FigmaBatchTypeCard({
    required this.scale,
    required this.svgAssetPath,
    required this.title,
    required this.subtitle,
    required this.subtitleFontSize,
    required this.tags,
    required this.selected,
    required this.showLeftStrip,
    required this.onTap,
  });

  final double scale;
  final String svgAssetPath;
  final String title;
  final String subtitle;
  final double subtitleFontSize;
  final List<String> tags;
  final bool selected;
  final bool showLeftStrip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    double s(double v) => v * scale;

    final Color chipBg = selected
        ? AppColors.brandBlue.withAlpha(26)
        : _BatchTypeSelectionPageState._chipBg;
    final Color chipBorder = selected
        ? AppColors.brandBlue.withAlpha(102)
        : _BatchTypeSelectionPageState._chipBorder;
    final Color chipFg = selected
        ? AppColors.brandBlue
        : AppColors.textTertiary;

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
            border: Border.all(color: _BatchTypeSelectionPageState._cardBorder),
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
              if (showLeftStrip)
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
                            border: Border.all(
                              color: _BatchTypeSelectionPageState._cardBorder,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: SvgPicture.asset(
                            svgAssetPath,
                            width: s(30),
                            height: s(30),
                            colorFilter: selected
                                ? const ColorFilter.mode(
                                    AppColors.brandBlue,
                                    BlendMode.srcIn,
                                  )
                                : null,
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
                        fontSize: s(subtitleFontSize),
                        fontWeight: FontWeight.w400,
                        height: 22.75 / subtitleFontSize,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    SizedBox(height: s(16)),
                    Wrap(
                      spacing: s(7),
                      runSpacing: s(6),
                      children: <Widget>[
                        for (final String tag in tags)
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: s(12),
                              vertical: s(6),
                            ),
                            decoration: BoxDecoration(
                              color: chipBg,
                              borderRadius: BorderRadius.circular(s(8)),
                              border: Border.all(color: chipBorder),
                            ),
                            child: Text(
                              tag.toUpperCase(),
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: s(11),
                                fontWeight: FontWeight.w600,
                                letterSpacing: s(0.55),
                                height: 1.5,
                                color: chipFg,
                              ),
                            ),
                          ),
                      ],
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

class _ContinueButton extends StatefulWidget {
  const _ContinueButton({
    required this.scale,
    required this.enabled,
    required this.onTap,
  });

  final double scale;
  final bool enabled;
  final VoidCallback onTap;

  @override
  State<_ContinueButton> createState() => _ContinueButtonState();
}

class _ContinueButtonState extends State<_ContinueButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    double s(double v) => v * widget.scale;

    final Widget content = Row(
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
          colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
        ),
      ],
    );

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 150),
      opacity: widget.enabled ? 1 : 0.45,
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
              onTap: widget.enabled ? widget.onTap : null,
              onHighlightChanged: (bool value) =>
                  setState(() => _isPressed = value),
              child: AnimatedScale(
                duration: const Duration(milliseconds: 90),
                scale: _isPressed ? 0.985 : 1,
                child: Center(child: content),
              ),
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

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../../core/router/app_router.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/widgets/tmz_input.dart';

enum _BlockchainVisibility { publicRegistry, privateRegistry }

class ProductBatchSetupPage extends StatefulWidget {
  const ProductBatchSetupPage({super.key});

  @override
  State<ProductBatchSetupPage> createState() => _ProductBatchSetupPageState();
}

class _ProductBatchSetupPageState extends State<ProductBatchSetupPage> {
  bool _didInitFromRoute = false;
  String _sector = 'Consumer Goods & Warranty';
  String _categoryId = '';
  String _mode = 'verification'; // 'verification' | 'warranty'

  late final TextEditingController _batchNameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _unitsController;

  _BlockchainVisibility _visibility = _BlockchainVisibility.publicRegistry;

  @override
  void initState() {
    super.initState();
    _batchNameController = TextEditingController();
    _descriptionController = TextEditingController();
    _unitsController = TextEditingController(text: '100');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInitFromRoute) return;
    _didInitFromRoute = true;

    final String mode =
        (GoRouterState.of(context).uri.queryParameters['mode'] ??
                'verification')
            .trim()
            .toLowerCase();
    if (mode == 'warranty' || mode == 'verification') {
      _mode = mode;
    }

    final Object? extra = GoRouterState.of(context).extra;
    final String? sector = extra is String ? extra : null;
    if (sector != null && sector.trim().isNotEmpty) {
      _sector = sector.trim();
    }

    final String? categoryId = GoRouterState.of(
      context,
    ).uri.queryParameters['category_id'];
    if (categoryId != null && categoryId.trim().isNotEmpty) {
      _categoryId = categoryId.trim();
    } else {
      _categoryId = _sector;
    }
  }

  @override
  void dispose() {
    _batchNameController.dispose();
    _descriptionController.dispose();
    _unitsController.dispose();
    super.dispose();
  }

  void _goBack(BuildContext context) {
    final GoRouter router = GoRouter.of(context);
    if (router.canPop()) {
      context.pop();
    } else {
      context.go(AppRouter.dashboardPath);
    }
  }

  int _units() => int.tryParse(_unitsController.text.trim()) ?? 0;

  bool get _canContinue =>
      _batchNameController.text.trim().isNotEmpty && _units() > 0;

  void _continue(BuildContext context) {
    if (!_canContinue) return;

    final Map<String, String> qp = <String, String>{
      'batch': _batchNameController.text.trim(),
      'units': _units().toString(),
      'visibility': _visibility.name,
      'mode': _mode,
      'category_id': _categoryId.trim(),
      if (_descriptionController.text.trim().isNotEmpty)
        'desc': _descriptionController.text.trim(),
    };

    final Uri uri = Uri(
      path: AppRouter.productBulkUploadPath,
      queryParameters: qp,
    );
    context.push(uri.toString(), extra: _sector);
  }

  @override
  Widget build(BuildContext context) {
    final String modeLabel = _mode == 'warranty' ? 'Warranty' : 'Verification';
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
                          Text(
                            'Product Details',
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
                          color: const Color(0xFFF7F9FC),
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(s(20)),
                          ),
                        ),
                        child: Column(
                          children: <Widget>[
                            Expanded(
                              child: ListView(
                                padding: EdgeInsets.fromLTRB(
                                  s(16),
                                  s(28),
                                  s(16),
                                  s(140),
                                ),
                                children: <Widget>[
                                  _ProductFlowStepper(
                                    scale: scale,
                                    stepIndex: 1,
                                    totalSteps: 3,
                                  ),
                                  SizedBox(height: s(24)),
                                  Text(
                                    'Batch Metadata',
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
                                    'Add batch details and select the certificate format.',
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
                                  TMZInput(
                                    label: 'Batch Name',
                                    hint: _mode == 'warranty'
                                        ? 'e.g. Warranty Cards — May 2026'
                                        : 'e.g. Verification Certificates — May 2026',
                                    controller: _batchNameController,
                                    onChanged: (_) => setState(() {}),
                                    prefixIcon: Icons.folder_rounded,
                                  ),
                                  SizedBox(height: s(16)),
                                  _MultilineInput(
                                    label: 'Description (Optional)',
                                    hint: 'Short description (max 3 lines)',
                                    controller: _descriptionController,
                                    maxLines: 3,
                                    onChanged: (_) => setState(() {}),
                                  ),
                                  SizedBox(height: s(16)),
                                  Container(
                                    padding: EdgeInsets.all(s(16)),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(
                                        s(18),
                                      ),
                                      border: Border.all(
                                        color: const Color(
                                          0xFFCBD5E1,
                                        ).withAlpha(160),
                                      ),
                                    ),
                                    child: Row(
                                      children: <Widget>[
                                        Icon(
                                          Icons.category_rounded,
                                          color: AppColors.brandBlue,
                                        ),
                                        SizedBox(width: s(12)),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: <Widget>[
                                              Text(
                                                'Product Category',
                                                style: TextStyle(
                                                  fontFamily: 'Inter',
                                                  fontSize: s(12),
                                                  fontWeight: FontWeight.w700,
                                                  letterSpacing: s(0.6),
                                                  height: 18 / 12,
                                                  color: AppColors.textTertiary,
                                                ),
                                              ),
                                              SizedBox(height: s(8)),
                                              Chip(
                                                label: Text(
                                                  '$_sector • $modeLabel',
                                                ),
                                                backgroundColor: AppColors
                                                    .brandBlue
                                                    .withAlpha(14),
                                                labelStyle: TextStyle(
                                                  fontFamily: 'Inter',
                                                  fontSize: s(12),
                                                  fontWeight: FontWeight.w800,
                                                  height: 16.5 / 12,
                                                  color: AppColors.brandBlue,
                                                ),
                                                side: BorderSide(
                                                  color: AppColors.brandBlue
                                                      .withAlpha(24),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: s(16)),
                                  TMZInput(
                                    label: 'Number of Units',
                                    hint: 'e.g. 500',
                                    controller: _unitsController,
                                    keyboardType: TextInputType.number,
                                    prefixIcon:
                                        Icons.format_list_numbered_rounded,
                                    onChanged: (_) => setState(() {}),
                                  ),
                                  SizedBox(height: s(16)),
                                  Text(
                                    'Blockchain Visibility',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: s(12),
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: s(1.1),
                                      height: 18 / 12,
                                      color: const Color(0xFF3A3A3A),
                                    ),
                                  ),
                                  SizedBox(height: s(12)),
                                  Row(
                                    children: <Widget>[
                                      Expanded(
                                        child: _ChoiceChipCard(
                                          title: 'Public',
                                          subtitle: '',
                                          icon: Icons.public_rounded,
                                          selected:
                                              _visibility ==
                                              _BlockchainVisibility
                                                  .publicRegistry,
                                          onTap: () => setState(
                                            () => _visibility =
                                                _BlockchainVisibility
                                                    .publicRegistry,
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: s(12)),
                                      Expanded(
                                        child: _ChoiceChipCard(
                                          title: 'Private',
                                          subtitle: '',
                                          icon: Icons.lock_rounded,
                                          selected:
                                              _visibility ==
                                              _BlockchainVisibility
                                                  .privateRegistry,
                                          onTap: () => setState(
                                            () => _visibility =
                                                _BlockchainVisibility
                                                    .privateRegistry,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            _BottomNav(
                              scale: scale,
                              child: _GradientCtaButton(
                                scale: scale,
                                label: 'Continue',
                                icon: Icons.arrow_forward_rounded,
                                enabled: _canContinue,
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

class _ChoiceChipCard extends StatelessWidget {
  const _ChoiceChipCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 68),
          padding: const EdgeInsets.all(AppSpacing.x3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? AppColors.brandBlue : AppColors.border,
              width: 1.25,
            ),
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.brandBlue.withAlpha(16)
                      : const Color(0xFFEFF3FF),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: AppColors.brandBlue),
              ),
              const SizedBox(width: AppSpacing.x3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      title,
                      style: AppTypography.body2.copyWith(
                        fontWeight: FontWeight.w900,
                        color: selected
                            ? AppColors.brandBlue
                            : AppColors.textPrimary,
                      ),
                    ),
                    if (subtitle.trim().isNotEmpty) ...<Widget>[
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.1,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.check_circle_rounded,
                color: selected ? AppColors.brandBlue : Colors.transparent,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MultilineInput extends StatefulWidget {
  const _MultilineInput({
    required this.label,
    this.hint,
    required this.controller,
    required this.maxLines,
    required this.onChanged,
  });

  final String label;
  final String? hint;
  final TextEditingController controller;
  final int maxLines;
  final ValueChanged<String> onChanged;

  @override
  State<_MultilineInput> createState() => _MultilineInputState();
}

class _MultilineInputState extends State<_MultilineInput> {
  late final FocusNode _focusNode;
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode()..addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_handleFocusChange)
      ..dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    if (_focused == _focusNode.hasFocus) return;
    setState(() => _focused = _focusNode.hasFocus);
  }

  @override
  Widget build(BuildContext context) {
    final Color borderColor = _focused ? AppColors.brandBlue : AppColors.border;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          widget.label.toUpperCase(),
          style: AppTypography.caption.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
            color: AppColors.textTertiary,
          ),
        ),
        const SizedBox(height: 8),
        AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: AppColors.cardSurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor, width: 1.25),
          ),
          child: TextField(
            focusNode: _focusNode,
            controller: widget.controller,
            maxLines: widget.maxLines,
            onChanged: widget.onChanged,
            style: AppTypography.body2.copyWith(
              color: AppColors.textPrimary,
              height: 1.25,
            ),
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: AppTypography.body2.copyWith(
                color: AppColors.textTertiary,
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              isDense: true,
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ),
      ],
    );
  }
}

class _ProductFlowStepper extends StatelessWidget {
  const _ProductFlowStepper({
    required this.scale,
    required this.stepIndex,
    required this.totalSteps,
  });

  final double scale;
  final int stepIndex;
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    double s(double v) => v * scale;
    final int currentStep = stepIndex.clamp(0, totalSteps - 1) + 1;
    final int progressPercent = ((currentStep / totalSteps) * 100).round();
    final double progress = stepIndex / (totalSteps - 1);

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
                'STEP $currentStep OF $totalSteps',
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
                '$progressPercent%',
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

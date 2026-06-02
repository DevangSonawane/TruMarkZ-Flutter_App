import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../../core/models/verification_models.dart';
import '../../../../../core/router/app_router.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../data/verification_repository.dart';

class ProductSectorSelectorPage extends ConsumerStatefulWidget {
  const ProductSectorSelectorPage({super.key});

  @override
  ConsumerState<ProductSectorSelectorPage> createState() =>
      _ProductSectorSelectorPageState();
}

class _ProductSectorSelectorPageState
    extends ConsumerState<ProductSectorSelectorPage> {
  VerificationCategory? _selectedCategory;
  bool _loading = true;
  String? _error;
  List<VerificationCategory> _categories = const <VerificationCategory>[];

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(_loadCategories);
  }

  Future<void> _loadCategories() async {
    try {
      final VerificationRepository repo = ref.read(
        verificationRepositoryProvider,
      );
      final List<VerificationCategory> categories = await repo
          .getProductCategories();
      if (!mounted) return;
      setState(() {
        _categories = categories;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
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
    final VerificationCategory? category = _selectedCategory;
    if (category == null) return;
    final String sector = category.categoryName.trim();
    final String categoryId = category.id.trim();
    final Uri uri = Uri(
      path: AppRouter.productServiceTypeSelectorPath,
      queryParameters: <String, String>{
        'sector': sector,
        'category_id': categoryId,
        'supports_warranty': category.supportsWarranty ? 'true' : 'false',
      },
    );
    context.push(uri.toString(), extra: sector);
  }

  @override
  Widget build(BuildContext context) {
    final List<VerificationCategory> categories = _categories;

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
                            'Bulk Upload',
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
                              child: SingleChildScrollView(
                                padding: EdgeInsets.fromLTRB(
                                  s(16),
                                  s(28),
                                  s(16),
                                  s(140),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    _ProductFlowStepper(
                                      scale: scale,
                                      stepIndex: 0,
                                      totalSteps: 4,
                                    ),
                                    SizedBox(height: s(24)),
                                    Text(
                                      'Select Product Sector',
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
                                      'Choose the sector category for this product verification batch.',
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: s(12),
                                        fontWeight: FontWeight.w500,
                                        letterSpacing: s(1.18),
                                        height: 17.75 / 12,
                                        color: const Color(0xFF94A3B8),
                                      ),
                                    ),
                                    SizedBox(height: s(22)),
                                    if (_loading)
                                      const Padding(
                                        padding: EdgeInsets.symmetric(
                                          vertical: AppSpacing.x6,
                                        ),
                                        child: Center(
                                          child: CircularProgressIndicator(),
                                        ),
                                      )
                                    else if (_error != null)
                                      _InfoBanner(
                                        scale: scale,
                                        title: 'Unable to load categories',
                                        message:
                                            'Try loading the category list again.',
                                        actionLabel: 'Retry',
                                        onAction: () {
                                          setState(() {
                                            _loading = true;
                                            _error = null;
                                          });
                                          _loadCategories();
                                        },
                                      )
                                    else
                                      LayoutBuilder(
                                        builder:
                                            (
                                              BuildContext context,
                                              BoxConstraints constraints,
                                            ) {
                                              final int columns =
                                                  constraints.maxWidth >= 800
                                                  ? 3
                                                  : 2;
                                              return GridView.builder(
                                                itemCount: categories.length,
                                                shrinkWrap: true,
                                                physics:
                                                    const NeverScrollableScrollPhysics(),
                                                gridDelegate:
                                                    SliverGridDelegateWithFixedCrossAxisCount(
                                                      crossAxisCount: columns,
                                                      mainAxisSpacing:
                                                          AppSpacing.x3,
                                                      crossAxisSpacing:
                                                          AppSpacing.x3,
                                                      childAspectRatio: 1,
                                                    ),
                                                itemBuilder:
                                                    (
                                                      BuildContext context,
                                                      int index,
                                                    ) {
                                                      final VerificationCategory
                                                      cat = categories[index];
                                                      final bool selected =
                                                          _selectedCategory
                                                              ?.id ==
                                                          cat.id;
                                                      return _SectorCard(
                                                        title: cat.categoryName,
                                                        description:
                                                            cat.description,
                                                        icon: _iconForCategory(
                                                          cat.categoryName,
                                                        ),
                                                        selected: selected,
                                                        onTap: () {
                                                          setState(
                                                            () =>
                                                                _selectedCategory =
                                                                    cat,
                                                          );
                                                          _continue(context);
                                                        },
                                                      );
                                                    },
                                              );
                                            },
                                      ),
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
                                enabled: _selectedCategory != null,
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

IconData _iconForCategory(String name) {
  final String n = name.trim().toLowerCase();
  if (n.contains('agri') || n.contains('farm') || n.contains('crop')) {
    return Icons.agriculture_rounded;
  }
  if (n.contains('beauty') || n.contains('cosmetic') || n.contains('spa')) {
    return Icons.spa_rounded;
  }
  if (n.contains('consumer') || n.contains('goods') || n.contains('fmcg')) {
    return Icons.shopping_bag_rounded;
  }
  if (n.contains('electronic') ||
      n.contains('appliance') ||
      n.contains('device')) {
    return Icons.devices_other_rounded;
  }
  if (n.contains('auto') || n.contains('vehicle') || n.contains('ev')) {
    return Icons.electric_car_rounded;
  }
  if (n.contains('health') || n.contains('pharma') || n.contains('medical')) {
    return Icons.medical_services_rounded;
  }
  if (n.contains('insurance') || n.contains('policy')) {
    return Icons.policy_rounded;
  }
  if (n.contains('luxury') || n.contains('jewel') || n.contains('diamond')) {
    return Icons.diamond_rounded;
  }
  if (n.contains('industrial') ||
      n.contains('equipment') ||
      n.contains('machine')) {
    return Icons.precision_manufacturing_rounded;
  }
  return Icons.inventory_rounded;
}

class _SectorCard extends StatelessWidget {
  const _SectorCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String description;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final BorderSide borderSide = selected
        ? const BorderSide(color: AppColors.brandBlue, width: 2)
        : BorderSide(color: Colors.transparent.withAlpha(0));

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.fromBorderSide(borderSide),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: AppColors.brandBlue.withAlpha(18),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          padding: const EdgeInsets.all(AppSpacing.x4),
          child: Stack(
            children: <Widget>[
              Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.brandBlue.withAlpha(24)
                          : const Color(0xFFEFF3FF),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: AppColors.brandBlue, size: 26),
                  ),
                  const SizedBox(height: AppSpacing.x2),
                  Text(
                    title,
                    style: AppTypography.body2.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 13.5,
                      height: 1.1,
                      color: selected
                          ? AppColors.brandBlue
                          : AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.2,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
              if (selected)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: <Color>[AppColors.brandBlue, Color(0xFF004AC6)],
                      ),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
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

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({
    required this.scale,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final double scale;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    double s(double v) => v * scale;
    return Container(
      padding: EdgeInsets.all(s(16)),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F6FF),
        borderRadius: BorderRadius.circular(s(18)),
        border: Border.all(color: AppColors.brandBlue.withAlpha(18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(Icons.info_outline_rounded, color: AppColors.brandBlue),
          SizedBox(width: s(12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: s(14),
                    fontWeight: FontWeight.w800,
                    height: 20 / 14,
                    color: const Color(0xFF111827),
                  ),
                ),
                SizedBox(height: s(6)),
                Text(
                  message,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: s(12),
                    fontWeight: FontWeight.w500,
                    height: 18 / 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: s(12)),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: onAction,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.brandBlue,
                      side: BorderSide(
                        color: AppColors.brandBlue.withAlpha(64),
                      ),
                      padding: EdgeInsets.symmetric(vertical: s(12)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(s(14)),
                      ),
                    ),
                    child: Text(
                      actionLabel,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: s(14),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
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

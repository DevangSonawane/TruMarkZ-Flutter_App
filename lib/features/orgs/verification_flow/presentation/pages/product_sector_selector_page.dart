import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/models/verification_models.dart';
import '../../../../../core/router/app_router.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../data/verification_repository.dart';
import '../../../../../core/widgets/org_top_bar.dart';
import 'flow_step_progress.dart';

class _ProductSectorCardData {
  const _ProductSectorCardData({
    required this.id,
    required this.title,
    required this.description,
    required this.categoryId,
    required this.warrantySupport,
    required this.imageAsset,
  });

  final String id;
  final String title;
  final String description;
  final String categoryId;
  final String warrantySupport;
  final String imageAsset;
}

class ProductSectorSelectorPage extends ConsumerStatefulWidget {
  const ProductSectorSelectorPage({super.key});

  @override
  ConsumerState<ProductSectorSelectorPage> createState() =>
      _ProductSectorSelectorPageState();
}

class _ProductSectorSelectorPageState
    extends ConsumerState<ProductSectorSelectorPage> {
  _ProductSectorCardData? _selectedSector;
  bool _loading = true;
  String? _error;
  List<VerificationIndustryType> _industryTypes =
      const <VerificationIndustryType>[];

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
      final List<VerificationIndustryType> industryTypes = await repo
          .getIndustryTypes();
      if (!mounted) return;
      setState(() {
        _industryTypes = industryTypes;
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

  void _continue(BuildContext context) {
    final _ProductSectorCardData? sectorCard = _selectedSector;
    if (sectorCard == null) return;
    final String sector = sectorCard.title.trim();
    final String categoryId = sectorCard.categoryId.trim();
    final String warranty = sectorCard.warrantySupport.trim().toLowerCase();
    final bool supportsWarranty = warranty.isNotEmpty && warranty != 'disabled';
    final Uri uri = Uri(
      path: AppRouter.productServiceTypeSelectorPath,
      queryParameters: <String, String>{
        'flow': 'product',
        'sector': sector,
        'sector_title': sectorCard.title.trim(),
        'industry': sector,
        'category_id': categoryId,
        'warranty_support': sectorCard.warrantySupport.trim(),
        'supports_warranty': supportsWarranty ? 'true' : 'false',
      },
    );
    context.push(uri.toString(), extra: sector);
  }

  @override
  Widget build(BuildContext context) {
    final List<_ProductSectorCardData> sectors = _industryTypes
        .map(_sectorFromIndustryType)
        .toList();

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
                      child: const OrgTopBar(title: 'Product Verification'),
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
                                    FlowStepProgress(
                                      scale: scale,
                                      stepLabel: 'STEP 1 OF 6',
                                      progressLabel: '17%',
                                      fillFactor: 0.1667,
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
                                      'Choose the industry category for this product verification batch.',
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
                                        title: 'Unable to load industries',
                                        message:
                                            'Try loading the industry list again.',
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
                                                itemCount: sectors.length,
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
                                                       childAspectRatio: 0.78,
                                                     ),
                                                itemBuilder:
                                                    (
                                                      BuildContext context,
                                                      int index,
                                                    ) {
                                                      final _ProductSectorCardData
                                                      sector = sectors[index];
                                                      final bool selected =
                                                          _selectedSector?.id ==
                                                          sector.id;
                                                      return _SectorCard(
                                                        title: sector.title,
                                                        imageAsset: sector.imageAsset,
                                                        selected: selected,
                                                        onTap: () {
                                                          setState(() {
                                                            _selectedSector =
                                                                sector;
                                                          });
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
                                enabled: _selectedSector != null,
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

const Map<String, String> _sectorImageAssets = {
  'Consumer Goods': 'assets/images/sectors/consumer.jpg',
  'Beauty & Cosmetics': 'assets/images/sectors/beauty.jpg',
  'Electronics & Appliances': 'assets/images/sectors/electronics.jpg',
  'EV & Automotive': 'assets/images/sectors/ev.jpg',
  'Insurance Policies': 'assets/images/sectors/insurance.jpg',
  'Healthcare Products': 'assets/images/sectors/healthcare.jpg',
  'Industrial Equipment': 'assets/images/sectors/industrial.jpg',
  'Agriculture Products': 'assets/images/sectors/agriculture.jpg',
  'Luxury Products': 'assets/images/sectors/luxury.jpg',
  'Others': 'assets/images/sectors/others.jpg',
};

String _imageAssetForSector(String title) {
  final String key = title.trim();
  if (_sectorImageAssets.containsKey(key)) {
    return _sectorImageAssets[key]!;
  }
  final String lower = key.toLowerCase();
  if (lower.contains('electronic') || lower.contains('appliance')) {
    return 'assets/images/sectors/electronics.jpg';
  }
  if (lower.contains('beauty') || lower.contains('cosmetic')) {
    return 'assets/images/sectors/beauty.jpg';
  }
  if (lower.contains('agriculture')) return 'assets/images/sectors/agriculture.jpg';
  if (lower.contains('health')) return 'assets/images/sectors/healthcare.jpg';
  if (lower.contains('industrial')) return 'assets/images/sectors/industrial.jpg';
  if (lower.contains('insurance')) return 'assets/images/sectors/insurance.jpg';
  if (lower.contains('luxury')) return 'assets/images/sectors/luxury.jpg';
  if (lower.contains('ev') || lower.contains('automotive')) {
    return 'assets/images/sectors/ev.jpg';
  }
  return 'assets/images/sectors/others.jpg';
}

_ProductSectorCardData _sectorFromIndustryType(
  VerificationIndustryType industryType,
) {
  final String title = industryType.name.trim().isNotEmpty
      ? industryType.name.trim()
      : 'Unknown';
  final String warrantySupport = industryType.warrantySupport.trim().isNotEmpty
      ? industryType.warrantySupport.trim()
      : 'optional';
  return _ProductSectorCardData(
    id: title,
    title: title,
    description: _descriptionForWarrantySupport(warrantySupport),
    categoryId: title,
    warrantySupport: warrantySupport,
    imageAsset: _imageAssetForSector(title),
  );
}

String _descriptionForWarrantySupport(String warrantySupport) {
  switch (warrantySupport.trim().toLowerCase()) {
    case 'required':
      return 'Warranty support is required for this industry.';
    case 'disabled':
      return 'Warranty support is not available for this industry.';
    case 'optional':
    default:
      return 'Warranty support is optional for this industry.';
  }
}


/// Home-style sector tile: photo box on top, label underneath.
/// No overlays on the image — selection shows as a blue ring + check.
class _SectorCard extends StatelessWidget {
  const _SectorCard({
    required this.title,
    required this.imageAsset,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String imageAsset;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Column(
        children: <Widget>[
          AspectRatio(
            aspectRatio: 1,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: selected
                      ? AppColors.brandBlue
                      : AppColors.divider,
                  width: selected ? 2.5 : 1,
                ),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: selected
                        ? AppColors.brandBlue.withAlpha(70)
                        : Colors.black.withValues(alpha: 0.06),
                    blurRadius: selected ? 20 : 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(13),
                child: Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    Image.asset(
                      imageAsset,
                      fit: BoxFit.cover,
                      errorBuilder:
                          (
                            BuildContext context,
                            Object error,
                            StackTrace? stackTrace,
                          ) => const DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: <Color>[
                                  AppColors.brandBlue,
                                  AppColors.deepNavy,
                                ],
                              ),
                            ),
                          ),
                    ),
                    if (selected)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: AppColors.brandBlue,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: Colors.white,
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            size: 15,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              color: selected
                  ? AppColors.brandBlue
                  : AppColors.textPrimary,
              fontSize: 14,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
              letterSpacing: -0.1,
              height: 1.15,
            ),
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

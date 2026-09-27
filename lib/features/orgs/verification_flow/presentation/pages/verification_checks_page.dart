import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/router/app_router.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/models/verification_models.dart';
import '../../../../../core/widgets/org_top_bar.dart';
import '../../../../auth/application/auth_notifier.dart';
import '../../../data/verification_repository.dart';
import 'product_verification_checks_catalog.dart';

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
  String _flow = 'human';
  String _mode = 'verification';
  String _industry = '';
  String _sectorTitle = '';
  String _categoryId = '';
  String _warrantySupport = 'required';
  bool _supportsWarranty = true;

  final Set<String> _selected = <String>{};

  static const List<_CheckItem> _warrantyItems = <_CheckItem>[
    _CheckItem(
      id: 'warranty_registration',
      title: 'Warranty Registration',
      subtitle: 'Verify the activation details and start date',
      mode: _CheckMode.auto,
      costInr: 140,
      materialIcon: Icons.verified_rounded,
    ),
    _CheckItem(
      id: 'serial',
      title: 'Serial Number Match',
      subtitle: 'Match the serial number to the original invoice',
      mode: _CheckMode.manual,
      costInr: 180,
      materialIcon: Icons.qr_code_rounded,
    ),
    _CheckItem(
      id: 'purchase_proof',
      title: 'Proof of Purchase',
      subtitle: 'Invoice or bill check for warranty validity',
      mode: _CheckMode.manual,
      costInr: 160,
      materialIcon: Icons.receipt_long_rounded,
    ),
    _CheckItem(
      id: 'activation',
      title: 'Activation Status',
      subtitle: 'Confirm product activation and claim window',
      mode: _CheckMode.auto,
      costInr: 120,
      materialIcon: Icons.toggle_on_rounded,
    ),
    _CheckItem(
      id: 'claim',
      title: 'Claim Eligibility',
      subtitle: 'Check whether the claim can be approved',
      mode: _CheckMode.manual,
      costInr: 220,
      materialIcon: Icons.verified_user_rounded,
    ),
  ];

  static const List<String> _industryOptions = <String>[
    'All',
    'Transport',
    'Healthcare',
    'Education',
    'Manufacturing',
    'Security',
    'Agriculture',
    'Beauty & Cosmetics',
    'Consumer Goods',
    'Electronics & Appliances',
    'EV & Automotive',
    'Healthcare Products',
    'Industrial Equipment',
    'Insurance Policies',
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
    final String nextFlow = (qp['flow'] ?? '').trim().toLowerCase();
    final String nextMode = (qp['mode'] ?? 'verification').trim().toLowerCase();
    final String nextCategoryId = (qp['category_id'] ?? '').trim();
    final String nextSectorTitle = (qp['sector_title'] ?? '').trim();
    final String nextWarrantySupport = (qp['warranty_support'] ?? '')
        .trim()
        .toLowerCase();
    final bool nextSupportsWarranty =
        (qp['supports_warranty'] ?? '').trim().toLowerCase() == 'true';
    final Set<String> nextChecks = <String>{};
    final String rawChecks = (qp['checks'] ?? '').trim();
    if (rawChecks.isNotEmpty) {
      nextChecks.addAll(
        rawChecks
            .split(',')
            .map((String s) => s.trim())
            .where((String s) => s.isNotEmpty),
      );
    }
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
    final bool needsFlowRefresh =
        nextFlow != _flow ||
        nextMode != _mode ||
        nextCategoryId != _categoryId ||
        nextSectorTitle != _sectorTitle ||
        nextWarrantySupport != _warrantySupport ||
        nextSupportsWarranty != _supportsWarranty;
    if (needsFlowRefresh) {
      setState(() {
        _flow = nextFlow.isEmpty ? 'human' : nextFlow;
        _mode = nextMode;
        _categoryId = nextCategoryId;
        _sectorTitle = nextSectorTitle;
        _warrantySupport = nextWarrantySupport.isEmpty
            ? (nextSupportsWarranty ? 'required' : 'disabled')
            : nextWarrantySupport;
        _supportsWarranty = _warrantySupport != 'disabled';
        _selected
          ..clear()
          ..addAll(nextChecks);
      });
    }
  }

  String _verificationCategoryForFlow() {
    final String category = _flow == 'product' ? 'product' : 'human';
    final String industry = _selectedIndustryForQuery();
    if (industry.isEmpty) return category;
    return '$category::$industry';
  }

  String _selectedIndustryForQuery() {
    final String raw = _industry.trim().isNotEmpty
        ? _industry.trim()
        : _sectorTitle.trim();
    if (raw.isEmpty) return '';
    final String normalized = raw.toLowerCase();
    if (normalized == 'all' || normalized == 'both') return '';
    return raw;
  }

  List<_CheckItem> _buildItems(List<VerificationTypeDefinition> types) {
    return types
        .map(
          (VerificationTypeDefinition item) => _CheckItem(
            id: item.id,
            title: item.name,
            subtitle: _subtitleForVerificationType(item),
            mode: item.label.trim().toLowerCase() == 'automatic'
                ? _CheckMode.auto
                : _CheckMode.manual,
            costInr: _resolvedPrice(item),
            materialIcon: _iconForVerificationType(item),
          ),
        )
        .toList();
  }

  int _resolvedPrice(VerificationTypeDefinition item) {
    final int? apiPrice = item.price;
    if (apiPrice != null && apiPrice > 0) return apiPrice;
    if (item.category.trim().toLowerCase() == 'product') {
      return ProductVerificationChecksCatalog.pricesInr[item.id] ?? 0;
    }
    return 0;
  }

  List<_CheckItem> _productWarrantyItems() {
    return _warrantyItems;
  }

  static String _checkDisplayName(_CheckItem item) {
    final String title = item.title.trim();
    if (title.isNotEmpty) return title;
    return item.id.trim();
  }

  void _ensureDefaultSelection(List<_CheckItem> items) {
    if (items.isEmpty) return;
    final bool hasValidSelection = _selected.any(
      (String id) => items.any((_CheckItem item) => item.id == id),
    );
    if (hasValidSelection) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_selected.any(
        (String id) => items.any((_CheckItem item) => item.id == id),
      )) {
        return;
      }
      setState(() {
        _selected
          ..clear()
          ..add(items.first.id);
      });
    });
  }

  static String _subtitleForVerificationType(VerificationTypeDefinition item) {
    final String timeline = item.timeline?.trim() ?? '';
    final int? price = item.price;
    final String email = item.emailAddress?.trim() ?? '';

    if (timeline.isNotEmpty && price != null) {
      return '$timeline • ₹$price';
    }
    if (timeline.isNotEmpty) return timeline;
    if (price != null) return 'Starting at ₹$price';
    if (email.isNotEmpty) return email;
    return item.category.trim().isNotEmpty
        ? item.category.trim().toUpperCase()
        : '';
  }

  static IconData _iconForVerificationType(VerificationTypeDefinition item) {
    final String key = '${item.category}-${item.name}-${item.id}'.toLowerCase();
    if (key.contains('dob')) return Icons.cake_rounded;
    if (key.contains('address')) return Icons.location_on_rounded;
    if (key.contains('education')) return Icons.school_rounded;
    if (key.contains('skills')) return Icons.psychology_rounded;
    if (key.contains('criminal')) return Icons.gavel_rounded;
    if (key.contains('driving')) return Icons.drive_eta_rounded;
    if (key.contains('experience')) return Icons.work_history_rounded;
    if (key.contains('drug')) return Icons.science_rounded;
    if (key.contains('company')) return Icons.domain_rounded;
    if (key.contains('police')) return Icons.local_police_rounded;
    if (key.contains('bis')) return Icons.verified_rounded;
    if (key.contains('quality')) return Icons.fact_check_rounded;
    if (key.contains('safety')) return Icons.electrical_services_rounded;
    if (key.contains('installation')) return Icons.handyman_rounded;
    if (key.contains('warranty')) return Icons.card_membership_rounded;
    if (key.contains('service centre') || key.contains('service_center')) {
      return Icons.store_rounded;
    }
    if (key.contains('repair')) return Icons.build_circle_rounded;
    if (key.contains('extended warranty')) {
      return Icons.workspace_premium_rounded;
    }
    return item.category.trim().toLowerCase() == 'product'
        ? Icons.inventory_2_rounded
        : Icons.badge_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final bool isProductFlow = _flow == 'product';
    final AsyncValue<List<VerificationTypeDefinition>> verificationTypesAsync =
        _mode == 'warranty'
        ? const AsyncData<List<VerificationTypeDefinition>>(
            <VerificationTypeDefinition>[],
          )
        : ref.watch(verificationTypesProvider(_verificationCategoryForFlow()));
    final List<_CheckItem> apiItems = _mode == 'warranty'
        ? _productWarrantyItems()
        : _buildItems(
            verificationTypesAsync.valueOrNull ??
                <VerificationTypeDefinition>[],
          );
    final Map<String, String> checkNamesById = <String, String>{
      for (final _CheckItem item in apiItems) item.id: _checkDisplayName(item),
    };
    _ensureDefaultSelection(apiItems);
    final String stepText = isProductFlow ? 'STEP 3 OF 6' : 'STEP 1 OF 6';
    final String progressText = isProductFlow ? '50%' : '17%';
    final double progressFactor = isProductFlow ? 0.5 : 0.1667;

    return Scaffold(
      backgroundColor: AppColors.brandBlue,
      body: PopScope(
        canPop: Navigator.of(context).canPop(),
        onPopInvokedWithResult: (bool didPop, Object? result) {
          if (didPop) return;
          context.go(AppRouter.dashboardPath);
        },
        child: SafeArea(
          bottom: false,
          child: LayoutBuilder(
            builder: (BuildContext layoutContext, BoxConstraints constraints) {
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
                        child: const OrgTopBar(
                          title: 'Verification Checks',
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                        child:
                                            verificationTypesAsync.isLoading &&
                                                apiItems.isEmpty
                                            ? const Center(
                                                child:
                                                    CircularProgressIndicator(),
                                              )
                                            : ListView.separated(
                                                padding: EdgeInsets.only(
                                                  bottom: s(16),
                                                ),
                                                itemBuilder:
                                                    (
                                                      BuildContext context,
                                                      int i,
                                                    ) {
                                                      final _CheckItem item =
                                                          apiItems[i];
                                                      final bool selected =
                                                          _selected.contains(
                                                            item.id,
                                                          );
                                                      return _CheckTile(
                                                        scale: scale,
                                                        item: item,
                                                        selected: selected,
                                                        onTap: () {
                                                          setState(() {
                                                            if (selected) {
                                                              _selected.remove(
                                                                item.id,
                                                              );
                                                            } else {
                                                              _selected.add(
                                                                item.id,
                                                              );
                                                            }
                                                          });
                                                        },
                                                      );
                                                    },
                                                separatorBuilder:
                                                    (
                                                      BuildContext context,
                                                      int i,
                                                    ) =>
                                                        SizedBox(height: s(16)),
                                                itemCount: apiItems.length,
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
                                      final List<String> ids =
                                          _selected.toList()..sort();
                                      qp['check_ids'] = ids.join(',');
                                      qp['checks'] = ids
                                          .map(
                                            (String id) =>
                                                checkNamesById[id] ?? id,
                                          )
                                          .join(',');
                                    }
                                    if (_industry.trim().isNotEmpty) {
                                      qp['industry'] = _industry.trim();
                                    }
                                    if (_flow == 'product') {
                                      qp['flow'] = 'product';
                                      qp['mode'] = _mode;
                                      if (_industry.trim().isNotEmpty) {
                                        qp['sector'] = _industry.trim();
                                        qp['industry'] = _industry.trim();
                                      }
                                      if (_sectorTitle.trim().isNotEmpty) {
                                        qp['sector_title'] = _sectorTitle
                                            .trim();
                                      }
                                      if (_categoryId.trim().isNotEmpty) {
                                        qp['category_id'] = _categoryId.trim();
                                      }
                                      if (_warrantySupport.trim().isNotEmpty) {
                                        qp['warranty_support'] =
                                            _warrantySupport.trim();
                                      }
                                      if (_supportsWarranty) {
                                        qp['supports_warranty'] = 'true';
                                      }
                                    }
                                    final Uri uri = Uri(
                                      path: _flow == 'product'
                                          ? AppRouter.productBulkUploadPath
                                          : AppRouter
                                                .verificationPermissionsPath,
                                      queryParameters: qp,
                                    );
                                    context.push(
                                      uri.toString(),
                                      extra: _flow == 'product'
                                          ? _industry
                                          : null,
                                    );
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
      ),
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
                child: Icon(
                  item.materialIcon ?? Icons.verified_rounded,
                  size: s(22),
                  color: AppColors.brandBlue,
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
                    item.costInr > 0 ? '₹${item.costInr}' : 'Custom',
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
    this.materialIcon,
  });

  final String id;
  final String title;
  final String subtitle;
  final _CheckMode mode;
  final int costInr;
  final IconData? materialIcon;
}

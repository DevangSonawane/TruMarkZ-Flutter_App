import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../../../../core/models/verification_models.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/tmz_card.dart';
import '../../../auth/application/auth_notifier.dart';
import '../../../auth/application/auth_state.dart';
import '../../data/verification_repository.dart';

/// MrBob-style home, Trumarkz colours:
/// - Solid brandBlue header that collapses on scroll.
/// - White search card pinned below the status bar.
/// - Promo banner (dot texture, headline, CTA + stats hero card) that
///   scrolls away under the sticky search with a rounded bottom curve.
/// - White body: Quick Actions grid + horizontally scrolling Recent Batches.
class OrgDashboardPage extends ConsumerStatefulWidget {
  const OrgDashboardPage({super.key});

  @override
  ConsumerState<OrgDashboardPage> createState() => _OrgDashboardPageState();
}

class _OrgDashboardPageState extends ConsumerState<OrgDashboardPage> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  bool _sectorsLoading = true;
  String? _sectorsError;
  List<VerificationIndustryType> _sectors = const <VerificationIndustryType>[];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      final String next = _searchController.text;
      if (next == _query) return;
      if (!mounted) return;
      setState(() => _query = next);
    });
    Future<void>.microtask(_loadSectors);
  }

  Future<void> _loadSectors() async {
    try {
      final VerificationRepository repo = ref.read(
        verificationRepositoryProvider,
      );
      final List<VerificationIndustryType> types = await repo
          .getIndustryTypes();
      if (!mounted) return;
      setState(() {
        _sectors = types
            .where((VerificationIndustryType t) => t.name.trim().isNotEmpty)
            .toList();
        _sectorsLoading = false;
        _sectorsError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _sectorsLoading = false;
        _sectorsError = e.toString();
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refreshDashboard() async {
    final List<VerificationBatchSummary> _ = await ref.refresh(
      verificationBatchesProvider.future,
    );
  }

  void _onTapNewBatch(String serviceType) {
    if (serviceType == 'human') {
      context.go(AppRouter.verificationChecksPath);
      return;
    }
    if (serviceType == 'product') {
      context.go(AppRouter.productSectorSelectorPath);
      return;
    }
    context.go(AppRouter.batchTypeSelectionPath);
  }

  void _showAllSectorsSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext sheetContext) {
        final double sheetHeight = MediaQuery.sizeOf(sheetContext).height;
        final double bottomInset = MediaQuery.paddingOf(sheetContext).bottom;
        final Widget body;
        if (_sectorsLoading) {
          body = const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(child: CircularProgressIndicator()),
          );
        } else if (_sectorsError != null || _sectors.isEmpty) {
          body = Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Text(
                  'Sectors are unavailable right now.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: AppColors.textSecondary,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    onPressed: () {
                      Navigator.of(sheetContext).pop();
                      _loadSectors();
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.brandBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Retry',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        } else {
          body = Padding(
            padding: EdgeInsets.fromLTRB(20, 4, 20, 20 + bottomInset),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                for (int i = 0; i < _sectors.length; i++) ...<Widget>[
                  if (i != 0)
                    const Divider(
                      height: 1,
                      color: AppColors.divider,
                    ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 9,
                    ),
                    child: Row(
                      children: <Widget>[
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: AppColors.brandBlue,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _sectors[i].name.trim(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              color: AppColors.textPrimary,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          );
        }
        return Container(
          constraints: BoxConstraints(maxHeight: sheetHeight * 0.82),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0E0E0),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Verification Sectors',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: const Text(
                    'These are the industries we offer',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      color: AppColors.textSecondary,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              body,
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<AuthState> authAsync = ref.watch(authNotifierProvider);
    final dynamic profile = authAsync.value?.userProfile;
    final String serviceType = (profile?.serviceType ?? '')
        .toString()
        .trim()
        .toLowerCase();
    final String displayName =
        profile?.organizationName?.trim().isNotEmpty == true
        ? profile!.organizationName!.trim()
        : (profile?.fullName?.trim().isNotEmpty == true
              ? profile!.fullName!.trim()
              : 'Organisation');
    final String headerLine2 = serviceType.isNotEmpty
        ? '${_toTitleCase(serviceType)} organisation'
        : 'Organisation dashboard';

    final String query = _query.trim().toLowerCase();
    final List<VerificationIndustryType> visibleSectors = query.isEmpty
        ? _sectors
        : _sectors
              .where(
                (VerificationIndustryType sector) =>
                    sector.name.toLowerCase().contains(query),
              )
              .toList();

    final double width = MediaQuery.sizeOf(context).width;
    final double bottomInset = MediaQuery.paddingOf(context).bottom;
    final double scale = (width / 430).clamp(0.78, 0.92);
    final double horizontalInset = (22.0 * scale).clamp(18.0, 22.0).toDouble();

    return Scaffold(
      backgroundColor: AppColors.brandBlue,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light.copyWith(
          statusBarColor: AppColors.brandBlue,
        ),
        child: SafeArea(
          top: true,
          bottom: false,
          left: false,
          right: false,
          child: Container(
            color: Colors.white,
            child: RefreshIndicator(
              color: AppColors.brandBlue,
              onRefresh: _refreshDashboard,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: <Widget>[
                  // ---- One single blue header: org row scrolls away,
                  // search stays pinned, promo scrolls away. ----
                  SliverPersistentHeader(
                    pinned: false,
                    delegate: _LocationBarDelegate(
                      scale: scale,
                      horizontalInset: horizontalInset,
                      orgName: displayName,
                      orgCaption: headerLine2,
                      onAlertsTap: () =>
                          context.go('${AppRouter.notificationsPath}?flow=org'),
                      onProfileTap: () => context.go(AppRouter.settingsPath),
                    ),
                  ),
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _StickySearchDelegate(
                      scale: scale,
                      horizontalInset: horizontalInset,
                      controller: _searchController,
                      query: _query,
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: _PromoBanner(
                      scale: scale,
                      horizontalInset: horizontalInset,
                      onNewBatch: () => _onTapNewBatch(serviceType),
                    ),
                  ),

                  // ---- Body (scrolls under the sticky search) ----
                  SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            horizontalInset,
                            36 * scale,
                            horizontalInset,
                            22 * scale,
                          ),
                          child: _SectionHeader(
                            title: 'Verification Sectors',
                            onViewAll: _showAllSectorsSheet,
                          ),
                        ),
                        _SectorGridBody(
                          loading: _sectorsLoading,
                          error: _sectorsError,
                          sectors: visibleSectors,
                          hasQuery: query.isNotEmpty,
                          scale: scale,
                          horizontalInset: horizontalInset,
          onRetry: _loadSectors,
        ),
                        SizedBox(height: 28 * scale),
                        Center(
                          child: Image.asset(
                            'assets/verification_badge.png',
                            width: 200 * scale,
                            height: 200 * scale,
                            fit: BoxFit.contain,
                            semanticLabel: 'Verification badge',
                          ),
                        ),
                        SizedBox(height: 16 * scale),
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: horizontalInset,
                          ),
                          child: Center(
                            child: Column(
                              children: <Widget>[
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    'Trust, sealed on blockchain.',
                                    maxLines: 1,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: AppColors.textPrimary,
                                      fontFamily: 'Inter',
                                      fontSize: 22 * scale,
                                      height: 1.15,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                ),
                                SizedBox(height: 8 * scale),
                                Text(
                                  'Bulk-issue tamper-proof certificates for people and products — verified in one tap.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontFamily: 'Inter',
                                    fontSize: 13 * scale,
                                    height: 1.45,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 20 * scale),
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: horizontalInset,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              _TrustItem(
                                scale: scale,
                                icon: LucideIcons.badgeCheck,
                                label: 'Top rated\nexperts',
                              ),
                              _TrustItem(
                                scale: scale,
                                icon: LucideIcons.flaskConical,
                                label: 'Professionally\ntested',
                              ),
                              _TrustItem(
                                scale: scale,
                                icon: LucideIcons.userShield,
                                label: 'Background\nverified',
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 120 + bottomInset),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TrustItem extends StatelessWidget {
  const _TrustItem({
    required this.scale,
    required this.icon,
    required this.label,
  });

  final double scale;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, color: AppColors.brandBlue, size: 36 * scale),
          SizedBox(height: 8 * scale),
          Text(
            label,
            maxLines: 2,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.black,
              fontFamily: 'Inter',
              fontSize: 11 * scale,
              height: 1.35,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectorGridBody extends StatelessWidget {
  const _SectorGridBody({
    required this.loading,
    required this.error,
    required this.sectors,
    required this.hasQuery,
    required this.scale,
    required this.horizontalInset,
    required this.onRetry,
  });

  final bool loading;
  final String? error;
  final List<VerificationIndustryType> sectors;
  final bool hasQuery;
  final double scale;
  final double horizontalInset;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: horizontalInset),
        child: GridView.builder(
          itemCount: 6,
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 16 * scale,
            crossAxisSpacing: 16 * scale,
            childAspectRatio: 0.78,
          ),
          itemBuilder: (BuildContext context, int index) {
            return Column(
              children: <Widget>[
                AspectRatio(
                  aspectRatio: 1,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.divider.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
                SizedBox(height: 8 * scale),
                Container(
                  height: 12 * scale,
                  width: 56 * scale,
                  decoration: BoxDecoration(
                    color: AppColors.divider.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ],
            );
          },
        ),
      );
    }
    if (error != null) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: horizontalInset),
        child: TMZCard(
          padding: const EdgeInsets.all(AppSpacing.x4),
          child: Row(
            children: <Widget>[
              const Icon(Icons.error_outline, color: AppColors.error),
              const SizedBox(width: AppSpacing.x3),
              const Expanded(
                child: Text(
                  'Unable to load sectors',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              TextButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }
    final List<VerificationIndustryType> tiles = sectors.take(6).toList();
    if (tiles.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: horizontalInset),
        child: TMZCard(
          padding: const EdgeInsets.all(AppSpacing.x4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                hasQuery
                    ? 'No sectors match your search'
                    : 'No sectors available',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppSpacing.x1),
              const Text(
                'Start a new batch to verify any sector.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalInset),
      child: GridView.builder(
        itemCount: tiles.length,
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 16 * scale,
          crossAxisSpacing: 16 * scale,
          childAspectRatio: 0.78,
        ),
        itemBuilder: (BuildContext context, int index) {
          final VerificationIndustryType sector = tiles[index];
          return _SectorGridTile(sector: sector, scale: scale);
        },
      ),
    );
  }
}

/// Location bar delegate: fixed 64px blue strip, scrolls away.
class _LocationBarDelegate extends SliverPersistentHeaderDelegate {
  _LocationBarDelegate({
    required this.scale,
    required this.horizontalInset,
    required this.orgName,
    required this.orgCaption,
    required this.onAlertsTap,
    required this.onProfileTap,
  });

  final double scale;
  final double horizontalInset;
  final String orgName;
  final String orgCaption;
  final VoidCallback onAlertsTap;
  final VoidCallback onProfileTap;

  @override
  double get minExtent => 64;

  @override
  double get maxExtent => 64;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: AppColors.brandBlue,
      padding: EdgeInsets.symmetric(horizontal: horizontalInset, vertical: 10),
      child: _LocationBar(
        scale: scale,
        orgName: orgName,
        orgCaption: orgCaption,
        onAlertsTap: onAlertsTap,
        onProfileTap: onProfileTap,
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _LocationBarDelegate oldDelegate) =>
      oldDelegate.scale != scale ||
      oldDelegate.horizontalInset != horizontalInset ||
      oldDelegate.orgName != orgName ||
      oldDelegate.orgCaption != orgCaption;
}

class _LocationBar extends StatelessWidget {
  const _LocationBar({
    required this.scale,
    required this.orgName,
    required this.orgCaption,
    required this.onAlertsTap,
    required this.onProfileTap,
  });

  final double scale;
  final String orgName;
  final String orgCaption;
  final VoidCallback onAlertsTap;
  final VoidCallback onProfileTap;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.brandBlue,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Container(
            width: 38 * scale,
            height: 38 * scale,
            decoration: BoxDecoration(
              color: AppColors.brandBlue,
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.18),
                width: 1,
              ),
            ),
            child: Icon(
              LucideIcons.building2,
              color: Colors.white,
              size: 20 * scale,
            ),
          ),
          SizedBox(width: 10 * scale),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'YOUR ORGANISATION',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.68),
                    fontFamily: 'Inter',
                    fontSize: 10 * scale,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.9,
                  ),
                ),
                SizedBox(height: 2 * scale),
                Row(
                  children: <Widget>[
                    Flexible(
                      child: Text(
                        orgName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'Inter',
                          fontSize: 16.5 * scale,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                          height: 1.1,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          _CircleAction(
            scale: scale,
            icon: LucideIcons.bell,
            hasDot: true,
            onTap: onAlertsTap,
          ),
          SizedBox(width: 10 * scale),
          GestureDetector(
            onTap: onProfileTap,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: EdgeInsets.all(10 * scale),
              child: Icon(
                LucideIcons.userRound,
                color: Colors.white,
                size: 24 * scale,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleAction extends StatelessWidget {
  const _CircleAction({
    required this.scale,
    required this.icon,
    required this.onTap,
    this.hasDot = false,
  });

  final double scale;
  final IconData icon;
  final VoidCallback onTap;
  final bool hasDot;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: EdgeInsets.all(10 * scale),
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            Icon(icon, color: Colors.white, size: 24 * scale),
            if (hasDot)
              Positioned(
                right: 1 * scale,
                top: 2 * scale,
                child: Container(
                  width: 8 * scale,
                  height: 8 * scale,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFBBF24),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Pinned search delegate: fixed 68px blue strip with a white search card.
class _StickySearchDelegate extends SliverPersistentHeaderDelegate {
  _StickySearchDelegate({
    required this.scale,
    required this.horizontalInset,
    required this.controller,
    required this.query,
  });

  final double scale;
  final double horizontalInset;
  final TextEditingController controller;
  final String query;

  @override
  double get minExtent => 68;

  @override
  double get maxExtent => 68;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: AppColors.brandBlue,
      padding: EdgeInsets.fromLTRB(horizontalInset, 8, horizontalInset, 8),
      child: SizedBox(
        height: 52,
        child: TextField(
          controller: controller,
          maxLines: 1,
          cursorColor: AppColors.brandBlue,
          style: const TextStyle(
            fontFamily: 'Inter',
            color: AppColors.textPrimary,
            fontSize: 14.5,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.1,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            isDense: true,
            contentPadding: EdgeInsets.zero,
            prefixIcon: const Padding(
              padding: EdgeInsets.only(left: 16, right: 12),
              child: Icon(
                LucideIcons.search,
                color: AppColors.textTertiary,
                size: 20,
              ),
            ),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 48,
              minHeight: 52,
            ),
            suffixIcon: query.isEmpty
                ? null
                : IconButton(
                    onPressed: controller.clear,
                    icon: const Icon(
                      LucideIcons.x,
                      color: AppColors.textTertiary,
                      size: 18,
                    ),
                  ),
            hintText: 'Search batches…',
            hintStyle: const TextStyle(
              fontFamily: 'Inter',
              color: AppColors.textTertiary,
              fontSize: 14.5,
              fontWeight: FontWeight.w500,
              letterSpacing: -0.1,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _StickySearchDelegate oldDelegate) =>
      oldDelegate.scale != scale ||
      oldDelegate.horizontalInset != horizontalInset ||
      oldDelegate.query != query;
}

/// Promo banner: blue card that scrolls away below the sticky search, with
/// dot texture, headline, CTA + stats hero card. The outer container owns
/// the bottom curve so corners round into the white body.
class _PromoBanner extends StatelessWidget {
  const _PromoBanner({
    required this.scale,
    required this.horizontalInset,
    required this.onNewBatch,
  });

  final double scale;
  final double horizontalInset;
  final VoidCallback onNewBatch;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.brandBlue,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          horizontalInset,
          2 * scale,
          horizontalInset,
          18 * scale,
        ),
        child: GestureDetector(
          onTap: onNewBatch,
          behavior: HitTestBehavior.opaque,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18 * scale),
            child: Transform.scale(
              scale: 1.04,
              child: Image.asset(
                'assets/Gemini_Generated_Image_za0202za0202za02.png',
                width: double.infinity,
                height: 158 * scale,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.onViewAll});

  final String title;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontFamily: 'Inter',
              fontSize: 17,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
              height: 1.15,
            ),
          ),
        ),
        TextButton.icon(
          onPressed: onViewAll,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.brandBlue,
            padding: EdgeInsets.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            minimumSize: Size.zero,
          ),
          iconAlignment: IconAlignment.end,
          label: const Text(
            'View all',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.1,
            ),
          ),
          icon: const Icon(LucideIcons.chevronRight, size: 16),
        ),
      ],
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
  if (lower.contains('agriculture')) {
    return 'assets/images/sectors/agriculture.jpg';
  }
  if (lower.contains('health')) return 'assets/images/sectors/healthcare.jpg';
  if (lower.contains('industrial')) {
    return 'assets/images/sectors/industrial.jpg';
  }
  if (lower.contains('insurance')) return 'assets/images/sectors/insurance.jpg';
  if (lower.contains('luxury')) return 'assets/images/sectors/luxury.jpg';
  if (lower.contains('ev') || lower.contains('automotive')) {
    return 'assets/images/sectors/ev.jpg';
  }
  return 'assets/images/sectors/others.jpg';
}

class _SectorGridTile extends StatelessWidget {
  const _SectorGridTile({required this.sector, required this.scale});

  final VerificationIndustryType sector;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final _SectorStyle style = _sectorStyle(sector.name);

    return Column(
      children: <Widget>[
        AspectRatio(
          aspectRatio: 1,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: style.tint,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: AppColors.divider),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 12 * scale,
                  offset: Offset(0, 6 * scale),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.asset(
                _imageAssetForSector(sector.name),
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
          ),
        ),
        SizedBox(height: 8 * scale),
        Text(
          _shortSectorLabel(sector.name),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontFamily: 'Inter',
            fontSize: 13 * scale,
            fontWeight: FontWeight.w400,
            letterSpacing: -0.1,
            height: 1.15,
          ),
        ),
      ],
    );
  }
}

class _SectorStyle {
  const _SectorStyle({
    required this.icon,
    required this.tint,
    required this.fg,
  });

  final IconData icon;
  final Color tint;
  final Color fg;
}

_SectorStyle _sectorStyle(String name) {
  final String key = name.toLowerCase();
  if (key.contains('electronics') || key.contains('appliance')) {
    return const _SectorStyle(
      icon: LucideIcons.cpu,
      tint: Color(0xFFDBEAFE),
      fg: AppColors.brandBlue,
    );
  }
  if (key.contains('beauty') || key.contains('cosmetics')) {
    return const _SectorStyle(
      icon: LucideIcons.sparkles,
      tint: Color(0xFFFFE4E6),
      fg: Color(0xFFE11D48),
    );
  }
  if (key.contains('agriculture')) {
    return const _SectorStyle(
      icon: LucideIcons.sprout,
      tint: Color(0xFFDCFCE7),
      fg: Color(0xFF15803D),
    );
  }
  if (key.contains('health')) {
    return const _SectorStyle(
      icon: LucideIcons.heartPulse,
      tint: Color(0xFFFFE4E6),
      fg: Color(0xFFB91C1C),
    );
  }
  if (key.contains('industrial') || key.contains('manufacturing')) {
    return const _SectorStyle(
      icon: LucideIcons.factory,
      tint: Color(0xFFFEF3C7),
      fg: Color(0xFFD97706),
    );
  }
  if (key.contains('insurance')) {
    return const _SectorStyle(
      icon: LucideIcons.umbrella,
      tint: Color(0xFFCFFAFE),
      fg: Color(0xFF0E7490),
    );
  }
  if (key.contains('luxury')) {
    return const _SectorStyle(
      icon: LucideIcons.gem,
      tint: Color(0xFFEDE9FE),
      fg: Color(0xFF7C3AED),
    );
  }
  if (key.contains('ev') ||
      key.contains('automotive') ||
      key.contains('transport')) {
    return const _SectorStyle(
      icon: LucideIcons.car,
      tint: Color(0xFFCFFAFE),
      fg: Color(0xFF0369A1),
    );
  }
  if (key.contains('education')) {
    return const _SectorStyle(
      icon: LucideIcons.graduationCap,
      tint: Color(0xFFEDE9FE),
      fg: Color(0xFF6D28D9),
    );
  }
  if (key.contains('security')) {
    return const _SectorStyle(
      icon: LucideIcons.shield,
      tint: Color(0xFFDBEAFE),
      fg: Color(0xFF1D4ED8),
    );
  }
  if (key.contains('consumer')) {
    return const _SectorStyle(
      icon: LucideIcons.shoppingBag,
      tint: Color(0xFFFEF3C7),
      fg: Color(0xFFB45309),
    );
  }
  return const _SectorStyle(
    icon: LucideIcons.package,
    tint: Color(0xFFDBEAFE),
    fg: AppColors.brandBlue,
  );
}

String _shortSectorLabel(String name) {
  final String key = name.trim().toLowerCase();
  if (key.contains('electronics') || key.contains('appliance')) {
    return 'Electronics';
  }
  if (key.contains('beauty') || key.contains('cosmetics')) return 'Beauty';
  if (key.contains('agriculture')) return 'Agriculture';
  if (key.contains('health')) return 'Healthcare';
  if (key.contains('industrial')) return 'Industrial';
  if (key.contains('manufacturing')) return 'Manufacturing';
  if (key.contains('insurance')) return 'Insurance';
  if (key.contains('luxury')) return 'Luxury';
  if (key.contains('automotive') || key == 'ev' || key.startsWith('ev ')) {
    return 'Automotive';
  }
  if (key.contains('transport')) return 'Transport';
  if (key.contains('education')) return 'Education';
  if (key.contains('security')) return 'Security';
  if (key.contains('consumer')) return 'Consumer Goods';
  final String trimmed = name.trim();
  if (trimmed.length <= 18) return trimmed;
  return '${trimmed.substring(0, 17)}…';
}

String _toTitleCase(String value) {
  final String trimmed = value.trim();
  if (trimmed.isEmpty) return trimmed;
  return trimmed
      .split(RegExp(r'\s+'))
      .where((String part) => part.isNotEmpty)
      .map((String part) {
        if (part.length == 1) return part.toUpperCase();
        return '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}';
      })
      .join(' ');
}

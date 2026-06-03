import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import 'dart:math' as math;

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/models/verification_models.dart';
import '../../../../core/services/batch_name_store.dart';
import '../../application/verification_list_notifier.dart';

class AllBatchesPage extends ConsumerStatefulWidget {
  const AllBatchesPage({super.key});

  @override
  ConsumerState<AllBatchesPage> createState() => _AllBatchesPageState();
}

class _AllBatchesPageState extends ConsumerState<AllBatchesPage> {
  final TextEditingController _searchController = TextEditingController();
  _BatchTab _tab = _BatchTab.all;

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(
      () =>
          ref.read(verificationListNotifierProvider.notifier).load(limit: 500),
    );
    _searchController.addListener(() {
      if (!mounted) return;
      setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const double refWidth = 402;
    final VerificationListState state = ref.watch(
      verificationListNotifierProvider,
    );
    final AsyncValue<VerificationListResponse> dataAsync = state.data;

    final VerificationListResponse? data = dataAsync.valueOrNull;
    final Map<String, String> savedBatchNames = ref.watch(
      batchNameStoreProvider,
    );
    final List<_BatchDirectoryItem> directory = data == null
        ? const <_BatchDirectoryItem>[]
        : _BatchDirectoryItem.fromUsers(
            data.users,
            savedBatchNames: savedBatchNames,
          );

    final int totalBatches = directory.length;
    final int pending = data?.pending ?? 0;
    final int verified = data?.verified ?? 0;
    final int failed = data?.failed ?? 0;

    final String search = _searchController.text.trim().toLowerCase();
    final List<_BatchDirectoryItem> filtered = directory.where((
      _BatchDirectoryItem item,
    ) {
      if (_tab != _BatchTab.all && _tab != _tabForItem(item)) return false;
      if (search.isEmpty) return true;
      return item.batchName.toLowerCase().contains(search) ||
          item.batchId.toLowerCase().contains(search) ||
          item.createdLabel.toLowerCase().contains(search);
    }).toList();

    final double safeTop = MediaQuery.paddingOf(context).top;
    final double safeBottom = MediaQuery.viewPaddingOf(context).bottom;
    final double screenWidth = MediaQuery.sizeOf(context).width;
    final double contentWidth = math.min(screenWidth, refWidth);
    final double scale = contentWidth / refWidth;
    double s(double v) => v * scale;

    // Figma positions are relative to a 44px status bar.
    final double bgTop = safeTop + s(61); // 105 - 44
    final double searchTop = safeTop + s(85); // 129 - 44
    final double topSectionHeight = safeTop + s(419); // 463 - 44
    final double pagePad = s(16);

    return Scaffold(
      backgroundColor: AppColors.brandBlue,
      body: Stack(
        children: <Widget>[
          const Positioned.fill(child: ColoredBox(color: AppColors.brandBlue)),
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: <Widget>[
              SliverToBoxAdapter(
                child: SizedBox(
                  height: topSectionHeight,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: <Widget>[
                      Positioned(
                        left: 0,
                        right: 0,
                        top: bgTop,
                        bottom: 0,
                        child: const DecoratedBox(
                          decoration: BoxDecoration(
                            color: Color(0xFFF7F9FC),
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(20),
                              topRight: Radius.circular(20),
                            ),
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.topCenter,
                        child: SizedBox(
                          width: contentWidth,
                          child: Stack(
                            children: <Widget>[
                              Positioned(
                                left: pagePad,
                                right: pagePad,
                                top: safeTop,
                                height: s(40),
                                child: _AllBatchesHeader(
                                  scale: scale,
                                  title: 'All Batches',
                                  avatarAssetPath:
                                      'assets/icons/dashbaord/profile.png',
                                  onAlertsTap: () =>
                                      context.push(AppRouter.notificationsPath),
                                  onProfileTap: () =>
                                      context.push(AppRouter.settingsPath),
                                ),
                              ),
                              Positioned(
                                left: pagePad,
                                right: pagePad,
                                top: searchTop,
                                child: _FigmaFilterContainer(
                                  scale: scale,
                                  searchController: _searchController,
                                  selected: _tab,
                                  onSelect: (_BatchTab t) =>
                                      setState(() => _tab = t),
                                  totalBatches: totalBatches,
                                  pendingRecords: pending,
                                  verifiedRecords: verified,
                                  failedRecords: failed,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Container(
                  color: const Color(0xFFF7F9FC),
                  alignment: Alignment.topCenter,
                  child: SizedBox(
                    width: contentWidth,
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(pagePad, 0, pagePad, 0),
                      child: _BatchDirectoryHeader(
                        onTapSeeAll: () => setState(() {
                          _tab = _BatchTab.all;
                        }),
                      ),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Container(
                  color: const Color(0xFFF7F9FC),
                  alignment: Alignment.topCenter,
                  child: SizedBox(
                    width: contentWidth,
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        pagePad,
                        s(11),
                        pagePad,
                        s(71.016) + safeBottom + s(140),
                      ),
                      child: _BatchesListBody(
                        dataAsync: dataAsync,
                        filtered: filtered,
                        onRetry: () => ref
                            .read(verificationListNotifierProvider.notifier)
                            .load(limit: 500),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BatchesListBody extends StatelessWidget {
  const _BatchesListBody({
    required this.dataAsync,
    required this.filtered,
    required this.onRetry,
  });

  final AsyncValue<VerificationListResponse> dataAsync;
  final List<_BatchDirectoryItem> filtered;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (dataAsync.isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 30),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (dataAsync.hasError) {
      return _ErrorCard(message: dataAsync.error.toString(), onRetry: onRetry);
    }
    return Column(
      children: <Widget>[
        for (int i = 0; i < filtered.length; i++) ...<Widget>[
          _BatchDirectoryCard(item: filtered[i]),
          if (i != filtered.length - 1) const SizedBox(height: 11),
        ],
        if (filtered.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 20),
            child: Center(
              child: Text(
                'No batches found',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  height: 20 / 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF94A3B8),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _AllBatchesHeader extends StatelessWidget {
  const _AllBatchesHeader({
    required this.scale,
    required this.title,
    required this.avatarAssetPath,
    this.onAlertsTap,
    this.onProfileTap,
  });

  final double scale;
  final String title;
  final String avatarAssetPath;
  final VoidCallback? onAlertsTap;
  final VoidCallback? onProfileTap;

  @override
  Widget build(BuildContext context) {
    // Responsive: scale all Figma coordinates from the 402px reference width.
    double s(double v) => v * scale;

    return SizedBox(
      width: 370 * scale,
      height: 40 * scale,
      child: Stack(
        children: <Widget>[
          Positioned(
            left: 0,
            top: s(10),
            width: s(212.829),
            height: s(20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: s(21),
                  height: 19.5 / 21,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          Positioned(
            left: s(302),
            top: s(8),
            width: s(24),
            height: s(24),
            child: GestureDetector(
              onTap: onAlertsTap,
              behavior: HitTestBehavior.opaque,
              child: SvgPicture.asset(
                'assets/icons/figma/all_batches_bell.svg',
                width: s(24),
                height: s(24),
              ),
            ),
          ),
          Positioned(
            left: s(338),
            top: s(4),
            width: s(32),
            height: s(32),
            child: GestureDetector(
              onTap: onProfileTap,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(9999),
                child: Container(
                  width: s(32),
                  height: s(32),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFE2E8F0),
                      width: s(1),
                    ),
                  ),
                  child: ClipOval(
                    child: Image.asset(avatarAssetPath, fit: BoxFit.cover),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _BatchTab { all, processing, verified, failed }

_BatchTab _tabForItem(_BatchDirectoryItem item) {
  if (item.failedCount > 0) return _BatchTab.failed;
  if (item.verifiedCount == item.records && item.records > 0) {
    return _BatchTab.verified;
  }
  return _BatchTab.processing;
}

class _FigmaSearchField extends StatelessWidget {
  const _FigmaSearchField({required this.scale, required this.controller});

  final double scale;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    // Keep the search field height and inner spacing consistent with Figma,
    // even on small screens (avoid the "thin pill" look).
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              offset: const Offset(0, 1),
              blurRadius: 2,
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(16, 14.5, 16, 14.5),
        child: Row(
          children: <Widget>[
            SvgPicture.asset(
              'assets/icons/figma/all_batches_search.svg',
              width: 16,
              height: 16,
              colorFilter: const ColorFilter.mode(
                Color(0xFF9CA3AF),
                BlendMode.srcIn,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: controller,
                maxLines: 1,
                cursorColor: AppColors.brandBlue,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  height: 16.943182 / 14,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF0B0F19),
                ),
                decoration: const InputDecoration(
                  isCollapsed: true,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  focusedErrorBorder: InputBorder.none,
                  hintText: 'Search batch ID or date…',
                  hintStyle: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    height: 16.943182 / 14,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF9CA3AF),
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

class _FigmaFilterContainer extends StatelessWidget {
  const _FigmaFilterContainer({
    required this.scale,
    required this.searchController,
    required this.selected,
    required this.onSelect,
    required this.totalBatches,
    required this.pendingRecords,
    required this.verifiedRecords,
    required this.failedRecords,
  });

  final double scale;
  final TextEditingController searchController;
  final _BatchTab selected;
  final ValueChanged<_BatchTab> onSelect;
  final int totalBatches;
  final int pendingRecords;
  final int verifiedRecords;
  final int failedRecords;

  @override
  Widget build(BuildContext context) {
    // Responsive stack: keep vertical rhythm identical to Figma, but allow width
    // to adapt to the screen.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _FigmaSearchField(scale: scale, controller: searchController),
        const SizedBox(height: 16),
        _FigmaTabsRow(scale: scale, selected: selected, onSelect: onSelect),
        const SizedBox(height: 16),
        _FigmaStatsGrid(
          scale: scale,
          totalBatches: totalBatches,
          pendingRecords: pendingRecords,
          verifiedRecords: verifiedRecords,
          failedRecords: failedRecords,
        ),
      ],
    );
  }
}

class _FigmaTabsRow extends StatelessWidget {
  const _FigmaTabsRow({
    required this.scale,
    required this.selected,
    required this.onSelect,
  });

  final double scale;
  final _BatchTab selected;
  final ValueChanged<_BatchTab> onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 370 * scale,
      height: 32 * scale,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          _FigmaTabButton(
            scale: scale,
            label: 'All',
            width: 44.73396301269531,
            height: 29.830284118652344,
            selected: selected == _BatchTab.all,
            onTap: () => onSelect(_BatchTab.all),
          ),
          SizedBox(width: 5.61 * scale),
          _FigmaTabButton(
            scale: scale,
            label: 'Processing',
            width: 89.73396301269531,
            height: 28.29358673095703,
            selected: selected == _BatchTab.processing,
            onTap: () => onSelect(_BatchTab.processing),
          ),
          SizedBox(width: 6.92 * scale),
          _FigmaTabButton(
            scale: scale,
            label: 'Verified',
            width: 71.71475219726562,
            height: 28.29358673095703,
            selected: selected == _BatchTab.verified,
            onTap: () => onSelect(_BatchTab.verified),
          ),
          SizedBox(width: 7.69 * scale),
          _FigmaTabButton(
            scale: scale,
            label: 'Failed',
            width: 62.73396301269531,
            height: 28.29358673095703,
            selected: selected == _BatchTab.failed,
            onTap: () => onSelect(_BatchTab.failed),
          ),
        ],
      ),
    );
  }
}

class _FigmaTabButton extends StatelessWidget {
  const _FigmaTabButton({
    required this.scale,
    required this.label,
    required this.width,
    required this.height,
    required this.selected,
    required this.onTap,
  });

  final double scale;
  final String label;
  final double width;
  final double height;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    double s(double v) => v * scale;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(s(12)),
      child: Container(
        width: s(width),
        height: s(height),
        decoration: BoxDecoration(
          color: selected ? AppColors.brandBlue : Colors.white,
          borderRadius: BorderRadius.circular(s(12)),
          border: Border.all(
            color: selected ? AppColors.brandBlue : const Color(0xFFE5E7EB),
            width: s(selected ? 1.7988859415054321 : 0.7683491706848145),
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: s(10.756889343261719),
            height: 15.366982460021973 / 10.756889343261719,
            fontWeight: FontWeight.w600,
            letterSpacing: label == 'All'
                ? 0.21009549498558044
                : label == 'Processing'
                ? 0.04201909899711609
                : label == 'Failed'
                ? 0.05252387374639511
                : 0,
            color: selected ? Colors.white : const Color(0xFF4B5563),
          ),
        ),
      ),
    );
  }
}

class _FigmaStatsGrid extends StatelessWidget {
  const _FigmaStatsGrid({
    required this.scale,
    required this.totalBatches,
    required this.pendingRecords,
    required this.verifiedRecords,
    required this.failedRecords,
  });

  final double scale;
  final int totalBatches;
  final int pendingRecords;
  final int verifiedRecords;
  final int failedRecords;

  @override
  Widget build(BuildContext context) {
    double s(double v) => v * scale;
    return SizedBox(
      width: 370 * scale,
      height: 198.48 * scale,
      child: Stack(
        children: <Widget>[
          Positioned(
            left: 0,
            top: 0,
            child: _FigmaStatCard(
              scale: scale,
              label: 'Total Batches',
              value: totalBatches.toString(),
              labelColor: AppColors.brandBlue,
            ),
          ),
          Positioned(
            left: s(191.47),
            top: 0,
            child: _FigmaStatCard(
              scale: scale,
              label: 'Pending',
              value: pendingRecords.toString(),
              labelColor: const Color(0xFFF59E0B),
              labelLetterSpacing: 0.15169461071491241,
            ),
          ),
          Positioned(
            left: 0,
            top: s(105.71),
            child: _FigmaStatCard(
              scale: scale,
              label: 'Verified',
              value: verifiedRecords.toString(),
              labelColor: const Color(0xFF10B981),
              labelLetterSpacing: 0.08848852291703224,
            ),
          ),
          Positioned(
            left: s(191.47),
            top: s(105.71),
            child: _FigmaStatCard(
              scale: scale,
              label: 'Failed',
              value: failedRecords.toString(),
              labelColor: const Color(0xFFEF4444),
              labelLetterSpacing: 0.12641217559576035,
            ),
          ),
        ],
      ),
    );
  }
}

class _FigmaStatCard extends StatelessWidget {
  const _FigmaStatCard({
    required this.scale,
    required this.label,
    required this.value,
    required this.labelColor,
    this.labelLetterSpacing,
  });

  final double scale;
  final String label;
  final String value;
  final Color labelColor;
  final double? labelLetterSpacing;

  @override
  Widget build(BuildContext context) {
    double s(double v) => v * scale;
    return Container(
      width: s(178.52769470214844),
      height: s(91.83381652832031),
      padding: EdgeInsets.all(s(17.259475708007812)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(s(12.94460678100586)),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: s(1.0787172317504883),
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.024),
            offset: Offset(0, s(1.0787172317504883)),
            blurRadius: s(2.1574344635009766),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: Offset(0, s(1.0787172317504883)),
            blurRadius: s(3.236151695251465),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textHeightBehavior: const TextHeightBehavior(
              applyHeightToFirstAscent: false,
              applyHeightToLastDescent: false,
            ),
            style: TextStyle(
              fontFamily: 'SF Pro Rounded',
              fontSize: s(12.94460678100586),
              height: 17.259475708007812 / 12.94460678100586,
              fontWeight: FontWeight.w500,
              letterSpacing: labelLetterSpacing ?? -0.012641217559576035,
              color: labelColor,
            ),
          ),
          SizedBox(height: s(4.314868927001953)),
          Text(
            value,
            textHeightBehavior: const TextHeightBehavior(
              applyHeightToFirstAscent: false,
              applyHeightToLastDescent: false,
            ),
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: s(25.88921356201172),
              height: 34.518951416015625 / 25.88921356201172,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0B0F19),
            ),
          ),
        ],
      ),
    );
  }
}

class _BatchDirectoryHeader extends StatelessWidget {
  const _BatchDirectoryHeader({required this.onTapSeeAll});

  final VoidCallback onTapSeeAll;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 29,
      child: Row(
        children: <Widget>[
          const Expanded(
            child: Text(
              'BATCH DIRECTORY',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                height: 17.750728607177734 / 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.1833819150924683,
                color: Color(0xFF323232),
              ),
            ),
          ),
          TextButton(
            onPressed: onTapSeeAll,
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
              foregroundColor: AppColors.brandBlue,
            ),
            child: const Text(
              'See All',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 15.008000373840332,
                height: 21.440000534057617 / 15.008000373840332,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.0586250014603138,
                color: AppColors.brandBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _BatchStatus { completed, processing, alert }

class _BatchDirectoryItem {
  const _BatchDirectoryItem({
    required this.batchId,
    required this.batchName,
    required this.status,
    required this.progress,
    required this.records,
    required this.verifiedCount,
    required this.pendingCount,
    required this.failedCount,
    required this.createdLabel,
    required this.createdAt,
    this.alertMessage,
  });

  final String batchId;
  final String batchName;
  final _BatchStatus status;
  final double progress;
  final int records;
  final int verifiedCount;
  final int pendingCount;
  final int failedCount;
  final String createdLabel;
  final DateTime? createdAt;
  final String? alertMessage;

  static List<_BatchDirectoryItem> fromUsers(
    List<VerificationUser> users, {
    Map<String, String> savedBatchNames = const <String, String>{},
  }) {
    final Map<String, List<VerificationUser>> groups =
        <String, List<VerificationUser>>{};
    for (final VerificationUser u in users) {
      final String key = u.batchId.trim().isEmpty
          ? 'unknown'
          : u.batchId.trim();
      (groups[key] ??= <VerificationUser>[]).add(u);
    }

    final List<_BatchDirectoryItem> items = <_BatchDirectoryItem>[];
    for (final MapEntry<String, List<VerificationUser>> e in groups.entries) {
      final List<VerificationUser> groupUsers = e.value;
      String groupBatchName = '';
      int verified = 0;
      int pending = 0;
      int failed = 0;
      DateTime? earliest;
      for (final VerificationUser u in groupUsers) {
        switch (u.verificationStatus) {
          case 'verified':
            verified += 1;
          case 'failed':
            failed += 1;
          default:
            pending += 1;
        }
        final DateTime? created = DateTime.tryParse(u.createdAt);
        if (created != null) {
          if (earliest == null || created.isBefore(earliest)) {
            earliest = created;
          }
        }
        if (groupBatchName.trim().isEmpty && u.batchName.trim().isNotEmpty) {
          groupBatchName = u.batchName.trim();
        }
      }

      final String? stored = savedBatchNames[e.key];
      if (stored != null && stored.trim().isNotEmpty) {
        groupBatchName = stored.trim();
      }

      if (groupBatchName.trim().isEmpty) {
        final String shortId = e.key.length <= 10
            ? e.key
            : e.key.substring(0, 10);
        groupBatchName = 'Batch $shortId';
      }

      final int total = groupUsers.length;
      final double progress = total == 0 ? 0 : (verified / total);
      final _BatchStatus status = failed > 0
          ? _BatchStatus.alert
          : (verified == total
                ? _BatchStatus.completed
                : _BatchStatus.processing);
      final String createdLabel = _formatShortDate(earliest);
      final String? alertMessage = failed > 0
          ? '$failed record(s) failed verification'
          : null;

      items.add(
        _BatchDirectoryItem(
          batchId: e.key,
          batchName: groupBatchName,
          status: status,
          progress: progress,
          records: total,
          verifiedCount: verified,
          pendingCount: pending,
          failedCount: failed,
          createdLabel: createdLabel,
          createdAt: earliest,
          alertMessage: alertMessage,
        ),
      );
    }
    items.sort((a, b) {
      final DateTime? da = a.createdAt;
      final DateTime? db = b.createdAt;
      if (da != null && db != null) return db.compareTo(da);
      if (da != null) return -1;
      if (db != null) return 1;
      return b.createdLabel.compareTo(a.createdLabel);
    });
    return items;
  }

  static String _formatShortDate(DateTime? dt) {
    if (dt == null) return '—';
    const List<String> months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${dt.day.toString().padLeft(2, '0')} ${months[dt.month - 1]}';
  }
}

class _BatchDirectoryCard extends StatelessWidget {
  const _BatchDirectoryCard({required this.item});

  final _BatchDirectoryItem item;

  @override
  Widget build(BuildContext context) {
    final String badgeText = switch (item.status) {
      _BatchStatus.processing => 'Processing',
      _BatchStatus.completed => 'Verified',
      _BatchStatus.alert => 'Failed',
    };

    final Color badgeFg = switch (item.status) {
      _BatchStatus.processing => AppColors.brandBlue,
      _BatchStatus.completed => const Color(0xFF059669),
      _BatchStatus.alert => AppColors.error,
    };

    final Color badgeBg = switch (item.status) {
      _BatchStatus.processing => AppColors.brandBlue.withValues(alpha: 0.10),
      _BatchStatus.completed => const Color(0xFFECFDF5),
      _BatchStatus.alert => const Color(0xFFFEF2F2),
    };

    final double badgeRadius = switch (item.status) {
      _BatchStatus.processing => 4.0,
      _BatchStatus.completed => 4.288000106811523,
      _BatchStatus.alert => 4.0,
    };

    final EdgeInsets badgePadding = switch (item.status) {
      _BatchStatus.processing => const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      _BatchStatus.completed => const EdgeInsets.symmetric(
        horizontal: 8.576000213623047,
        vertical: 2.1440000534057617,
      ),
      _BatchStatus.alert => const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
    };

    final double badgeFontSize = switch (item.status) {
      _BatchStatus.processing => 10,
      _BatchStatus.completed => 10.720000267028809,
      _BatchStatus.alert => 10,
    };

    final double badgeLineHeight = switch (item.status) {
      _BatchStatus.processing => 15 / 10,
      _BatchStatus.completed => 16.079999923706055 / 10.720000267028809,
      _BatchStatus.alert => 15 / 10,
    };

    final double badgeLetterSpacing = switch (item.status) {
      _BatchStatus.processing => -0.25,
      _BatchStatus.completed => 0.1465625036507845,
      _BatchStatus.alert => -0.25,
    };

    final String leftIcon = switch (item.status) {
      _BatchStatus.processing => 'assets/icons/figma/batch_icon_processing.svg',
      _BatchStatus.completed => 'assets/icons/figma/batch_icon_verified.svg',
      _BatchStatus.alert => 'assets/icons/figma/batch_icon_processing.svg',
    };

    final Color leftBg = switch (item.status) {
      _BatchStatus.processing => AppColors.brandBlue.withValues(alpha: 0.05),
      _BatchStatus.completed => const Color(0xFF059669).withValues(alpha: 0.10),
      _BatchStatus.alert => AppColors.error.withValues(alpha: 0.08),
    };

    final bool isProcessing = item.status == _BatchStatus.processing;
    final int pct = (item.progress * 100).round().clamp(0, 100);
    final Color borderColor = const Color(0xFFE2E8F0).withValues(alpha: 0.6);

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double localScale = (constraints.maxWidth / 370).clamp(0.0, 1.0);
        double s(double v) => v * localScale;

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              context.push(
                '${AppRouter.appBatchTrackingDetailPath}?batch_id=${Uri.encodeQueryComponent(item.batchId)}',
              );
            },
            borderRadius: BorderRadius.circular(s(16)),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(s(16)),
                border: Border.all(color: borderColor, width: s(1)),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: s(2),
                    offset: Offset(0, s(1)),
                  ),
                ],
              ),
              padding: EdgeInsets.all(s(20)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Container(
                        width: s(40),
                        height: s(40),
                        decoration: BoxDecoration(
                          color: leftBg,
                          borderRadius: BorderRadius.circular(s(12)),
                        ),
                        alignment: Alignment.center,
                        child: SvgPicture.asset(
                          leftIcon,
                          width: s(20),
                          height: s(20),
                          colorFilter: ColorFilter.mode(
                            badgeFg,
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                      SizedBox(width: s(12)),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              'Batch: ${item.batchName}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'SF Pro Rounded',
                                fontSize: s(14),
                                height: 20 / 14,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.013671875,
                                color: const Color(0xFF0B0F19),
                              ),
                            ),
                            SizedBox(height: s(2)),
                            Text(
                              'Created ${item.createdLabel} • ${_formatInt(item.records)} records',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'SF Pro Rounded',
                                fontSize: s(11),
                                height: 16.5 / 11,
                                fontWeight: FontWeight.w400,
                                letterSpacing: -0.01,
                                color: const Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: badgeBg,
                          borderRadius: BorderRadius.circular(s(badgeRadius)),
                        ),
                        padding: EdgeInsets.fromLTRB(
                          s(badgePadding.left),
                          s(badgePadding.top),
                          s(badgePadding.right),
                          s(badgePadding.bottom),
                        ),
                        child: Text(
                          badgeText.toUpperCase(),
                          style: TextStyle(
                            fontFamily: 'SF Pro Rounded',
                            fontSize: s(badgeFontSize),
                            height: badgeLineHeight,
                            fontWeight: FontWeight.w700,
                            letterSpacing: badgeLetterSpacing,
                            color: badgeFg,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: s(10)),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          'Status: ${_statusLabel(item)}',
                          style: TextStyle(
                            fontFamily: 'SF Pro Rounded',
                            fontSize: s(11),
                            height: 16.5 / 11,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.03,
                            color: const Color(0xFF0B0F19),
                          ),
                        ),
                      ),
                      Text(
                        '$pct%',
                        style: TextStyle(
                          fontFamily: 'SF Pro Rounded',
                          fontSize: s(11),
                          height: 16.5 / 11,
                          fontWeight: FontWeight.w700,
                          color: badgeFg,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: s(10)),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(s(999)),
                    child: LinearProgressIndicator(
                      value: item.progress.clamp(0, 1),
                      minHeight: s(6),
                      backgroundColor: AppColors.divider.withValues(
                        alpha: 0.35,
                      ),
                      valueColor: AlwaysStoppedAnimation<Color>(badgeFg),
                    ),
                  ),
                  SizedBox(height: s(10)),
                  if (isProcessing)
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            '${_formatInt(item.verifiedCount)} / ${_formatInt(item.records)} processed',
                            style: TextStyle(
                              fontFamily: 'SF Pro Rounded',
                              fontSize: s(10),
                              height: 15 / 10,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.03,
                              color: const Color(0xFF94A3B8),
                            ),
                          ),
                        ),
                        Text(
                          '2d 18hrs remaining',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontFamily: 'SF Pro Rounded',
                            fontSize: s(10),
                            height: 15 / 10,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.06,
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    )
                  else
                    Text(
                      'Created ${item.createdLabel} • ${_formatInt(item.records)} records',
                      style: TextStyle(
                        fontFamily: 'SF Pro Rounded',
                        fontSize: s(14),
                        height: 20 / 14,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF94A3B8),
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
}

String _statusLabel(_BatchDirectoryItem item) {
  if (item.failedCount > 0) return 'Needs attention';
  if (item.verifiedCount == item.records && item.records > 0) {
    return 'Completed';
  }
  if (item.verifiedCount == 0 && item.pendingCount == item.records) {
    return 'Pending review';
  }
  return 'Under Review';
}

String _formatInt(int v) {
  final String s = v.toString();
  final StringBuffer b = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    final int remaining = s.length - i;
    b.write(s[i]);
    if (remaining > 1 && remaining % 3 == 1) b.write(',');
  }
  return b.toString();
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFEF2F2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Failed to load batches',
            style: AppTypography.heading2.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: AppTypography.body2.copyWith(color: AppColors.textSecondary),
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
            style: TextButton.styleFrom(foregroundColor: AppColors.brandBlue),
          ),
        ],
      ),
    );
  }
}

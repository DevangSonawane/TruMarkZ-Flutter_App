import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../../../../core/models/verification_models.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/org_top_bar.dart';
import '../../data/verification_repository.dart';

/// MrBob "My bookings" style batch list, Trumarkz colours:
/// unified OrgTopBar on blue, light panel with a dark segmented filter
/// (All | Processing | Verified | Failed), compact rows and an empty
/// state with a create CTA.
class AllBatchesPage extends ConsumerStatefulWidget {
  const AllBatchesPage({super.key});

  @override
  ConsumerState<AllBatchesPage> createState() => _AllBatchesPageState();
}

class _AllBatchesPageState extends ConsumerState<AllBatchesPage> {
  final TextEditingController _searchController = TextEditingController();
  _BatchTab _tab = _BatchTab.all;

  static const List<String> _filters = <String>[
    'All',
    'Processing',
    'Verified',
    'Failed',
  ];

  @override
  void initState() {
    super.initState();
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
    final AsyncValue<List<VerificationBatchSummary>> batchesAsync = ref.watch(
      verificationBatchesProvider,
    );
    final List<VerificationBatchSummary> batches =
        batchesAsync.valueOrNull ?? const <VerificationBatchSummary>[];
    final List<_BatchDirectoryItem> directory = batches
        .map(
          (VerificationBatchSummary item) =>
              _BatchDirectoryItem.fromSummary(item),
        )
        .toList();

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

    final double safeBottom = MediaQuery.viewPaddingOf(context).bottom;
    final double screenWidth = MediaQuery.sizeOf(context).width;
    final double contentWidth = screenWidth < refWidth
        ? screenWidth
        : refWidth;

    return Scaffold(
      backgroundColor: AppColors.brandBlue,
      body: SafeArea(
        bottom: false,
        child: Center(
          child: SizedBox(
            width: contentWidth,
            child: Column(
              children: <Widget>[
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: OrgTopBar(title: 'All Batches'),
                ),
                const SizedBox(height: 21),
                Expanded(
                  child: DecoratedBox(
                    decoration: const BoxDecoration(
                      color: Color(0xFFF7F9FC),
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    child: RefreshIndicator(
                      color: AppColors.brandBlue,
                      onRefresh: () async {
                        ref.invalidate(verificationBatchesProvider);
                        await ref.read(verificationBatchesProvider.future);
                      },
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        padding: EdgeInsets.fromLTRB(
                          16,
                          32,
                          16,
                          140 + safeBottom,
                        ),
                        children: <Widget>[
                          _FilterBar(
                            filters: _filters,
                            selectedIndex: _tab.index,
                            onSelected: (int index) => setState(
                              () => _tab = _BatchTab.values[index],
                            ),
                          ),
                          const SizedBox(height: 16),
                          _SearchField(controller: _searchController),
                          const SizedBox(height: 20),
                          _BatchesListBody(
                            dataAsync: batchesAsync,
                            filtered: filtered,
                            hasQuery: search.isNotEmpty,
                            onRetry: () =>
                                ref.refresh(verificationBatchesProvider),
                          ),
                        ],
                      ),
                    ),
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

/// Dark segmented filter bar mirroring the bookings filter.
class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.filters,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<String> filters;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.deepNavy,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: <Widget>[
          for (int i = 0; i < filters.length; i++)
            Expanded(
              child: GestureDetector(
                onTap: () => onSelected(i),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selectedIndex == i
                        ? Colors.white
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    filters[i],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      color: selectedIndex == i
                          ? AppColors.brandBlue
                          : Colors.white70,
                      fontSize: 12.5,
                      fontWeight: selectedIndex == i
                          ? FontWeight.w800
                          : FontWeight.w600,
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

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: TextField(
        controller: controller,
        maxLines: 1,
        cursorColor: AppColors.brandBlue,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 14.5,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.1,
          color: AppColors.textPrimary,
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
          suffixIcon: controller.text.isEmpty
              ? null
              : IconButton(
                  onPressed: controller.clear,
                  icon: const Icon(
                    LucideIcons.x,
                    color: AppColors.textTertiary,
                    size: 18,
                  ),
                ),
          hintText: 'Search batch ID or date…',
          hintStyle: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 14.5,
            fontWeight: FontWeight.w500,
            letterSpacing: -0.1,
            color: AppColors.textTertiary,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.divider),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.brandBlue),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.divider),
          ),
        ),
      ),
    );
  }
}

class _BatchesListBody extends StatelessWidget {
  const _BatchesListBody({
    required this.dataAsync,
    required this.filtered,
    required this.hasQuery,
    required this.onRetry,
  });

  final AsyncValue<List<VerificationBatchSummary>> dataAsync;
  final List<_BatchDirectoryItem> filtered;
  final bool hasQuery;
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
      return _ErrorCard(
        message: dataAsync.error.toString(),
        onRetry: onRetry,
      );
    }
    if (filtered.isEmpty) {
      return _EmptyState(hasQuery: hasQuery);
    }
    return Column(
      children: <Widget>[
        for (int i = 0; i < filtered.length; i++) ...<Widget>[
          _BatchRowCard(item: filtered[i]),
          if (i != filtered.length - 1) const SizedBox(height: 14),
        ],
      ],
    );
  }
}

/// Compact batch row mirroring the MrBob booking card: tinted icon box,
/// two-line title and a coloured status label.
class _BatchRowCard extends StatelessWidget {
  const _BatchRowCard({required this.item});

  final _BatchDirectoryItem item;

  @override
  Widget build(BuildContext context) {
    final Color fg = switch (item.status) {
      _BatchStatus.processing => AppColors.brandBlue,
      _BatchStatus.completed => AppColors.success,
      _BatchStatus.alert => AppColors.danger,
    };
    final Color tint = switch (item.status) {
      _BatchStatus.processing => const Color(0xFFDBEAFE),
      _BatchStatus.completed => AppColors.successBg,
      _BatchStatus.alert => AppColors.dangerBg,
    };
    final IconData icon = switch (item.status) {
      _BatchStatus.processing => LucideIcons.loader,
      _BatchStatus.completed => LucideIcons.badgeCheck,
      _BatchStatus.alert => LucideIcons.triangleAlert,
    };
    final String statusText = switch (item.status) {
      _BatchStatus.processing => _statusLabel(item),
      _BatchStatus.completed => 'Verified',
      _BatchStatus.alert => 'Needs attention',
    };
    final String modeQuery = item.isWarrantyBatch ? '&mode=warranty' : '';

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        child: InkWell(
          onTap: () {
            context.push(
              '${AppRouter.appBatchTrackingDetailPath}?batch_id=${Uri.encodeQueryComponent(item.batchId)}$modeQuery',
            );
          },
          borderRadius: BorderRadius.circular(15),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 11,
              vertical: 12,
            ),
            child: Row(
              children: <Widget>[
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: tint,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: fg, size: 20),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        'Batch: ${item.batchName}',
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
                      const SizedBox(height: 1),
                      Text(
                        'Created ${item.createdLabel} • ${_formatInt(item.records)} records',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        statusText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          color: fg,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  LucideIcons.chevronRight,
                  color: AppColors.textTertiary,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.hasQuery});

  final bool hasQuery;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 44),
      child: Column(
        children: <Widget>[
          Container(
            width: 76,
            height: 76,
            decoration: const BoxDecoration(
              color: Color(0xFFEEF3FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              LucideIcons.packageOpen,
              color: AppColors.textTertiary,
              size: 30,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            hasQuery ? 'No batches here' : 'No batches yet',
            style: const TextStyle(
              fontFamily: 'Inter',
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            hasQuery
                ? 'Try a different search or filter.'
                : 'Batches you create will appear here. Tap below to start your first batch.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Inter',
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.4,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (!hasQuery) ...<Widget>[
            const SizedBox(height: 18),
            FilledButton(
              onPressed: () =>
                  context.push(AppRouter.batchTypeSelectionPath),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.brandBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              child: const Text(
                'Create batch',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

enum _BatchTab { all, processing, verified, failed }

_BatchTab _tabForItem(_BatchDirectoryItem item) {
  if (item.failedCount > 0 || item.status == _BatchStatus.alert) {
    return _BatchTab.failed;
  }
  if (item.verifiedCount == item.records && item.records > 0) {
    return _BatchTab.verified;
  }
  return _BatchTab.processing;
}

enum _BatchStatus { completed, processing, alert }

class _BatchDirectoryItem {
  const _BatchDirectoryItem({
    required this.batchId,
    required this.batchName,
    required this.status,
    required this.isWarrantyBatch,
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
  final bool isWarrantyBatch;
  final double progress;
  final int records;
  final int verifiedCount;
  final int pendingCount;
  final int failedCount;
  final String createdLabel;
  final DateTime? createdAt;
  final String? alertMessage;

  static _BatchDirectoryItem fromSummary(VerificationBatchSummary item) {
    final DateTime? created = DateTime.tryParse(item.createdAt);
    final int total = item.totalUsers;
    final int verified = item.verified;
    final int failed = item.issueCount;
    final int pending = item.pending;
    final double progress = total == 0 ? 0 : (verified / total);
    final _BatchStatus status = _batchStatusFromSummary(item);
    final String batchName = item.batchName.trim().isNotEmpty
        ? item.batchName.trim()
        : (item.batchId.length <= 10
              ? 'Batch ${item.batchId}'
              : 'Batch ${item.batchId.substring(0, 10)}');

    return _BatchDirectoryItem(
      batchId: item.batchId,
      batchName: batchName,
      status: status,
      isWarrantyBatch: item.isWarrantyBatch,
      progress: progress,
      records: total,
      verifiedCount: verified,
      pendingCount: pending,
      failedCount: failed,
      createdLabel: _formatShortDate(created),
      createdAt: created,
      alertMessage: failed > 0 ? '$failed record(s) failed verification' : null,
    );
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

_BatchStatus _batchStatusFromSummary(VerificationBatchSummary item) {
  final String status = item.status.trim().toLowerCase();
  if (item.hasIssues ||
      status.contains('skip') ||
      status.contains('error') ||
      status.contains('fail')) {
    return _BatchStatus.alert;
  }
  if (status.contains('verified') ||
      status.contains('complete') ||
      item.isComplete) {
    return _BatchStatus.completed;
  }
  return _BatchStatus.processing;
}

String _statusLabel(_BatchDirectoryItem item) {
  if (item.status == _BatchStatus.alert) return 'Needs attention';
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
        border: Border.all(color: AppColors.dangerBg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Failed to load batches',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/models/verification_models.dart';
import '../../application/verification_list_notifier.dart';

class BatchProgressPage extends ConsumerStatefulWidget {
  const BatchProgressPage({super.key});

  @override
  ConsumerState<BatchProgressPage> createState() => _BatchProgressPageState();
}

class _BatchProgressPageState extends ConsumerState<BatchProgressPage> {
  @override
  void initState() {
    super.initState();
    Future<void>.microtask(
      () => ref.read(verificationListNotifierProvider.notifier).load(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final VerificationListState state = ref.watch(
      verificationListNotifierProvider,
    );
    final AsyncValue<VerificationListResponse> dataAsync = state.data;

    final VerificationListResponse? data = dataAsync.valueOrNull;
    final List<_BatchDirectoryItem> directory = data == null
        ? const <_BatchDirectoryItem>[]
        : _BatchDirectoryItem.fromUsers(data.users);

    final int totalBatches = directory.length;
    final int pending = data?.pending ?? 0;
    final int verified = data?.verified ?? 0;
    final int failed = data?.failed ?? 0;

    return Scaffold(
      backgroundColor: AppColors.pageBg,
      body: CustomScrollView(
        slivers: <Widget>[
          SliverAppBar(
            pinned: true,
            elevation: 0,
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            toolbarHeight: 64,
            titleSpacing: 20,
            title: Row(
              children: <Widget>[
                const Icon(
                  Icons.verified_user_outlined,
                  color: AppColors.brandBlue,
                ),
                const SizedBox(width: 10),
                Text(
                  'Batches',
                  style: AppTypography.display2.copyWith(
                    fontSize: 22,
                    color: AppColors.brandBlue,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            actions: <Widget>[
              IconButton(
                tooltip: 'Notifications',
                onPressed: () => context.push(AppRouter.notificationsPath),
                icon: const Icon(Icons.notifications_none_rounded),
              ),
              IconButton(
                tooltip: 'Profile',
                onPressed: () => context.push(AppRouter.settingsPath),
                icon: const Icon(Icons.account_circle_outlined),
              ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: Container(
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1),
                ),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Color(0x142563EB),
                    blurRadius: 12,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(0, 24, 0, 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate.fixed(<Widget>[
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: _BatchSearchField(),
                ),
                const SizedBox(height: 24),
                _SummaryCarousel(
                  items: <_SummaryItem>[
                    _SummaryItem(
                      label: 'Total Batches',
                      value: totalBatches.toString(),
                      valueColor: AppColors.brandBlue,
                      borderColor: const Color(0xFFEFF6FF),
                    ),
                    _SummaryItem(
                      label: 'Pending',
                      value: pending.toString(),
                      valueColor: const Color(0xFFF59E0B),
                      borderColor: const Color(0xFFFFFBEB),
                    ),
                    _SummaryItem(
                      label: 'Verified',
                      value: verified.toString(),
                      valueColor: AppColors.success,
                      borderColor: const Color(0xFFF0FDF4),
                    ),
                    _SummaryItem(
                      label: 'Failed',
                      value: failed.toString(),
                      valueColor: AppColors.error,
                      borderColor: const Color(0xFFFEF2F2),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _StatusFilterRow(
                    selected: state.statusFilter,
                    onSelect: (String? v) => ref
                        .read(verificationListNotifierProvider.notifier)
                        .setFilter(v),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          'Batch Directory',
                          style: AppTypography.heading2.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {},
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.brandBlue,
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                        ),
                        child: Text(
                          'See All',
                          style: AppTypography.body2.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.brandBlue,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (dataAsync.isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (dataAsync.hasError)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _ErrorCard(
                      message: dataAsync.error.toString(),
                      onRetry: () => ref
                          .read(verificationListNotifierProvider.notifier)
                          .load(),
                    ),
                  )
                else ...<Widget>[
                  for (final _BatchDirectoryItem item in directory) ...<Widget>[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _BatchDirectoryCard(item: item),
                    ),
                    const SizedBox(height: 16),
                  ],
                ],
                const SizedBox(height: 110),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _BatchSearchField extends StatelessWidget {
  const _BatchSearchField();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: <Widget>[
        Container(
          height: 54,
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
        ),
        const Positioned(
          left: 14,
          child: Icon(Icons.search, color: AppColors.textTertiary),
        ),
        Positioned.fill(
          child: TextField(
            textAlign: TextAlign.center,
            textAlignVertical: TextAlignVertical.center,
            style: AppTypography.body2.copyWith(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'Find batches...',
              hintStyle: AppTypography.body2.copyWith(
                color: AppColors.textTertiary,
              ),
              isDense: false,
              filled: false,
              fillColor: Colors.transparent,
              // Keep left/right padding symmetric so the centered hint/text
              // stays visually centered even with the left icon.
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 44,
                vertical: 16,
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }
}

class _SummaryItem {
  const _SummaryItem({
    required this.label,
    required this.value,
    required this.valueColor,
    required this.borderColor,
  });

  final String label;
  final String value;
  final Color valueColor;
  final Color borderColor;
}

class _SummaryCarousel extends StatelessWidget {
  const _SummaryCarousel({required this.items});

  final List<_SummaryItem> items;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 92,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        clipBehavior: Clip.none,
        // Extra right padding prevents the last card's corner/shadow
        // from feeling clipped at the screen edge.
        padding: const EdgeInsets.fromLTRB(20, 0, 40, 0),
        itemBuilder: (BuildContext context, int index) {
          return _SummaryCard(item: items[index]);
        },
        separatorBuilder: (BuildContext context, int index) =>
            const SizedBox(width: 16),
        itemCount: items.length,
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.item});

  final _SummaryItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: item.borderColor),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.brandBlue.withAlpha(0x14),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            item.label,
            style: AppTypography.caption.copyWith(
              fontSize: 10,
              color: AppColors.textTertiary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: <Widget>[
              Text(
                item.value,
                style: AppTypography.display1.copyWith(
                  color: item.valueColor,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
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
    required this.status,
    required this.progress,
    required this.records,
    required this.verifiedCount,
    required this.pendingCount,
    required this.failedCount,
    required this.createdLabel,
    this.alertMessage,
  });

  final String batchId;
  final _BatchStatus status;
  final double progress;
  final int records;
  final int verifiedCount;
  final int pendingCount;
  final int failedCount;
  final String createdLabel;
  final String? alertMessage;

  static List<_BatchDirectoryItem> fromUsers(List<VerificationUser> users) {
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
          status: status,
          progress: progress,
          records: total,
          verifiedCount: verified,
          pendingCount: pending,
          failedCount: failed,
          createdLabel: createdLabel,
          alertMessage: alertMessage,
        ),
      );
    }
    items.sort((a, b) => b.createdLabel.compareTo(a.createdLabel));
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
    final bool isAlert = item.status == _BatchStatus.alert;
    final Color pillBg = switch (item.status) {
      _BatchStatus.completed => AppColors.blueTint,
      _BatchStatus.processing => const Color(0xFFEFF6FF),
      _BatchStatus.alert => const Color(0xFFFFDAD6),
    };
    final Color pillFg = switch (item.status) {
      _BatchStatus.completed => AppColors.brandBlue,
      _BatchStatus.processing => const Color(0xFF2563EB),
      _BatchStatus.alert => AppColors.error,
    };
    final String pillLabel = switch (item.status) {
      _BatchStatus.completed => 'Completed',
      _BatchStatus.processing => 'Processing',
      _BatchStatus.alert => 'Alert',
    };

    final Color progressTextColor = isAlert
        ? AppColors.error
        : AppColors.brandBlue;
    final Color trackColor = isAlert
        ? const Color(0xFFFFDAD6)
        : AppColors.blueTint;
    final Color fillColor = isAlert ? AppColors.error : AppColors.brandBlue;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        context.push(
          '${AppRouter.appBatchTrackingDetailPath}?batch_id=${Uri.encodeQueryComponent(item.batchId)}',
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isAlert ? const Color(0xFFFEF2F2) : const Color(0xFFF8FAFC),
          ),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: Color(0x142563EB),
              blurRadius: 12,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        _labelForBatch(item.batchId),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.body2.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Created ${item.createdLabel} • ${item.records} records',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textTertiary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: pillBg,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    pillLabel.toUpperCase(),
                    style: AppTypography.caption.copyWith(
                      color: pillFg,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    'Verification Progress',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textTertiary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  '${(item.progress * 100).round()}%',
                  style: AppTypography.caption.copyWith(
                    color: progressTextColor,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: item.progress.clamp(0, 1),
                minHeight: 8,
                backgroundColor: trackColor,
                valueColor: AlwaysStoppedAnimation<Color>(fillColor),
              ),
            ),
            if (item.alertMessage != null) ...<Widget>[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: <Widget>[
                    const Icon(
                      Icons.info_outline_rounded,
                      color: AppColors.error,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.alertMessage!,
                        style: AppTypography.body2.copyWith(
                          fontSize: 12,
                          color: AppColors.error,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

String _labelForBatch(String batchId) {
  final String id = batchId.trim();
  if (id.isEmpty || id == 'unknown') return 'Batch';
  final String shortId = id.length <= 10 ? id : id.substring(0, 10);
  return 'Batch $shortId';
}

class _StatusFilterRow extends StatelessWidget {
  const _StatusFilterRow({required this.selected, required this.onSelect});

  final String? selected;
  final ValueChanged<String?> onSelect;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: <Widget>[
        _FilterChip(
          label: 'All',
          selected: selected == null,
          onTap: () => onSelect(null),
        ),
        _FilterChip(
          label: 'Pending',
          selected: selected == 'pending_verification',
          onTap: () => onSelect('pending_verification'),
        ),
        _FilterChip(
          label: 'Verified',
          selected: selected == 'verified',
          onTap: () => onSelect('verified'),
        ),
        _FilterChip(
          label: 'Failed',
          selected: selected == 'failed',
          onTap: () => onSelect('failed'),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.brandBlue.withAlpha(18) : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? AppColors.brandBlue : const Color(0xFFE2E8F0),
          ),
        ),
        child: Text(
          label,
          style: AppTypography.body2.copyWith(
            color: selected ? AppColors.brandBlue : AppColors.textSecondary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
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

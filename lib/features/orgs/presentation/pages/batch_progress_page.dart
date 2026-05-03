import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

class BatchProgressPage extends StatelessWidget {
  const BatchProgressPage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<_BatchDirectoryItem> directory = _BatchDirectoryItem.sample();

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
                  items: const <_SummaryItem>[
                    _SummaryItem(
                      label: 'Total Batches',
                      value: '12',
                      valueColor: AppColors.brandBlue,
                      borderColor: Color(0xFFEFF6FF),
                    ),
                    _SummaryItem(
                      label: 'Active',
                      value: '3',
                      valueColor: AppColors.brandBlue,
                      borderColor: Color(0xFFEFF6FF),
                    ),
                    _SummaryItem(
                      label: 'Alerts',
                      value: '1',
                      valueColor: AppColors.error,
                      borderColor: Color(0xFFFEF2F2),
                      trailingIcon: Icons.warning_amber_rounded,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
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
                for (final _BatchDirectoryItem item in directory) ...<Widget>[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _BatchDirectoryCard(item: item),
                  ),
                  const SizedBox(height: 16),
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
    this.trailingIcon,
  });

  final String label;
  final String value;
  final Color valueColor;
  final Color borderColor;
  final IconData? trailingIcon;
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
              color: item.trailingIcon != null
                  ? AppColors.error
                  : AppColors.textTertiary,
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
              if (item.trailingIcon != null) ...<Widget>[
                const SizedBox(width: 6),
                Icon(item.trailingIcon, color: item.valueColor, size: 20),
              ],
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
    required this.name,
    required this.industry,
    required this.status,
    required this.progress,
    required this.records,
    required this.createdLabel,
    required this.slaLabel,
    this.alertMessage,
  });

  final String name;
  final String industry;
  final _BatchStatus status;
  final double progress;
  final int records;
  final String createdLabel;
  final String slaLabel;
  final String? alertMessage;

  static List<_BatchDirectoryItem> sample() => const <_BatchDirectoryItem>[
    _BatchDirectoryItem(
      name: 'Driver Onboarding Q1',
      industry: 'Transport Industry',
      status: _BatchStatus.completed,
      progress: 1,
      records: 200,
      createdLabel: '02 Apr',
      slaLabel: '5 days',
    ),
    _BatchDirectoryItem(
      name: 'Delivery Staff Batch 4',
      industry: 'Logistics Industry',
      status: _BatchStatus.processing,
      progress: 0.45,
      records: 200,
      createdLabel: '02 Apr',
      slaLabel: '5 days',
    ),
    _BatchDirectoryItem(
      name: 'Security Personnel',
      industry: 'Public Safety',
      status: _BatchStatus.alert,
      progress: 0.15,
      records: 200,
      createdLabel: '02 Apr',
      slaLabel: '5 days',
      alertMessage: '3 records require manual review',
    ),
  ];
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
          '${AppRouter.appBatchTrackingDetailPath}'
          '?batch=${Uri.encodeQueryComponent(item.name)}'
          '&industry=${Uri.encodeQueryComponent(item.industry)}'
          '&records=${item.records}'
          '&created=${Uri.encodeQueryComponent(item.createdLabel)}'
          '&sla=${Uri.encodeQueryComponent(item.slaLabel)}'
          '&progress=${item.progress}',
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
                        item.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.body2.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.industry,
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

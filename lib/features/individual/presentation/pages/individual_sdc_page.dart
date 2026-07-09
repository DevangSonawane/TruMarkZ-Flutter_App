import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/models/verification_models.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../auth/application/auth_notifier.dart';
import '../../../auth/application/auth_state.dart';
import '../../../orgs/data/verification_repository.dart';

class IndividualSdcPage extends ConsumerStatefulWidget {
  const IndividualSdcPage({super.key});

  @override
  ConsumerState<IndividualSdcPage> createState() => _IndividualSdcPageState();
}

class _IndividualSdcPageState extends ConsumerState<IndividualSdcPage> {
  final TextEditingController _searchController = TextEditingController();

  Timer? _debounce;
  bool _didInit = false;
  String _orgId = '';
  String _spaceId = '';
  String _batchId = '';
  String _batchName = '';
  int _active = 1;
  int _page = 1;
  int _pageSize = 30;

  AsyncValue<SdcRecordsResponse> _records = const AsyncLoading();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_handleSearchChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInit) return;
    _didInit = true;
    final Map<String, String> qp = GoRouterState.of(context).uri.queryParameters;
    _orgId = (qp['org_id'] ?? qp['orgId'] ?? '').trim();
    _spaceId = (qp['space_id'] ?? qp['spaceId'] ?? '').trim();
    _batchId = (qp['batch_id'] ?? qp['batchId'] ?? '').trim();
    _batchName = (qp['batch_name'] ?? qp['batchName'] ?? '').trim();
    _active = int.tryParse((qp['active'] ?? '').trim()) ?? 1;
    _page = int.tryParse((qp['page'] ?? '').trim()) ?? 1;
    _pageSize = int.tryParse((qp['pageSize'] ?? '').trim()) ?? 30;
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController
      ..removeListener(_handleSearchChanged)
      ..dispose();
    super.dispose();
  }

  void _handleSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      _page = 1;
      _load();
    });
  }

  String? _resolvedOrgId() {
    final String fromQuery = _orgId;
    if (fromQuery.isNotEmpty) return fromQuery;
    return null;
  }

  Future<void> _load() async {
    setState(() => _records = const AsyncLoading());
    try {
      final VerificationRepository repo = ref.read(verificationRepositoryProvider);
      final SdcRecordsResponse res = await repo.getSdcRecords(
        orgId: _resolvedOrgId(),
        spaceId: _spaceId.isNotEmpty ? _spaceId : null,
        active: _active,
        page: _page,
        pageSize: _pageSize,
        search: _searchController.text,
      );
      if (!mounted) return;
      setState(() {
        _records = AsyncData(res);
        _page = res.page <= 0 ? _page : res.page;
        _pageSize = res.pageSize > 0 ? res.pageSize : _pageSize;
      });
    } catch (error, stackTrace) {
      if (!mounted) return;
      setState(() => _records = AsyncError(error, stackTrace));
    }
  }

  void _goBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go(AppRouter.dashboardPath);
  }

  @override
  Widget build(BuildContext context) {
    final AuthState? authState = ref.watch(authNotifierProvider).valueOrNull;
    final String orgLabel = authState?.userProfile?.organizationName?.trim().isNotEmpty == true
        ? authState!.userProfile!.organizationName!.trim()
        : (authState?.userProfile?.fullName?.trim().isNotEmpty == true
              ? authState!.userProfile!.fullName!.trim()
              : 'Organisation');
    final SdcRecordsResponse? data = _records.valueOrNull;
    final List<SdcRecord> records = data?.records ?? const <SdcRecord>[];
    final int totalCount = data?.count ?? 0;
    final bool canGoBack = context.canPop();
    final bool isLoading = _records.isLoading;

    return Scaffold(
      backgroundColor: AppColors.brandBlue,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.x4,
                AppSpacing.x3,
                AppSpacing.x4,
                AppSpacing.x3,
              ),
              child: Row(
                children: <Widget>[
                  IconButton(
                    tooltip: 'Back',
                    onPressed: () => _goBack(context),
                    icon: const Icon(Icons.arrow_back_rounded),
                    color: Colors.white,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'SDC Records',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.heading1.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _batchName.isNotEmpty
                              ? 'Batch: $_batchName'
                              : (_batchId.isNotEmpty
                                    ? 'Batch ID: $_batchId'
                                    : orgLabel),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.body2.copyWith(
                            color: Colors.white.withValues(alpha: 0.82),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _HeaderBadge(
                    label: _active == 1 ? 'Active only' : 'All active states',
                  ),
                  if (!canGoBack) const SizedBox(width: 8),
                ],
              ),
            ),
            Expanded(
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  color: Color(0xFFF7F9FC),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: RefreshIndicator(
                  color: AppColors.brandBlue,
                  onRefresh: _load,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.x4,
                      AppSpacing.x4,
                      AppSpacing.x4,
                      AppSpacing.x6,
                    ),
                    children: <Widget>[
                      _SearchBox(
                        controller: _searchController,
                        onSubmitted: () {
                          _page = 1;
                          _load();
                        },
                        onClear: _searchController.text.isEmpty
                            ? null
                            : () {
                                _searchController.clear();
                                _page = 1;
                                _load();
                              },
                      ),
                      const SizedBox(height: AppSpacing.x3),
                      _SummaryStrip(
                        totalCount: totalCount,
                        page: _page,
                        pageSize: _pageSize,
                        instanceKey: data?.instanceKey ?? '',
                        batchId: _batchId,
                        spaceId: _spaceId,
                      ),
                      const SizedBox(height: AppSpacing.x4),
                      if (isLoading)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: AppSpacing.x8),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (_records.hasError)
                        _ErrorCard(
                          message: _records.error.toString(),
                          onRetry: _load,
                        )
                      else ...<Widget>[
                        if (records.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: AppSpacing.x8),
                            child: Center(
                              child: Text(
                                'No records found.',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                            ),
                          )
                        else
                          for (int i = 0; i < records.length; i++) ...<Widget>[
                            _SdcRecordCard(
                              record: records[i],
                              onTap: () => context.push(
                                AppRouter.sdcRecordLocation(
                                  publicId: records[i].publicId,
                                  instanceKey: data?.instanceKey.isNotEmpty == true
                                      ? data!.instanceKey
                                      : 'de',
                                ),
                              ),
                            ),
                            if (i != records.length - 1) const SizedBox(height: 12),
                          ],
                        const SizedBox(height: AppSpacing.x4),
                        _PaginationRow(
                          page: _page,
                          pageSize: _pageSize,
                          totalCount: totalCount,
                          onPrev: _page <= 1
                              ? null
                              : () {
                                  setState(() => _page -= 1);
                                  _load();
                                },
                          onNext: records.length < _pageSize && totalCount <= _page * _pageSize
                              ? null
                              : () {
                                  setState(() => _page += 1);
                                  _load();
                                },
                        ),
                      ],
                    ],
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

class _SearchBox extends StatelessWidget {
  const _SearchBox({
    required this.controller,
    required this.onSubmitted,
    required this.onClear,
  });

  final TextEditingController controller;
  final VoidCallback onSubmitted;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.7)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x3),
      child: Row(
        children: <Widget>[
          const Icon(Icons.search_rounded, color: AppColors.textTertiary),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              textInputAction: TextInputAction.search,
              decoration: const InputDecoration(
                hintText: 'Search title or recipient',
                border: InputBorder.none,
                isCollapsed: true,
              ),
              style: AppTypography.body1,
              onSubmitted: (_) => onSubmitted(),
            ),
          ),
          if (onClear != null)
            TextButton(
              onPressed: onClear,
              child: const Text('Clear'),
            ),
        ],
      ),
    );
  }
}

class _SummaryStrip extends StatelessWidget {
  const _SummaryStrip({
    required this.totalCount,
    required this.page,
    required this.pageSize,
    required this.instanceKey,
    required this.batchId,
    required this.spaceId,
  });

  final int totalCount;
  final int page;
  final int pageSize;
  final String instanceKey;
  final String batchId;
  final String spaceId;

  @override
  Widget build(BuildContext context) {
    final List<Widget> chips = <Widget>[
      _MetricChip(label: 'Records', value: totalCount.toString()),
      _MetricChip(label: 'Page', value: page.toString()),
      _MetricChip(label: 'Page size', value: pageSize.toString()),
    ];
    if (batchId.trim().isNotEmpty) {
      chips.add(_MetricChip(label: 'Batch', value: batchId.trim()));
    }
    if (spaceId.trim().isNotEmpty) {
      chips.add(_MetricChip(label: 'Space', value: spaceId.trim()));
    }
    if (instanceKey.trim().isNotEmpty) {
      chips.add(_MetricChip(label: 'Instance', value: instanceKey.trim()));
    }

    return Wrap(
      spacing: AppSpacing.x2,
      runSpacing: AppSpacing.x2,
      children: chips,
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.x3,
        vertical: AppSpacing.x2,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.8)),
      ),
      child: RichText(
        text: TextSpan(
          style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
          children: <TextSpan>[
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SdcRecordCard extends StatelessWidget {
  const _SdcRecordCard({required this.record, required this.onTap});

  final SdcRecord record;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final DateTime? createdAt = DateTime.tryParse(record.createdAt);
    final DateTime? updatedAt = DateTime.tryParse(record.updatedAt);
    final String subtitle = record.recipients.isEmpty
        ? 'No recipients listed'
        : record.recipients.join(', ');

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.divider.withValues(alpha: 0.7)),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          padding: const EdgeInsets.all(AppSpacing.x4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: record.active
                          ? AppColors.success.withValues(alpha: 0.12)
                          : AppColors.warning.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      record.active
                          ? Icons.verified_rounded
                          : Icons.pause_circle_filled_rounded,
                      color: record.active ? AppColors.success : AppColors.warning,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.x3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          record.title.trim().isNotEmpty ? record.title.trim() : 'Untitled record',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.heading2.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Public ID: ${record.publicId.trim().isNotEmpty ? record.publicId.trim() : record.id}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.body2.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.x2),
                  _StatusPill(active: record.active),
                ],
              ),
              const SizedBox(height: AppSpacing.x3),
              Text(
                subtitle,
                style: AppTypography.body2.copyWith(color: AppColors.textPrimary),
              ),
              const SizedBox(height: AppSpacing.x3),
              Wrap(
                spacing: AppSpacing.x2,
                runSpacing: AppSpacing.x2,
                children: <Widget>[
                  _TinyInfo(label: 'Created', value: _formatDate(createdAt)),
                  _TinyInfo(label: 'Updated', value: _formatDate(updatedAt)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    final Color fg = active ? AppColors.success : AppColors.warning;
    final Color bg = active
        ? AppColors.success.withValues(alpha: 0.12)
        : AppColors.warning.withValues(alpha: 0.12);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        active ? 'ACTIVE' : 'INACTIVE',
        style: AppTypography.caption.copyWith(
          color: fg,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _TinyInfo extends StatelessWidget {
  const _TinyInfo({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.pageBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label.toUpperCase(),
            style: AppTypography.caption.copyWith(
              color: AppColors.textTertiary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTypography.body2.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _PaginationRow extends StatelessWidget {
  const _PaginationRow({
    required this.page,
    required this.pageSize,
    required this.totalCount,
    required this.onPrev,
    required this.onNext,
  });

  final int page;
  final int pageSize;
  final int totalCount;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final int start = totalCount == 0 ? 0 : ((page - 1) * pageSize) + 1;
    final int end = totalCount == 0 ? 0 : (page * pageSize).clamp(0, totalCount);

    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            totalCount == 0
                ? 'No records to page through'
                : 'Showing $start-$end of $totalCount',
            style: AppTypography.body2.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        TextButton(
          onPressed: onPrev,
          child: const Text('Prev'),
        ),
        const SizedBox(width: 4),
        TextButton(
          onPressed: onNext,
          child: const Text('Next'),
        ),
      ],
    );
  }
}

class _HeaderBadge extends StatelessWidget {
  const _HeaderBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Text(
        label,
        style: AppTypography.caption.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w800,
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
      padding: const EdgeInsets.all(AppSpacing.x4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Unable to load records',
            style: AppTypography.heading2.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: AppSpacing.x2),
          Text(
            message,
            style: AppTypography.body2.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.x3),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

String _formatDate(DateTime? dt) {
  if (dt == null) return 'Unknown';
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
  final String day = dt.day.toString().padLeft(2, '0');
  final String month = months[dt.month - 1];
  return '$day $month ${dt.year}';
}

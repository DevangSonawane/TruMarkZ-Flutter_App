import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/models/verification_models.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../orgs/data/verification_repository.dart';

class IndividualSdcRecordDetailPage extends ConsumerStatefulWidget {
  const IndividualSdcRecordDetailPage({super.key});

  @override
  ConsumerState<IndividualSdcRecordDetailPage> createState() =>
      _IndividualSdcRecordDetailPageState();
}

class _IndividualSdcRecordDetailPageState
    extends ConsumerState<IndividualSdcRecordDetailPage> {
  bool _didInit = false;
  String _publicId = '';
  String _instanceKey = 'de';
  String _orgId = '';
  String _spaceId = '';
  int _active = 1;
  int _page = 1;
  int _pageSize = 30;
  String _search = '';

  AsyncValue<SdcRecord> _data = const AsyncLoading();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInit) return;
    _didInit = true;

    final Map<String, String> qp = GoRouterState.of(
      context,
    ).uri.queryParameters;
    _publicId = (qp['public_id'] ?? qp['publicId'] ?? '').trim();
    _instanceKey = (qp['instance_key'] ?? qp['instanceKey'] ?? 'de').trim();
    _orgId = (qp['org_id'] ?? qp['orgId'] ?? '').trim();
    _spaceId = (qp['space_id'] ?? qp['spaceId'] ?? '').trim();
    _active = int.tryParse((qp['active'] ?? '').trim()) ?? 1;
    _page = int.tryParse((qp['page'] ?? '').trim()) ?? 1;
    _pageSize = int.tryParse((qp['pageSize'] ?? '').trim()) ?? 30;
    _search = (qp['search'] ?? '').trim();
    debugPrint(
      '[sdc-detail] init publicId=$_publicId instanceKey=$_instanceKey orgId=$_orgId spaceId=$_spaceId active=$_active page=$_page pageSize=$_pageSize search=$_search',
    );
    _load();
  }

  Future<void> _load() async {
    if (_publicId.isEmpty && _search.isEmpty) {
      debugPrint('[sdc-detail] missing public_id and search');
      setState(() {
        _data = AsyncError(
          const ApiException(
            statusCode: null,
            message: 'Missing public_id and search.',
          ),
          StackTrace.current,
        );
      });
      return;
    }

    setState(() => _data = const AsyncLoading());
    try {
      final VerificationRepository repo = ref.read(
        verificationRepositoryProvider,
      );
      debugPrint(
        '[sdc-detail] loading /sdc/records orgId=$_orgId spaceId=$_spaceId active=$_active page=$_page pageSize=$_pageSize search=$_search',
      );
      SdcRecord? selected;

      Future<void> loadFromList({String? search}) async {
        final String effectiveSearch = (search ?? _search).trim();
        final SdcRecordsResponse res = await repo.getSdcRecords(
          orgId: _orgId.isNotEmpty ? _orgId : null,
          spaceId: _spaceId.isNotEmpty ? _spaceId : null,
          active: _active,
          page: _page,
          pageSize: _pageSize,
          search: effectiveSearch,
        );
        debugPrint(
          '[sdc-detail] /sdc/records returned count=${res.count} page=${res.page} pageSize=${res.pageSize} records=${res.records.length} instanceKey=${res.instanceKey}',
        );
        selected = _matchRecord(res.records, searchHint: effectiveSearch);
        debugPrint(
          '[sdc-detail] match=${selected == null ? 'none' : selected!.publicId}',
        );
      }

      final String initialSearch = _search.isNotEmpty ? _search : _publicId;
      await loadFromList(search: initialSearch);
      if (selected == null && _publicId.isNotEmpty && _search != _publicId) {
        debugPrint('[sdc-detail] retrying /sdc/records with search=$_publicId');
        await loadFromList(search: _publicId);
      }

      if (!mounted) return;
      if (selected == null) {
        debugPrint('[sdc-detail] record not found after lookup');
        setState(() {
          _data = AsyncError(
            StateError('Record not found in the loaded page.'),
            StackTrace.current,
          );
        });
        return;
      }

      setState(() => _data = AsyncData(selected!));
    } on ApiException catch (e, st) {
      if (!mounted) return;
      setState(() => _data = AsyncError(e, st));
    } catch (e, st) {
      if (!mounted) return;
      setState(() => _data = AsyncError(e, st));
    }
  }

  SdcRecord? _matchRecord(List<SdcRecord> records, {String? searchHint}) {
    final String hint = (searchHint ?? '').trim().toLowerCase();
    for (final SdcRecord record in records) {
      if (record.publicId.trim() == _publicId.trim() ||
          record.id.trim() == _publicId.trim()) {
        return record;
      }
      if (hint.isNotEmpty) {
        final String title = record.title.trim().toLowerCase();
        if (title == hint || title.contains(hint)) return record;
        if (record.recipients.any(
          (String recipient) => recipient.trim().toLowerCase() == hint,
        )) {
          return record;
        }
      }
    }
    return records.length == 1 ? records.first : null;
  }

  void _goBack(BuildContext context) {
    final GoRouter router = GoRouter.of(context);
    if (router.canPop()) {
      context.pop();
    } else {
      context.go(AppRouter.appSdcPath);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                          'Record Detail',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.heading1.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _publicId.isEmpty ? 'SDC record' : _publicId,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.body2.copyWith(
                            color: Colors.white.withValues(alpha: 0.82),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Refresh',
                    onPressed: _load,
                    icon: const Icon(Icons.refresh_rounded),
                    color: Colors.white,
                  ),
                ],
              ),
            ),
            Expanded(
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  color: Color(0xFFF7F9FC),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: _data.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (Object err, _) => Padding(
                    padding: const EdgeInsets.all(AppSpacing.x4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Unable to load record',
                          style: AppTypography.display2,
                        ),
                        const SizedBox(height: AppSpacing.x2),
                        Text(
                          err.toString(),
                          style: AppTypography.body2.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.x4),
                        ElevatedButton.icon(
                          onPressed: _load,
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                  data: (SdcRecord record) {
                    return ListView(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(
                        AppSpacing.x4,
                        AppSpacing.x4,
                        AppSpacing.x4,
                        AppSpacing.x6 +
                            MediaQuery.viewPaddingOf(context).bottom,
                      ),
                      children: <Widget>[
                        _HeroCard(
                          record: record,
                          instanceKey: _instanceKey,
                          onDownload: () => _downloadPdf(record),
                        ),
                        const SizedBox(height: AppSpacing.x4),
                        _SectionCard(
                          title: 'Identity',
                          children: <Widget>[
                            _DetailRow(label: 'Title', value: record.title),
                            _DetailRow(
                              label: 'Public ID',
                              value: record.publicId,
                            ),
                            _DetailRow(label: 'Record ID', value: record.id),
                            _DetailRow(
                              label: 'Unique Value',
                              value: record.uniqueIdValue,
                            ),
                            _DetailRow(
                              label: 'Instance Key',
                              value: _instanceKey.isEmpty ? 'de' : _instanceKey,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.x4),
                        _SectionCard(
                          title: 'Status',
                          children: <Widget>[
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: <Widget>[
                                _StatusChip(
                                  label: record.active ? 'Active' : 'Inactive',
                                  active: record.active,
                                ),
                                _StatusChip(
                                  label: record.latest ? 'Latest' : 'Archived',
                                  active: record.latest,
                                ),
                                _StatusChip(
                                  label: record.revoked ? 'Revoked' : 'Valid',
                                  active: !record.revoked,
                                ),
                                _StatusChip(
                                  label: record.edited ? 'Edited' : 'Original',
                                  active: !record.edited,
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.x3),
                            _DetailRow(
                              label: 'Anchor Time',
                              value: _formatDateTime(record.anchorTime),
                            ),
                            _DetailRow(
                              label: 'Expires',
                              value: _formatDateTime(record.expires),
                            ),
                            _DetailRow(
                              label: 'Created',
                              value: _formatDateTime(record.createdAt),
                            ),
                            _DetailRow(
                              label: 'Updated',
                              value: _formatDateTime(record.updatedAt),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.x4),
                        _SectionCard(
                          title: 'Recipients',
                          children: record.recipients.isEmpty
                              ? <Widget>[
                                  Text(
                                    'No recipients listed.',
                                    style: AppTypography.body2.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ]
                              : record.recipients
                                    .map(
                                      (String recipient) => Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: AppSpacing.x2,
                                        ),
                                        child: Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: AppSpacing.x3,
                                            vertical: AppSpacing.x3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.pageBg,
                                            borderRadius: BorderRadius.circular(
                                              14,
                                            ),
                                            border: Border.all(
                                              color: AppColors.divider
                                                  .withValues(alpha: 0.5),
                                            ),
                                          ),
                                          child: Text(
                                            recipient,
                                            style: AppTypography.body2.copyWith(
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _downloadPdf(SdcRecord record) async {
    try {
      debugPrint(
        '[sdc-detail] download requested publicId=${record.publicId} title=${record.title}',
      );
      final VerificationRepository repo = ref.read(
        verificationRepositoryProvider,
      );
      final SdcRecordDetailResponse res = await repo.getSdcRecord(
        publicId: record.publicId.trim().isNotEmpty
            ? record.publicId.trim()
            : record.id.trim(),
        instanceKey: 'de',
      );
      if (res.pdfUrl.trim().isEmpty) {
        throw StateError('PDF URL is unavailable for this record.');
      }
      final Directory tempDir = await getTemporaryDirectory();
      final String safeTitle = record.title.trim().isEmpty
          ? 'record'
          : record.title
                .trim()
                .toLowerCase()
                .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
                .replaceAll(RegExp(r'_+'), '_')
                .replaceAll(RegExp(r'^_|_$'), '');
      final String fileName =
          'sdc_record_${safeTitle.isEmpty ? 'record' : safeTitle}_${record.publicId.isEmpty ? record.id : record.publicId}.pdf';
      final File file = File('${tempDir.path}/$fileName');
      debugPrint('[sdc-detail] downloading pdf from ${res.pdfUrl}');
      await Dio().download(res.pdfUrl, file.path);
      await Share.shareXFiles(<XFile>[
        XFile(file.path, mimeType: 'application/pdf'),
      ], text: 'SDC record PDF');
    } catch (e, st) {
      debugPrint('[sdc-detail] pdf download failed: $e');
      debugPrintStack(stackTrace: st);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to download PDF right now.')),
      );
    }
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.record,
    required this.instanceKey,
    required this.onDownload,
  });

  final SdcRecord record;
  final String instanceKey;
  final VoidCallback onDownload;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.7)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: record.active
                      ? AppColors.success.withValues(alpha: 0.12)
                      : AppColors.warning.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
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
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            record.title.trim().isEmpty
                                ? 'Untitled record'
                                : record.title.trim(),
                            style: AppTypography.heading1.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        TextButton.icon(
                          onPressed: onDownload,
                          icon: const Icon(Icons.download_rounded, size: 18),
                          label: const Text('Download'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Instance ${instanceKey.isEmpty ? 'de' : instanceKey}',
                      style: AppTypography.body2.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.x3),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _StatusChip(
                label: 'Created ${_formatDateTime(record.createdAt)}',
                active: true,
              ),
              _StatusChip(
                label: record.recipients.length == 1
                    ? '1 recipient'
                    : '${record.recipients.length} recipients',
                active: true,
              ),
              _StatusChip(
                label: record.uniqueIdValue.trim().isEmpty
                    ? 'No unique value'
                    : 'Unique value set',
                active: record.uniqueIdValue.trim().isNotEmpty,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: AppTypography.heading2.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: AppSpacing.x3),
          ...children,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.x2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: AppTypography.caption.copyWith(
                color: AppColors.textTertiary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.trim().isEmpty ? '—' : value.trim(),
              style: AppTypography.body2.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.active});

  final String label;
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
        label,
        style: AppTypography.caption.copyWith(
          color: fg,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

String _formatDateTime(String? raw) {
  final String value = raw?.trim() ?? '';
  if (value.isEmpty) return 'Unknown';
  final DateTime? parsed = DateTime.tryParse(value);
  if (parsed == null) return value;
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
  final String day = parsed.day.toString().padLeft(2, '0');
  final String month = months[parsed.month - 1];
  final String hours = parsed.hour.toString().padLeft(2, '0');
  final String minutes = parsed.minute.toString().padLeft(2, '0');
  return '$day $month ${parsed.year}, $hours:$minutes';
}

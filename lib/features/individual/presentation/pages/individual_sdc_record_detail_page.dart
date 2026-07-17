import 'dart:math' as math;
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
                  error: (Object err, _) =>
                      _PendingSdcErrorState(error: err, onRetry: _load),
                  data: (SdcRecord record) {
                    return LayoutBuilder(
                      builder:
                          (BuildContext context, BoxConstraints constraints) {
                            return SingleChildScrollView(
                              physics: const BouncingScrollPhysics(),
                              padding: EdgeInsets.fromLTRB(
                                AppSpacing.x4,
                                AppSpacing.x4,
                                AppSpacing.x4,
                                AppSpacing.x6 +
                                    MediaQuery.viewPaddingOf(context).bottom +
                                    72,
                              ),
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  minHeight: constraints.maxHeight,
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
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
                                        _IdentityFieldRow(
                                          icon: Icons.badge_outlined,
                                          label: 'Public ID',
                                          value: record.publicId,
                                          onCopy: () => _copyText(
                                            record.publicId,
                                            'Public ID',
                                          ),
                                        ),
                                        const SizedBox(height: 18),
                                        _IdentityFieldRow(
                                          icon: Icons.pin_outlined,
                                          label: 'Record ID',
                                          value: record.id,
                                          onCopy: () =>
                                              _copyText(record.id, 'Record ID'),
                                        ),
                                        const SizedBox(height: 18),
                                        _IdentityFieldRow(
                                          icon: Icons.calendar_today_rounded,
                                          label: 'Date',
                                          value: record.uniqueIdValue,
                                          onCopy: () => _copyText(
                                            record.uniqueIdValue,
                                            'Date',
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: AppSpacing.x4),
                                    _SectionCard(
                                      title: 'Timeline',
                                      children: <Widget>[
                                        _TimelineItem(
                                          icon: Icons.description_outlined,
                                          iconColor: const Color(0xFF16A34A),
                                          title: 'Created',
                                          dateTime: _formatCardDate(
                                            record.createdAt,
                                          ),
                                          description: 'Record created',
                                          isLast: false,
                                        ),
                                        _TimelineItem(
                                          icon: Icons.anchor_rounded,
                                          iconColor: const Color(0xFF2563EB),
                                          title: 'Anchored',
                                          dateTime: _formatCardDate(
                                            record.anchorTime,
                                          ),
                                          description:
                                              'Record anchored on blockchain',
                                          isLast: false,
                                        ),
                                        _TimelineItem(
                                          icon: Icons.star_outline_rounded,
                                          iconColor: const Color(0xFF7C3AED),
                                          title: 'Latest Version',
                                          dateTime: _formatCardDate(
                                            record.updatedAt,
                                          ),
                                          description:
                                              'This is the latest version',
                                          isLast: false,
                                        ),
                                        _TimelineItem(
                                          icon: Icons
                                              .check_circle_outline_rounded,
                                          iconColor: const Color(0xFF16A34A),
                                          title: 'Active',
                                          dateTime: _formatCardDate(
                                            record.updatedAt,
                                          ),
                                          description: record.active
                                              ? 'Record is active and valid'
                                              : 'Record is inactive',
                                          isLast: true,
                                          showConnector: false,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: AppSpacing.x4),
                                    _SectionCard(
                                      title: 'Recipients',
                                      children: <Widget>[
                                        if (record.recipients.isEmpty)
                                          Text(
                                            'No recipients listed.',
                                            style: AppTypography.body2.copyWith(
                                              color: AppColors.textSecondary,
                                            ),
                                          )
                                        else
                                          ...record.recipients.map(
                                            (String recipient) => Padding(
                                              padding: const EdgeInsets.only(
                                                bottom: AppSpacing.x2,
                                              ),
                                              child: _RecipientTile(
                                                name: recipient,
                                              ),
                                            ),
                                          ),
                                        const SizedBox(height: AppSpacing.x3),
                                        const _AboutRecordCard(),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
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

  Future<void> _copyText(String value, String label) async {
    final String text = value.trim();
    if (text.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$label copied')));
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
    final String createdLabel = _formatCardDate(
      record.anchorTime ?? record.createdAt,
    );
    final String recipientLabel = record.recipients.length == 1
        ? '1 recipient'
        : '${record.recipients.length} recipients';
    final bool isLatest = record.latest;
    final bool isValid = !record.revoked;
    final bool isOriginal = !record.edited;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.x4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.7)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF7EF),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(
                      Icons.verified_rounded,
                      color: Color(0xFF24A559),
                      size: 30,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: 180,
                    child: Text(
                      record.title.trim().isEmpty
                          ? 'Untitled record'
                          : record.title.trim(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.heading1.copyWith(
                        fontWeight: FontWeight.w800,
                        height: 1.05,
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Align(
                alignment: Alignment.topRight,
                child: _StatusChip(
                  label: record.active ? 'Active' : 'Inactive',
                  active: record.active,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.x3),
          Row(
            children: <Widget>[
              Expanded(
                child: _MetaRow(
                  icon: Icons.calendar_today_rounded,
                  label: createdLabel,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: _MetaRow(
                    icon: Icons.person_outline_rounded,
                    label: recipientLabel,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.x3),
          Center(
            child: Wrap(
              alignment: WrapAlignment.center,
              runAlignment: WrapAlignment.center,
              spacing: 10,
              runSpacing: 10,
              children: <Widget>[
                _StatusChip(label: 'Latest', active: isLatest),
                _StatusChip(label: 'Valid', active: isValid),
                _StatusChip(label: 'Original', active: isOriginal),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.x4),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onDownload,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                elevation: 0,
                minimumSize: const Size.fromHeight(54),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.download_rounded, size: 18),
              label: const Text(
                'Download Certificate',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: 15, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Text(
          label,
          style: AppTypography.body2.copyWith(
            color: AppColors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
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

class _IdentityFieldRow extends StatelessWidget {
  const _IdentityFieldRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onCopy,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon, size: 18, color: AppColors.textSecondary),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                label,
                style: AppTypography.body2.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                value.trim().isEmpty ? '—' : value.trim(),
                style: AppTypography.body2.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        IconButton(
          onPressed: onCopy,
          icon: const Icon(Icons.copy_rounded, size: 18),
          color: AppColors.textSecondary,
          tooltip: 'Copy $label',
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
        ),
      ],
    );
  }
}

class _RecipientTile extends StatelessWidget {
  const _RecipientTile({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.x3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              color: Color(0xFFEAF2FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_rounded,
              color: Color(0xFF5B7FFF),
              size: 30,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.body1.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Verified recipient',
                  style: AppTypography.body2.copyWith(
                    color: const Color(0xFF16A34A),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.textSecondary,
            size: 26,
          ),
        ],
      ),
    );
  }
}

class _AboutRecordCard extends StatelessWidget {
  const _AboutRecordCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.x4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFFF3F8FF), Color(0xFFEAF2FF)],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD7E5FF)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 26,
            height: 26,
            decoration: const BoxDecoration(
              color: Color(0xFFE7F0FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.info_outline_rounded,
              color: Color(0xFF2563EB),
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'About this record',
                  style: AppTypography.body1.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'This record is secured on the blockchain and can\'t be tampered with. You can share this certificate as a proof of authenticity.',
                  style: AppTypography.body2.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.45,
                    fontWeight: FontWeight.w500,
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

class _PendingSdcErrorState extends StatefulWidget {
  const _PendingSdcErrorState({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  State<_PendingSdcErrorState> createState() => _PendingSdcErrorStateState();
}

class _PendingSdcErrorStateState extends State<_PendingSdcErrorState>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool _isPendingState(Object error) {
    final String message = error.toString().toLowerCase();
    return error is StateError ||
        message.contains('not found') ||
        message.contains('missing public_id') ||
        message.contains('missing user id') ||
        message.contains('missing user if') ||
        message.contains('missing user') ||
        message.contains('still creating');
  }

  @override
  Widget build(BuildContext context) {
    final bool isPending = _isPendingState(widget.error);
    final String title = isPending
        ? 'Oops, we are still creating your SDC'
        : 'Unable to load record';
    final String subtitle = isPending
        ? 'Hang tight. Your record is still being prepared. Try again in a moment and we’ll bring it right back.'
        : widget.error.toString();

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double width = constraints.maxWidth;
        final double height = constraints.maxHeight;
        final double size = width < 402 ? width : 402;
        final double scale = size / 402;
        double s(double v) => v * scale;

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            s(16),
            s(20),
            s(16),
            s(32) + MediaQuery.viewPaddingOf(context).bottom,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: height - s(24)),
            child: Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: double.infinity,
                child: Container(
                  padding: EdgeInsets.all(s(20)),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: <Color>[Color(0xFFFDFEFF), Color(0xFFF2F7FF)],
                    ),
                    borderRadius: BorderRadius.circular(s(24)),
                    border: Border.all(
                      color: const Color(0xFFDCE8FF),
                      width: s(1),
                    ),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: s(24),
                        offset: Offset(0, s(12)),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      AnimatedBuilder(
                        animation: _controller,
                        builder: (BuildContext context, Widget? child) {
                          final double t = _controller.value;
                          final double pulse =
                              0.92 +
                              (0.08 * (0.5 + 0.5 * _sin(t * 2 * 3.1415926535)));
                          final double floatY =
                              _sin(t * 2 * 3.1415926535) * s(6);
                          final double orbit = _sin(t * 2 * 3.1415926535);

                          return SizedBox(
                            height: s(150),
                            child: Stack(
                              alignment: Alignment.center,
                              children: <Widget>[
                                Container(
                                  width: s(110) * pulse,
                                  height: s(110) * pulse,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: const Color(
                                      0xFF2563EB,
                                    ).withValues(alpha: 0.10 + (0.05 * pulse)),
                                  ),
                                ),
                                Container(
                                  width: s(82),
                                  height: s(82),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white,
                                    border: Border.all(
                                      color: const Color(0xFFBFD4FF),
                                      width: s(1.2),
                                    ),
                                  ),
                                  child: Transform.translate(
                                    offset: Offset(0, floatY),
                                    child: Icon(
                                      Icons.hourglass_bottom_rounded,
                                      size: s(36),
                                      color: const Color(0xFF2563EB),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  left: s(76) + orbit * s(6),
                                  top: s(30),
                                  child: _FloatingDot(
                                    size: s(14),
                                    color: const Color(0xFF16A34A),
                                    scale: pulse,
                                  ),
                                ),
                                Positioned(
                                  right: s(72) - orbit * s(5),
                                  bottom: s(28),
                                  child: _FloatingDot(
                                    size: s(18),
                                    color: const Color(0xFFF59E0B),
                                    scale: 1.06 - (pulse - 0.92),
                                  ),
                                ),
                                Positioned(
                                  top: s(18),
                                  right: s(108) + orbit * s(8),
                                  child: _FloatingStar(
                                    size: s(22),
                                    color: const Color(0xFF7C3AED),
                                    rotation: t * 2 * 3.1415926535,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      SizedBox(height: s(6)),
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: AppTypography.display2.copyWith(
                          fontWeight: FontWeight.w900,
                          height: 1.0,
                        ),
                      ),
                      SizedBox(height: s(10)),
                      Text(
                        subtitle,
                        textAlign: TextAlign.center,
                        style: AppTypography.body2.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: s(18)),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: s(8),
                        runSpacing: s(8),
                        children: const <Widget>[
                          _StatusChip(label: 'Still baking', active: true),
                          _StatusChip(label: 'Almost there', active: true),
                        ],
                      ),
                      SizedBox(height: s(20)),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: widget.onRetry,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            minimumSize: Size.fromHeight(s(52)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(s(14)),
                            ),
                          ),
                          icon: const Icon(Icons.refresh_rounded, size: 18),
                          label: const Text(
                            'Try Again',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _FloatingDot extends StatelessWidget {
  const _FloatingDot({
    required this.size,
    required this.color,
    required this.scale,
  });

  final double size;
  final Color color;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: scale,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: color.withValues(alpha: 0.28),
              blurRadius: size / 2,
              offset: Offset(0, size / 5),
            ),
          ],
        ),
      ),
    );
  }
}

class _FloatingStar extends StatelessWidget {
  const _FloatingStar({
    required this.size,
    required this.color,
    required this.rotation,
  });

  final double size;
  final Color color;
  final double rotation;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: rotation,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.14),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.auto_awesome_rounded,
          color: color,
          size: size * 0.75,
        ),
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

String _formatCardDate(String? raw) {
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

double _sin(double value) => math.sin(value);

class _TimelineItem extends StatelessWidget {
  const _TimelineItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.dateTime,
    required this.description,
    required this.isLast,
    this.showConnector = true,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String dateTime;
  final String description;
  final bool isLast;
  final bool showConnector;

  @override
  Widget build(BuildContext context) {
    final bool hasDateTime =
        dateTime.trim().isNotEmpty && dateTime.trim() != 'Unknown';
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 44,
            child: Column(
              children: <Widget>[
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: iconColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: Colors.white, size: 18),
                ),
                if (showConnector)
                  Container(
                    width: 2,
                    height: 72,
                    margin: const EdgeInsets.only(top: 2),
                    color: const Color(0xFFE5E7EB),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: AppTypography.body1.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (hasDateTime)
                    Text(
                      dateTime,
                      style: AppTypography.body2.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: AppTypography.body2.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

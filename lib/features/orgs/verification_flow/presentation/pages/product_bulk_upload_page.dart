import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/models/verification_models.dart';
import '../../../../../core/network/api_client.dart';
import '../../../../../core/router/app_router.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/utils/file_picker_util.dart';
import '../../../../auth/application/auth_notifier.dart';
import '../../../../auth/application/auth_state.dart';
import '../../../../auth/data/auth_repository.dart';
import '../../../data/verification_repository.dart';
import '../../../../../core/services/batch_name_store.dart';
import 'flow_step_progress.dart';

class ProductBulkUploadPage extends ConsumerStatefulWidget {
  const ProductBulkUploadPage({super.key});

  @override
  ConsumerState<ProductBulkUploadPage> createState() =>
      _ProductBulkUploadPageState();
}

class _ProductBulkUploadPageState extends ConsumerState<ProductBulkUploadPage> {
  String? _lastRouteSignature;
  bool _didInitFromRoute = false;
  late final TextEditingController _batchNameController;

  String _industry = '';
  String _sector = 'Consumer Goods & Warranty';
  String _categoryId = '';
  String _batchName = 'New Product Batch';
  String _description = '';
  String _mode = 'verification'; // 'verification' | 'warranty'
  String _access = 'public_searchable';
  String _defaultProductId = '';
  final Set<String> _checks = <String>{};
  final List<int> _documentCardIds = <int>[];
  int _nextDocumentCardId = 0;

  PickedFile? _pickedFile;
  bool _creating = false;
  List<String> _savedTemplateHeaders = <String>[];
  String get _resolvedBatchName {
    final String typed = _batchNameController.text.trim();
    return typed.isNotEmpty ? typed : _batchName.trim();
  }

  @override
  void initState() {
    super.initState();
    _batchNameController = TextEditingController(text: _batchName);
  }

  void _goBack(BuildContext context) {
    final GoRouter router = GoRouter.of(context);
    if (router.canPop()) {
      context.pop();
    } else {
      context.go(AppRouter.dashboardPath);
    }
  }

  void _syncBatchName(String value) {
    final String cleaned = value.trim();
    if (cleaned.isEmpty) return;
    _batchName = cleaned;
    if (_batchNameController.text.trim() != cleaned) {
      _batchNameController.value = TextEditingValue(
        text: cleaned,
        selection: TextSelection.collapsed(offset: cleaned.length),
      );
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final Uri uri = GoRouterState.of(context).uri;
    final String signature = uri.query;
    if (_lastRouteSignature == signature) return;
    _lastRouteSignature = signature;
    if (!_didInitFromRoute) {
      _didInitFromRoute = true;
    }

    final Object? extra = GoRouterState.of(context).extra;
    final String? sector = extra is String ? extra : null;
    if (sector != null && sector.trim().isNotEmpty) {
      _sector = sector.trim();
    }

    final Map<String, String> qp = uri.queryParameters;
    final String previousMode = _mode;

    final String flowIndustry = (qp['industry'] ?? '').trim();
    if (flowIndustry.isNotEmpty) {
      _industry = flowIndustry;
    }

    final String productId = (qp['product_id'] ?? '').trim();
    if (productId.isNotEmpty) {
      _defaultProductId = productId;
    }

    final String? categoryId = qp['category_id'];
    if (categoryId != null && categoryId.trim().isNotEmpty) {
      _categoryId = categoryId.trim();
    } else {
      _categoryId = _sector;
    }

    final String? batch = qp['batch'];
    if (batch != null && batch.trim().isNotEmpty) {
      _syncBatchName(batch.trim());
    }

    final String mode = (qp['mode'] ?? 'verification').trim().toLowerCase();
    if (mode == 'warranty' || mode == 'verification') {
      _mode = mode;
    }
    if (_mode != previousMode) {
      _savedTemplateHeaders = <String>[];
      if (_mode == 'warranty') {
        _checks.clear();
      }
    }

    final String description = (qp['desc'] ?? '').trim();
    if (description.isNotEmpty) {
      _description = description;
    } else if (_description.trim().isEmpty) {
      _description = _defaultDescriptionForMode();
    }

    final String access = (qp['access'] ?? _access).trim().toLowerCase();
    if (access.isNotEmpty) {
      _access = access;
    }

    final String checks = (qp['checks'] ?? '').trim();
    if (checks.isNotEmpty) {
      _checks
        ..clear()
        ..addAll(
          checks
              .split(',')
              .map((String s) => s.trim())
              .where((String s) => s.isNotEmpty),
        );
    }
  }

  @override
  void dispose() {
    _batchNameController.dispose();
    super.dispose();
  }

  List<String> _defaultTemplateHeaders() {
    if (_mode == 'warranty') {
      return <String>[
        'product_name',
        'category',
        'serial_number',
        'purchase_date',
        'warranty_start_date',
        'warranty_end_date',
      ];
    }
    return <String>[
      'product_name',
      'serial_number',
      'model',
      'batch_number',
      'certificate_number',
    ];
  }

  Future<void> _downloadTemplate() async {
    final List<String> initialHeaders = _savedTemplateHeaders.isNotEmpty
        ? List<String>.from(_savedTemplateHeaders)
        : _defaultTemplateHeaders();

    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return _ProductTemplateDialog(
          initialHeaders: initialHeaders,
          categoryId: _categoryId,
          isWarranty: _mode == 'warranty',
          onSave: (List<String> headers) {
            setState(() {
              _savedTemplateHeaders = List<String>.from(headers);
            });
          },
        );
      },
    );
  }

  Future<void> _pickExcelFile() async {
    final PickedFile? picked = await FilePickerUtil.pickExcel();
    if (!mounted) return;
    if (picked == null) return;
    await _setPickedFile(picked);
  }

  Future<void> _setPickedFile(PickedFile picked) async {
    setState(() => _pickedFile = picked);
  }

  void _toggleDocumentSection() {
    setState(() {
      if (_documentCardIds.isEmpty) {
        _documentCardIds.add(_nextDocumentCardId++);
      } else {
        _documentCardIds.clear();
      }
    });
  }

  void _addDocumentCard() {
    setState(() {
      _documentCardIds.add(_nextDocumentCardId++);
    });
  }

  void _removeDocumentCard(int cardId) {
    setState(() {
      _documentCardIds.remove(cardId);
    });
  }

  Future<void> _confirmAndCreateBatch() async {
    final PickedFile? pickedFile = _pickedFile;
    if (_creating) {
      return;
    }
    if (pickedFile != null) {
      // Product uploads should follow the same lightweight client-side flow as
      // human bulk uploads: let the backend validate the spreadsheet.
    }
    final List<String> columns = _columns();
    final String resolvedIndustry = _effectiveIndustry();
    final String displayIndustry = _prettyIndustry(resolvedIndustry);
    final String description = _resolvedDescription();
    final String checks = _resolvedVerificationTypesCsv();
    final Uri previewUri = Uri(
      path: AppRouter.certificatePreviewPath,
      queryParameters: <String, String>{
        if (checks.isNotEmpty) 'checks': checks,
        'industry': resolvedIndustry,
        'industry_label': displayIndustry,
        'access': _access,
        'identity_type': 'Product',
        'flow': 'product',
        'mode': _mode,
        if (_categoryId.trim().isNotEmpty) 'category_id': _categoryId.trim(),
        if (_sector.trim().isNotEmpty) 'sector': _sector.trim(),
        if (_mode == 'warranty') 'supports_warranty': 'true',
        'batch': _resolvedBatchName,
        'desc': description,
      },
    );
    Future<void> confirmAction() => _uploadAndNavigate(columns);
    // ignore: use_build_context_synchronously
    await context.push(previewUri.toString(), extra: confirmAction);
  }

  Future<void> _uploadAndNavigate(List<String> columns) async {
    if (_creating) return;
    final PickedFile? pickedFile = _pickedFile;
    if (pickedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload an Excel file first.')),
      );
      return;
    }

    setState(() => _creating = true);
    try {
      final VerificationRepository repo = ref.read(
        verificationRepositoryProvider,
      );
      final bool isWarranty = _mode == 'warranty';
      final BulkUploadResponse res = isWarranty
          ? await repo.uploadWarrantyProducts(
              batchName: _resolvedBatchName,
              description: _resolvedDescription(),
              fileBytes: pickedFile.bytes,
              fileName: pickedFile.name,
            )
          : await repo.bulkUploadProducts(
              batchName: _resolvedBatchName,
              description: _resolvedDescription(),
              verificationTypes: _resolvedVerificationTypesCsv(),
              fileBytes: pickedFile.bytes,
              fileName: pickedFile.name,
            );
      await ref
          .read(batchNameStoreProvider.notifier)
          .setBatchName(res.batchId, _resolvedBatchName);
      if (!mounted) return;
      final String checks = _resolvedVerificationTypesCsv();
      final Uri uri = Uri(
        path: AppRouter.productBatchCreatedPath,
        queryParameters: <String, String>{
          'sector': _sector,
          if (_industry.trim().isNotEmpty) 'industry': _industry.trim(),
          if (_categoryId.trim().isNotEmpty) 'category_id': _categoryId.trim(),
          'batch': _resolvedBatchName,
          'records': res.totalUploaded.toString(),
          'skipped': res.totalSkipped.toString(),
          'batchId': res.batchId,
          if (columns.isNotEmpty) 'columns': columns.join(','),
          if (checks.isNotEmpty) 'checks': checks,
          'access': _access,
          'flow': 'product',
          'mode': _mode,
          if (_mode == 'warranty') 'supports_warranty': 'true',
          if (_mode == 'warranty' && _industry.trim().isNotEmpty)
            'industry_label': _prettyIndustry(_industry),
        },
      );
      context.go(uri.toString(), extra: res);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Something went wrong. Please try again.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  String _resolvedDescription() {
    final String typed = _description.trim();
    if (typed.isNotEmpty) return typed;
    return _defaultDescriptionForMode();
  }

  String _defaultDescriptionForMode() {
    final String modeLabel = _mode == 'warranty'
        ? 'Warranty'
        : 'Product Verification';
    return '$_sector • $modeLabel';
  }

  String _resolvedVerificationTypesCsv() {
    final List<String> checks = _checks
        .map((String value) => value.trim())
        .where((String value) => value.isNotEmpty)
        .toList()
      ..sort();
    return checks.join(',');
  }
  List<String> _columns() {
    final List<String> source = _savedTemplateHeaders.isNotEmpty
        ? _savedTemplateHeaders
        : _defaultTemplateHeaders();
    final List<String> out = source
        .map((String s) => s.trim())
        .where((String s) => s.isNotEmpty)
        .toList();
    return out;
  }

  String _effectiveIndustry() {
    final AsyncValue<AuthState> authAsync = ref.read(authNotifierProvider);
    final String? orgId = authAsync.valueOrNull?.userProfile?.id;
    final AsyncValue<String?> industryAsync = orgId == null
        ? const AsyncData<String?>(null)
        : ref.read(organizationIndustryTypeProvider(orgId));
    final String apiIndustry = industryAsync.valueOrNull?.trim() ?? '';
    final String profileIndustry =
        authAsync.valueOrNull?.userProfile?.industry?.trim() ?? '';
    if (_industry.trim().isNotEmpty) return _industry.trim();
    if (apiIndustry.isNotEmpty) return apiIndustry;
    return profileIndustry;
  }

  static String _prettyIndustry(String raw) {
    final String v = raw.trim();
    if (v.isEmpty) return 'Product';
    final String lower = v.toLowerCase();
    if (lower == 'all' || lower == 'both') return 'All';

    final List<String> parts = _parseIndustryParts(v);
    if (parts.length > 1) {
      if (parts.length >= 10) return 'All';
      return '${_formatIndustryPart(parts.first)} +${parts.length - 1}';
    }
    if (parts.isNotEmpty) return _formatIndustryPart(parts.first);

    final List<String> singleParts = v
        .replaceAll(RegExp(r'[_-]+'), ' ')
        .split(' ')
        .where((String p) => p.trim().isNotEmpty)
        .toList();
    if (singleParts.isEmpty) return 'Product';
    return singleParts.map(_formatIndustryPart).join(' ');
  }

  static List<String> _parseIndustryParts(String raw) {
    final String v = raw.trim();
    if (v.isEmpty) return <String>[];
    if (v.startsWith('[') && v.endsWith(']')) {
      return v
          .substring(1, v.length - 1)
          .split(',')
          .map((String s) => s.replaceAll('"', '').trim())
          .where((String s) => s.isNotEmpty)
          .toList();
    }
    if (v.contains(',')) {
      return v
          .split(',')
          .map((String s) => s.trim())
          .where((String s) => s.isNotEmpty)
          .toList();
    }
    return <String>[v];
  }

  static String _formatIndustryPart(String s) {
    final String cleaned = s.replaceAll(RegExp(r'[_-]+'), ' ').trim();
    if (cleaned.isEmpty) return '';
    final List<String> tokens = cleaned
        .split(' ')
        .where((String token) => token.trim().isNotEmpty)
        .toList();
    return tokens
        .map(
          (String token) => token.isEmpty
              ? token
              : '${token[0].toUpperCase()}${token.substring(1).toLowerCase()}',
        )
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final double referenceWidth = 402;
    final String resolvedIndustry = _effectiveIndustry();
    final String displayIndustry = _prettyIndustry(resolvedIndustry);
    final String verificationFilter = resolvedIndustry.isNotEmpty
        ? 'product::$resolvedIndustry'
        : 'product';
    final AsyncValue<List<VerificationTypeDefinition>> productTypesAsync = ref
        .watch(verificationTypesProvider(verificationFilter));
    final Map<String, VerificationTypeDefinition> productTypesById =
        <String, VerificationTypeDefinition>{
          for (final VerificationTypeDefinition item
              in productTypesAsync.valueOrNull ??
                  <VerificationTypeDefinition>[])
            item.id: item,
        };
    final bool isWarranty = _mode == 'warranty';
    final int currentStep = isWarranty ? 3 : 4;
    final int totalSteps = isWarranty ? 5 : 6;
    final String stepLabel = 'STEP $currentStep OF $totalSteps';
    final String progressLabel =
        '${((currentStep / totalSteps) * 100).round()}%';
    return Scaffold(
      backgroundColor: AppColors.brandBlue,
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
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
                      child: Row(
                        children: <Widget>[
                          InkResponse(
                            onTap: () => _goBack(context),
                            radius: s(22),
                            child: SvgPicture.asset(
                              'assets/icons/figma/new_batch_back.svg',
                              width: s(24),
                              height: s(24),
                              colorFilter: const ColorFilter.mode(
                                Colors.white,
                                BlendMode.srcIn,
                              ),
                            ),
                          ),
                          SizedBox(width: s(12)),
                          Text(
                            'Bulk Upload',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: s(21),
                              fontWeight: FontWeight.w600,
                              height: 19.5 / 21,
                              color: Colors.white,
                            ),
                          ),
                          const Spacer(),
                          ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: contentWidth * 0.42,
                            ),
                            child: _IndustryPill(
                              scale: scale,
                              label: displayIndustry,
                              onTap: () {},
                            ),
                          ),
                        ],
                      ),
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
                                      stepLabel: stepLabel,
                                      progressLabel: progressLabel,
                                      fillFactor: currentStep / totalSteps,
                                    ),
                                    SizedBox(height: s(24)),
                                    Text(
                                      'BATCH NAME',
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: s(12),
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: s(1.1),
                                        height: 18 / 12,
                                        color: const Color(0xFF3A3A3A),
                                      ),
                                    ),
                                    SizedBox(height: s(12)),
                                    _ProductBatchNameField(
                                      scale: scale,
                                      controller: _batchNameController,
                                      onChanged: () => setState(() {}),
                                    ),
                                    SizedBox(height: s(10)),
                                    Text(
                                      'Assign a unique name to easily track this upload later.',
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: s(11),
                                        fontWeight: FontWeight.w500,
                                        height: 16 / 11,
                                        color: const Color(0xFF94A3B8),
                                      ),
                                    ),
                                    if (_checks.isNotEmpty) ...<Widget>[
                                      SizedBox(height: s(16)),
                                      Text(
                                        'Selected checks',
                                        style: TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: s(12),
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: s(1.1),
                                          height: 18 / 12,
                                          color: const Color(0xFF3A3A3A),
                                        ),
                                      ),
                                      SizedBox(height: s(10)),
                                      if (productTypesAsync.isLoading &&
                                          productTypesAsync.valueOrNull == null)
                                        Text(
                                          'Loading verification types...',
                                          style: TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: s(12),
                                            fontWeight: FontWeight.w500,
                                            height: 18 / 12,
                                            color: const Color(0xFF64748B),
                                          ),
                                        )
                                      else
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          children: <Widget>[
                                            for (final String check
                                                in _checks.toList()..sort())
                                              Chip(
                                                label: Text(
                                                  productTypesById[check]
                                                          ?.name ??
                                                      check,
                                                ),
                                                backgroundColor: AppColors
                                                    .brandBlue
                                                    .withAlpha(18),
                                                labelStyle: TextStyle(
                                                  fontFamily: 'Inter',
                                                  fontSize: s(12),
                                                  fontWeight: FontWeight.w600,
                                                  height: 16.5 / 12,
                                                  color: AppColors.brandBlue,
                                                ),
                                              ),
                                          ],
                                        ),
                                    ],
                                    SizedBox(height: s(26)),
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: <Widget>[
                                        Expanded(
                                          child: Text(
                                            'Upload Excel',
                                            style: TextStyle(
                                              fontFamily: 'Inter',
                                              fontSize: s(32),
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: s(1.18),
                                              height: 34 / 32,
                                              color: const Color(0xFF3A3A3A),
                                            ),
                                          ),
                                        ),
                                        TextButton(
                                          onPressed: _downloadTemplate,
                                          style: TextButton.styleFrom(
                                            padding: EdgeInsets.zero,
                                            minimumSize: Size.zero,
                                            tapTargetSize: MaterialTapTargetSize
                                                .shrinkWrap,
                                            visualDensity:
                                                VisualDensity.compact,
                                            foregroundColor:
                                                AppColors.brandBlue,
                                            textStyle: TextStyle(
                                              fontFamily: 'Inter',
                                              fontSize: s(12),
                                              fontWeight: FontWeight.w600,
                                              height: 18 / 12,
                                            ),
                                          ),
                                          child: const Text(
                                            'Download Excel',
                                            style: TextStyle(
                                              color: AppColors.brandBlue,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: s(14)),
                                    Text(
                                      'Download template based on your selected sector.\nUpload your Excel, optionally add documents, then confirm the batch.',
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
                                    _DropZone(
                                      scale: scale,
                                      onTap: _pickExcelFile,
                                    ),
                                    SizedBox(height: s(26)),
                                    if (_pickedFile != null) ...<Widget>[
                                      Text(
                                        'SELECTED FILE',
                                        style: TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: s(12),
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: s(1.1),
                                          height: 18 / 12,
                                          color: const Color(0xFF3A3A3A),
                                        ),
                                      ),
                                      SizedBox(height: s(12)),
                                      _SelectedFileCard(
                                        scale: scale,
                                        fileName: _pickedFile!.name,
                                        fileSizeLabel: _formatBytes(
                                          _pickedFile!.bytes.length,
                                        ),
                                        onRemove: () =>
                                            setState(() => _pickedFile = null),
                                      ),
                                    ],
                                    SizedBox(height: s(28)),
                                    _DocumentUploadsSection(
                                      scale: scale,
                                      modeLabel: isWarranty
                                          ? 'Warranty'
                                          : 'Verification',
                                      defaultProductId: _defaultProductId,
                                      cardIds: _documentCardIds,
                                      onToggleSection: _toggleDocumentSection,
                                      onAddCard: _addDocumentCard,
                                      onRemoveCard: _removeDocumentCard,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            _BottomNav(
                              scale: scale,
                              child: _UploadButton(
                                scale: scale,
                                isLoading: _creating,
                                enabled:
                                    !_creating &&
                                    _pickedFile != null &&
                                    _resolvedBatchName.isNotEmpty,
                                onTap: _confirmAndCreateBatch,
                                label: 'Create Batch',
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

class _ProductBatchNameField extends StatelessWidget {
  const _ProductBatchNameField({
    required this.scale,
    required this.controller,
    required this.onChanged,
  });

  final double scale;
  final TextEditingController controller;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    double s(double v) => v * scale;

    return TextField(
      controller: controller,
      onChanged: (_) => onChanged(),
      decoration: InputDecoration(
        hintText: 'Enter a batch name, Ex. Product Verification Q1',
        hintStyle: TextStyle(
          fontFamily: 'Inter',
          fontSize: s(14),
          fontWeight: FontWeight.w500,
          height: 20 / 14,
          color: const Color(0xFFC7D2E1),
        ),
        filled: true,
        fillColor: const Color(0xFFF7F9FC),
        contentPadding: EdgeInsets.fromLTRB(s(16), s(16), s(16), s(16)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(s(18)),
          borderSide: BorderSide(
            color: const Color(0xFFCBD5E1).withAlpha(160),
            width: s(1),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(s(18)),
          borderSide: BorderSide(
            color: const Color(0xFFCBD5E1).withAlpha(160),
            width: s(1),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(s(18)),
          borderSide: BorderSide(
            color: AppColors.brandBlue.withAlpha(200),
            width: s(1.2),
          ),
        ),
      ),
      style: TextStyle(
        fontFamily: 'Inter',
        fontSize: s(14),
        fontWeight: FontWeight.w600,
        height: 20 / 14,
        color: const Color(0xFF111827),
      ),
      textInputAction: TextInputAction.done,
    );
  }
}

class _ProductTemplateDialog extends ConsumerStatefulWidget {
  const _ProductTemplateDialog({
    required this.initialHeaders,
    required this.categoryId,
    required this.isWarranty,
    required this.onSave,
  });

  final List<String> initialHeaders;
  final String categoryId;
  final bool isWarranty;
  final ValueChanged<List<String>> onSave;

  @override
  ConsumerState<_ProductTemplateDialog> createState() =>
      _ProductTemplateDialogState();
}

class _ProductTemplateDialogState
    extends ConsumerState<_ProductTemplateDialog> {
  static const MethodChannel _downloadsChannel = MethodChannel(
    'trumarkz/downloads',
  );

  late final TextEditingController _headerInputController;
  late List<String> _headers;
  bool _isGenerating = false;
  bool _headersSaved = false;

  @override
  void initState() {
    super.initState();
    _headerInputController = TextEditingController();
    _headers = _normalizeHeaders(widget.initialHeaders);
    _headersSaved = _headers.isNotEmpty;
  }

  @override
  void dispose() {
    _headerInputController.dispose();
    super.dispose();
  }

  List<String> _normalizeHeaders(List<String> headers) {
    final List<String> merged = <String>[];
    final Set<String> seen = <String>{};

    for (final String raw in headers) {
      final String cleaned = raw.trim();
      if (cleaned.isEmpty) continue;
      final String key = cleaned.toLowerCase();
      if (seen.add(key)) {
        merged.add(cleaned);
      }
    }
    return merged;
  }

  void _addHeader() {
    final String cleaned = _headerInputController.text.trim();
    if (cleaned.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a header first.')),
      );
      return;
    }
    setState(() {
      _headers = _normalizeHeaders(<String>[..._headers, cleaned]);
      _headersSaved = true;
    });
    widget.onSave(List<String>.from(_headers));
    _headerInputController.clear();
  }

  void _removeHeader(String header) {
    setState(() {
      _headers = List<String>.from(_headers)
        ..removeWhere(
          (String value) => value.toLowerCase() == header.toLowerCase(),
        );
      _headersSaved = _headers.isNotEmpty;
    });
    widget.onSave(List<String>.from(_headers));
  }

  Future<void> _generateTemplate() async {
    if (_headers.isEmpty || _isGenerating) return;
    if (!widget.isWarranty && widget.categoryId.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Missing sector category. Please go back and reselect.',
          ),
        ),
      );
      return;
    }

    setState(() {
      _isGenerating = true;
    });

    try {
      final VerificationRepository repo = ref.read(
        verificationRepositoryProvider,
      );
      final VerificationBinaryResponse res = widget.isWarranty
          ? await repo.generateWarrantyTemplate()
          : await repo.generateProductsTemplate(
              categoryId: widget.categoryId,
              headers: <String>[
                for (final String header in _headers)
                  if (header.trim().isNotEmpty)
                    header.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '_'),
              ],
            );
      if (!mounted) return;

      final Uint8List templateBytes = res.bytes;
      String savedUri = '';
      try {
        savedUri =
            await _downloadsChannel.invokeMethod<
              String
            >('saveFileToDownloads', <String, dynamic>{
              'fileName': res.filename,
              'mimeType':
                  'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
              'bytes': templateBytes,
            }) ??
            '';
      } on MissingPluginException catch (e) {
        debugPrint('[ProductTemplate] downloads channel missing: $e');
      }

      if (!mounted) return;
      Navigator.of(context).pop();
      if (savedUri.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Template generated. Restart the app once to enable Downloads save, or use Share now.',
            ),
            action: SnackBarAction(
              label: 'Share',
              onPressed: () async {
                await Share.shareXFiles(<XFile>[
                  XFile.fromData(
                    templateBytes,
                    name: res.filename,
                    mimeType:
                        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
                  ),
                ]);
              },
            ),
          ),
        );
        return;
      }
      await _showTemplateActions(
        filePath: savedUri,
        fileName: res.filename,
        fileBytes: templateBytes,
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      debugPrint('[ProductTemplate] unexpected failure: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Something went wrong. Please try again.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final MediaQueryData mediaQuery = MediaQuery.of(context);
    final bool keyboardOpen = mediaQuery.viewInsets.bottom > 0;
    final double scale = mediaQuery.size.width / 402;
    double s(double v) => v * scale;

    return Dialog.fullscreen(
      backgroundColor: const Color(0xFFF8FAFC),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: const Color(0xFFF8FAFC),
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            widget.isWarranty ? 'Download Warranty Excel' : 'Download Excel',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: s(16),
              fontWeight: FontWeight.w700,
              height: 24 / 16,
              color: const Color(0xFF111827),
            ),
          ),
          centerTitle: false,
        ),
        body: ListView(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.x4,
            AppSpacing.x2,
            AppSpacing.x4,
            AppSpacing.x4 + AppSpacing.x8,
          ),
          children: <Widget>[
            Text(
              widget.isWarranty
                  ? 'Use the fixed warranty template, then fill it out and upload it back.'
                  : 'Add headers one at a time. Added headers are saved automatically, then generate the product template.',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: s(12),
                fontWeight: FontWeight.w500,
                height: 18 / 12,
                color: const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: AppSpacing.x4),
            Text(
              widget.isWarranty
                  ? 'Warranty template fields'
                  : 'Default product fields',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: s(12),
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
                height: 18 / 12,
                color: const Color(0xFF111827),
              ),
            ),
            const SizedBox(height: AppSpacing.x2),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                for (final String header in widget.initialHeaders)
                  Chip(
                    label: Text(header),
                    backgroundColor: AppColors.brandBlue.withAlpha(20),
                    labelStyle: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: s(12),
                      fontWeight: FontWeight.w600,
                      height: 16.5 / 12,
                      color: AppColors.brandBlue,
                    ),
                  ),
              ],
            ),
            if (!widget.isWarranty) ...<Widget>[
              const SizedBox(height: AppSpacing.x4),
              TextField(
                controller: _headerInputController,
                onSubmitted: (_) => _addHeader(),
                textInputAction: TextInputAction.done,
                scrollPadding: const EdgeInsets.only(bottom: 180),
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: s(14),
                  fontWeight: FontWeight.w400,
                  height: 20 / 14,
                  color: const Color(0xFF0F172A),
                ),
                cursorColor: AppColors.brandBlue,
                decoration: InputDecoration(
                  hintText: 'Enter header name',
                  hintStyle: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: s(14),
                    fontWeight: FontWeight.w400,
                    height: 20 / 14,
                    color: const Color(0xFF94A3B8),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: AppColors.brandBlue,
                      width: s(1.2),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.x3),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _addHeader,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandBlue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: EdgeInsets.symmetric(vertical: s(14)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'Add New',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: s(14),
                      fontWeight: FontWeight.w700,
                      height: 20 / 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.x4),
              Text(
                'Saved headers',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: s(12),
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                  height: 18 / 12,
                  color: const Color(0xFF111827),
                ),
              ),
              const SizedBox(height: AppSpacing.x2),
              if (_headers.isEmpty)
                Text(
                  'No headers added yet.',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: s(12),
                    fontWeight: FontWeight.w500,
                    height: 18 / 12,
                    color: const Color(0xFF64748B),
                  ),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    for (final String header in _headers)
                      InputChip(
                        label: Text(header),
                        backgroundColor: AppColors.brandBlue,
                        deleteIcon: const Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                        ),
                        onDeleted: () => _removeHeader(header),
                        labelStyle: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: s(12),
                          fontWeight: FontWeight.w600,
                          height: 16.5 / 12,
                          color: Colors.white,
                        ),
                        deleteIconColor: Colors.white,
                      ),
                  ],
                ),
            ],
            const SizedBox(height: AppSpacing.x8),
            if (_headersSaved)
              Text(
                widget.isWarranty
                    ? 'Warranty fields locked. You can generate the template now.'
                    : 'Headers saved. You can generate the template now.',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: s(12),
                  fontWeight: FontWeight.w600,
                  height: 18 / 12,
                  color: const Color(0xFF0F766E),
                ),
              ),
          ],
        ),
        bottomNavigationBar: SafeArea(
          top: false,
          child: keyboardOpen
              ? const SizedBox.shrink()
              : AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.x4,
                    AppSpacing.x2,
                    AppSpacing.x4,
                    AppSpacing.x4,
                  ),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF8FAFC),
                    border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _headers.isNotEmpty && !_isGenerating
                          ? _generateTemplate
                          : null,
                      icon: _isGenerating
                          ? SizedBox(
                              width: s(16),
                              height: s(16),
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.download_rounded),
                      label: Text(
                        _isGenerating
                            ? 'Generating...'
                            : widget.isWarranty
                                ? 'Generate Warranty Template'
                                : 'Generate Product Template',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.brandBlue,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: EdgeInsets.symmetric(vertical: s(14)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        textStyle: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: s(14),
                          fontWeight: FontWeight.w700,
                          height: 20 / 14,
                        ),
                      ),
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Future<void> _showTemplateActions({
    required String filePath,
    required String fileName,
    required Uint8List fileBytes,
  }) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Template ready'),
          content: const Text('Your Excel template has been generated.'),
          actions: <Widget>[
            TextButton(
              onPressed: () async {
                try {
                  await launchUrl(
                    Uri.parse(filePath),
                    mode: LaunchMode.externalApplication,
                  );
                } catch (e) {
                  debugPrint('[ProductTemplate] open failed: $e');
                }
                if (context.mounted) Navigator.of(context).pop();
              },
              child: const Text('Open file'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  await Share.shareXFiles(<XFile>[
                    XFile.fromData(fileBytes, name: fileName),
                  ]);
                } catch (e) {
                  debugPrint('[ProductTemplate] share failed: $e');
                }
                if (context.mounted) Navigator.of(context).pop();
              },
              child: const Text('Share file'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}

class _IndustryPill extends StatelessWidget {
  const _IndustryPill({
    required this.scale,
    required this.label,
    required this.onTap,
  });

  final double scale;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    double s(double v) => v * scale;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(s(10)),
      child: Container(
        height: s(29),
        padding: EdgeInsets.symmetric(horizontal: s(12), vertical: s(6)),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F7FF),
          borderRadius: BorderRadius.circular(s(10)),
          border: Border.all(color: const Color(0xFFE0EFFE)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            SvgPicture.asset(
              'assets/icons/figma/bulk_industry_building.svg',
              width: s(12),
              height: s(10),
              colorFilter: const ColorFilter.mode(
                AppColors.brandBlue,
                BlendMode.srcIn,
              ),
            ),
            SizedBox(width: s(8)),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: s(11),
                  fontWeight: FontWeight.w600,
                  letterSpacing: s(0.0644531),
                  height: 16.5 / 11,
                  color: AppColors.brandBlue,
                ),
              ),
            ),
            SizedBox(width: s(8)),
            Container(
              width: s(1),
              height: s(12),
              color: const Color(0xFFE2E8F0),
            ),
            SizedBox(width: s(8)),
            Text(
              'EDIT',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: s(10),
                fontWeight: FontWeight.w600,
                letterSpacing: s(0.25),
                height: 15 / 10,
                color: AppColors.brandBlue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GradientCtaButton extends StatefulWidget {
  const _GradientCtaButton({
    required this.label,
    required this.icon,
    required this.gradient,
    required this.enabled,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final Gradient gradient;
  final bool enabled;
  final FutureOr<void> Function() onPressed;

  @override
  State<_GradientCtaButton> createState() => _GradientCtaButtonState();
}

class _GradientCtaButtonState extends State<_GradientCtaButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final Widget content = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(
          widget.label,
          style: AppTypography.button.copyWith(color: Colors.white),
        ),
        const SizedBox(width: 10),
        Icon(widget.icon, color: Colors.white, size: 18),
      ],
    );

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 150),
      opacity: widget.enabled ? 1 : 0.45,
      child: SizedBox(
        height: 54,
        width: double.infinity,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: widget.gradient,
            borderRadius: BorderRadius.circular(999),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: AppColors.brandBlue.withAlpha(40),
                blurRadius: 22,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: widget.enabled ? () => widget.onPressed() : null,
              onHighlightChanged: (bool value) =>
                  setState(() => _isPressed = value),
              child: AnimatedScale(
                duration: const Duration(milliseconds: 90),
                scale: _isPressed ? 0.985 : 1,
                child: Center(child: content),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DropZone extends StatelessWidget {
  const _DropZone({required this.scale, required this.onTap});

  final double scale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    double s(double v) => v * scale;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(s(20)),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(s(16), s(26), s(16), s(26)),
        decoration: BoxDecoration(
          color: const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(s(20)),
        ),
        child: CustomPaint(
          painter: _DashedRRectPainter(
            radius: s(20),
            strokeWidth: s(2),
            dashLength: s(8),
            gapLength: s(6),
            color: const Color(0xFFBFD6FF),
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(s(14), s(20), s(14), s(20)),
            child: Column(
              children: <Widget>[
                Container(
                  width: s(64),
                  height: s(64),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(s(18)),
                    border: Border.all(
                      color: const Color(0xFFE6EAF2),
                      width: s(1),
                    ),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: Colors.black.withAlpha(20),
                        blurRadius: s(16),
                        offset: Offset(0, s(6)),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: SvgPicture.asset(
                    'assets/icons/figma/bulk_upload_icon_upload.svg',
                    width: s(28),
                    height: s(28),
                    colorFilter: const ColorFilter.mode(
                      AppColors.brandBlue,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
                SizedBox(height: s(18)),
                Text(
                  'Tap to select your file',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: s(20),
                    fontWeight: FontWeight.w700,
                    letterSpacing: s(0.2),
                    height: 24 / 20,
                    color: const Color(0xFF111827),
                  ),
                ),
                SizedBox(height: s(8)),
                Text(
                  'Upload your Excel file here',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: s(12),
                    fontWeight: FontWeight.w500,
                    letterSpacing: s(0.1),
                    height: 18 / 12,
                    color: const Color(0xFF64748B),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectedFileCard extends StatelessWidget {
  const _SelectedFileCard({
    required this.scale,
    required this.fileName,
    required this.fileSizeLabel,
    required this.onRemove,
  });

  final double scale;
  final String fileName;
  final String fileSizeLabel;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    double s(double v) => v * scale;

    return Container(
      padding: EdgeInsets.fromLTRB(s(14), s(14), s(14), s(14)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(s(18)),
        border: Border.all(color: const Color(0xFFE5E7EB), width: s(1)),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: s(48),
            height: s(48),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(s(14)),
            ),
            alignment: Alignment.center,
            child: SvgPicture.asset(
              'assets/icons/figma/bulk_upload_icon_file_attach.svg',
              width: s(26),
              height: s(26),
              colorFilter: const ColorFilter.mode(
                Colors.black,
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
                  fileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: s(16),
                    fontWeight: FontWeight.w700,
                    height: 20 / 16,
                    color: const Color(0xFF111827),
                  ),
                ),
                SizedBox(height: s(4)),
                Text(
                  fileSizeLabel,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: s(12),
                    fontWeight: FontWeight.w500,
                    height: 16 / 12,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
          InkResponse(
            onTap: onRemove,
            radius: s(20),
            child: SvgPicture.asset(
              'assets/icons/figma/bulk_close_x.svg',
              width: s(18),
              height: s(18),
              colorFilter: const ColorFilter.mode(
                Color(0xFF9CA3AF),
                BlendMode.srcIn,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UploadButton extends StatelessWidget {
  const _UploadButton({
    required this.scale,
    required this.isLoading,
    required this.enabled,
    required this.onTap,
    required this.label,
  });

  final double scale;
  final bool isLoading;
  final bool enabled;
  final VoidCallback onTap;
  final String label;

  @override
  Widget build(BuildContext context) {
    double s(double v) => v * scale;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: enabled ? onTap : null,
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
        child: isLoading
            ? SizedBox(
                width: s(20),
                height: s(20),
                child: CircularProgressIndicator(
                  strokeWidth: s(2),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
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
    );
  }
}

class _DocumentUploadsSection extends StatelessWidget {
  const _DocumentUploadsSection({
    required this.scale,
    required this.modeLabel,
    required this.defaultProductId,
    required this.cardIds,
    required this.onToggleSection,
    required this.onAddCard,
    required this.onRemoveCard,
  });

  final double scale;
  final String modeLabel;
  final String defaultProductId;
  final List<int> cardIds;
  final VoidCallback onToggleSection;
  final VoidCallback onAddCard;
  final ValueChanged<int> onRemoveCard;

  @override
  Widget build(BuildContext context) {
    double s(double v) => v * scale;
    final bool hasCards = cardIds.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Add Documents',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: s(14),
                      fontWeight: FontWeight.w700,
                      letterSpacing: s(0.2),
                      height: 20 / 14,
                      color: const Color(0xFF111827),
                    ),
                  ),
                  SizedBox(height: s(4)),
                  Text(
                    '$modeLabel uploads are optional. Attach certificates, warranty cards, or compliance docs to a specific product UUID.',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: s(11),
                      fontWeight: FontWeight.w500,
                      height: 16 / 11,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            TextButton.icon(
              onPressed: onToggleSection,
              icon: Icon(
                hasCards ? Icons.remove_rounded : Icons.add_rounded,
                size: s(16),
              ),
              label: Text(hasCards ? 'Remove' : 'Add documents'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.brandBlue,
                padding: EdgeInsets.symmetric(
                  horizontal: s(12),
                  vertical: s(10),
                ),
                textStyle: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: s(12),
                  fontWeight: FontWeight.w700,
                  height: 16 / 12,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: s(14)),
        if (hasCards) ...<Widget>[
          for (final int cardId in cardIds) ...<Widget>[
            _ProductDocumentCard(
              key: ValueKey<int>(cardId),
              scale: scale,
              defaultProductId: defaultProductId,
              onRemove: () => onRemoveCard(cardId),
            ),
            SizedBox(height: s(12)),
          ],
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: onAddCard,
              icon: Icon(Icons.add_rounded, size: s(16)),
              label: const Text('Add another document'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.brandBlue,
                padding: EdgeInsets.zero,
                textStyle: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: s(12),
                  fontWeight: FontWeight.w700,
                  height: 16 / 12,
                ),
              ),
            ),
          ),
        ] else
          Text(
            'Add one or more documents if needed, or continue without them.',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: s(11),
              fontWeight: FontWeight.w500,
              height: 16 / 11,
              color: const Color(0xFF64748B),
            ),
          ),
      ],
    );
  }
}

class _ProductDocumentCard extends ConsumerStatefulWidget {
  const _ProductDocumentCard({
    super.key,
    required this.scale,
    required this.defaultProductId,
    required this.onRemove,
  });

  final double scale;
  final String defaultProductId;
  final VoidCallback onRemove;

  @override
  ConsumerState<_ProductDocumentCard> createState() =>
      _ProductDocumentCardState();
}

class _ProductDocumentCardState extends ConsumerState<_ProductDocumentCard> {
  static const List<String> _labelOptions = <String>[
    'certificate',
    'warranty_card',
    'compliance_doc',
  ];

  late final TextEditingController _productIdController;
  PickedFile? _pickedFile;
  bool _uploading = false;
  String _documentLabel = _labelOptions.first;
  UploadDocumentResponse? _response;

  @override
  void initState() {
    super.initState();
    _productIdController = TextEditingController(
      text: widget.defaultProductId,
    );
  }

  @override
  void dispose() {
    _productIdController.dispose();
    super.dispose();
  }

  Future<void> _pickDocument() async {
    if (_uploading) return;
    final PickedFile? picked = await FilePickerUtil.pickDocument();
    if (!mounted || picked == null) return;
    setState(() {
      _pickedFile = picked;
      _uploading = true;
      _response = null;
    });
    final String productId = _productIdController.text.trim();
    if (productId.isEmpty) {
      if (!mounted) return;
      setState(() => _uploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product ID is required.')),
      );
      return;
    }

    try {
      final VerificationRepository repo = ref.read(
        verificationRepositoryProvider,
      );
      final UploadDocumentResponse res = await repo.uploadProductDocument(
        productId: productId,
        documentLabel: _documentLabel,
        fileBytes: picked.bytes,
        fileName: picked.name,
      );
      if (!mounted) return;
      setState(() => _response = res);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            res.message.isEmpty
                ? 'Document uploaded successfully.'
                : res.message,
          ),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Something went wrong. Please try again.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    double s(double v) => v * widget.scale;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(s(14)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(s(18)),
        border: Border.all(color: const Color(0xFFE5E7EB), width: s(1)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withAlpha(6),
            blurRadius: s(18),
            offset: Offset(0, s(8)),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: s(36),
                height: s(36),
                decoration: BoxDecoration(
                  color: AppColors.brandBlue.withAlpha(14),
                  borderRadius: BorderRadius.circular(s(12)),
                ),
                child: Icon(
                  Icons.description_rounded,
                  size: s(20),
                  color: AppColors.brandBlue,
                ),
              ),
              SizedBox(width: s(10)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Document upload',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: s(14),
                        fontWeight: FontWeight.w700,
                        height: 20 / 14,
                        color: const Color(0xFF111827),
                      ),
                    ),
                    SizedBox(height: s(2)),
                    Text(
                      'Attach a file to a product UUID.',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: s(11),
                        fontWeight: FontWeight.w500,
                        height: 16 / 11,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: widget.onRemove,
                icon: const Icon(Icons.close_rounded),
                color: const Color(0xFF94A3B8),
                tooltip: 'Remove document card',
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          SizedBox(height: s(14)),
          TextField(
            controller: _productIdController,
            textInputAction: TextInputAction.next,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: s(13),
              fontWeight: FontWeight.w600,
              height: 18 / 13,
              color: const Color(0xFF111827),
            ),
            decoration: InputDecoration(
              labelText: 'Product ID',
              hintText: 'UUID of the product record',
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(s(14)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(s(14)),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(s(14)),
                borderSide: BorderSide(
                  color: AppColors.brandBlue,
                  width: s(1.2),
                ),
              ),
            ),
          ),
          SizedBox(height: s(12)),
          Text(
            'Document label',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: s(12),
              fontWeight: FontWeight.w700,
              height: 18 / 12,
              color: const Color(0xFF111827),
            ),
          ),
          SizedBox(height: s(8)),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _labelOptions.map((String label) {
              final bool selected = _documentLabel == label;
              return ChoiceChip(
                label: Text(label),
                selected: selected,
                onSelected: (_) {
                  setState(() => _documentLabel = label);
                },
                selectedColor: AppColors.brandBlue.withAlpha(18),
                backgroundColor: const Color(0xFFF8FAFC),
                labelStyle: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: s(12),
                  fontWeight: FontWeight.w600,
                  color: selected ? AppColors.brandBlue : const Color(0xFF475569),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                  side: BorderSide(
                    color: selected
                        ? AppColors.brandBlue.withAlpha(50)
                        : const Color(0xFFE5E7EB),
                  ),
                ),
              );
            }).toList(),
          ),
          SizedBox(height: s(12)),
          OutlinedButton.icon(
            onPressed: _uploading ? null : _pickDocument,
            icon: const Icon(Icons.attach_file_rounded),
            label: Text(
              _pickedFile == null ? 'Choose file' : _pickedFile!.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF111827),
              backgroundColor: const Color(0xFFF8FAFC),
              side: const BorderSide(color: Color(0xFFE5E7EB)),
              padding: EdgeInsets.symmetric(
                horizontal: s(14),
                vertical: s(14),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(s(14)),
              ),
              textStyle: TextStyle(
                fontFamily: 'Inter',
                fontSize: s(13),
                fontWeight: FontWeight.w600,
                height: 18 / 13,
              ),
            ),
          ),
          if (_pickedFile != null) ...<Widget>[
            SizedBox(height: s(10)),
            Row(
              children: <Widget>[
                Icon(
                  Icons.check_circle_rounded,
                  color: Colors.green.shade600,
                  size: s(16),
                ),
                SizedBox(width: s(6)),
                Expanded(
                  child: Text(
                    'Selected: ${_pickedFile!.name}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: s(11),
                      fontWeight: FontWeight.w500,
                      height: 16 / 11,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (_response != null) ...<Widget>[
            SizedBox(height: s(10)),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(s(12)),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(s(14)),
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    _response!.message.isEmpty
                        ? 'Uploaded successfully'
                        : _response!.message,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: s(12),
                      fontWeight: FontWeight.w700,
                      height: 18 / 12,
                      color: const Color(0xFF166534),
                    ),
                  ),
                  SizedBox(height: s(4)),
                  Text(
                    'Version ${_response!.version} • ${_response!.documentId}',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: s(11),
                      fontWeight: FontWeight.w500,
                      height: 16 / 11,
                      color: const Color(0xFF15803D),
                    ),
                  ),
                ],
              ),
            ),
          ],
    SizedBox(height: s(12)),
          Text(
            'Selecting a file uploads it automatically.',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: s(11),
              fontWeight: FontWeight.w500,
              height: 16 / 11,
              color: const Color(0xFF64748B),
            ),
          ),
        ],
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

class _DashedRRectPainter extends CustomPainter {
  const _DashedRRectPainter({
    required this.radius,
    required this.strokeWidth,
    required this.dashLength,
    required this.gapLength,
    required this.color,
  });

  final double radius;
  final double strokeWidth;
  final double dashLength;
  final double gapLength;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    final RRect rrect = RRect.fromRectAndRadius(
      rect.deflate(strokeWidth / 2),
      Radius.circular(radius),
    );

    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final Path path = Path()..addRRect(rrect);
    final PathMetrics metrics = path.computeMetrics();
    for (final PathMetric metric in metrics) {
      double distance = 0;
      while (distance < metric.length) {
        final double next = distance + dashLength;
        final Path extract = metric.extractPath(
          distance,
          next.clamp(0, metric.length),
        );
        canvas.drawPath(extract, paint);
        distance = next + gapLength;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedRRectPainter oldDelegate) {
    return oldDelegate.radius != radius ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.dashLength != dashLength ||
        oldDelegate.gapLength != gapLength ||
        oldDelegate.color != color;
  }
}

String _formatBytes(int bytes) {
  if (bytes <= 0) return '0 B';
  const List<String> units = <String>['B', 'KB', 'MB', 'GB'];
  double b = bytes.toDouble();
  int unit = 0;
  while (b >= 1024 && unit < units.length - 1) {
    b /= 1024;
    unit++;
  }
  final String value = b >= 10 || unit == 0
      ? b.toStringAsFixed(0)
      : b.toStringAsFixed(1);
  return '$value ${units[unit]}';
}

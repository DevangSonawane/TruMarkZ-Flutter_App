import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/network/api_client.dart';
import '../../../../../core/router/app_router.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/utils/file_picker_util.dart';
import '../../../../../core/utils/spreadsheet_preview_util.dart';
import '../../../data/verification_repository.dart';
import '../../../../../core/services/batch_name_store.dart';

class ProductBulkUploadPage extends ConsumerStatefulWidget {
  const ProductBulkUploadPage({super.key});

  @override
  ConsumerState<ProductBulkUploadPage> createState() =>
      _ProductBulkUploadPageState();
}

class _ProductBulkUploadPageState extends ConsumerState<ProductBulkUploadPage> {
  bool _didInitFromRoute = false;
  final GlobalKey _menuKey = GlobalKey();

  String _sector = 'Consumer Goods & Warranty';
  String _categoryId = '';
  String _batchName = 'New Product Batch';
  String _mode = 'verification'; // 'verification' | 'warranty'

  PickedFile? _pickedFile;
  bool _creating = false;
  List<String> _savedTemplateHeaders = <String>[];
  final TextEditingController _templateHeadersController =
      TextEditingController();

  String _selectedCategoryName() => _sector.trim();

  void _goBack(BuildContext context) {
    final GoRouter router = GoRouter.of(context);
    if (router.canPop()) {
      context.pop();
    } else {
      context.go(AppRouter.dashboardPath);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInitFromRoute) return;
    _didInitFromRoute = true;

    final Object? extra = GoRouterState.of(context).extra;
    final String? sector = extra is String ? extra : null;
    if (sector != null && sector.trim().isNotEmpty) {
      _sector = sector.trim();
    }

    final Map<String, String> qp = GoRouterState.of(
      context,
    ).uri.queryParameters;

    final String? categoryId = qp['category_id'];
    if (categoryId != null && categoryId.trim().isNotEmpty) {
      _categoryId = categoryId.trim();
    } else {
      _categoryId = _sector;
    }

    final String? batch = qp['batch'];
    if (batch != null && batch.trim().isNotEmpty) {
      _batchName = batch.trim();
    }

    final String mode = (qp['mode'] ?? 'verification').trim().toLowerCase();
    if (mode == 'warranty' || mode == 'verification') {
      _mode = mode;
    }
  }

  @override
  void dispose() {
    _templateHeadersController.dispose();
    super.dispose();
  }

  Future<void> _downloadTemplate() async {
    final String suggested = _savedTemplateHeaders.isNotEmpty
        ? _savedTemplateHeaders.join(', ')
        : (_templateHeadersController.text.trim().isNotEmpty
              ? _templateHeadersController.text.trim()
              : 'product_name,category,serial_number,model');
    _templateHeadersController.text = suggested;

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (BuildContext ctx) {
        final EdgeInsets viewInsets = MediaQuery.viewInsetsOf(ctx);
        List<String> savedHeaders = List<String>.from(_savedTemplateHeaders);
        return StatefulBuilder(
          builder: (BuildContext context, void Function(void Function()) setSheetState) {
            final double scale = MediaQuery.sizeOf(context).width / 402;
            double s(double v) => v * scale;
            return SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.x4,
                  AppSpacing.x4,
                  AppSpacing.x4,
                  AppSpacing.x4 + viewInsets.bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Download Template',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: s(16),
                        fontWeight: FontWeight.w700,
                        height: 24 / 16,
                        color: const Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.x2),
                    Text(
                      'Enter column headers (comma-separated). Save them first, then generate the Excel template.',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: s(12),
                        fontWeight: FontWeight.w500,
                        height: 18 / 12,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.x3),
                    TextField(
                      controller: _templateHeadersController,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: s(14),
                        fontWeight: FontWeight.w400,
                        height: 20 / 14,
                        color: const Color(0xFF0F172A),
                      ),
                      cursorColor: AppColors.brandBlue,
                      minLines: 2,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'product_name, serial_number, model, ...',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.x4),
                    if (savedHeaders.isNotEmpty) ...<Widget>[
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: <Widget>[
                          for (final String header in savedHeaders)
                            Chip(
                              label: Text(header),
                              backgroundColor: AppColors.brandBlue.withAlpha(
                                14,
                              ),
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
                      const SizedBox(height: AppSpacing.x3),
                    ],
                    SizedBox(
                      width: double.infinity,
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                final List<String> headers =
                                    _templateHeadersController.text
                                        .split(',')
                                        .map((String s) => s.trim())
                                        .where((String s) => s.isNotEmpty)
                                        .toList();
                                if (headers.isEmpty) {
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Please enter at least 1 header.',
                                      ),
                                    ),
                                  );
                                  return;
                                }
                                final Set<String> normalized = headers
                                    .map(
                                      (String s) => s
                                          .trim()
                                          .toLowerCase()
                                          .replaceAll(' ', '_'),
                                    )
                                    .toSet();
                                if (!normalized.contains('product_name') ||
                                    !normalized.contains('category')) {
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Template must include required columns: product_name, category',
                                      ),
                                    ),
                                  );
                                  return;
                                }
                                setSheetState(() {
                                  savedHeaders = headers;
                                });
                                setState(() {
                                  _savedTemplateHeaders = headers;
                                });
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Headers saved for template generation.',
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.save_rounded),
                              label: Text(
                                'Save Headers',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: s(14),
                                  fontWeight: FontWeight.w700,
                                  height: 20 / 14,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.x3),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: savedHeaders.isEmpty
                                  ? null
                                  : () async {
                                      final ScaffoldMessengerState messenger =
                                          ScaffoldMessenger.of(ctx);
                                      final List<String> headers =
                                          List<String>.from(savedHeaders);
                                      try {
                                        final VerificationRepository repo = ref
                                            .read(
                                              verificationRepositoryProvider,
                                            );
                                        final String res = await repo
                                            .generateProductsTemplate(
                                              categoryId: _categoryId,
                                              headers: headers,
                                            );
                                        if (!ctx.mounted) return;
                                        Navigator.of(ctx).pop();

                                        final String out = res.trim();
                                        if (out.startsWith('http://') ||
                                            out.startsWith('https://')) {
                                          final Uri uri = Uri.parse(out);
                                          final bool ok = await launchUrl(
                                            uri,
                                            mode:
                                                LaunchMode.externalApplication,
                                          );
                                          if (!mounted) return;
                                          if (!ok) {
                                            messenger.showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Could not open template link.',
                                                ),
                                              ),
                                            );
                                          }
                                          return;
                                        }

                                        if (out.isNotEmpty) {
                                          await Clipboard.setData(
                                            ClipboardData(text: out),
                                          );
                                        }
                                        if (!mounted) return;
                                        messenger.showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              out.isEmpty
                                                  ? 'Template generated.'
                                                  : 'Template generated (response copied).',
                                            ),
                                          ),
                                        );
                                      } on ApiException catch (e) {
                                        if (!ctx.mounted) return;
                                        ScaffoldMessenger.of(ctx).showSnackBar(
                                          SnackBar(content: Text(e.message)),
                                        );
                                      } catch (_) {
                                        if (!ctx.mounted) return;
                                        ScaffoldMessenger.of(ctx).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Something went wrong. Please try again.',
                                            ),
                                          ),
                                        );
                                      }
                                    },
                              icon: const Icon(Icons.download_rounded),
                              label: Text(
                                'Generate',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: s(14),
                                  fontWeight: FontWeight.w700,
                                  height: 20 / 14,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _openUploadSheet() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext context) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.x4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Bulk Upload', style: AppTypography.heading1),
                const SizedBox(height: AppSpacing.x2),
                Text(
                  'Pick an Excel/CSV file to create the batch.',
                  style: AppTypography.body2.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withAlpha(160),
                  ),
                ),
                const SizedBox(height: AppSpacing.x4),
                _SheetAction(
                  icon: Icons.folder_open_rounded,
                  label: 'Pick Excel/CSV File',
                  onTap: () async {
                    final PickedFile? picked = await FilePickerUtil.pickExcel();
                    if (!mounted) return;
                    if (!context.mounted) return;
                    if (picked == null) return;
                    Navigator.of(context).pop();
                    await _setPickedFile(picked);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _setPickedFile(PickedFile picked) async {
    setState(() => _pickedFile = picked);
  }

  Future<void> _createBatch() async {
    final PickedFile? pickedFile = _pickedFile;
    if (pickedFile == null || _creating) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please pick an Excel file first.')),
      );
      return;
    }
    final String? missing = _missingRequiredColumns(pickedFile);
    if (missing != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(missing)));
      return;
    }
    final String? categoryIssue = await _validateCategoryValues(pickedFile);
    if (categoryIssue != null) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(categoryIssue)));
      return;
    }
    setState(() => _creating = true);
    try {
      final VerificationRepository repo = ref.read(
        verificationRepositoryProvider,
      );
      final String modeLabel = _mode == 'warranty'
          ? 'Warranty'
          : 'Verification';
      final res = await repo.bulkUploadProducts(
        batchName: _batchName,
        description: '$_sector • $modeLabel',
        fileBytes: pickedFile.bytes,
        fileName: pickedFile.name,
      );
      await ref
          .read(batchNameStoreProvider.notifier)
          .setBatchName(res.batchId, _batchName);
      if (!mounted) return;
      final Uri uri = Uri(
        path: AppRouter.productBatchCreatedPath,
        queryParameters: <String, String>{
          'sector': _sector,
          'batch': _batchName,
          'records': res.totalUploaded.toString(),
          'skipped': res.totalSkipped.toString(),
          'batchId': res.batchId,
        },
      );
      context.push(uri.toString(), extra: res);
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

  String? _missingRequiredColumns(PickedFile file) {
    String norm(String s) => s.trim().toLowerCase().replaceAll(' ', '_');
    SpreadsheetPreview preview;
    try {
      preview = SpreadsheetPreviewUtil.parse(
        bytes: file.bytes,
        extension: file.extension,
        maxColumns: 60,
        maxRows: 1,
      );
    } on FormatException catch (e) {
      return e.message;
    } catch (_) {
      return 'Unable to read this file. Please upload a valid .xlsx or .csv.';
    }

    final Set<String> cols = preview.columns.map(norm).toSet();
    final List<String> required = <String>['product_name', 'category'];
    final List<String> missing = required
        .where((r) => !cols.contains(r))
        .toList();
    if (missing.isEmpty) return null;
    final String available = preview.columns.take(12).join(', ');
    return 'Missing required columns: ${missing.join(', ')}. '
        'Your file headers: $available';
  }

  Future<String?> _validateCategoryValues(PickedFile file) async {
    String norm(String s) => s.trim().toLowerCase().replaceAll(' ', '_');
    SpreadsheetPreview preview;
    try {
      preview = SpreadsheetPreviewUtil.parse(
        bytes: file.bytes,
        extension: file.extension,
        maxColumns: 60,
        maxRows: 25,
      );
    } on FormatException catch (e) {
      return e.message;
    } catch (_) {
      return 'Unable to read this file. Please upload a valid .xlsx or .csv.';
    }

    final int categoryIndex = preview.columns.indexWhere(
      (String c) => norm(c) == 'category',
    );
    if (categoryIndex == -1) return null;

    final Set<String> seen = <String>{};
    for (final List<String> row in preview.rows) {
      if (categoryIndex >= row.length) continue;
      final String v = row[categoryIndex].trim();
      if (v.isNotEmpty) seen.add(v);
      if (seen.length >= 8) break;
    }
    if (seen.isEmpty) {
      return 'Column "category" is empty. Use a valid category name from the Sector list (e.g. "${_selectedCategoryName()}").';
    }

    // Backend validates `category` by name (category_name), not by id.
    // Use categories API to show accurate allowed values.
    try {
      final VerificationRepository repo = ref.read(
        verificationRepositoryProvider,
      );
      final categories = await repo.getProductCategories();
      final Set<String> allowed = categories
          .map((c) => c.categoryName.trim())
          .where((s) => s.isNotEmpty)
          .toSet();

      final List<String> invalid = seen
          .where((v) => !allowed.contains(v))
          .toList();
      if (invalid.isEmpty) return null;

      final String selectedName = _selectedCategoryName();
      final bool selectedIsAllowed =
          selectedName.isNotEmpty && allowed.contains(selectedName);
      final String sample = invalid.take(3).join(', ');
      return 'Invalid category value(s) in your file: $sample. '
          'The "category" column must match a Sector name exactly (from /verification/categories), '
          '${selectedIsAllowed ? 'for this batch use "$selectedName".' : 'please pick a valid sector name.'}';
    } catch (_) {
      // If the categories API fails, don't block upload.
      return null;
    }
  }

  Future<void> _openMoreMenu({required double scale}) async {
    final BuildContext? ctx = _menuKey.currentContext;
    if (ctx == null) return;

    final RenderBox button = ctx.findRenderObject()! as RenderBox;
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject()! as RenderBox;
    final Offset buttonTopLeft = button.localToGlobal(
      Offset.zero,
      ancestor: overlay,
    );
    final Offset buttonBottomRight = button.localToGlobal(
      button.size.bottomRight(Offset.zero),
      ancestor: overlay,
    );

    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(buttonTopLeft, buttonBottomRight),
      Offset.zero & overlay.size,
    );

    final _MoreAction? picked = await showMenu<_MoreAction>(
      context: context,
      position: position.shift(Offset(0, button.size.height * 0.6)),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6 * scale),
        side: BorderSide(color: const Color(0xFFE5E7EB), width: 1 * scale),
      ),
      items: <PopupMenuEntry<_MoreAction>>[
        PopupMenuItem<_MoreAction>(
          value: _MoreAction.downloadTemplate,
          child: Text(
            'Download Template',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14 * scale,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF111827),
            ),
          ),
        ),
      ],
    );

    if (picked == _MoreAction.downloadTemplate) {
      await _downloadTemplate();
    }
  }

  @override
  Widget build(BuildContext context) {
    final double referenceWidth = 402;
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
                          _SectorPill(
                            scale: scale,
                            label: _sector.trim().isEmpty
                                ? 'Product'
                                : _sector.trim(),
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
                                    _ProductFlowStepper(
                                      scale: scale,
                                      stepIndex: 3,
                                      totalSteps: 4,
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
                                    Container(
                                      width: double.infinity,
                                      padding: EdgeInsets.symmetric(
                                        horizontal: s(16),
                                        vertical: s(14),
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(
                                          s(18),
                                        ),
                                        border: Border.all(
                                          color: const Color(
                                            0xFFCBD5E1,
                                          ).withAlpha(160),
                                        ),
                                      ),
                                      child: Text(
                                        _batchName,
                                        style: TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: s(14),
                                          fontWeight: FontWeight.w600,
                                          height: 20 / 14,
                                          color: const Color(0xFF111827),
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: s(10)),
                                    Text(
                                      'Assigned from the previous step. This batch name will be used for tracking.',
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: s(11),
                                        fontWeight: FontWeight.w500,
                                        height: 16 / 11,
                                        color: const Color(0xFF94A3B8),
                                      ),
                                    ),
                                    SizedBox(height: s(26)),
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: <Widget>[
                                        Expanded(
                                          child: Text(
                                            'Upload CSV',
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
                                        InkResponse(
                                          key: _menuKey,
                                          onTap: () =>
                                              _openMoreMenu(scale: scale),
                                          radius: s(22),
                                          child: SvgPicture.asset(
                                            'assets/icons/figma/bulk_upload_icon_more.svg',
                                            width: s(22),
                                            height: s(22),
                                            colorFilter: const ColorFilter.mode(
                                              AppColors.brandBlue,
                                              BlendMode.srcIn,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: s(14)),
                                    Text(
                                      'Download template based on your selected sector.\nUpload your Excel/CSV, then create the batch.',
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
                                      onTap: _openUploadSheet,
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
                                  ],
                                ),
                              ),
                            ),
                            _BottomNav(
                              scale: scale,
                              child: _UploadButton(
                                scale: scale,
                                isLoading: _creating,
                                enabled: _pickedFile != null && !_creating,
                                onTap: _createBatch,
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

class _SheetAction extends StatelessWidget {
  const _SheetAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.x4,
            vertical: AppSpacing.x4,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: onTap == null ? AppColors.border : AppColors.brandBlue,
              width: 1.25,
            ),
          ),
          child: Row(
            children: <Widget>[
              Icon(icon, color: AppColors.brandBlue),
              const SizedBox(width: AppSpacing.x3),
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.body1.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (onTap == null)
                Text(
                  'Soon',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textTertiary,
                    fontWeight: FontWeight.w700,
                  ),
                )
              else
                const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

enum _MoreAction { downloadTemplate }

class _SectorPill extends StatelessWidget {
  const _SectorPill({required this.scale, required this.label});

  final double scale;
  final String label;

  @override
  Widget build(BuildContext context) {
    double s(double v) => v * scale;

    return Container(
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
          Text(
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
        ],
      ),
    );
  }
}

class _ProductFlowStepper extends StatelessWidget {
  const _ProductFlowStepper({
    required this.scale,
    required this.stepIndex,
    required this.totalSteps,
  });

  final double scale;
  final int stepIndex;
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    double s(double v) => v * scale;
    final int currentStep = stepIndex.clamp(0, totalSteps - 1) + 1;
    final int progressPercent = ((currentStep / totalSteps) * 100).round();
    final double progress = stepIndex / (totalSteps - 1);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: s(14), vertical: s(12)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(s(16)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.brandBlue.withAlpha(14),
            blurRadius: s(14),
            offset: Offset(0, s(8)),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SizedBox(
            height: s(8),
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints c) {
                final double width = c.maxWidth;
                return Stack(
                  children: <Widget>[
                    Container(
                      width: width,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(s(99)),
                      ),
                    ),
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: progress.clamp(0, 1)),
                      duration: const Duration(milliseconds: 260),
                      curve: Curves.easeOutCubic,
                      builder: (BuildContext context, double t, Widget? child) {
                        return Container(
                          width: width * t,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: <Color>[
                                AppColors.brandBlue,
                                AppColors.deepNavy,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(s(99)),
                          ),
                        );
                      },
                    ),
                  ],
                );
              },
            ),
          ),
          SizedBox(height: s(10)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                'STEP $currentStep OF $totalSteps',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: s(10),
                  fontWeight: FontWeight.w700,
                  letterSpacing: s(1),
                  height: 15 / 10,
                  color: const Color(0xFF94A3B8),
                ),
              ),
              Text(
                '$progressPercent%',
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
        ],
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
                  'Upload your Excel or CSV file here',
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

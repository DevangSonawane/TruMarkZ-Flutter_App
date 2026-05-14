import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';

import '../../../../../core/network/api_client.dart';
import '../../../../../core/router/app_router.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/utils/file_picker_util.dart';
import '../../../../../core/utils/spreadsheet_preview_util.dart';
import '../../../../../core/widgets/tmz_button.dart';
import '../../../../../core/widgets/tmz_card.dart';
import '../../../data/verification_repository.dart';

class BulkUploadPage extends ConsumerStatefulWidget {
  const BulkUploadPage({super.key});

  @override
  ConsumerState<BulkUploadPage> createState() => _BulkUploadPageState();
}

class _BulkUploadPageState extends ConsumerState<BulkUploadPage> {
  bool _didInitFromRoute = false;

  late final TextEditingController _batchNameController;
  late final TextEditingController _columnsController;

  String _industry = 'transport';
  Set<String> _checks = <String>{'identity', 'address', 'criminal'};

  PickedFile? _pickedFile;
  bool _isUploading = false;

  SpreadsheetPreview? _preview;
  String? _previewError;
  bool _parsingPreview = false;

  @override
  void initState() {
    super.initState();
    _batchNameController = TextEditingController(
      text: 'Driver Verification Q1 — 80 records',
    );
    _columnsController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInitFromRoute) return;
    _didInitFromRoute = true;

    final Map<String, String> qp = GoRouterState.of(
      context,
    ).uri.queryParameters;

    _industry = (qp['industry'] ?? _industry).trim();
    _checks = _parseCsvSet(qp['checks']) ?? _checks;

    final List<String> initialColumns =
        _parseCsvList(qp['columns']) ?? _templateColumnsForChecks(_checks);
    _columnsController.text = initialColumns.join(',');
  }

  @override
  void dispose() {
    _batchNameController.dispose();
    _columnsController.dispose();
    super.dispose();
  }

  static Set<String>? _parseCsvSet(String? raw) {
    final List<String>? list = _parseCsvList(raw);
    return list?.toSet();
  }

  static List<String>? _parseCsvList(String? raw) {
    if (raw == null) return null;
    final List<String> list = raw
        .split(',')
        .map((String s) => s.trim())
        .where((String s) => s.isNotEmpty)
        .toList();
    return list.isEmpty ? null : list;
  }

  static List<String> _templateColumnsForChecks(Set<String> checks) {
    final Set<String> columns = <String>{
      'full_name',
      'dob',
      'id_number',
      'phone',
      'email',
      'address',
    };

    final Map<String, List<String>> perCheck = <String, List<String>>{
      'identity': <String>['kyc_id', 'id_type'],
      'address': <String>['pincode', 'city', 'state'],
      'criminal': <String>['police_station', 'jurisdiction'],
      'education': <String>['institute', 'course', 'graduation_year'],
      'employment': <String>['employer', 'role', 'start_date'],
    };

    for (final String check in checks) {
      columns.addAll(perCheck[check] ?? const <String>[]);
    }

    final List<String> sorted = columns.toList()..sort();
    return sorted;
  }

  List<String> _columns() {
    return (_columnsController.text)
        .split(',')
        .map((String s) => s.trim())
        .where((String s) => s.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
  }

  Future<void> _downloadTemplate() async {
    final List<String> columns = _columns();
    final String headerRow = columns.join(',');
    await Clipboard.setData(ClipboardData(text: headerRow));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Template header copied to clipboard.')),
    );
  }

  void _openUploadSheet({
    required String title,
    required String description,
  }) {
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
                Text(title, style: AppTypography.heading1),
                const SizedBox(height: AppSpacing.x2),
                Text(
                  description,
                  style: AppTypography.body2.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withAlpha(160),
                  ),
                ),
                const SizedBox(height: AppSpacing.x4),
                TMZButton(
                  label: 'Pick Excel File',
                  variant: TMZButtonVariant.secondary,
                  icon: Icons.folder_open_rounded,
                  onPressed: () async {
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
    setState(() {
      _pickedFile = picked;
      _parsingPreview = true;
      _previewError = null;
      _preview = null;
    });

    try {
      final SpreadsheetPreview p = SpreadsheetPreviewUtil.parse(
        bytes: picked.bytes,
        extension: picked.extension,
        maxColumns: 200,
        maxRows: 10,
      );
      if (!mounted) return;
      setState(() {
        _preview = p;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _previewError = e.toString());
    } finally {
      if (mounted) setState(() => _parsingPreview = false);
    }
  }

  void _confirmAndCreateBatch() {
    final List<String> columns = _columns();
    if (_batchNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a batch name.')),
      );
      return;
    }
    if (_pickedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload an Excel file first.')),
      );
      return;
    }

    _uploadAndNavigate(columns);
  }

  Future<void> _uploadAndNavigate(List<String> columns) async {
    if (_isUploading) return;
    final PickedFile? file = _pickedFile;
    if (file == null) return;

    setState(() => _isUploading = true);
    try {
      final VerificationRepository repo = ref.read(
        verificationRepositoryProvider,
      );
      final res = await repo.bulkUpload(
        batchName: _batchNameController.text.trim(),
        description: null,
        fileBytes: file.bytes,
        fileName: file.name,
      );
      if (!mounted) return;
      final Uri uri = Uri(
        path: AppRouter.batchCreatedSuccessPath,
        queryParameters: <String, String>{
          'batch_id': res.batchId,
          'total_uploaded': res.totalUploaded.toString(),
          'total_skipped': res.totalSkipped.toString(),
          'errors': res.errors.length.toString(),
          'columns': columns.join(','),
          'checks': _checks.join(','),
          'industry': _industry,
          'batch': _batchNameController.text.trim(),
        },
      );
      context.push(uri.toString());
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } on DioException catch (e) {
      if (!mounted) return;
      debugPrint(
        '[BulkUploadPage] DioException: type=${e.type} uri=${e.requestOptions.uri} '
        'status=${e.response?.statusCode} data=${e.response?.data} message=${e.message}',
      );
      final Object? inner = e.error;
      if (inner is ApiException) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(inner.message)));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'Upload failed. Please try again.')),
        );
      }
    } catch (e, st) {
      if (!mounted) return;
      debugPrint('[BulkUploadPage] bulk upload failed: $e\n$st');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final List<String> columns = _columns();

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Image.asset('assets/icons/headers_app_icon.png', height: 22),
            const SizedBox(width: AppSpacing.x2),
            const Text('Bulk Upload'),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.x4),
                children: <Widget>[
                  Text('Upload CSV', style: AppTypography.display2),
                  const SizedBox(height: AppSpacing.x2),
                  Text(
                    'Download a template based on your selected checks, upload your Excel/CSV and optional photos, then confirm the batch.',
                    style: AppTypography.body2.copyWith(
                      color: scheme.onSurface.withAlpha(160),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.x4),
                  TMZButton(
                    label: 'Download Excel Template',
                    icon: Icons.download_rounded,
                    onPressed: _downloadTemplate,
                  ),
                  const SizedBox(height: AppSpacing.x3),
                  TMZCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text('Template Columns', style: AppTypography.heading2),
                        const SizedBox(height: AppSpacing.x2),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: <Widget>[
                            for (final String c in columns)
                              Chip(
                                label: Text(c),
                                backgroundColor: scheme.primary.withAlpha(18),
                              ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.x3),
                        Text(
                          'Industry: ${_industry.toUpperCase()}  •  Checks: ${_checks.length}',
                          style: AppTypography.caption.copyWith(
                            color: scheme.onSurface.withAlpha(150),
                            letterSpacing: 0.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.x4),
                  Text('Uploads', style: AppTypography.heading2),
                  const SizedBox(height: AppSpacing.x2),
                  _UploadTile(
                    title: 'Excel / CSV File',
                    subtitle: _pickedFile != null
                        ? '${_pickedFile!.name} • ${columns.length} fields'
                        : 'Upload your records file',
                    leadingIcon: Icons.upload_file_rounded,
                    uploaded: _pickedFile != null,
                    onTap: () => _openUploadSheet(
                      title: 'Upload Excel / CSV',
                      description: 'Pick an Excel/CSV file to create the batch.',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.x4),
                  Text('Batch Name', style: AppTypography.heading2),
                  const SizedBox(height: AppSpacing.x2),
                  TextField(
                    controller: _batchNameController,
                    decoration: const InputDecoration(
                      hintText: 'Driver Verification Q1 — 200 records',
                      border: OutlineInputBorder(),
                    ),
                    textInputAction: TextInputAction.done,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: AppSpacing.x4),
                  Text('Preview', style: AppTypography.heading2),
                  const SizedBox(height: AppSpacing.x2),
                  TMZCard(
                    child: _pickedFile == null
                        ? Text(
                            'Upload an Excel/CSV file to see a preview.',
                            style: AppTypography.body2.copyWith(
                              color: scheme.onSurface.withAlpha(160),
                            ),
                          )
                        : _parsingPreview
                        ? Row(
                            children: <Widget>[
                              const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                              const SizedBox(width: AppSpacing.x2),
                              Text(
                                'Reading ${_pickedFile!.name}…',
                                style: AppTypography.body2.copyWith(
                                  color: scheme.onSurface.withAlpha(160),
                                ),
                              ),
                            ],
                          )
                        : (_previewError != null)
                        ? Text(
                            'Unable to preview file: $_previewError',
                            style: AppTypography.body2.copyWith(
                              color: AppColors.error,
                            ),
                          )
                        : _PreviewTable(preview: _preview),
                  ),
                ],
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.x4,
                  AppSpacing.x2,
                  AppSpacing.x4,
                  AppSpacing.x4,
                ),
                child: TMZButton(
                  label: 'Confirm & Upload',
                  icon: Icons.arrow_forward_rounded,
                  isLoading: _isUploading,
                  onPressed:
                      (_pickedFile != null &&
                          _batchNameController.text.trim().isNotEmpty &&
                          !_isUploading)
                      ? _confirmAndCreateBatch
                      : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UploadTile extends StatelessWidget {
  const _UploadTile({
    required this.title,
    required this.subtitle,
    required this.leadingIcon,
    required this.uploaded,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData leadingIcon;
  final bool uploaded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeOutCubic,
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.98, end: 1).animate(animation),
            child: child,
          ),
        );
      },
      child: uploaded
          ? TMZCard(
              key: const ValueKey<String>('uploaded'),
              onTap: onTap,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.x3,
                vertical: AppSpacing.x3,
              ),
              child: Row(
                children: <Widget>[
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.successBg,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.success,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.x3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          title,
                          style: AppTypography.body1.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: AppTypography.body2.copyWith(
                            color: scheme.onSurface.withAlpha(160),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textTertiary,
                  ),
                ],
              ),
            )
          : TMZCard(
              key: const ValueKey<String>('pending'),
              onTap: onTap,
              padding: EdgeInsets.zero,
              child: CustomPaint(
                painter: _DashedBorderPainter(
                  color: AppColors.brandBlue.withAlpha(153),
                  strokeWidth: 1.5,
                  radius: 20,
                  dash: const <double>[6, 4],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.x4),
                  child: Row(
                    children: <Widget>[
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.brandBlue.withAlpha(16),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        alignment: Alignment.center,
                        child: Icon(leadingIcon, color: AppColors.brandBlue),
                      ),
                      const SizedBox(width: AppSpacing.x3),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              title,
                              style: AppTypography.body1.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              subtitle,
                              style: AppTypography.body2.copyWith(
                                color: scheme.onSurface.withAlpha(160),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.textTertiary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.radius,
    required this.dash,
  });

  final Color color;
  final double strokeWidth;
  final double radius;
  final List<double> dash;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final RRect rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(radius),
    );

    final Path path = Path()..addRRect(rrect);
    final PathMetrics metrics = path.computeMetrics();

    for (final PathMetric metric in metrics) {
      double distance = 0;
      int index = 0;
      while (distance < metric.length) {
        final double len = dash[index % dash.length];
        final bool draw = index.isEven;
        if (draw) {
          final Path extract = metric.extractPath(
            distance,
            (distance + len).clamp(0, metric.length),
          );
          canvas.drawPath(extract, paint);
        }
        distance += len;
        index += 1;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.radius != radius ||
        oldDelegate.dash != dash;
  }
}

class _PreviewTable extends StatelessWidget {
  const _PreviewTable({required this.preview});

  final SpreadsheetPreview? preview;

  @override
  Widget build(BuildContext context) {
    final SpreadsheetPreview? p = preview;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    if (p == null) {
      return Text(
        'No preview available.',
        style: AppTypography.body2.copyWith(color: scheme.onSurface.withAlpha(160)),
      );
    }

    if (p.columns.isEmpty) {
      return Text(
        'No rows found in ${p.sheetName}.',
        style: AppTypography.body2.copyWith(color: scheme.onSurface.withAlpha(160)),
      );
    }

    final List<String> displayColumns = p.columns.take(8).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          '${p.sheetName} • showing ${p.rows.length} of ${p.totalRows} rows',
          style: AppTypography.caption.copyWith(
            color: scheme.onSurface.withAlpha(150),
          ),
        ),
        const SizedBox(height: AppSpacing.x3),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingTextStyle: AppTypography.caption.copyWith(
              fontWeight: FontWeight.w800,
              color: scheme.onSurface.withAlpha(180),
            ),
            dataTextStyle: AppTypography.caption.copyWith(
              color: scheme.onSurface.withAlpha(160),
            ),
            columns: <DataColumn>[
              for (final String c in displayColumns) DataColumn(label: Text(c)),
            ],
            rows: <DataRow>[
              for (final List<String> row in p.rows)
                DataRow(
                  cells: <DataCell>[
                    for (int i = 0; i < displayColumns.length; i++)
                      DataCell(
                        Text(
                          i < row.length ? row[i] : '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }
}

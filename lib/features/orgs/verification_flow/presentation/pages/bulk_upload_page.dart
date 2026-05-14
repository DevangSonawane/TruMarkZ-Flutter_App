import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/network/api_client.dart';
import '../../../../../core/router/app_router.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/utils/file_picker_util.dart';
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
  bool _excelUploaded = false;
  bool _photosZipUploaded = false;
  bool _isUploading = false;

  List<Map<String, String>> _previewRows = <Map<String, String>>[];

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

    _previewRows = _buildSampleRows(initialColumns);
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

  static List<Map<String, String>> _buildSampleRows(List<String> columns) {
    final List<Map<String, String>> rows = <Map<String, String>>[];
    final List<Map<String, String>> base = <Map<String, String>>[
      <String, String>{
        'full_name': 'Ravi Kumar',
        'dob': '1997-06-12',
        'id_number': 'ID-298172',
        'phone': '+91 98XXXXXX21',
        'email': 'ravi@org.com',
        'address': 'Bengaluru, IN',
        'city': 'Bengaluru',
        'state': 'KA',
        'pincode': '560001',
      },
      <String, String>{
        'full_name': 'Asha Nair',
        'dob': '1999-01-03',
        'id_number': 'ID-772190',
        'phone': '+91 97XXXXXX10',
        'email': 'asha@org.com',
        'address': 'Kochi, IN',
        'city': 'Kochi',
        'state': 'KL',
        'pincode': '682001',
      },
      <String, String>{
        'full_name': 'Mohit Singh',
        'dob': '1996-11-21',
        'id_number': 'ID-551902',
        'phone': '+91 99XXXXXX32',
        'email': 'mohit@org.com',
        'address': 'Delhi, IN',
        'city': 'Delhi',
        'state': 'DL',
        'pincode': '110001',
      },
    ];

    for (final Map<String, String> b in base) {
      final Map<String, String> row = <String, String>{};
      for (final String c in columns) {
        row[c] = b[c] ?? '—';
      }
      rows.add(row);
    }
    return rows;
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
    required VoidCallback onUseSample,
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
                  label: 'Use Sample File (Demo Mode)',
                  icon: Icons.auto_awesome_rounded,
                  onPressed: () {
                    Navigator.of(context).pop();
                    onUseSample();
                  },
                ),
                const SizedBox(height: AppSpacing.x2),
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
                    setState(() {
                      _pickedFile = picked;
                      _excelUploaded = true;
                      _previewRows = _buildSampleRows(_columns());
                    });
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
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
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Something went wrong. Please try again.'),
        ),
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
                      description:
                          'Pick an Excel/CSV file. For now you can use sample data.',
                      onUseSample: () {
                        setState(() {
                          _excelUploaded = true;
                          _previewRows = _buildSampleRows(columns);
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: AppSpacing.x3),
                  _UploadTile(
                    title: 'Photos ZIP (Optional)',
                    subtitle: _photosZipUploaded
                        ? 'photos.zip — linked by id_number'
                        : 'Upload photos ZIP for face photo fields',
                    leadingIcon: Icons.photo_library_outlined,
                    uploaded: _photosZipUploaded,
                    onTap: () => _openUploadSheet(
                      title: 'Upload Photos ZIP',
                      description:
                          'Upload a ZIP of photos named by a unique column (e.g. id_number).',
                      onUseSample: () =>
                          setState(() => _photosZipUploaded = true),
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
                  if (!_excelUploaded)
                    TMZCard(
                      child: Text(
                        'Upload an Excel/CSV file to see a preview table of entries.',
                        style: AppTypography.body2.copyWith(
                          color: scheme.onSurface.withAlpha(160),
                        ),
                      ),
                    )
                  else
                    TMZCard(
                      child: _PreviewTable(
                        columns: columns,
                        rows: _previewRows,
                      ),
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
  const _PreviewTable({required this.columns, required this.rows});

  final List<String> columns;
  final List<Map<String, String>> rows;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final List<Map<String, String>> limited = rows.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Showing ${limited.length} of 80 records',
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
              for (final String c in columns.take(6))
                DataColumn(label: Text(c)),
            ],
            rows: <DataRow>[
              for (final Map<String, String> row in limited)
                DataRow(
                  cells: <DataCell>[
                    for (final String c in columns.take(6))
                      DataCell(
                        Text(
                          row[c] ?? '—',
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

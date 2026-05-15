import 'dart:ui';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart';

import '../../../../../core/models/verification_models.dart';
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
  bool _isUploading = false;
  bool _preflightChecking = false;

  @override
  void initState() {
    super.initState();
    _batchNameController = TextEditingController();
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

  void _openUploadSheet({required String title, required String description}) {
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
    setState(() => _pickedFile = picked);
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

    final bool ok = await _preflightPreventDuplicatePeople(file);
    if (!ok) return;

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
          SnackBar(
            content: Text(e.message ?? 'Upload failed. Please try again.'),
          ),
        );
      }
    } catch (e, st) {
      if (!mounted) return;
      debugPrint('[BulkUploadPage] bulk upload failed: $e\n$st');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<bool> _preflightPreventDuplicatePeople(PickedFile file) async {
    if (_preflightChecking) return false;
    setState(() => _preflightChecking = true);

    try {
      final _Identifiers fileIds = _Identifiers.fromFile(file);
      if (fileIds.keys.isEmpty) {
        // If we can't extract any identifiers, don't block uploads.
        return true;
      }

      if (fileIds.duplicatesInFile.isNotEmpty) {
        await _showBlockingDialog(
          title: 'Duplicate rows found',
          message:
              'Your file contains duplicate people (same email/phone/etc). Please remove duplicates and try again.',
          samples: fileIds.duplicatesInFile.take(6).toList(),
        );
        return false;
      }

      final Set<String> existing = await _fetchExistingIdentifierKeys();
      final Set<String> overlap = fileIds.keys.intersection(existing);
      if (overlap.isNotEmpty) {
        await _showBlockingDialog(
          title: 'People already exist',
          message:
              'Some people in this file already have verifications in your org. To avoid multiple human verifications for the same people, remove them from the file and re-upload.',
          samples: overlap.take(6).toList(),
        );
        return false;
      }

      return true;
    } catch (_) {
      // If preflight fails, don't block uploads.
      return true;
    } finally {
      if (mounted) setState(() => _preflightChecking = false);
    }
  }

  Future<void> _showBlockingDialog({
    required String title,
    required String message,
    required List<String> samples,
  }) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(message),
              if (samples.isNotEmpty) ...<Widget>[
                const SizedBox(height: 12),
                Text(
                  'Examples:',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                for (final String s in samples)
                  Text(
                    '• $s',
                    style: AppTypography.body2.copyWith(fontSize: 12),
                  ),
              ],
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<Set<String>> _fetchExistingIdentifierKeys() async {
    final VerificationRepository repo = ref.read(
      verificationRepositoryProvider,
    );
    final Set<String> out = <String>{};

    int offset = 0;
    const int limit = 500;
    int guard = 0;

    while (guard < 50) {
      guard++;
      final VerificationListResponse res = await repo.getAllVerifications(
        limit: limit,
        offset: offset,
      );
      for (final VerificationUser u in res.users) {
        final String email = _normalizeEmail(u.email);
        if (email.isNotEmpty) out.add('email:$email');
        final String phone = _normalizePhone(u.phoneNumber);
        if (phone.isNotEmpty) out.add('phone:$phone');
        final String aadhar = _normalizeDigits(u.aadharNumber ?? '');
        if (aadhar.isNotEmpty) out.add('aadhar:$aadhar');
        final String pan = _normalizeAlphaNum(u.panNumber ?? '');
        if (pan.isNotEmpty) out.add('pan:$pan');
      }

      offset += res.users.length;
      if (res.users.isEmpty || offset >= res.total) break;
    }
    return out;
  }

  static String _normalizeEmail(String v) => v.trim().toLowerCase();

  static String _normalizePhone(String v) {
    final String digits = _normalizeDigits(v);
    if (digits.isEmpty) return '';
    // Keep last 10 digits for Indian phone numbers if longer.
    return digits.length > 10 ? digits.substring(digits.length - 10) : digits;
  }

  static String _normalizeDigits(String v) {
    return v.replaceAll(RegExp(r'[^0-9]'), '').trim();
  }

  static String _normalizeAlphaNum(String v) {
    return v.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').trim().toUpperCase();
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
                          'Pick an Excel/CSV file to create the batch.',
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
                          !_isUploading &&
                          !_preflightChecking)
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

class _Identifiers {
  const _Identifiers({required this.keys, required this.duplicatesInFile});

  final Set<String> keys;
  final Set<String> duplicatesInFile;

  static _Identifiers fromFile(PickedFile file) {
    final String ext = file.extension.toLowerCase().replaceAll('.', '').trim();
    if (ext == 'csv') {
      return _fromCsv(file.bytes);
    }
    if (ext == 'xlsx') {
      return _fromXlsx(file.bytes);
    }
    return const _Identifiers(keys: <String>{}, duplicatesInFile: <String>{});
  }

  static _Identifiers _fromCsv(Uint8List bytes) {
    final String raw = utf8.decode(bytes, allowMalformed: true);
    final List<List<dynamic>> table = const CsvToListConverter(
      shouldParseNumbers: false,
    ).convert(raw);
    if (table.isEmpty) {
      return const _Identifiers(keys: <String>{}, duplicatesInFile: <String>{});
    }

    int headerIndex = 0;
    while (headerIndex < table.length && _isRowEmpty(table[headerIndex])) {
      headerIndex += 1;
    }
    if (headerIndex >= table.length) {
      return const _Identifiers(keys: <String>{}, duplicatesInFile: <String>{});
    }

    final List<String> header = table[headerIndex]
        .map((dynamic e) => (e?.toString() ?? '').trim())
        .toList();
    final Map<String, int> ix = _indexMap(header);
    final _Accumulator acc = _Accumulator();

    for (int i = headerIndex + 1; i < table.length; i++) {
      final List<dynamic> row = table[i];
      if (_isRowEmpty(row)) continue;
      acc.addEmail(_rowValue(row, ix['email']));
      acc.addPhone(_rowValue(row, ix['phone']));
      acc.addAadhar(_rowValue(row, ix['aadhar']));
      acc.addPan(_rowValue(row, ix['pan']));
    }
    return acc.toIdentifiers();
  }

  static _Identifiers _fromXlsx(Uint8List bytes) {
    Excel excel;
    try {
      excel = Excel.decodeBytes(bytes);
    } catch (_) {
      return const _Identifiers(keys: <String>{}, duplicatesInFile: <String>{});
    }
    final List<String> sheetNames = excel.tables.keys.toList();
    if (sheetNames.isEmpty) {
      return const _Identifiers(keys: <String>{}, duplicatesInFile: <String>{});
    }
    final Sheet? sheet = excel.tables[sheetNames.first];
    if (sheet == null) {
      return const _Identifiers(keys: <String>{}, duplicatesInFile: <String>{});
    }
    final List<List<Data?>> all = sheet.rows;
    if (all.isEmpty) {
      return const _Identifiers(keys: <String>{}, duplicatesInFile: <String>{});
    }

    int headerIndex = 0;
    while (headerIndex < all.length && _isExcelRowEmpty(all[headerIndex])) {
      headerIndex += 1;
    }
    if (headerIndex >= all.length) {
      return const _Identifiers(keys: <String>{}, duplicatesInFile: <String>{});
    }

    final List<String> header = all[headerIndex]
        .map((Data? d) => (d?.value?.toString() ?? '').trim())
        .toList();
    final Map<String, int> ix = _indexMap(header);
    final _Accumulator acc = _Accumulator();

    for (int i = headerIndex + 1; i < all.length; i++) {
      final List<Data?> row = all[i];
      if (_isExcelRowEmpty(row)) continue;
      acc.addEmail(_excelValue(row, ix['email']));
      acc.addPhone(_excelValue(row, ix['phone']));
      acc.addAadhar(_excelValue(row, ix['aadhar']));
      acc.addPan(_excelValue(row, ix['pan']));
    }
    return acc.toIdentifiers();
  }

  static Map<String, int> _indexMap(List<String> header) {
    final Map<String, int> out = <String, int>{};
    for (int i = 0; i < header.length; i++) {
      final String key = _normHeader(header[i]);
      if (key.isEmpty) continue;
      out[key] = i;
    }

    int? pick(List<String> keys) {
      for (final String k in keys) {
        final int? i = out[k];
        if (i != null) return i;
      }
      return null;
    }

    return <String, int>{
      'email': pick(<String>['email', 'email_id']) ?? -1,
      'phone':
          pick(<String>['phone', 'phone_number', 'mobile', 'mobile_number']) ??
          -1,
      'aadhar': pick(<String>['aadhar', 'aadhar_number', 'aadhaar']) ?? -1,
      'pan': pick(<String>['pan', 'pan_number']) ?? -1,
    };
  }

  static String _rowValue(List<dynamic> row, int? idx) {
    if (idx == null || idx < 0 || idx >= row.length) return '';
    return (row[idx]?.toString() ?? '').trim();
  }

  static String _excelValue(List<Data?> row, int? idx) {
    if (idx == null || idx < 0 || idx >= row.length) return '';
    return (row[idx]?.value?.toString() ?? '').trim();
  }

  static bool _isRowEmpty(List<dynamic> row) {
    for (final dynamic v in row) {
      final String s = (v?.toString() ?? '').trim();
      if (s.isNotEmpty) return false;
    }
    return true;
  }

  static bool _isExcelRowEmpty(List<Data?> row) {
    for (final Data? v in row) {
      final String s = (v?.value?.toString() ?? '').trim();
      if (s.isNotEmpty) return false;
    }
    return true;
  }

  static String _normHeader(String v) {
    return v
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'\\s+'), '_')
        .replaceAll(RegExp(r'[^a-z0-9_]'), '');
  }
}

class _Accumulator {
  final Set<String> _keys = <String>{};
  final Set<String> _dups = <String>{};

  void addEmail(String raw) {
    final String email = _BulkUploadPageState._normalizeEmail(raw);
    if (!email.contains('@')) return;
    _add('email:$email');
  }

  void addPhone(String raw) {
    final String phone = _BulkUploadPageState._normalizePhone(raw);
    if (phone.length < 10) return;
    _add('phone:$phone');
  }

  void addAadhar(String raw) {
    final String digits = _BulkUploadPageState._normalizeDigits(raw);
    if (digits.length < 12) return;
    _add('aadhar:$digits');
  }

  void addPan(String raw) {
    final String pan = _BulkUploadPageState._normalizeAlphaNum(raw);
    if (pan.length != 10) return;
    _add('pan:$pan');
  }

  void _add(String key) {
    if (_keys.contains(key)) _dups.add(key);
    _keys.add(key);
  }

  _Identifiers toIdentifiers() =>
      _Identifiers(keys: _keys, duplicatesInFile: _dups);
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

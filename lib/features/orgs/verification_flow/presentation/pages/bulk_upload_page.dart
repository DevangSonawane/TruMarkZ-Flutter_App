import 'dart:ui';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart' hide Border;

import '../../../../../core/models/verification_models.dart';
import '../../../../../core/network/api_client.dart';
import '../../../../../core/router/app_router.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/utils/file_picker_util.dart';
import '../../../../../core/widgets/tmz_button.dart';
import '../../../data/verification_repository.dart';
import '../../../../../core/services/batch_name_store.dart';

class BulkUploadPage extends ConsumerStatefulWidget {
  const BulkUploadPage({super.key});

  @override
  ConsumerState<BulkUploadPage> createState() => _BulkUploadPageState();
}

class _BulkUploadPageState extends ConsumerState<BulkUploadPage> {
  static const double _referenceWidth = 402;
  static const Color _panelBg = Color(0xFFF7F9FC);
  static const Color _panelText = Color(0xFF3A3A3A);

  final GlobalKey _menuKey = GlobalKey();

  String? _lastRouteSignature;

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

    final Uri uri = GoRouterState.of(context).uri;
    final String signature = uri.query;
    if (_lastRouteSignature == signature) return;
    _lastRouteSignature = signature;

    final Map<String, String> qp = uri.queryParameters;
    final String nextIndustry = (qp['industry'] ?? _industry).trim();
    final Set<String> nextChecks = _parseCsvSet(qp['checks']) ?? _checks;
    final List<String> nextColumns =
        _parseCsvList(qp['columns']) ?? _templateColumnsForChecks(nextChecks);

    setState(() {
      _industry = nextIndustry;
      _checks = nextChecks;
      _columnsController.text = nextColumns.join(',');
    });
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
      'email',
      'phone_number',
      'aadhar_number',
      'pan_number',
      'address_line1',
      'address_line2',
      'address_line3',
      'pincode',
      'state',
      'country',
    };

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

  // TODO: Remove once backend file parsing is fully relied upon everywhere.
  // ignore: unused_element
  List<Map<String, dynamic>> _parseUsersFromPickedFile(PickedFile file) {
    final String safeName = file.name.trim();
    final String ext = safeName.contains('.')
        ? safeName.split('.').last.toLowerCase()
        : '';
    debugPrint('[BulkUploadPage] Parsing file=$safeName ext=$ext');
    final Uint8List bytes = file.bytes;
    if (ext == 'csv') return _parseUsersFromCsv(bytes);

    // XLSX files are ZIP containers (start with "PK"). If the extension says
    // xlsx but content isn't a ZIP, it's usually a misnamed CSV export.
    if (ext == 'xlsx' && !_looksLikeZip(bytes)) {
      debugPrint(
        '[BulkUploadPage] File extension is xlsx but content is not ZIP; trying CSV fallback.',
      );
      return _parseUsersFromCsv(bytes);
    }

    final List<Map<String, dynamic>> fromXlsx = _parseUsersFromXlsx(bytes);
    if (fromXlsx.isNotEmpty) return fromXlsx;

    return fromXlsx;
  }

  static bool _looksLikeZip(Uint8List bytes) {
    if (bytes.length < 4) return false;
    // ZIP local file header signature: 0x50 0x4B 0x03 0x04
    return bytes[0] == 0x50 && bytes[1] == 0x4B;
  }

  List<Map<String, dynamic>> _parseUsersFromCsv(Uint8List bytes) {
    final String text = utf8.decode(bytes, allowMalformed: true);
    final List<List<dynamic>> table = const CsvToListConverter(
      eol: '\n',
      shouldParseNumbers: false,
    ).convert(text);
    if (table.isEmpty) return <Map<String, dynamic>>[];

    int headerIndex = 0;
    while (headerIndex < table.length &&
        _Identifiers._isRowEmpty(table[headerIndex])) {
      headerIndex += 1;
    }
    if (headerIndex >= table.length) return <Map<String, dynamic>>[];

    final List<String> header = table[headerIndex]
        .map((dynamic v) => (v?.toString() ?? '').trim())
        .toList();
    final Map<String, int> ix = _userIndexMap(header);

    final List<Map<String, dynamic>> out = <Map<String, dynamic>>[];
    List<dynamic>? firstNonEmptyRow;
    for (int i = headerIndex + 1; i < table.length; i++) {
      final List<dynamic> row = table[i];
      if (_Identifiers._isRowEmpty(row)) continue;
      firstNonEmptyRow ??= row;
      final Map<String, dynamic>? user = _userFromRow(
        valueAt: (String key) => _Identifiers._rowValue(row, ix[key]),
      );
      if (user != null) out.add(user);
    }

    if (out.isEmpty) {
      debugPrint(
        '[BulkUploadPage] CSV header(normalized)=${header.map(_Identifiers._normHeader).toList()}',
      );
      if (firstNonEmptyRow != null) {
        final List<dynamic> row = firstNonEmptyRow;
        final Map<String, String> sample = _sampleRequiredFields(
          valueAt: (String key) => _Identifiers._rowValue(row, ix[key]),
        );
        debugPrint('[BulkUploadPage] CSV firstRow(sample)=$sample');
      }
    }
    return out;
  }

  List<Map<String, dynamic>> _parseUsersFromXlsx(Uint8List bytes) {
    Excel excel;
    try {
      excel = Excel.decodeBytes(bytes);
    } catch (_) {
      debugPrint(
        '[BulkUploadPage] XLSX decodeBytes failed (not a valid xlsx or corrupted). bytes=${bytes.length}',
      );
      return <Map<String, dynamic>>[];
    }
    final List<String> sheetNames = excel.tables.keys.toList();
    if (sheetNames.isEmpty) {
      debugPrint('[BulkUploadPage] XLSX has no sheets. bytes=${bytes.length}');
      return <Map<String, dynamic>>[];
    }
    final Sheet? sheet = excel.tables[sheetNames.first];
    if (sheet == null) {
      debugPrint(
        '[BulkUploadPage] XLSX first sheet is null. first=${sheetNames.first}',
      );
      return <Map<String, dynamic>>[];
    }

    final List<List<Data?>> all = sheet.rows;
    if (all.isEmpty) {
      debugPrint(
        '[BulkUploadPage] XLSX sheet has 0 rows. sheet=${sheetNames.first}',
      );
      return <Map<String, dynamic>>[];
    }

    int headerIndex = 0;
    while (headerIndex < all.length &&
        _Identifiers._isExcelRowEmpty(all[headerIndex])) {
      headerIndex += 1;
    }
    if (headerIndex >= all.length) {
      debugPrint(
        '[BulkUploadPage] XLSX has no non-empty header row. rows=${all.length}',
      );
      return <Map<String, dynamic>>[];
    }

    final List<String> header = all[headerIndex]
        .map((Data? d) => _excelCellToString(d).trim())
        .toList();
    final Map<String, int> ix = _userIndexMap(header);
    _logLong('[BulkUploadPage] XLSX header(raw)=$header');
    _logLong(
      '[BulkUploadPage] XLSX header(normalized)=${header.map(_Identifiers._normHeader).toList()}',
    );
    _logLong(
      '[BulkUploadPage] XLSX indexMap(full_name=${ix['full_name']} email=${ix['email']} phone_number=${ix['phone_number']} dob=${ix['dob']})',
    );

    final List<Map<String, dynamic>> out = <Map<String, dynamic>>[];
    List<Data?>? firstNonEmptyRow;
    for (int i = headerIndex + 1; i < all.length; i++) {
      final List<Data?> row = all[i];
      if (_Identifiers._isExcelRowEmpty(row)) continue;
      firstNonEmptyRow ??= row;
      final Map<String, dynamic>? user = _userFromRow(
        valueAt: (String key) {
          final int? idx = ix[key];
          if (idx == null || idx < 0 || idx >= row.length) return '';
          return _excelCellToString(row[idx]);
        },
      );
      if (user != null) out.add(user);
    }

    if (out.isEmpty) {
      debugPrint('[BulkUploadPage] XLSX parse produced 0 users');
      if (firstNonEmptyRow != null) {
        final List<Data?> row = firstNonEmptyRow;
        final Map<String, String> sample = _sampleRequiredFields(
          valueAt: (String key) {
            final int? idx = ix[key];
            if (idx == null || idx < 0 || idx >= row.length) {
              return '';
            }
            return _excelCellToString(row[idx]);
          },
        );
        debugPrint('[BulkUploadPage] XLSX firstRow(sample)=$sample');
      }
    }
    return out;
  }

  static String _excelCellToString(Data? cell) {
    final Object? v = cell?.value;
    if (v == null) return '';
    if (v is num) {
      if (v.isNaN || v.isInfinite) return '';
      // Avoid scientific notation for large integers (phone/aadhar/pincode).
      final num rounded = v.round();
      final bool isIntLike = (v - rounded).abs() < 1e-9;
      if (isIntLike) return rounded.toInt().toString();
      // Keep as-is for decimals (rare in our sheet).
      return v.toString();
    }
    return v.toString().trim();
  }

  Map<String, int> _userIndexMap(List<String> header) {
    final Map<String, int> normalized = <String, int>{};
    for (int i = 0; i < header.length; i++) {
      final String key = _Identifiers._normHeader(header[i]);
      if (key.isEmpty) continue;
      normalized[key] = i;
    }

    int? pick(List<String> keys) {
      for (final String k in keys) {
        final int? i = normalized[k];
        if (i != null) return i;
      }
      return null;
    }

    int? pickWhere(bool Function(String) predicate) {
      for (final MapEntry<String, int> e in normalized.entries) {
        if (predicate(e.key)) return e.value;
      }
      return null;
    }

    return <String, int>{
      'full_name':
          pick(<String>['full_name', 'name', 'fullname']) ??
          pickWhere((String k) => k.contains('full_name')) ??
          pickWhere((String k) => k.contains('fullname')) ??
          pickWhere(
            (String k) => k.endsWith('_name') || k.startsWith('name_'),
          ) ??
          -1,
      'dob': pick(<String>['dob', 'date_of_birth']) ?? -1,
      'phone_number':
          pick(<String>['phone_number', 'phone', 'mobile', 'mobile_number']) ??
          pickWhere((String k) => k.contains('phone')) ??
          pickWhere((String k) => k.contains('mobile')) ??
          -1,
      'email':
          pick(<String>['email', 'email_id']) ??
          pickWhere((String k) => k.contains('email')) ??
          -1,
      'aadhar_number':
          pick(<String>[
            'aadhar_number',
            'aadhar',
            'aadhaar',
            'aadhaar_number',
          ]) ??
          -1,
      'pan_number': pick(<String>['pan_number', 'pan']) ?? -1,
      'address_line1':
          pick(<String>['address_line1', 'address1', 'address']) ?? -1,
      'address_line2': pick(<String>['address_line2', 'address2']) ?? -1,
      'address_line3': pick(<String>['address_line3', 'address3']) ?? -1,
      'pincode': pick(<String>['pincode', 'pin', 'zip', 'postal_code']) ?? -1,
      'state': pick(<String>['state', 'province']) ?? -1,
      'country': pick(<String>['country']) ?? -1,
    };
  }

  static Map<String, String> _sampleRequiredFields({
    required String Function(String) valueAt,
  }) {
    String maskEmail(String v) {
      final String raw = v.trim();
      final int at = raw.indexOf('@');
      if (at <= 1) return raw.isEmpty ? '' : '***';
      return '${raw[0]}***${raw.substring(at)}';
    }

    String maskPhone(String v) {
      final String digits = _BulkUploadPageState._normalizeDigits(v);
      if (digits.isEmpty) return '';
      final String tail = digits.length <= 4
          ? digits
          : digits.substring(digits.length - 4);
      return '***$tail';
    }

    return <String, String>{
      'full_name': valueAt('full_name').trim(),
      'email': maskEmail(valueAt('email')),
      'phone_number': maskPhone(valueAt('phone_number')),
      'dob': valueAt('dob').trim(),
    };
  }

  Map<String, dynamic>? _userFromRow({
    required String Function(String) valueAt,
  }) {
    final String fullName = valueAt('full_name').trim();
    final String rawEmail = valueAt('email');
    final String email = _looksLikeEmail(rawEmail)
        ? _normalizeEmail(rawEmail)
        : '';
    final String phone = _normalizePhone(valueAt('phone_number'));

    if (fullName.isEmpty) return null;
    if (email.isEmpty && phone.isEmpty) return null;

    final String? dob = _normalizeDob(valueAt('dob'));
    final String aadhar = _normalizeDigits(valueAt('aadhar_number'));
    final String pan = _normalizeAlphaNum(valueAt('pan_number'));

    final String addressLine1 = valueAt('address_line1').trim();
    final String addressLine2 = valueAt('address_line2').trim();
    final String addressLine3 = valueAt('address_line3').trim();
    final String pincode = _normalizeDigits(valueAt('pincode'));
    final String state = valueAt('state').trim();
    final String country = valueAt('country').trim();

    return <String, dynamic>{
      'full_name': fullName,
      if (dob case final String v) 'dob': v,
      if (phone.isNotEmpty) 'phone_number': phone,
      if (email.isNotEmpty) 'email': email,
      if (aadhar.isNotEmpty) 'aadhar_number': aadhar,
      if (pan.isNotEmpty) 'pan_number': pan,
      if (addressLine1.isNotEmpty) 'address_line1': addressLine1,
      if (addressLine2.isNotEmpty) 'address_line2': addressLine2,
      if (addressLine3.isNotEmpty) 'address_line3': addressLine3,
      if (pincode.isNotEmpty) 'pincode': pincode,
      if (state.isNotEmpty) 'state': state,
      if (country.isNotEmpty) 'country': country,
    };
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
    debugPrint(
      '[BulkUploadPage] Picked file name=${picked.name} bytes=${picked.bytes.length}',
    );
    setState(() => _pickedFile = picked);
  }

  Future<void> _confirmAndCreateBatch() async {
    final List<String> columns = _columns();
    debugPrint(
      '[BulkUploadPage] Confirm tapped batch=${_batchNameController.text.trim()} picked=${_pickedFile?.name}',
    );
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

    final Uri uri = Uri(
      path: AppRouter.certificatePreviewPath,
      queryParameters: <String, String>{
        'checks': _checks.join(','),
        'industry': _industry,
        'industry_label': _prettyIndustry(_industry),
        'identity_type': 'Individual',
      },
    );
    final Object? res = await context.push(uri.toString());
    if (res == true) {
      await _uploadAndNavigate(columns);
    }
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
      debugPrint(
        '[BulkUploadPage] Uploading bulk file name=${file.name} bytes=${file.bytes.length}',
      );
      final res = await repo.bulkUpload(
        batchName: _batchNameController.text.trim(),
        description: null,
        fileBytes: file.bytes,
        fileName: file.name,
      );
      final String batchName = _batchNameController.text.trim();
      await ref
          .read(batchNameStoreProvider.notifier)
          .setBatchName(res.batchId, batchName);
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
        final dynamic data = e.response?.data;
        String? serverMessage;
        if (data is String && data.trim().isNotEmpty) {
          serverMessage = data.trim();
        } else if (data is Map && data['message'] is String) {
          final String m = (data['message'] as String).trim();
          if (m.isNotEmpty) serverMessage = m;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              serverMessage ?? e.message ?? 'Upload failed. Please try again.',
            ),
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
        // Don't hard-block: the backend already supports skipping duplicates and
        // returns `skipped_users`. Blocking here can be confusing, especially
        // if the previous attempt partially succeeded (e.g. server error after
        // creating some records).
        final bool proceed = await _confirmProceedDialog(
          title: 'Some people may already exist',
          message:
              'Some people in this file already have verifications in your org. If you continue, they may be skipped.',
          samples: overlap.take(6).toList(),
          confirmLabel: 'Continue',
          cancelLabel: 'Cancel',
        );
        return proceed;
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

  Future<bool> _confirmProceedDialog({
    required String title,
    required String message,
    required List<String> samples,
    required String confirmLabel,
    required String cancelLabel,
  }) async {
    if (!mounted) return false;
    final bool? res = await showDialog<bool>(
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
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(cancelLabel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(confirmLabel),
            ),
          ],
        );
      },
    );
    return res ?? false;
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

  static bool _looksLikeEmail(String v) {
    final String s = v.trim();
    return s.contains('@') && s.contains('.');
  }

  static String? _normalizeDob(String raw) {
    final String v = raw.trim();
    if (v.isEmpty) return null;

    final RegExp iso = RegExp(r'^\d{4}-\d{2}-\d{2}$');
    if (iso.hasMatch(v)) return v;

    final RegExp dmy = RegExp(r'^(\d{1,2})[\/\-](\d{1,2})[\/\-](\d{4})$');
    final Match? m = dmy.firstMatch(v);
    if (m == null) return null;
    final int? dd = int.tryParse(m.group(1)!);
    final int? mm = int.tryParse(m.group(2)!);
    final int? yyyy = int.tryParse(m.group(3)!);
    if (dd == null || mm == null || yyyy == null) return null;
    if (yyyy < 1900 || yyyy > 2100) return null;
    if (mm < 1 || mm > 12) return null;
    if (dd < 1 || dd > 31) return null;
    final String m2 = mm.toString().padLeft(2, '0');
    final String d2 = dd.toString().padLeft(2, '0');
    return '$yyyy-$m2-$d2';
  }

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

  void _logLong(String message) {
    // debugPrint() can throttle long lines; chunk them to ensure visibility.
    const int chunk = 800;
    if (message.length <= chunk) {
      debugPrint(message);
      return;
    }
    for (int i = 0; i < message.length; i += chunk) {
      final int end = (i + chunk < message.length) ? i + chunk : message.length;
      debugPrint(message.substring(i, end));
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<String> columns = _columns();

    return Scaffold(
      backgroundColor: AppColors.brandBlue,
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final double contentWidth = constraints.maxWidth < _referenceWidth
                ? constraints.maxWidth
                : _referenceWidth;
            final double scale = contentWidth / _referenceWidth;
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
                            onTap: () => context.pop(),
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
                          _IndustryPill(
                            scale: scale,
                            industryLabel: _prettyIndustry(_industry),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: s(18)),
                    Expanded(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: _panelBg,
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
                                    Row(
                                      children: <Widget>[
                                        Text(
                                          'STEP 4 OF 4',
                                          style: TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: s(10),
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: s(1),
                                            height: 15 / 10,
                                            color: const Color(0xFF94A3B8),
                                          ),
                                        ),
                                        const Spacer(),
                                        Text(
                                          '75%',
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
                                    SizedBox(height: s(8)),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(
                                        s(9999),
                                      ),
                                      child: SizedBox(
                                        height: s(4),
                                        child: Stack(
                                          fit: StackFit.expand,
                                          children: <Widget>[
                                            const DecoratedBox(
                                              decoration: BoxDecoration(
                                                color: Color(0xFFE5E7EB),
                                              ),
                                            ),
                                            FractionallySizedBox(
                                              alignment: Alignment.centerLeft,
                                              widthFactor: 0.8027,
                                              child: const DecoratedBox(
                                                decoration: BoxDecoration(
                                                  color: AppColors.brandBlue,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
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
                                        color: _panelText,
                                      ),
                                    ),
                                    SizedBox(height: s(12)),
                                    _BatchNameField(
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
                                              color: _panelText,
                                            ),
                                          ),
                                        ),
                                        InkResponse(
                                          key: _menuKey,
                                          onTap: () => _openMoreMenu(
                                            scale: scale,
                                            columns: columns,
                                          ),
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
                                      'Download template based on your selected checks.\nUpload your Excel/CSV, then Confirm the batch.',
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
                                      onTap: () => _openUploadSheet(
                                        title: 'Upload Excel / CSV',
                                        description:
                                            'Pick an Excel/CSV file to create the batch.',
                                      ),
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
                                          color: _panelText,
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
                                      SizedBox(height: s(28)),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                            _BottomNav(
                              scale: scale,
                              child: _UploadButton(
                                scale: scale,
                                isLoading: _isUploading,
                                enabled:
                                    _pickedFile != null &&
                                    _batchNameController.text
                                        .trim()
                                        .isNotEmpty &&
                                    !_isUploading &&
                                    !_preflightChecking,
                                onTap: () => _confirmAndCreateBatch(),
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

  static String _formatBytes(int bytes) {
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

  static String _prettyIndustry(String raw) {
    final String v = raw.trim();
    if (v.isEmpty) return 'Real Estate';
    final String lower = v.toLowerCase();
    if (lower == 'all' || lower == 'both') return 'All';

    // Handle serialized multi-select values like '["A","B"]' or 'A,B'.
    if ((v.startsWith('[') && v.endsWith(']')) || v.contains(',')) {
      List<String> parts;
      if (v.startsWith('[') && v.endsWith(']')) {
        parts = v
            .substring(1, v.length - 1)
            .split(',')
            .map((String s) => s.replaceAll('"', '').trim())
            .where((String s) => s.isNotEmpty)
            .toList();
      } else {
        parts = v
            .split(',')
            .map((String s) => s.trim())
            .where((String s) => s.isNotEmpty)
            .toList();
      }
      if (parts.isNotEmpty && parts.length >= 10) return 'All';
    }
    final List<String> parts = v
        .replaceAll(RegExp(r'[_-]+'), ' ')
        .split(' ')
        .where((String p) => p.trim().isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'Real Estate';
    String cap(String s) =>
        s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1).toLowerCase()}';
    return parts.map(cap).join(' ');
  }

  Future<void> _openMoreMenu({
    required double scale,
    required List<String> columns,
  }) async {
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
          height: 40 * scale,
          child: Center(
            child: Text(
              'Download Template',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12 * scale,
                fontWeight: FontWeight.w600,
                height: 18 / 12,
                color: AppColors.brandBlue,
              ),
            ),
          ),
        ),
        const PopupMenuDivider(height: 1),
        PopupMenuItem<_MoreAction>(
          value: _MoreAction.viewTemplateColumns,
          height: 40 * scale,
          child: Center(
            child: Text(
              'View Template Columns',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12 * scale,
                fontWeight: FontWeight.w600,
                height: 18 / 12,
                color: AppColors.brandBlue,
              ),
            ),
          ),
        ),
      ],
    );

    if (!mounted || picked == null) return;

    switch (picked) {
      case _MoreAction.downloadTemplate:
        await _downloadTemplate();
      case _MoreAction.viewTemplateColumns:
        await _showTemplateColumnsDialog(scale: scale, columns: columns);
    }
  }

  Future<void> _showTemplateColumnsDialog({
    required double scale,
    required List<String> columns,
  }) async {
    double s(double v) => v * scale;

    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          insetPadding: EdgeInsets.fromLTRB(s(18), s(18), s(18), s(18)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(s(16)),
            side: BorderSide(color: const Color(0xFFE5E7EB), width: s(1)),
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(s(16), s(16), s(16), s(16)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Text(
                      'Template Columns',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: s(16),
                        fontWeight: FontWeight.w700,
                        height: 24 / 16,
                        color: const Color(0xFF111827),
                      ),
                    ),
                    const Spacer(),
                    InkResponse(
                      onTap: () => Navigator.of(context).pop(),
                      radius: s(18),
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
                SizedBox(height: s(12)),
                Wrap(
                  spacing: s(8),
                  runSpacing: s(8),
                  children: <Widget>[
                    for (final String c in columns)
                      Container(
                        padding: EdgeInsets.fromLTRB(s(10), s(6), s(10), s(6)),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF3FF),
                          borderRadius: BorderRadius.circular(s(999)),
                        ),
                        child: Text(
                          c,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: s(12),
                            fontWeight: FontWeight.w600,
                            height: 16 / 12,
                            color: AppColors.brandBlue,
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: s(14)),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'Close',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: s(13),
                        fontWeight: FontWeight.w600,
                        color: AppColors.brandBlue,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

enum _MoreAction { downloadTemplate, viewTemplateColumns }

class _IndustryPill extends StatelessWidget {
  const _IndustryPill({required this.scale, required this.industryLabel});

  final double scale;
  final String industryLabel;

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
            industryLabel,
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
          SizedBox(width: s(8)),
          Container(width: s(1), height: s(12), color: const Color(0xFFE2E8F0)),
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
                    fontSize: s(18),
                    fontWeight: FontWeight.w700,
                    height: 24 / 18,
                    color: const Color(0xFF111827),
                  ),
                ),
                SizedBox(height: s(8)),
                Text(
                  'Upload your Excel or CSV file here',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: s(13),
                    fontWeight: FontWeight.w500,
                    height: 18 / 13,
                    color: const Color(0xFF94A3B8),
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

class _BatchNameField extends StatelessWidget {
  const _BatchNameField({
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
        hintText: 'Enter a batch name, Ex. Driver Verification Q1',
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

class _UploadButton extends StatelessWidget {
  const _UploadButton({
    required this.scale,
    required this.isLoading,
    required this.enabled,
    required this.onTap,
  });

  final double scale;
  final bool isLoading;
  final bool enabled;
  final VoidCallback onTap;

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
                    'Upload',
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
        .replaceAll(RegExp(r'\s+'), '_')
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

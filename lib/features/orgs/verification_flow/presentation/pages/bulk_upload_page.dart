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
import '../../../../../core/widgets/org_top_bar.dart';
import '../../../../../core/widgets/tmz_badge.dart';
import '../../../../../core/widgets/tmz_button.dart';
import 'human_verification_checks_catalog.dart';
import 'product_verification_checks_catalog.dart';

class BulkUploadPage extends ConsumerStatefulWidget {
  const BulkUploadPage({super.key});

  @override
  ConsumerState<BulkUploadPage> createState() => _BulkUploadPageState();
}

class _BulkUploadPageState extends ConsumerState<BulkUploadPage> {
  static const double _referenceWidth = 402;
  static const Color _panelBg = Color(0xFFF7F9FC);
  static const Color _panelText = Color(0xFF3A3A3A);
  static const List<String> _defaultHumanTemplateHeaders = <String>[
    'full_name',
    'email',
    'phone_number',
    'aadhar_number',
    'pan_number',
    'dob',
    'gender',
    'dl_number',
    'nationality',
  ];
  static const String _humanDocumentFieldsCsv =
      'full_name,name,email,phone_number,dob,license_number,dl_number,dl_no,doi,valid_till,cov_lmv_doi,cov_mcwg_doi,blood_group,sdw_of,issuing_authority,aadhar_number,pan_number,address_line1,address_line2,address_line3,address,pincode,pin,state,country';
  static const List<String> _drivingLicenseTemplateHeaders = <String>[
    'full_name',
    'phone_number',
    'email',
    'dob',
    'dl_number',
    'nationality',
  ];

  String? _lastRouteSignature;

  late final TextEditingController _batchNameController;
  late final TextEditingController _columnsController;
  List<String> _savedTemplateHeaders = <String>[];
  bool _seededRouteTemplate = false;

  String _industry = '';
  String _credentialVisibility = 'public_searchable';
  Set<String> _checks = <String>{};
  Set<String> _checkIds = <String>{};
  bool _seededDefaultChecks = false;

  PickedFile? _pickedFile;
  bool _isUploading = false;
  bool _preflightChecking = false;
  List<Map<String, dynamic>> _parsedUsers = <Map<String, dynamic>>[];
  final Map<int, List<_HumanDocumentDraft>> _attachedDocumentsByUser =
      <int, List<_HumanDocumentDraft>>{};
  int _selectedUserIndex = 0;

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
    final String nextVisibility = (qp['access'] ?? _credentialVisibility)
        .trim()
        .toLowerCase();
    final Set<String> nextChecks = _parseCsvSet(qp['checks']) ?? <String>{};
    final Set<String> nextCheckIds =
        _parseCsvSet(qp['check_ids']) ?? <String>{};
    final List<String> nextColumns =
        _parseCsvList(qp['columns']) ??
        _templateColumnsForChecks(nextChecks, nextCheckIds);

    setState(() {
      _industry = nextIndustry;
      if (nextVisibility.isNotEmpty) {
        _credentialVisibility = nextVisibility;
      }
      _checks = nextChecks;
      _checkIds = nextCheckIds;
      _seededDefaultChecks = false;
      _savedTemplateHeaders = <String>[];
      _seededRouteTemplate = false;
      _columnsController.text = nextColumns.join(',');
    });

    debugPrint(
      '[BulkUploadPage] route checks=${nextChecks.join(",")} check_ids=${nextCheckIds.join(",")} columns=${nextColumns.join(",")}',
    );
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

  static bool _looksLikeDrivingLicenseToken(String value) {
    final String normalized = value.trim().toLowerCase();
    return normalized.contains('drive') || normalized.contains('license');
  }

  static bool _hasDrivingLicenseSelection(
    Iterable<String> checks,
    Iterable<String> checkIds,
  ) {
    for (final String value in <String>[...checks, ...checkIds]) {
      if (_looksLikeDrivingLicenseToken(value)) return true;
    }
    return false;
  }

  static List<String> _templateColumnsForChecks(
    Set<String> checks,
    Set<String> checkIds,
  ) {
    if (_hasDrivingLicenseSelection(checks, checkIds)) {
      // Driving license flows need a smaller starter set, but users can still
      // add more columns in the template dialog before generating the file.
      return List<String>.from(_drivingLicenseTemplateHeaders);
    }
    // Keep the human template seeded with the default fields requested for
    // first-time download. Users can still remove any of them in the template
    // dialog before generating the file.
    return List<String>.from(_defaultHumanTemplateHeaders);
  }

  static bool _looksLikeDrivingLicenseCheck(VerificationTypeDefinition item) {
    final String haystack = <String>[
      item.id,
      item.name,
      item.label,
    ].join(' ').toLowerCase();
    return haystack.contains('drive') || haystack.contains('license');
  }

  bool _shouldUseDrivingLicenseTemplate(
    Set<String> checks,
    Set<String> checkIds,
    Map<String, VerificationTypeDefinition> verificationTypesById,
  ) {
    if (_hasDrivingLicenseSelection(checks, checkIds)) return true;
    for (final String id in checkIds) {
      final VerificationTypeDefinition? item = verificationTypesById[id];
      if (item == null) continue;
      if (_looksLikeDrivingLicenseCheck(item)) return true;
    }
    for (final String raw in checks) {
      final VerificationTypeDefinition? item = verificationTypesById[raw];
      if (item == null) continue;
      if (_looksLikeDrivingLicenseCheck(item)) return true;
    }
    return false;
  }

  List<String> _columns() {
    return _dedupeHeaders(
      (_columnsController.text)
          .split(',')
          .map((String s) => s.trim())
          .where((String s) => s.isNotEmpty)
          .toList(),
    );
  }

  static List<String> _dedupeHeaders(List<String> headers) {
    final List<String> ordered = <String>[];
    final Set<String> seen = <String>{};
    for (final String header in headers) {
      final String cleaned = header.trim();
      if (cleaned.isEmpty) continue;
      final String key = cleaned.toLowerCase();
      if (seen.add(key)) {
        ordered.add(cleaned);
      }
    }
    return ordered;
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
      // Excel-facing DL column is `dl_number`. Keep accepting the legacy
      // `license_number` (and common aliases) so older files still parse.
      // Both keys resolve to the same column; backend still receives
      // `license_number` (dl_number → license_number mapping preserved).
      'license_number':
          pick(<String>[
            'dl_number',
            'license_number',
            'dl_no',
            'driving_license_number',
            'driver_license_number',
            'driving_licence_number',
          ]) ??
          -1,
      'dl_number':
          pick(<String>[
            'dl_number',
            'license_number',
            'dl_no',
            'driving_license_number',
            'driver_license_number',
            'driving_licence_number',
          ]) ??
          -1,
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
    // Match the backend contract for human bulk upload:
    // full_name, email, and phone_number are all required.
    if (email.isEmpty || phone.isEmpty) return null;

    final String? dob = _normalizeDob(valueAt('dob'));
    // Excel-facing DL column is `dl_number`; backend still expects
    // `license_number` (dl_number → license_number mapping preserved).
    final String dlRaw = valueAt('dl_number').trim().isNotEmpty
        ? valueAt('dl_number')
        : valueAt('license_number');
    final String licenseNumber = _normalizeAlphaNum(dlRaw);
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
      if (licenseNumber.isNotEmpty) 'license_number': licenseNumber,
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
    final List<String> initialHeaders = _savedTemplateHeaders.isNotEmpty
        ? List<String>.from(_savedTemplateHeaders)
        : _columns();
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black54,
      builder: (BuildContext dialogContext) {
        return _HumanTemplateDialog(
          initialHeaders: initialHeaders,
          selectedChecks: _checks,
          selectedCheckIds: _checkIds,
          verificationFilter: 'human',
          onSave: (List<String> headers) {
            if (!mounted) return;
            setState(() {
              _savedTemplateHeaders = List<String>.from(headers);
            });
          },
        );
      },
    );
  }

  Future<void> _pickExcelFile() async {
    if (_batchNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a batch name first.')),
      );
      return;
    }
    final PickedFile? picked = await FilePickerUtil.pickExcel();
    if (!mounted) return;
    if (picked == null) return;
    await _setPickedFile(picked);
  }

  Future<void> _setPickedFile(PickedFile picked) async {
    debugPrint(
      '[BulkUploadPage] Picked file name=${picked.name} bytes=${picked.bytes.length}',
    );
    setState(() {
      _pickedFile = picked;
      _parsedUsers = _parseUsersFromPickedFile(picked);
      _attachedDocumentsByUser.clear();
      _selectedUserIndex = 0;
    });
  }

  String _displayUserLabel(Map<String, dynamic> user, int index) {
    final String fullName = (user['full_name'] ?? '').toString().trim();
    final String email = (user['email'] ?? '').toString().trim();
    final String phone = (user['phone_number'] ?? '').toString().trim();
    if (fullName.isNotEmpty) return fullName;
    if (email.isNotEmpty) return email;
    if (phone.isNotEmpty) return phone;
    return 'User ${index + 1}';
  }

  void _ensureDocumentUsers() {
    if (_parsedUsers.isNotEmpty) return;
    _parsedUsers = <Map<String, dynamic>>[
      <String, dynamic>{'full_name': 'User 1'},
    ];
    _selectedUserIndex = 0;
  }

  void _addManualDocumentUser() {
    final int nextIndex = _parsedUsers.length + 1;
    _parsedUsers = <Map<String, dynamic>>[
      ..._parsedUsers,
      <String, dynamic>{'full_name': 'User $nextIndex'},
    ];
    _selectedUserIndex = _parsedUsers.length - 1;
  }

  List<_HumanDocumentDraft> _documentDraftsForUser(int index) {
    return _attachedDocumentsByUser[index] ?? <_HumanDocumentDraft>[];
  }

  void _mergeOcrIntoUser(int index, Map<String, dynamic> ocrData) {
    if (index < 0 || index >= _parsedUsers.length) return;
    final Map<String, dynamic> current = Map<String, dynamic>.from(
      _parsedUsers[index],
    );
    for (final MapEntry<String, dynamic> entry in ocrData.entries) {
      final String key = entry.key.trim();
      final dynamic value = entry.value;
      if (key.isEmpty) continue;
      if (value == null) continue;
      final String str = value.toString().trim();
      if (str.isEmpty) continue;
      current[key] = str;
    }
    _parsedUsers[index] = current;
  }

  Map<String, dynamic> _normalizeOcrMap(dynamic response) {
    Map<String, dynamic> responseMap;
    if (response is Map<String, dynamic>) {
      responseMap = response;
    } else if (response is Map) {
      responseMap = Map<String, dynamic>.from(response);
    } else if (response is String) {
      final String raw = response.trim();
      if (raw.startsWith('{') && raw.endsWith('}')) {
        try {
          final dynamic decoded = jsonDecode(raw);
          if (decoded is Map) {
            responseMap = Map<String, dynamic>.from(decoded);
          } else {
            return <String, dynamic>{'raw_text': raw};
          }
        } catch (_) {
          // Fall through to raw string wrapper.
          return <String, dynamic>{'raw_text': raw};
        }
      } else {
        return <String, dynamic>{'raw_text': raw};
      }
    } else {
      return <String, dynamic>{'raw_text': response.toString()};
    }

    final Map<String, dynamic> flattened = <String, dynamic>{};

    final dynamic extracted = responseMap['extracted'];
    if (extracted is Map) {
      flattened.addAll(Map<String, dynamic>.from(extracted));
    }

    final dynamic perFile = responseMap['per_file'];
    if (perFile is List) {
      for (final dynamic item in perFile) {
        if (item is Map && item['extracted'] is Map) {
          flattened.addAll(Map<String, dynamic>.from(item['extracted'] as Map));
        }
      }
    }

    // Some OCR responses may already come back flattened; keep any top-level
    // field values as a fallback without overwriting extracted values.
    for (final MapEntry<String, dynamic> entry in responseMap.entries) {
      final String key = entry.key.trim();
      if (key.isEmpty || key == 'extracted' || key == 'per_file') continue;
      if (!flattened.containsKey(key)) {
        flattened[key] = entry.value;
      }
    }

    if (flattened.isNotEmpty) return flattened;

    return responseMap;
  }

  Map<String, dynamic> _applyOcrFieldAliases(Map<String, dynamic> data) {
    final Map<String, dynamic> mapped = Map<String, dynamic>.from(data);

    void setIfMissing(String target, List<String> sources) {
      if ((mapped[target] ?? '').toString().trim().isNotEmpty) return;
      for (final String source in sources) {
        final String value = (mapped[source] ?? '').toString().trim();
        if (value.isNotEmpty) {
          mapped[target] = value;
          return;
        }
      }
    }

    setIfMissing('full_name', <String>[
      'full_name',
      'name',
      'name_english',
      'name_hindi',
    ]);
    setIfMissing('license_number', <String>[
      'license_number',
      'dl_no',
      'dl_number',
      'driving_license_number',
      'driver_license_number',
    ]);
    setIfMissing('aadhar_number', <String>['aadhar_number', 'aadhaar_number']);
    setIfMissing('address_line1', <String>[
      'address_line1',
      'address',
      'address_english',
      'address_hindi',
    ]);
    setIfMissing('pincode', <String>['pincode', 'pin', 'pin_code']);

    return mapped;
  }

  Future<Map<String, dynamic>?> _extractOcrForDocs(
    List<_HumanDocumentDraft> docs,
  ) async {
    final List<Uint8List> imageBytes = docs
        .where(
          (_HumanDocumentDraft draft) =>
              draft.file.extension.toLowerCase().contains('jpg') ||
              draft.file.extension.toLowerCase().contains('jpeg') ||
              draft.file.extension.toLowerCase().contains('png') ||
              draft.file.extension.toLowerCase().contains('webp'),
        )
        .map((_HumanDocumentDraft draft) => draft.file.bytes)
        .toList();
    if (imageBytes.isEmpty) return null;

    try {
      final VerificationRepository repo = ref.read(
        verificationRepositoryProvider,
      );
      final dynamic res = await repo.extractHumanOcr(
        files: imageBytes,
        fields: _humanDocumentFieldsCsv,
        docType: docs.first.label,
      );
      return _applyOcrFieldAliases(_normalizeOcrMap(res));
    } catch (e) {
      debugPrint('[BulkUploadPage] OCR extraction failed: $e');
      return null;
    }
  }

  int _findMatchingDraftIndex(BulkUploadSuccessUser serverUser, int fallback) {
    final String targetFullName = serverUser.fullName.trim().toLowerCase();
    final String targetEmail = serverUser.email.trim().toLowerCase();
    final String targetPhone = serverUser.phoneNumber.trim().replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );

    for (int i = 0; i < _parsedUsers.length; i++) {
      final Map<String, dynamic> user = _parsedUsers[i];
      final String fullName = (user['full_name'] ?? '')
          .toString()
          .trim()
          .toLowerCase();
      final String email = (user['email'] ?? '')
          .toString()
          .trim()
          .toLowerCase();
      final String phone = (user['phone_number'] ?? '').toString().replaceAll(
        RegExp(r'[^0-9]'),
        '',
      );

      if (targetEmail.isNotEmpty && email == targetEmail) return i;
      if (targetPhone.isNotEmpty && phone == targetPhone) return i;
      if (targetFullName.isNotEmpty && fullName == targetFullName) return i;
    }

    if (fallback >= 0 && fallback < _parsedUsers.length) return fallback;
    return -1;
  }

  Map<String, dynamic> _userPayloadFromDraft(Map<String, dynamic> user) {
    final Map<String, dynamic> payload = <String, dynamic>{
      'full_name': (user['full_name'] ?? '').toString().trim(),
      'email': (user['email'] ?? '').toString().trim(),
      'phone_number': (user['phone_number'] ?? '').toString().trim(),
    };
    const List<String> optionalKeys = <String>[
      'dob',
      'aadhar_number',
      'pan_number',
      'address_line1',
      'address_line2',
      'address_line3',
      'pincode',
      'state',
      'country',
    ];
    for (final String key in optionalKeys) {
      final String value = (user[key] ?? '').toString().trim();
      if (value.isNotEmpty) payload[key] = value;
    }
    return payload;
  }

  /// Opens the dedicated OCR documents page (documents → review → photos),
  /// forwarding the current flow context. Replaces the legacy attach sheet
  /// for new uploads; legacy dialog code below stays for reference.
  void _openOcrDocumentsFlow() {
    if (_batchNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a batch name first.')),
      );
      return;
    }
    final List<String> sortedChecks = _checks.toList()..sort();
    final List<String> sortedCheckIds = _checkIds.toList()..sort();
    final Uri uri = Uri(
      path: AppRouter.ocrDocumentsFlowPath,
      queryParameters: <String, String>{
        'batch': _batchNameController.text.trim(),
        if (_industry.trim().isNotEmpty) 'industry': _industry.trim(),
        if (_credentialVisibility.trim().isNotEmpty)
          'access': _credentialVisibility.trim(),
        if (sortedChecks.isNotEmpty) 'checks': sortedChecks.join(','),
        if (sortedCheckIds.isNotEmpty) 'check_ids': sortedCheckIds.join(','),
        if (_columnsController.text.trim().isNotEmpty)
          'columns': _columnsController.text.trim(),
      },
    );
    context.push(uri.toString());
  }

  Future<void> _openAttachDocumentsDialog() async {
    if (_batchNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a batch name first.')),
      );
      return;
    }
    setState(_ensureDocumentUsers);
    int selectedIndex = _selectedUserIndex.clamp(0, _parsedUsers.length - 1);
    bool isProcessing = false;
    bool isAddingDocs = false;
    String busyStatus = '';
    bool sheetBusy() => isProcessing || isAddingDocs;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, void Function(void Function()) setDialogState) {
            Future<void> addDocuments() async {
              if (sheetBusy()) return;
              setDialogState(() => isAddingDocs = true);
              final List<PickedFile> picked =
                  await FilePickerUtil.pickDocuments();
              try {
                if (!mounted || picked.isEmpty) return;
                final List<_HumanDocumentDraft> drafts = picked
                    .map(
                      (PickedFile file) =>
                          _HumanDocumentDraft(label: 'document', file: file),
                    )
                    .toList();
                setState(() {
                  final List<_HumanDocumentDraft> docs =
                      _attachedDocumentsByUser.putIfAbsent(
                        selectedIndex,
                        () => <_HumanDocumentDraft>[],
                      );
                  docs.addAll(drafts);
                  _selectedUserIndex = selectedIndex;
                });
                final Map<String, dynamic>? ocr = await _extractOcrForDocs(
                  drafts,
                );
                if (ocr != null) {
                  setState(() => _mergeOcrIntoUser(selectedIndex, ocr));
                }
              } finally {
                if (mounted) {
                  setDialogState(() => isAddingDocs = false);
                }
              }
            }

            // Smooth in-sheet flow: the sheet stays open with inline progress
            // while uploading, then review and photo sheets stack on top of
            // it — the background page is never exposed mid-flow. Review/photo
            // sheets share the same Dialog styling so it reads as one wizard
            // (steps 1→2→3). Same workers as _submitDocumentBatch, same order,
            // same requests; only the presentation is unified.
            Future<void> reviewAndContinue() async {
              if (sheetBusy()) return;
              if (_documentUploadFiles().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please attach at least one document image.'),
                  ),
                );
                return;
              }
              setDialogState(() {
                isProcessing = true;
                busyStatus =
                    'Uploading ${(_documentUploadFiles().length)} document(s)…';
              });
              try {
                final ({
                  BulkUploadResponse res,
                  Map<int, String> userIdsByIndex,
                })
                uploaded = await _uploadOcrDocumentsAndMerge();
                final BulkUploadResponse uploadedRes = uploaded.res;
                final Map<int, String> uploadedIds = uploaded.userIdsByIndex;
                if (!mounted || !dialogContext.mounted) return;
                setDialogState(() {
                  busyStatus = 'Reading OCR results…';
                });
                setState(() {});
                // Stacked on top of this sheet — this sheet stays underneath
                // so dismissing review returns here instead of flashing the
                // background page.
                final List<Map<String, dynamic>>? reviewedUsers =
                    await showDialog<List<Map<String, dynamic>>>(
                      context: dialogContext,
                      barrierDismissible: false,
                      builder: (BuildContext context) {
                        return _HumanReviewDialog(
                          users: _parsedUsers,
                          documentsByUser: _attachedDocumentsByUser,
                          skipped: uploadedRes.skippedUsers,
                          errors: uploadedRes.errors,
                          stepEyebrow: 'STEP 2 OF 3 • REVIEW',
                        );
                      },
                    );
                if (reviewedUsers == null || reviewedUsers.isEmpty) {
                  setDialogState(() {
                    isProcessing = false;
                    busyStatus = '';
                  });
                  return;
                }
                if (!mounted || !dialogContext.mounted) return;
                setDialogState(() {
                  busyStatus = 'Saving review…';
                });
                await _persistReviewedOcrUsers(reviewedUsers, uploadedIds);
                if (!mounted || !dialogContext.mounted) return;
                if (uploadedRes.successfulUsers.isNotEmpty) {
                  final Map<String, int> localIndexByUserId = <String, int>{
                    for (final MapEntry<int, String> e in uploadedIds.entries)
                      e.value: e.key,
                  };
                  setDialogState(() {
                    busyStatus = 'Documents saved — add photos.';
                  });
                  await showDialog<void>(
                    context: dialogContext,
                    barrierDismissible: false,
                    builder: (BuildContext context) {
                      return _OcrPhotoStageDialog(
                        users: uploadedRes.successfulUsers,
                        skippedCount: uploadedRes.totalSkipped,
                        skipped: uploadedRes.skippedUsers,
                        docErrors: uploadedRes.errors,
                        displayNameFor: (BulkUploadSuccessUser u) =>
                            _ocrPhotoDisplayName(
                              u,
                              localIndexByUserId,
                              reviewedUsers,
                            ),
                      );
                    },
                  );
                }
                if (!mounted || !dialogContext.mounted) return;
                Navigator.of(dialogContext).pop();
                await Future<void>.delayed(Duration.zero);
                if (!mounted) return;
                await _storeBatchAndGoToCosting(uploadedRes);
              } catch (e) {
                if (e is DioException) {
                  debugPrint(
                    '[BulkUploadPage] Smooth OCR flow DioException: type=${e.type} '
                    'status=${e.response?.statusCode} data=${e.response?.data} message=${e.message}',
                  );
                }
                if (!mounted || !dialogContext.mounted) return;
                ScaffoldMessenger.of(
                  dialogContext,
                ).showSnackBar(SnackBar(content: Text(_ocrFriendlyError(e))));
                setDialogState(() {
                  isProcessing = false;
                  busyStatus = '';
                });
              }
            }

            void addUser() {
              setState(() {
                _addManualDocumentUser();
                selectedIndex = _selectedUserIndex;
              });
              setDialogState(() {});
            }

            void removeCurrentUser() {
              if (_parsedUsers.length <= 1) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Keep at least one user in the batch.'),
                  ),
                );
                return;
              }
              setState(() {
                final int removedIndex = selectedIndex;
                _parsedUsers.removeAt(removedIndex);
                _attachedDocumentsByUser.remove(removedIndex);

                final Map<int, List<_HumanDocumentDraft>> shifted =
                    <int, List<_HumanDocumentDraft>>{};
                for (final MapEntry<int, List<_HumanDocumentDraft>> entry
                    in _attachedDocumentsByUser.entries.toList()) {
                  final int key = entry.key;
                  if (key > removedIndex) {
                    shifted[key - 1] = entry.value;
                  } else {
                    shifted[key] = entry.value;
                  }
                }
                _attachedDocumentsByUser
                  ..clear()
                  ..addAll(shifted);

                if (selectedIndex >= _parsedUsers.length) {
                  selectedIndex = _parsedUsers.length - 1;
                }
                if (selectedIndex < 0) selectedIndex = 0;
                _selectedUserIndex = selectedIndex;
              });
              setDialogState(() {});
            }

            void goToPreviousUser() {
              if (selectedIndex <= 0) return;
              setDialogState(() => selectedIndex -= 1);
            }

            void goToNextUser() {
              if (selectedIndex >= _parsedUsers.length - 1) return;
              setDialogState(() => selectedIndex += 1);
            }

            void removeDocument(int docIndex) {
              final List<_HumanDocumentDraft>? docs =
                  _attachedDocumentsByUser[selectedIndex];
              if (docs == null || docIndex < 0 || docIndex >= docs.length) {
                return;
              }
              setState(() {
                docs.removeAt(docIndex);
                if (docs.isEmpty) {
                  _attachedDocumentsByUser.remove(selectedIndex);
                }
              });
              setDialogState(() {});
            }

            final List<_HumanDocumentDraft> currentDocs =
                _documentDraftsForUser(selectedIndex);
            Widget stepLabel() {
              return Text(
                'STEP 1 OF 3 • DOCUMENTS',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.label.copyWith(
                  color: AppColors.textTertiary,
                ),
              );
            }

            Widget navChevron({
              required IconData icon,
              required String tooltip,
              required VoidCallback? onTap,
            }) {
              return InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(999),
                child: SizedBox(
                  width: 30,
                  height: 30,
                  child: Icon(
                    icon,
                    size: 15,
                    color: onTap == null
                        ? AppColors.textTertiary.withAlpha(120)
                        : AppColors.textSecondary,
                  ),
                ),
              );
            }

            Widget headerActions() {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  if (_parsedUsers.length > 1)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: AppColors.offWhite,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          navChevron(
                            icon: Icons.arrow_back_ios_new_rounded,
                            tooltip: 'Previous user',
                            onTap: sheetBusy() || selectedIndex <= 0
                                ? null
                                : goToPreviousUser,
                          ),
                          Container(
                            width: 1,
                            height: 16,
                            color: AppColors.divider,
                          ),
                          navChevron(
                            icon: Icons.arrow_forward_ios_rounded,
                            tooltip: 'Next user',
                            onTap:
                                sheetBusy() ||
                                    selectedIndex >= _parsedUsers.length - 1
                                ? null
                                : goToNextUser,
                          ),
                        ],
                      ),
                    ),
                  if (_parsedUsers.length > 1) const SizedBox(width: 8),
                  InkWell(
                    onTap: sheetBusy()
                        ? null
                        : () => Navigator.of(dialogContext).pop(),
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.cardSurface,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.divider),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.close_rounded,
                        size: 16,
                        color: sheetBusy()
                            ? AppColors.textTertiary.withAlpha(120)
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              );
            }

            return Dialog(
              insetPadding: const EdgeInsets.all(16),
              backgroundColor: AppColors.cardSurface,
              surfaceTintColor: AppColors.cardSurface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 560,
                  maxHeight: 720,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      LayoutBuilder(
                          builder:
                              (
                                BuildContext context,
                                BoxConstraints constraints,
                              ) {
                                if (constraints.maxWidth < 320) {
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      stepLabel(),
                                      const SizedBox(height: 6),
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: headerActions(),
                                      ),
                                    ],
                                  );
                                }
                                return Row(
                                  children: <Widget>[
                                    Expanded(child: stepLabel()),
                                    const SizedBox(width: 8),
                                    headerActions(),
                                  ],
                                );
                              },
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: const SizedBox(
                            height: 4,
                            child: Stack(
                              fit: StackFit.expand,
                              children: <Widget>[
                                DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: AppColors.divider,
                                  ),
                                ),
                                FractionallySizedBox(
                                  alignment: Alignment.centerLeft,
                                  widthFactor: 1 / 3,
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      color: AppColors.brandBlue,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Add documents',
                          style: AppTypography.heading1.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _parsedUsers.length > 1
                              ? 'Move between users with the arrows, then attach each person’s ID. Multi-select is fine — everything goes in one request (1 image = 1 user). Photos come after review.'
                              : 'Attach this user’s ID. Multi-select is fine — everything goes in one request. Photos come after review.',
                          style: AppTypography.body2.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Expanded(
                          child: SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.offWhite,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: AppColors.divider,
                                    ),
                                  ),
                                  child: Row(
                                    children: <Widget>[
                                      Container(
                                        width: 40,
                                        height: 40,
                                decoration: BoxDecoration(
                                  color: AppColors.blueTint,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '${selectedIndex + 1}',
                                  style: AppTypography.heading2.copyWith(
                                    color: AppColors.brandBlue,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      _displayUserLabel(
                                        _parsedUsers[selectedIndex],
                                        selectedIndex,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTypography.body2.copyWith(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    Text(
                                      _parsedUsers.length > 1
                                          ? 'User ${selectedIndex + 1} of ${_parsedUsers.length}'
                                          : 'Single user batch',
                                      style: AppTypography.caption.copyWith(
                                        color: AppColors.textTertiary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (_parsedUsers.length > 1) ...<Widget>[
                                TMZBadge.manual(
                                  label:
                                      '${selectedIndex + 1}/${_parsedUsers.length}',
                                ),
                                const SizedBox(width: 6),
                                IconButton(
                                  onPressed: sheetBusy()
                                      ? null
                                      : removeCurrentUser,
                                  icon: const Icon(
                                    Icons.delete_outline_rounded,
                                    size: 18,
                                  ),
                                  color: AppColors.textSecondary,
                                  tooltip: 'Remove user',
                                  visualDensity: VisualDensity.compact,
                                  style: IconButton.styleFrom(
                                    backgroundColor: AppColors.cardSurface,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                      TMZButton(
                        label: isAddingDocs
                            ? 'Reading…'
                            : 'Add documents',
                        icon: Icons.attach_file_rounded,
                        variant: TMZButtonVariant.secondary,
                        isLoading: isAddingDocs,
                        onPressed: sheetBusy() ? null : addDocuments,
                        showShadow: false,
                      ),
                        if (isProcessing) ...<Widget>[
                          const SizedBox(height: 10),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.blueTint,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.divider),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                const Icon(
                                  Icons.sync_rounded,
                                  size: 14,
                                  color: AppColors.brandBlue,
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    busyStatus.isNotEmpty
                                        ? busyStatus
                                        : 'Working…',
                                    textAlign: TextAlign.center,
                                    style: AppTypography.caption.copyWith(
                                      color: AppColors.brandBlue,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        Row(
                          children: <Widget>[
                            Text(
                              'PREVIEW',
                              style: AppTypography.label.copyWith(
                                color: AppColors.textTertiary,
                                fontSize: 11,
                              ),
                            ),
                            const Spacer(),
                            if (currentDocs.isNotEmpty)
                              TMZBadge.pending(
                                label:
                                    '${currentDocs.length} file${currentDocs.length == 1 ? '' : 's'}',
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        RepaintBoundary(
                          child: SizedBox(
                            height: 188,
                            child: currentDocs.isEmpty
                                ? DecoratedBox(
                                    decoration: BoxDecoration(
                                      color: AppColors.offWhite,
                                      borderRadius: BorderRadius.circular(18),
                                      border: Border.all(
                                        color: AppColors.divider,
                                      ),
                                    ),
                                    child: Center(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: <Widget>[
                                          const Icon(
                                            Icons.drive_folder_upload_outlined,
                                            size: 28,
                                            color: AppColors.textTertiary,
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Add a document to see the preview here.',
                                            textAlign: TextAlign.center,
                                            style: AppTypography.body2.copyWith(
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                : GridView.builder(
                                    gridDelegate:
                                        const SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: 3,
                                          crossAxisSpacing: 10,
                                          mainAxisSpacing: 10,
                                          childAspectRatio: 1,
                                        ),
                                    itemCount: currentDocs.length,
                                    itemBuilder:
                                        (BuildContext context, int index) {
                                          final _HumanDocumentDraft draft =
                                              currentDocs[index];
                                          return _DocumentPreviewTile(
                                            fileName: draft.file.name,
                                            fileBytes: draft.file.bytes,
                                            onRemove: sheetBusy()
                                                ? () {}
                                                : () => removeDocument(index),
                                  );
                                },
                              ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                          child: Row(
                            children: <Widget>[
                              Expanded(
                                child: TMZButton(
                                  label: 'Add user',
                                  icon: Icons.person_add_alt_1_rounded,
                                  variant: TMZButtonVariant.secondary,
                                  onPressed: sheetBusy() ? null : addUser,
                                  showShadow: false,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TMZButton(
                                  label: isProcessing ? 'Working…' : 'Continue',
                                  icon: Icons.arrow_forward_rounded,
                                  isLoading: isProcessing,
                                  onPressed: sheetBusy()
                                      ? null
                                      : reviewAndContinue,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            );
          },
        );
      },
    );
  }

  Future<void> _confirmAndCreateBatch() async {
    if (_batchNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a batch name.')),
      );
      return;
    }
    if (_pickedFile != null) {
      await _submitExcelBatch();
      return;
    }
    if (_documentUploadFiles().isNotEmpty) {
      await _submitDocumentBatch();
      return;
    }
    if (_parsedUsers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one user first.')),
      );
      return;
    }

    final List<Map<String, dynamic>>? reviewedUsers =
        await showDialog<List<Map<String, dynamic>>>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return _HumanReviewDialog(
              users: _parsedUsers,
              documentsByUser: _attachedDocumentsByUser,
            );
          },
        );
    if (reviewedUsers == null || reviewedUsers.isEmpty) return;
    await _submitReviewedBatch(reviewedUsers);
  }

  String _verificationTypesCsv() {
    final List<String> sortedChecks = _checks.toList()..sort();
    return sortedChecks.join(',');
  }

  List<BulkUploadDocumentInput> _documentUploadFiles() {
    // trumarkz_ocr.md §3.1: backend accepts multiple files under the same
    // `files` field in ONE request, processed in upload order. Send every
    // attached image (sorted by user, then attach order) — not just the
    // first per user — so multi-document bulk truly works.
    final List<BulkUploadDocumentInput> files = <BulkUploadDocumentInput>[];
    final List<int> userIndices = _attachedDocumentsByUser.keys.toList()
      ..sort();
    for (final int userIndex in userIndices) {
      final List<_HumanDocumentDraft> docs =
          _attachedDocumentsByUser[userIndex] ?? <_HumanDocumentDraft>[];
      for (final _HumanDocumentDraft draft in docs) {
        final String ext = draft.file.extension.toLowerCase();
        final bool isImage =
            ext.contains('jpg') ||
            ext.contains('jpeg') ||
            ext.contains('png') ||
            ext.contains('webp');
        if (!isImage) continue;
        files.add(
          BulkUploadDocumentInput(
            fileBytes: draft.file.bytes,
            fileName: draft.file.name,
          ),
        );
      }
    }
    return files;
  }

  Future<void> _submitExcelBatch() async {
    final PickedFile? pickedFile = _pickedFile;
    if (pickedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload an Excel file first.')),
      );
      return;
    }
    if (_isUploading) return;

    setState(() => _isUploading = true);
    try {
      final VerificationRepository repo = ref.read(
        verificationRepositoryProvider,
      );
      final BulkUploadResponse res = await repo.bulkUpload(
        batchName: _batchNameController.text.trim(),
        industryType: _industry.trim().isNotEmpty ? _industry.trim() : null,
        verificationTypes: _verificationTypesCsv().isNotEmpty
            ? _verificationTypesCsv()
            : null,
        credentialVisibility: _credentialVisibility.trim().isNotEmpty
            ? _credentialVisibility.trim()
            : null,
        fileBytes: pickedFile.bytes,
        fileName: pickedFile.name,
      );

      await ref
          .read(batchNameStoreProvider.notifier)
          .setBatchName(res.batchId, _batchNameController.text.trim());

      if (!mounted) return;
      final String resolvedIndustry = _industry.trim();
      final String verificationChecks = _verificationTypesCsv();
      final Uri paymentUri = Uri(
        path: AppRouter.perUnitCostBreakdownPath,
        queryParameters: <String, String>{
          if (verificationChecks.isNotEmpty) 'checks': verificationChecks,
          if (resolvedIndustry.isNotEmpty) 'industry': resolvedIndustry,
          'industry_label': _prettyIndustry(resolvedIndustry),
          'identity_type': 'Human',
          'flow': 'human',
          'access': _credentialVisibility.trim().isNotEmpty
              ? _credentialVisibility.trim()
              : 'public_searchable',
          'users_count': res.totalUploaded.toString(),
          'batch': _batchNameController.text.trim(),
        },
      );
      Future<void> confirmAction() async {
        if (!mounted) return;
        final Uri successUri = Uri(
          path: AppRouter.batchCreatedSuccessPath,
          queryParameters: <String, String>{
            'batch_id': res.batchId,
            'total_uploaded': res.totalUploaded.toString(),
            'total_skipped': res.totalSkipped.toString(),
            'errors': res.errors.length.toString(),
            'batch': _batchNameController.text.trim(),
          },
        );
        context.push(successUri.toString());
      }

      // ignore: use_build_context_synchronously
      await context.push(paymentUri.toString(), extra: confirmAction);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } on DioException catch (e) {
      if (!mounted) return;
      debugPrint(
        '[BulkUploadPage] Excel upload DioException: type=${e.type} uri=${e.requestOptions.uri} '
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
              serverMessage ??
                  'Could not upload the Excel file. Please try again.',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      debugPrint('[BulkUploadPage] Excel upload failed: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Something went wrong. Please try again.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  /// Shared OCR worker — uploads `files[]` once and merges OCR into local
  /// drafts. No dialogs, no navigation, so both the smooth attach-sheet flow
  /// and the page-level Upload button can use the exact same sequence.
  Future<({BulkUploadResponse res, Map<int, String> userIdsByIndex})>
  _uploadOcrDocumentsAndMerge() async {
    final VerificationRepository repo = ref.read(
      verificationRepositoryProvider,
    );
    final String verificationTypesCsv = _verificationTypesCsv();
    final List<_HumanDocumentDraft> selectedDocs = _documentDraftsForUser(
      _selectedUserIndex,
    );
    final String docType = selectedDocs.isNotEmpty
        ? selectedDocs.first.label.trim()
        : 'document';
    final BulkUploadResponse res = await repo.bulkUploadDocuments(
      batchName: _batchNameController.text.trim(),
      industryType: _industry.trim().isNotEmpty ? _industry.trim() : null,
      verificationTypes: verificationTypesCsv.isNotEmpty
          ? verificationTypesCsv
          : null,
      credentialVisibility: _credentialVisibility.trim().isNotEmpty
          ? _credentialVisibility.trim()
          : null,
      docType: docType.isNotEmpty ? docType : 'document',
      fields: _humanDocumentFieldsCsv,
      files: _documentUploadFiles(),
    );

    final Map<int, String> userIdsByIndex = <int, String>{};
    for (int i = 0; i < res.successfulUsers.length; i++) {
      final BulkUploadSuccessUser serverUser = res.successfulUsers[i];
      final int localIndex = _findMatchingDraftIndex(serverUser, i);
      if (localIndex < 0) continue;
      userIdsByIndex[localIndex] = serverUser.userId;
      if (serverUser.extracted.isNotEmpty) {
        _mergeOcrIntoUser(
          localIndex,
          _applyOcrFieldAliases(_normalizeOcrMap(serverUser.extracted)),
        );
      }
    }
    return (res: res, userIdsByIndex: userIdsByIndex);
  }

  /// Shared OCR worker — persists reviewed fields per BatchUser.
  Future<void> _persistReviewedOcrUsers(
    List<Map<String, dynamic>> reviewedUsers,
    Map<int, String> userIdsByIndex,
  ) async {
    final VerificationRepository repo = ref.read(
      verificationRepositoryProvider,
    );
    for (final MapEntry<int, String> entry in userIdsByIndex.entries) {
      final int userIndex = entry.key;
      final String userId = entry.value;
      await repo.updateBatchUser(
        userId: userId,
        fullName: reviewedUsers[userIndex]['full_name']?.toString(),
        email: reviewedUsers[userIndex]['email']?.toString(),
        phoneNumber: reviewedUsers[userIndex]['phone_number']?.toString(),
        dob: reviewedUsers[userIndex]['dob']?.toString(),
        aadharNumber: reviewedUsers[userIndex]['aadhar_number']?.toString(),
        panNumber: reviewedUsers[userIndex]['pan_number']?.toString(),
        addressLine1: reviewedUsers[userIndex]['address_line1']?.toString(),
        addressLine2: reviewedUsers[userIndex]['address_line2']?.toString(),
        addressLine3: reviewedUsers[userIndex]['address_line3']?.toString(),
        pincode: reviewedUsers[userIndex]['pincode']?.toString(),
        state: reviewedUsers[userIndex]['state']?.toString(),
        country: reviewedUsers[userIndex]['country']?.toString(),
        customFields: reviewedUsers[userIndex],
        markReviewed: true,
      );
    }
  }

  /// Shared OCR worker — stores the batch name and navigates to costing,
  /// handing it the success navigation as the confirm action.
  Future<void> _storeBatchAndGoToCosting(BulkUploadResponse res) async {
    await ref
        .read(batchNameStoreProvider.notifier)
        .setBatchName(res.batchId, _batchNameController.text.trim());

    if (!mounted) return;
    final String resolvedIndustry = _industry.trim();
    final String verificationChecks = _verificationTypesCsv();
    final Uri paymentUri = Uri(
      path: AppRouter.perUnitCostBreakdownPath,
      queryParameters: <String, String>{
        if (verificationChecks.isNotEmpty) 'checks': verificationChecks,
        if (resolvedIndustry.isNotEmpty) 'industry': resolvedIndustry,
        'industry_label': _prettyIndustry(resolvedIndustry),
        'identity_type': 'Human',
        'flow': 'human',
        'access': _credentialVisibility.trim().isNotEmpty
            ? _credentialVisibility.trim()
            : 'public_searchable',
        'users_count': res.totalUploaded.toString(),
        'batch': _batchNameController.text.trim(),
      },
    );
    Future<void> confirmAction() async {
      if (!mounted) return;
      final Uri successUri = Uri(
        path: AppRouter.batchCreatedSuccessPath,
        queryParameters: <String, String>{
          'batch_id': res.batchId,
          'total_uploaded': res.totalUploaded.toString(),
          'total_skipped': res.totalSkipped.toString(),
          'errors': res.errors.length.toString(),
          'batch': _batchNameController.text.trim(),
        },
      );
      context.push(successUri.toString());
    }

    // ignore: use_build_context_synchronously
    await context.push(paymentUri.toString(), extra: confirmAction);
  }

  /// Single mapping for OCR upload/save failures (ApiException passthrough,
  /// Dio status hints, generic fallback).
  String _ocrFriendlyError(Object e) {
    if (e is ApiException) return e.message;
    if (e is DioException) {
      final Object? inner = e.error;
      if (inner is ApiException) return inner.message;
      final dynamic data = e.response?.data;
      if (data is String && data.trim().isNotEmpty) return data.trim();
      if (data is Map && data['message'] is String) {
        final String m = (data['message'] as String).trim();
        if (m.isNotEmpty) return m;
      }
      if (e.response?.statusCode == 404) {
        return 'User not found. Please re-upload the documents.';
      }
      if (e.response?.statusCode == 403) {
        return 'You don\u2019t have access to this batch.';
      }
      if (e.message?.trim().isNotEmpty == true) return e.message!.trim();
      return 'Could not upload the document images. Please try again.';
    }
    return 'Something went wrong. Please try again.';
  }

  String _ocrPhotoDisplayName(
    BulkUploadSuccessUser u,
    Map<String, int> localIndexByUserId,
    List<Map<String, dynamic>> reviewedUsers,
  ) {
    final int? local = localIndexByUserId[u.userId];
    if (local != null && local >= 0 && local < reviewedUsers.length) {
      final String name = (reviewedUsers[local]['full_name'] ?? '')
          .toString()
          .trim();
      if (name.isNotEmpty) return name;
    }
    if (u.fullName.trim().isNotEmpty) return u.fullName.trim();
    if (u.email.trim().isNotEmpty) return u.email.trim();
    return 'User';
  }

  Future<void> _submitDocumentBatch() async {
    // Page-level entry (Upload button with docs already attached). Same
    // worker sequence as the smooth attach-sheet flow below.
    if (_isUploading) return;

    if (_documentUploadFiles().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please attach at least one document image.'),
        ),
      );
      return;
    }

    setState(() => _isUploading = true);
    try {
      final ({BulkUploadResponse res, Map<int, String> userIdsByIndex})
      uploaded = await _uploadOcrDocumentsAndMerge();
      final BulkUploadResponse res = uploaded.res;
      final Map<int, String> userIdsByIndex = uploaded.userIdsByIndex;

      if (!mounted) return;
      final List<Map<String, dynamic>>? reviewedUsers =
          await showDialog<List<Map<String, dynamic>>>(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return _HumanReviewDialog(
                users: _parsedUsers,
                documentsByUser: _attachedDocumentsByUser,
                skipped: res.skippedUsers,
                errors: res.errors,
                stepEyebrow: 'STEP 2 OF 3 • REVIEW',
              );
            },
          );
      if (reviewedUsers == null || reviewedUsers.isEmpty) return;

      await _persistReviewedOcrUsers(reviewedUsers, userIdsByIndex);

      // Stage 2 — photos (trumarkz_ocr.md §3.2/§3.3, §5, §8). Independent
      // request: documents/BatchUsers stay untouched if photos fail or are
      // skipped. Positional pairing: successful_users[] order is preserved,
      // skipped docs have no id and are excluded automatically.
      if (!mounted) return;
      if (res.successfulUsers.isNotEmpty) {
        final Map<String, int> localIndexByUserId = <String, int>{
          for (final MapEntry<int, String> e in userIdsByIndex.entries)
            e.value: e.key,
        };
        await showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return _OcrPhotoStageDialog(
              users: res.successfulUsers,
              skippedCount: res.totalSkipped,
              skipped: res.skippedUsers,
              docErrors: res.errors,
              displayNameFor: (BulkUploadSuccessUser u) =>
                  _ocrPhotoDisplayName(u, localIndexByUserId, reviewedUsers),
            );
          },
        );
      }

      await _storeBatchAndGoToCosting(res);
    } catch (e) {
      if (!mounted) return;
      if (e is DioException) {
        debugPrint(
          '[BulkUploadPage] Document upload DioException: type=${e.type} uri=${e.requestOptions.uri} '
          'status=${e.response?.statusCode} data=${e.response?.data} message=${e.message}',
        );
      } else {
        debugPrint('[BulkUploadPage] Document upload failed: $e');
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_ocrFriendlyError(e))));
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _submitReviewedBatch(
    List<Map<String, dynamic>> reviewedUsers,
  ) async {
    if (_isUploading) return;
    setState(() => _isUploading = true);
    try {
      final VerificationRepository repo = ref.read(
        verificationRepositoryProvider,
      );
      final BulkUploadResponse res = await repo.createHumanBatch(
        batchName: _batchNameController.text.trim(),
        users: reviewedUsers.map(_userPayloadFromDraft).toList(),
      );
      final Map<int, String> userIdsByIndex = <int, String>{};
      for (int i = 0; i < res.successfulUsers.length; i++) {
        final BulkUploadSuccessUser serverUser = res.successfulUsers[i];
        final int localIndex = _findMatchingDraftIndex(serverUser, i);
        if (localIndex < 0) continue;
        userIdsByIndex[localIndex] = serverUser.userId;
      }

      for (final MapEntry<int, String> entry in userIdsByIndex.entries) {
        final int userIndex = entry.key;
        final String userId = entry.value;
        final List<_HumanDocumentDraft> docs =
            _attachedDocumentsByUser[userIndex] ?? <_HumanDocumentDraft>[];
        for (final _HumanDocumentDraft draft in docs) {
          await repo.uploadHumanDocument(
            userId: userId,
            documentLabel: draft.label,
            fileBytes: draft.file.bytes,
            fileName: draft.file.name,
          );
        }

        await repo.updateBatchUser(
          userId: userId,
          fullName: reviewedUsers[userIndex]['full_name']?.toString(),
          email: reviewedUsers[userIndex]['email']?.toString(),
          phoneNumber: reviewedUsers[userIndex]['phone_number']?.toString(),
          dob: reviewedUsers[userIndex]['dob']?.toString(),
          aadharNumber: reviewedUsers[userIndex]['aadhar_number']?.toString(),
          panNumber: reviewedUsers[userIndex]['pan_number']?.toString(),
          addressLine1: reviewedUsers[userIndex]['address_line1']?.toString(),
          addressLine2: reviewedUsers[userIndex]['address_line2']?.toString(),
          addressLine3: reviewedUsers[userIndex]['address_line3']?.toString(),
          pincode: reviewedUsers[userIndex]['pincode']?.toString(),
          state: reviewedUsers[userIndex]['state']?.toString(),
          country: reviewedUsers[userIndex]['country']?.toString(),
          customFields: reviewedUsers[userIndex],
          markReviewed: true,
        );
      }

      await ref
          .read(batchNameStoreProvider.notifier)
          .setBatchName(res.batchId, _batchNameController.text.trim());

      if (!mounted) return;
      final Uri uri = Uri(
        path: AppRouter.batchCreatedSuccessPath,
        queryParameters: <String, String>{
          'batch_id': res.batchId,
          'total_uploaded': reviewedUsers.length.toString(),
          'total_skipped': '0',
          'errors': '0',
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

  PickedFile? _normalizeDobInCsv(PickedFile file) {
    final String raw = utf8.decode(file.bytes, allowMalformed: true);
    final List<List<dynamic>> table = const CsvToListConverter(
      shouldParseNumbers: false,
    ).convert(raw);
    if (table.isEmpty) return null;

    int headerIndex = 0;
    while (headerIndex < table.length &&
        _Identifiers._isRowEmpty(table[headerIndex])) {
      headerIndex += 1;
    }
    if (headerIndex >= table.length) return null;

    final List<String> header = table[headerIndex]
        .map((dynamic e) => (e?.toString() ?? '').trim())
        .toList();
    final int dobIndex = _userIndexMap(header)['dob'] ?? -1;
    if (dobIndex < 0) return null;

    bool changed = false;
    for (int i = headerIndex + 1; i < table.length; i++) {
      final List<dynamic> row = table[i];
      if (_Identifiers._isRowEmpty(row)) continue;
      if (dobIndex >= row.length) continue;
      final String rawDob = row[dobIndex]?.toString().trim() ?? '';
      final String? normalized = _normalizeDob(rawDob);
      if (normalized == null || normalized == rawDob) continue;
      row[dobIndex] = normalized;
      changed = true;
    }

    if (!changed) return null;
    final String csv = const ListToCsvConverter().convert(table);
    return PickedFile(
      name: file.name,
      bytes: Uint8List.fromList(utf8.encode(csv)),
      extension: file.extension,
    );
  }

  PickedFile? _normalizeDobInXlsx(PickedFile file) {
    Excel excel;
    try {
      excel = Excel.decodeBytes(file.bytes);
    } catch (_) {
      return null;
    }

    final List<String> sheetNames = excel.tables.keys.toList();
    if (sheetNames.isEmpty) return null;
    final Sheet? sheet = excel.tables[sheetNames.first];
    if (sheet == null) return null;

    final List<List<Data?>> all = sheet.rows;
    if (all.isEmpty) return null;

    int headerIndex = 0;
    while (headerIndex < all.length &&
        _Identifiers._isExcelRowEmpty(all[headerIndex])) {
      headerIndex += 1;
    }
    if (headerIndex >= all.length) return null;

    final List<String> header = all[headerIndex]
        .map((Data? d) => (d?.value?.toString() ?? '').trim())
        .toList();
    final int dobIndex = _userIndexMap(header)['dob'] ?? -1;
    if (dobIndex < 0) return null;

    bool changed = false;
    for (int i = headerIndex + 1; i < all.length; i++) {
      final List<Data?> row = all[i];
      if (_Identifiers._isExcelRowEmpty(row)) continue;
      if (dobIndex >= row.length) continue;

      final Data? cell = row[dobIndex];
      final String rawDob = (cell?.value?.toString() ?? '').trim();
      final String? normalized = _normalizeDob(rawDob);
      if (normalized == null || normalized == rawDob) continue;
      excel.updateCell(
        sheetNames.first,
        CellIndex.indexByColumnRow(columnIndex: dobIndex, rowIndex: i),
        TextCellValue(normalized),
      );
      changed = true;
    }

    if (!changed) return null;
    final List<int>? encoded = excel.encode();
    if (encoded == null) return null;
    return PickedFile(
      name: file.name,
      bytes: Uint8List.fromList(encoded),
      extension: file.extension,
    );
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
    final AsyncValue<AuthState> authAsync = ref.watch(authNotifierProvider);
    final String? orgId = authAsync.valueOrNull?.userProfile?.id;
    final AsyncValue<String?> industryAsync = orgId == null
        ? const AsyncData<String?>(null)
        : ref.watch(organizationIndustryTypeProvider(orgId));
    final String apiIndustry = industryAsync.valueOrNull?.trim() ?? '';
    final String profileIndustry =
        authAsync.valueOrNull?.userProfile?.industry?.trim() ?? '';
    final String rawIndustry = _industry.trim().isNotEmpty
        ? _industry.trim()
        : apiIndustry.isNotEmpty
        ? apiIndustry
        : profileIndustry;
    final String resolvedIndustry = _sanitizeIndustryFilter(rawIndustry);
    final String verificationFilter = resolvedIndustry.isNotEmpty
        ? 'human::$resolvedIndustry'
        : 'human';
    final AsyncValue<List<VerificationTypeDefinition>> humanTypesAsync = ref
        .watch(verificationTypesProvider(verificationFilter));
    final Map<String, VerificationTypeDefinition> humanTypesById =
        <String, VerificationTypeDefinition>{
          for (final VerificationTypeDefinition item
              in humanTypesAsync.valueOrNull ?? <VerificationTypeDefinition>[])
            item.id: item,
        };
    final bool useDrivingLicenseTemplate = _shouldUseDrivingLicenseTemplate(
      _checks,
      _checkIds,
      humanTypesById,
    );
    if (useDrivingLicenseTemplate &&
        !_seededRouteTemplate &&
        _columnsController.text.trim() !=
            _drivingLicenseTemplateHeaders.join(',')) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (_seededRouteTemplate) return;
        setState(() {
          _savedTemplateHeaders = <String>[];
          _columnsController.text = _drivingLicenseTemplateHeaders.join(',');
          _seededRouteTemplate = true;
        });
        debugPrint(
          '[BulkUploadPage] driving-license template seeded from resolved check names',
        );
      });
    }
    if (_checks.isEmpty &&
        !_seededDefaultChecks &&
        (humanTypesAsync.valueOrNull?.isNotEmpty == true ||
            !humanTypesAsync.isLoading)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (_checks.isNotEmpty) return;
        setState(() {
          _checks
            ..clear()
            ..addAll(
              (humanTypesAsync.valueOrNull?.isNotEmpty == true)
                  ? humanTypesAsync.valueOrNull!
                        .take(3)
                        .map((VerificationTypeDefinition t) => t.id)
                  : <String>{'police', 'dob', 'education'},
            );
          _seededDefaultChecks = true;
        });
      });
    }
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
                      child: const OrgTopBar(title: 'Bulk Upload'),
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
                                  s(28),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Row(
                                      children: <Widget>[
                                        Text(
                                          'STEP 3 OF 6',
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
                                          '50%',
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
                                      // No page rebuild on keystroke: the
                                      // Upload button below listens to the
                                      // controller directly, so typing never
                                      // relayouts the whole page (keyboard
                                      // animation stays smooth).
                                      onChanged: () {},
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
                                            'Upload Excel',
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
                                          child: Text(
                                            'Download Excel',
                                            style: const TextStyle(
                                              color: AppColors.brandBlue,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: s(14)),
                                    Text(
                                      'Download template based on your selected checks.\nUpload your Excel, then Confirm the batch.',
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
                                    // Isolate custom-paint + SVG raster work
                                    // from keyboard-resize repaints.
                                    RepaintBoundary(
                                      child: _DropZone(
                                        scale: scale,
                                        onTap: _pickExcelFile,
                                      ),
                                    ),
                                    SizedBox(height: s(18)),
                                    Row(
                                      children: <Widget>[
                                        Expanded(
                                          child: Divider(
                                            color: const Color(0xFFE5E7EB),
                                            thickness: s(1),
                                          ),
                                        ),
                                        Padding(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: s(12),
                                          ),
                                          child: Text(
                                            'OR',
                                            style: TextStyle(
                                              fontFamily: 'Inter',
                                              fontSize: s(11),
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: s(1.4),
                                              color: const Color(0xFF94A3B8),
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: Divider(
                                            color: const Color(0xFFE5E7EB),
                                            thickness: s(1),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: s(14)),
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: <Widget>[
                                              Text(
                                                'Add documents for users',
                                                style: TextStyle(
                                                  fontFamily: 'Inter',
                                                  fontSize: s(18),
                                                  fontWeight: FontWeight.w700,
                                                  height: 22 / 18,
                                                  color: _panelText,
                                                ),
                                              ),
                                              SizedBox(height: s(6)),
                                              Text(
                                                'Step 1 of 2 — attach ID documents (multi-select). You’ll review OCR, then add each person’s photo in step 2.',
                                                style: TextStyle(
                                                  fontFamily: 'Inter',
                                                  fontSize: s(12),
                                                  fontWeight: FontWeight.w500,
                                                  height: 17 / 12,
                                                  color: const Color(
                                                    0xFF94A3B8,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: s(14)),
                                    RepaintBoundary(
                                      child: _DropZone(
                                        scale: scale,
                                        onTap: _openOcrDocumentsFlow,
                                        title: 'Add documents for users',
                                        subtitle:
                                            'Guided pages: documents → review → photos. 1 image = 1 user.',
                                        iconAsset:
                                            'assets/icons/figma/bulk_upload_icon_file_attach.svg',
                                      ),
                                    ),
                                    if (_parsedUsers.isNotEmpty &&
                                        _attachedDocumentsByUser
                                            .isNotEmpty) ...<Widget>[
                                      SizedBox(height: s(14)),
                                      Column(
                                        children: List<Widget>.generate(
                                          _parsedUsers.length,
                                          (int userIndex) {
                                            final List<_HumanDocumentDraft>
                                            docs = _documentDraftsForUser(
                                              userIndex,
                                            );
                                            if (docs.isEmpty) {
                                              return const SizedBox.shrink();
                                            }
                                            return Padding(
                                              padding: EdgeInsets.only(
                                                bottom: s(10),
                                              ),
                                              child: _UserDocumentGroupCard(
                                                scale: scale,
                                                title: _displayUserLabel(
                                                  _parsedUsers[userIndex],
                                                  userIndex,
                                                ),
                                                documents: docs,
                                                onRemoveDocument: (int docIndex) {
                                                  setState(() {
                                                    final List<
                                                      _HumanDocumentDraft
                                                    >
                                                    userDocs =
                                                        _attachedDocumentsByUser[userIndex] ??
                                                        <_HumanDocumentDraft>[];
                                                    if (docIndex >= 0 &&
                                                        docIndex <
                                                            userDocs.length) {
                                                      userDocs.removeAt(
                                                        docIndex,
                                                      );
                                                      if (userDocs.isEmpty) {
                                                        _attachedDocumentsByUser
                                                            .remove(userIndex);
                                                      }
                                                    }
                                                  });
                                                },
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ],
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
                              child: ValueListenableBuilder<TextEditingValue>(
                                valueListenable: _batchNameController,
                                builder:
                                    (
                                      BuildContext context,
                                      TextEditingValue batchValue,
                                      _,
                                    ) => _UploadButton(
                                      scale: scale,
                                      isLoading: _isUploading,
                                      enabled:
                                          _parsedUsers.isNotEmpty &&
                                          batchValue.text.trim().isNotEmpty &&
                                          !_isUploading &&
                                          !_preflightChecking,
                                      onTap: () => _confirmAndCreateBatch(),
                                    ),
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

  static const List<String> _industryOptions = <String>[
    'All',
    'Transport',
    'Healthcare',
    'Education',
    'Manufacturing',
    'Security',
    'Agriculture',
    'Beauty & Cosmetics',
    'Consumer Goods',
    'Electronics & Appliances',
    'EV & Automotive',
    'Healthcare Products',
    'Industrial Equipment',
    'Insurance Policies',
    'Agriculture Products',
    'Luxury Products',
    'Others',
  ];

  static String _prettyIndustry(String raw) {
    final String v = raw.trim();
    if (v.isEmpty) return 'Real Estate';
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
    if (singleParts.isEmpty) return 'Real Estate';
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

  String _effectiveIndustry() {
    final AsyncValue<AuthState> authAsync = ref.read(authNotifierProvider);
    final String? orgId = authAsync.valueOrNull?.userProfile?.id;
    final AsyncValue<String?> industryAsync = orgId == null
        ? const AsyncData<String?>(null)
        : ref.read(organizationIndustryTypeProvider(orgId));
    final String currentIndustry = _sanitizeIndustryFilter(_industry);
    if (currentIndustry.isNotEmpty) return currentIndustry;

    final String apiIndustry = _sanitizeIndustryFilter(
      industryAsync.valueOrNull ?? '',
    );
    if (apiIndustry.isNotEmpty) return apiIndustry;

    final String profileIndustry = _sanitizeIndustryFilter(
      authAsync.valueOrNull?.userProfile?.industry ?? '',
    );
    return profileIndustry;
  }

  String _verificationFilter({required String category, String? industry}) {
    final String selectedIndustry = (industry ?? _effectiveIndustry()).trim();
    if (selectedIndustry.isEmpty) return category;
    return '$category::$selectedIndustry';
  }

  String _sanitizeIndustryFilter(String raw) {
    final String value = raw.trim();
    if (value.isEmpty) return '';
    if (value.contains('{') || value.contains('}')) return '';
    if (value.contains(':')) return '';

    final String normalized = value.toLowerCase();
    if (normalized == 'all' || normalized == 'both') return '';
    if (RegExp(r'^[0-9a-f-]{24,}$', caseSensitive: false).hasMatch(value)) {
      return '';
    }

    final bool looksKnown = _industryOptions.any(
      (String option) => option.toLowerCase() == normalized,
    );
    return looksKnown ? value : '';
  }
}

class _HumanTemplateDialog extends ConsumerStatefulWidget {
  const _HumanTemplateDialog({
    required this.initialHeaders,
    required this.selectedChecks,
    required this.selectedCheckIds,
    required this.verificationFilter,
    required this.onSave,
  });

  final List<String> initialHeaders;
  final Set<String> selectedChecks;
  final Set<String> selectedCheckIds;
  final String verificationFilter;
  final ValueChanged<List<String>> onSave;

  @override
  ConsumerState<_HumanTemplateDialog> createState() =>
      _HumanTemplateDialogState();
}

class _HumanTemplateDialogState extends ConsumerState<_HumanTemplateDialog> {
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
    setState(() {
      _isGenerating = true;
    });

    try {
      final VerificationRepository repo = ref.read(
        verificationRepositoryProvider,
      );
      final List<VerificationTypeDefinition> verificationTypes = await ref.read(
        verificationTypesProvider(widget.verificationFilter).future,
      );
      final Map<String, VerificationTypeDefinition> verificationTypesById =
          <String, VerificationTypeDefinition>{
            for (final VerificationTypeDefinition item in verificationTypes)
              item.id: item,
          };
      final List<String> sortedChecks = widget.selectedCheckIds.isNotEmpty
          ? (widget.selectedCheckIds.toList()..sort())
          : (widget.selectedChecks.toList()..sort());
      final List<String> headers = <String>[
        for (final String header in _headers)
          if (header.trim().isNotEmpty) header.trim(),
      ];
      final String headersCsv = headers.join(',');
      final String verificationTypesCsv = sortedChecks.join(',');
      final List<String> resolvedCheckPairs = <String>[
        for (final String id in sortedChecks)
          _formatCheckResolution(id.trim(), verificationTypesById),
      ];
      debugPrint(
        '[HumanTemplate] request headers=$headersCsv verification_types=$verificationTypesCsv',
      );
      debugPrint(
        '[HumanTemplate] check resolutions=${resolvedCheckPairs.join(', ')}',
      );
      final VerificationBinaryResponse res = await repo.generateHumanTemplate(
        headers: headersCsv,
        verificationTypes: verificationTypesCsv,
      );
      if (!mounted) return;

      final Uint8List templateBytes = res.bytes;
      debugPrint(
        '[HumanTemplate] generated file=${res.filename} bytes=${templateBytes.length}',
      );

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
        debugPrint('[HumanTemplate] downloads channel missing: $e');
      }

      if (!mounted) return;
      Navigator.of(context).pop();
      if (savedUri.isEmpty) {
        final String fallbackName = res.filename;
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
                    name: fallbackName,
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
    } on PlatformException catch (e) {
      debugPrint(
        '[HumanTemplate] save failed code=${e.code} message=${e.message} details=${e.details}',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.message?.trim().isNotEmpty == true
                ? e.message!.trim()
                : 'Could not save the template to Downloads.',
          ),
        ),
      );
    } catch (e) {
      debugPrint('[HumanTemplate] unexpected failure: $e');
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
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          titleTextStyle: AppTypography.heading2.copyWith(
            color: AppColors.textPrimary,
          ),
          contentTextStyle: AppTypography.body2.copyWith(
            color: AppColors.textSecondary,
          ),
          title: const Text('Template ready'),
          content: const Text('Your Excel template has been generated.'),
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(foregroundColor: AppColors.brandBlue),
              onPressed: () async {
                try {
                  await launchUrl(
                    Uri.parse(filePath),
                    mode: LaunchMode.externalApplication,
                  );
                } catch (e) {
                  debugPrint('[HumanTemplate] open failed: $e');
                }
                if (context.mounted) Navigator.of(context).pop();
              },
              child: const Text('Open file'),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: AppColors.brandBlue),
              onPressed: () async {
                try {
                  await Share.shareXFiles(<XFile>[
                    XFile.fromData(fileBytes, name: fileName),
                  ]);
                } catch (e) {
                  debugPrint('[HumanTemplate] share failed: $e');
                }
                if (context.mounted) Navigator.of(context).pop();
              },
              child: const Text('Share file'),
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  static String _verificationTypeDisplayName(VerificationTypeDefinition item) {
    final String name = item.name.trim();
    if (name.isNotEmpty) return name;

    final String label = item.label.trim();
    if (label.isNotEmpty) return label;

    final HumanVerificationCheckDefinition? humanItem =
        HumanVerificationChecksCatalog.byId[item.id.trim()];
    if (humanItem != null && humanItem.title.trim().isNotEmpty) {
      return humanItem.title.trim();
    }

    final ProductVerificationCheckDefinition? productItem =
        ProductVerificationChecksCatalog.byId[item.id.trim()];
    if (productItem != null && productItem.title.trim().isNotEmpty) {
      return productItem.title.trim();
    }

    final String fallback = item.id.trim();
    if (fallback.isEmpty) return '';

    return fallback
        .replaceAll(RegExp(r'[_\-]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static String _formatCheckResolution(
    String id,
    Map<String, VerificationTypeDefinition> verificationTypesById,
  ) {
    final VerificationTypeDefinition? item = verificationTypesById[id];
    if (item == null) return '$id=>MISS';
    return '$id=>${_verificationTypeDisplayName(item)}';
  }

  @override
  Widget build(BuildContext context) {
    final MediaQueryData mediaQuery = MediaQuery.of(context);
    final bool keyboardOpen = mediaQuery.viewInsets.bottom > 0;
    final double scale = mediaQuery.size.width / 402;
    double s(double v) => v * scale;
    const Color surfaceColor = Color(0xFFF8FAFC);
    final AsyncValue<List<VerificationTypeDefinition>> verificationTypesAsync =
        ref.watch(verificationTypesProvider(widget.verificationFilter));
    final Map<String, VerificationTypeDefinition> verificationTypesById =
        <String, VerificationTypeDefinition>{
          for (final VerificationTypeDefinition item
              in verificationTypesAsync.valueOrNull ??
                  <VerificationTypeDefinition>[])
            item.id: item,
        };

    return Dialog.fullscreen(
      backgroundColor: surfaceColor,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: surfaceColor,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
          systemNavigationBarColor: surfaceColor,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
        child: Material(
          color: surfaceColor,
          child: Scaffold(
            backgroundColor: surfaceColor,
            extendBodyBehindAppBar: false,
            appBar: AppBar(
              backgroundColor: surfaceColor,
              elevation: 0,
              scrolledUnderElevation: 0,
              shadowColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              systemOverlayStyle: const SystemUiOverlayStyle(
                statusBarColor: surfaceColor,
                statusBarIconBrightness: Brightness.dark,
                statusBarBrightness: Brightness.light,
                systemNavigationBarColor: surfaceColor,
                systemNavigationBarIconBrightness: Brightness.dark,
              ),
              leading: IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.of(context).pop(),
              ),
              title: Text(
                'Download Excel',
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
            body: ColoredBox(
              color: surfaceColor,
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.x4,
                  AppSpacing.x2,
                  AppSpacing.x4,
                  AppSpacing.x4 + AppSpacing.x8,
                ),
                children: <Widget>[
                  Text(
                    'Add headers one at a time. Added headers are saved automatically, then generate the Excel template. Selected verification types will be added automatically.',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: s(12),
                      fontWeight: FontWeight.w500,
                      height: 18 / 12,
                      color: const Color(0xFF64748B),
                    ),
                  ),
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
                    'Verification types',
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
                  if (verificationTypesAsync.isLoading &&
                      verificationTypesAsync.valueOrNull == null)
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
                            in widget.selectedChecks.toList()..sort())
                          Chip(
                            label: Text(
                              verificationTypesById[check] != null
                                  ? _verificationTypeDisplayName(
                                      verificationTypesById[check]!,
                                    )
                                  : check,
                            ),
                            backgroundColor: AppColors.brandBlue,
                            labelStyle: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: s(12),
                              fontWeight: FontWeight.w600,
                              height: 16.5 / 12,
                              color: Colors.white,
                            ),
                          ),
                      ],
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
                  const SizedBox(height: AppSpacing.x8),
                  if (_headersSaved)
                    Text(
                      'Headers saved. You can generate the template now.',
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
            ),
            bottomNavigationBar: ColoredBox(
              color: surfaceColor,
              child: SafeArea(
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
                          color: surfaceColor,
                          border: Border(
                            top: BorderSide(color: Color(0xFFE5E7EB)),
                          ),
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
                              _isGenerating ? 'Downloading' : 'Download',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: s(14),
                                fontWeight: FontWeight.w700,
                                height: 20 / 14,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.brandBlue,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: AppColors.brandBlue
                                  .withAlpha(90),
                              disabledForegroundColor: Colors.white.withAlpha(
                                180,
                              ),
                              elevation: 0,
                              padding: EdgeInsets.symmetric(vertical: s(18)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(s(20)),
                              ),
                            ),
                          ),
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DropZone extends StatelessWidget {
  const _DropZone({
    required this.scale,
    required this.onTap,
    this.title = 'Tap to select your file',
    this.subtitle = 'Upload your Excel file here',
    this.iconAsset = 'assets/icons/figma/bulk_upload_icon_upload.svg',
  });

  final double scale;
  final VoidCallback onTap;
  final String title;
  final String subtitle;
  final String iconAsset;

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
                    iconAsset,
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
                  title,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: s(20),
                    fontWeight: FontWeight.w700,
                    letterSpacing: s(0.2),
                    height: 24 / 20,
                    color: const Color(0xFF111827),
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: s(8)),
                Text(
                  subtitle,
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
      autocorrect: false,
      enableSuggestions: false,
      textCapitalization: TextCapitalization.words,
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

class _AttachedDocumentCard extends StatelessWidget {
  const _AttachedDocumentCard({
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
      width: double.infinity,
      padding: EdgeInsets.all(s(14)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(s(18)),
        border: Border.all(color: const Color(0xFFE5E7EB), width: s(1)),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: s(38),
            height: s(38),
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
                    fontSize: s(13),
                    fontWeight: FontWeight.w600,
                    height: 18 / 13,
                    color: const Color(0xFF111827),
                  ),
                ),
                SizedBox(height: s(2)),
                Text(
                  fileSizeLabel,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: s(11),
                    fontWeight: FontWeight.w500,
                    height: 16 / 11,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onRemove,
            icon: const Icon(Icons.close_rounded),
            color: const Color(0xFF94A3B8),
            tooltip: 'Remove document',
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

class _DocumentPreviewTile extends StatelessWidget {
  const _DocumentPreviewTile({
    required this.fileName,
    required this.fileBytes,
    required this.onRemove,
  });

  final String fileName;
  final Uint8List fileBytes;
  final VoidCallback onRemove;

  bool get _isImage {
    final String safe = fileName.toLowerCase();
    if (!safe.contains('.')) return false;
    final String ext = safe.split('.').last;
    return <String>{'jpg', 'jpeg', 'png', 'webp', 'gif'}.contains(ext);
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Stack(
          children: <Widget>[
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: _isImage
                    ? Image.memory(
                        fileBytes,
                        fit: BoxFit.cover,
                        // Thumbnail bounds: decode at display size instead of
                        // full camera resolution so scroll + keyboard resize
                        // frames stay cheap.
                        cacheWidth: 384,
                        cacheHeight: 384,
                        filterQuality: FilterQuality.low,
                      )
                    : Container(
                        color: const Color(0xFFF8FAFC),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Icon(
                                Icons.description_rounded,
                                size: 28,
                                color: AppColors.brandBlue,
                              ),
                              const SizedBox(height: 6),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                child: Text(
                                  fileName,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: AppTypography.caption.copyWith(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
              ),
            ),
            Positioned(
              top: 6,
              right: 6,
              child: InkWell(
                onTap: onRemove,
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEF4444),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.close_rounded,
                    size: 11,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            Positioned(
              left: 8,
              right: 8,
              bottom: 8,
              child: Text(
                fileName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.caption.copyWith(
                  color: _isImage ? Colors.white : AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                  shadows: _isImage
                      ? <Shadow>[
                          const Shadow(blurRadius: 12, color: Colors.black54),
                        ]
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

class _UserDocumentGroupCard extends StatelessWidget {
  const _UserDocumentGroupCard({
    required this.scale,
    required this.title,
    required this.documents,
    required this.onRemoveDocument,
  });

  final double scale;
  final String title;
  final List<_HumanDocumentDraft> documents;
  final void Function(int docIndex) onRemoveDocument;

  @override
  Widget build(BuildContext context) {
    double s(double v) => v * scale;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(s(14)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(s(18)),
        border: Border.all(color: const Color(0xFFE5E7EB), width: s(1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: s(13),
                    fontWeight: FontWeight.w700,
                    height: 18 / 13,
                    color: const Color(0xFF111827),
                  ),
                ),
              ),
              Text(
                '${documents.length} file${documents.length == 1 ? '' : 's'}',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: s(11),
                  fontWeight: FontWeight.w600,
                  height: 16 / 11,
                  color: const Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
          SizedBox(height: s(12)),
          Column(
            children: List<Widget>.generate(documents.length, (int index) {
              final _HumanDocumentDraft draft = documents[index];
              return Padding(
                padding: EdgeInsets.only(
                  bottom: index == documents.length - 1 ? 0 : s(10),
                ),
                child: _AttachedDocumentCard(
                  scale: scale,
                  fileName: '${draft.label} • ${draft.file.name}',
                  fileSizeLabel: _BulkUploadPageState._formatBytes(
                    draft.file.bytes.length,
                  ),
                  onRemove: () => onRemoveDocument(index),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _HumanDocumentDraft {
  _HumanDocumentDraft({required this.label, required this.file});

  final String label;
  final PickedFile file;
}

class _HumanReviewDialog extends StatefulWidget {
  const _HumanReviewDialog({
    required this.users,
    required this.documentsByUser,
    this.skipped = const <BulkUploadSkippedUser>[],
    this.errors = const <BulkUploadErrorRow>[],
    this.stepEyebrow,
  });

  final List<Map<String, dynamic>> users;
  final Map<int, List<_HumanDocumentDraft>> documentsByUser;
  final List<BulkUploadSkippedUser> skipped;
  final List<BulkUploadErrorRow> errors;
  final String? stepEyebrow;

  @override
  State<_HumanReviewDialog> createState() => _HumanReviewDialogState();
}

class _HumanReviewDialogState extends State<_HumanReviewDialog> {
  static const List<String> _fieldKeys = <String>[
    'full_name',
    'phone_number',
    'email',
    'dob',
    'license_number',
    'doi',
    'valid_till',
    'cov_lmv_doi',
    'cov_mcwg_doi',
    'blood_group',
    'sdw_of',
    'issuing_authority',
    'aadhar_number',
    'pan_number',
    'address_line1',
    'address_line2',
    'address_line3',
    'pincode',
    'state',
    'country',
  ];

  late final PageController _pageController;
  late final List<Map<String, dynamic>> _users;
  late final List<Map<String, TextEditingController>> _controllers;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _users = widget.users
        .map((Map<String, dynamic> user) => Map<String, dynamic>.from(user))
        .toList();
    _controllers = _users.map((Map<String, dynamic> user) {
      return <String, TextEditingController>{
        for (final String key in _fieldKeys)
          key: TextEditingController(text: user[key]?.toString() ?? ''),
      };
    }).toList();
  }

  @override
  void dispose() {
    _pageController.dispose();
    for (final Map<String, TextEditingController> entry in _controllers) {
      for (final TextEditingController controller in entry.values) {
        controller.dispose();
      }
    }
    super.dispose();
  }

  void _updateValue(int userIndex, String key, String value) {
    _users[userIndex][key] = value;
  }

  InputDecoration _decoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.brandBlue, width: 1.5),
      ),
    );
  }

  String _userLabel(Map<String, dynamic> user, int index) {
    final String fullName = (user['full_name'] ?? '').toString().trim();
    if (fullName.isNotEmpty) return fullName;
    return 'User ${index + 1}';
  }

  bool _isDrivingLicenseUser(
    Map<String, dynamic> user,
    List<_HumanDocumentDraft> docs,
  ) {
    bool hasValue(String key) => (user[key] ?? '').toString().trim().isNotEmpty;
    if (hasValue('license_number') ||
        hasValue('dl_number') ||
        hasValue('dl_no') ||
        hasValue('doi') ||
        hasValue('valid_till') ||
        hasValue('cov_lmv_doi') ||
        hasValue('cov_mcwg_doi') ||
        hasValue('issuing_authority')) {
      return true;
    }
    return docs.any(((_HumanDocumentDraft doc) {
      final String label = doc.label.toLowerCase();
      final String name = doc.file.name.toLowerCase();
      return label.contains('license') ||
          label.contains('licence') ||
          label.contains('dl') ||
          name.contains('license') ||
          name.contains('licence');
    }));
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      shadowColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 760),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (widget.stepEyebrow != null) ...<Widget>[
                Text(
                  widget.stepEyebrow!,
                  style: AppTypography.label.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
                const SizedBox(height: 8),
              ],
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      'Review OCR data',
                      style: AppTypography.heading1.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Text(
                    '${_index + 1}/${_users.length}',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Swipe between users, edit any OCR values you want to change, then confirm.',
                style: AppTypography.body2.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.35,
                ),
              ),
              if (widget.stepEyebrow != null) ...<Widget>[
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: const SizedBox(
                    height: 4,
                    child: Stack(
                      fit: StackFit.expand,
                      children: <Widget>[
                        DecoratedBox(
                          decoration: BoxDecoration(color: AppColors.divider),
                        ),
                        FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: 2 / 3,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: AppColors.brandBlue,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              if (widget.skipped.isNotEmpty) ...<Widget>[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.warningBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.warning.withAlpha(70)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          const Icon(
                            Icons.info_rounded,
                            size: 14,
                            color: AppColors.warning,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Skipped ${widget.skipped.length} — excluded from photos',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.warning,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      for (final BulkUploadSkippedUser s in widget.skipped.take(
                        5,
                      ))
                        Text(
                          'Doc ${s.row > 0 ? '#${s.row} ' : ''}• ${s.reason}',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.warning,
                          ),
                        ),
                      if (widget.skipped.length > 5)
                        Text(
                          '+${widget.skipped.length - 5} more',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.warning,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
              if (widget.errors.isNotEmpty) ...<Widget>[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.dangerBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.danger.withAlpha(60)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          const Icon(
                            Icons.error_outline_rounded,
                            size: 14,
                            color: AppColors.danger,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '${widget.errors.length} error(s)',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.danger,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      for (final BulkUploadErrorRow e in widget.errors.take(5))
                        Text(
                          'Doc ${e.row > 0 ? '#${e.row} ' : ''}• ${e.field.isNotEmpty ? '${e.field}: ' : ''}${e.error}',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.danger,
                          ),
                        ),
                      if (widget.errors.length > 5)
                        Text(
                          '+${widget.errors.length - 5} more',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.danger,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _users.length,
                  onPageChanged: (int value) => setState(() => _index = value),
                  itemBuilder: (BuildContext context, int pageIndex) {
                    final Map<String, dynamic> user = _users[pageIndex];
                    final Map<String, TextEditingController> controllers =
                        _controllers[pageIndex];
                    final List<_HumanDocumentDraft> docs =
                        widget.documentsByUser[pageIndex] ??
                        <_HumanDocumentDraft>[];
                    final bool isDrivingLicense = _isDrivingLicenseUser(
                      user,
                      docs,
                    );

                    Widget field(String key, String label, {String? hint}) {
                      return TextFormField(
                        controller: controllers[key],
                        decoration: _decoration(label).copyWith(hintText: hint),
                        onChanged: (String value) =>
                            _updateValue(pageIndex, key, value),
                      );
                    }

                    return SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            _userLabel(user, pageIndex),
                            style: AppTypography.heading2,
                          ),
                          const SizedBox(height: 12),
                          if (docs.isNotEmpty) ...<Widget>[
                            Text(
                              'Documents',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 8),
                            for (final _HumanDocumentDraft doc in docs)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _AttachedDocumentCard(
                                  scale: 1,
                                  fileName: '${doc.label} • ${doc.file.name}',
                                  fileSizeLabel:
                                      _BulkUploadPageState._formatBytes(
                                        doc.file.bytes.length,
                                      ),
                                  onRemove: () {},
                                ),
                              ),
                            const SizedBox(height: 12),
                          ],
                          field('full_name', 'Full name'),
                          const SizedBox(height: 12),
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: field('phone_number', 'Phone number'),
                              ),
                              const SizedBox(width: 12),
                              Expanded(child: field('email', 'Email')),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: field('dob', 'DOB', hint: 'YYYY-MM-DD'),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: field(
                                  'license_number',
                                  'License number',
                                ),
                              ),
                            ],
                          ),
                          if (isDrivingLicense) ...<Widget>[
                            const SizedBox(height: 12),
                            Row(
                              children: <Widget>[
                                Expanded(
                                  child: field(
                                    'doi',
                                    'Date of issue',
                                    hint: 'DD-MM-YYYY',
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: field('valid_till', 'Valid till'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: <Widget>[
                                Expanded(
                                  child: field('cov_lmv_doi', 'LMV DOI'),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: field('cov_mcwg_doi', 'MCWG DOI'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: <Widget>[
                                Expanded(
                                  child: field('blood_group', 'Blood group'),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: field('issuing_authority', 'RTO'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            field('sdw_of', 'S/D/W of'),
                          ],
                          const SizedBox(height: 12),
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: field('aadhar_number', 'Aadhaar'),
                              ),
                              const SizedBox(width: 12),
                              Expanded(child: field('pan_number', 'PAN')),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: <Widget>[
                              Expanded(child: field('pincode', 'Pincode')),
                              const SizedBox(width: 12),
                              Expanded(child: field('state', 'State')),
                            ],
                          ),
                          const SizedBox(height: 12),
                          field('address_line1', 'Address line 1'),
                          const SizedBox(height: 12),
                          field('address_line2', 'Address line 2'),
                          const SizedBox(height: 12),
                          field('address_line3', 'Address line 3'),
                          const SizedBox(height: 12),
                          field('country', 'Country'),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: <Widget>[
                  if (_users.length > 1)
                    SizedBox(
                      width: 44,
                      height: 44,
                      child: OutlinedButton(
                        onPressed: _index > 0
                            ? () => _pageController.previousPage(
                                duration: const Duration(milliseconds: 220),
                                curve: Curves.easeOut,
                              )
                            : null,
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          side: const BorderSide(color: AppColors.border),
                          foregroundColor: AppColors.textPrimary,
                        ),
                        child: const Icon(Icons.chevron_left_rounded),
                      ),
                    ),
                  if (_users.length > 1) const SizedBox(width: 12),
                  if (_users.length > 1)
                    SizedBox(
                      width: 44,
                      height: 44,
                      child: OutlinedButton(
                        onPressed: _index < _users.length - 1
                            ? () => _pageController.nextPage(
                                duration: const Duration(milliseconds: 220),
                                curve: Curves.easeOut,
                              )
                            : null,
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          side: const BorderSide(color: AppColors.border),
                          foregroundColor: AppColors.textPrimary,
                        ),
                        child: const Icon(Icons.chevron_right_rounded),
                      ),
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop(_users);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.brandBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Confirm'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Stage 2 — OCR photos (trumarkz_ocr.md §3.2/§3.3, §5, §8).
///
/// Users are shown in `successful_users[]` order and pairing is strictly
/// positional (`batch_user_ids[i] ↔ photos[i]`). Skipped documents have no
/// id and never reach this dialog. Photos are optional — Skip keeps the
/// already-created documents/BatchUsers untouched.
class _OcrPhotoStageDialog extends ConsumerStatefulWidget {
  const _OcrPhotoStageDialog({
    required this.users,
    required this.displayNameFor,
    this.skippedCount = 0,
    this.skipped = const <BulkUploadSkippedUser>[],
    this.docErrors = const <BulkUploadErrorRow>[],
  });

  final List<BulkUploadSuccessUser> users;
  final String Function(BulkUploadSuccessUser) displayNameFor;
  final int skippedCount;
  final List<BulkUploadSkippedUser> skipped;
  final List<BulkUploadErrorRow> docErrors;

  @override
  ConsumerState<_OcrPhotoStageDialog> createState() =>
      _OcrPhotoStageDialogState();
}

enum _OcrPhotoStatus { pending, ready, uploading, uploaded, failed }

class _OcrPhotoStageDialogState extends ConsumerState<_OcrPhotoStageDialog> {
  late final List<PickedFile?> _photos;
  late final List<_OcrPhotoStatus> _status;
  late final List<String> _errors;
  late final List<String> _photoUrls;
  late final List<int> _versions;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _photos = List<PickedFile?>.filled(widget.users.length, null);
    _status = List<_OcrPhotoStatus>.filled(
      widget.users.length,
      _OcrPhotoStatus.pending,
    );
    _errors = List<String>.filled(widget.users.length, '');
    _photoUrls = List<String>.filled(widget.users.length, '');
    _versions = List<int>.filled(widget.users.length, 0);
  }

  int get _readyCount =>
      _status.where((s) => s == _OcrPhotoStatus.ready).length;
  int get _uploadedCount =>
      _status.where((s) => s == _OcrPhotoStatus.uploaded).length;
  int get _failedCount =>
      _status.where((s) => s == _OcrPhotoStatus.failed).length;

  Future<void> _pickSingle(int index) async {
    final PickedFile? picked = await FilePickerUtil.pickImage();
    if (!mounted || picked == null) return;
    if (picked.bytes.isEmpty) return;
    setState(() {
      _photos[index] = picked;
      _status[index] = _OcrPhotoStatus.ready;
      _errors[index] = '';
    });
  }

  Future<void> _pickMultiple() async {
    final List<PickedFile> picked = await FilePickerUtil.pickImages();
    if (!mounted || picked.isEmpty) return;
    setState(() {
      int p = 0;
      for (int i = 0; i < _photos.length && p < picked.length; i++) {
        if (_photos[i] == null && _status[i] != _OcrPhotoStatus.uploaded) {
          _photos[i] = picked[p++];
          _status[i] = _OcrPhotoStatus.ready;
          _errors[i] = '';
        }
      }
      if (p < picked.length) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Only ${_photos.length} user slot(s) — ${picked.length - p} extra photo(s) ignored. Pairing is by order shown.',
            ),
          ),
        );
      }
    });
  }

  void _removeAt(int index) {
    if (_status[index] == _OcrPhotoStatus.uploading) return;
    setState(() {
      _photos[index] = null;
      if (_status[index] != _OcrPhotoStatus.uploaded) {
        _status[index] = _OcrPhotoStatus.pending;
      } else {
        // Keep uploaded state; removing the draft does not delete server copy.
        _photos[index] = null;
      }
      _errors[index] = '';
    });
  }

  Future<void> _uploadAll() async {
    if (_isUploading) return;
    final List<int> indices = <int>[];
    for (int i = 0; i < _photos.length; i++) {
      if (_photos[i] != null &&
          _status[i] != _OcrPhotoStatus.uploaded &&
          _status[i] != _OcrPhotoStatus.uploading) {
        indices.add(i);
      }
    }
    if (indices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Attach at least one photo first.')),
      );
      return;
    }
    setState(() {
      _isUploading = true;
      for (final int i in indices) {
        _status[i] = _OcrPhotoStatus.uploading;
        _errors[i] = '';
      }
    });
    try {
      final VerificationRepository repo = ref.read(
        verificationRepositoryProvider,
      );
      if (indices.length == 1) {
        final int i = indices.single;
        try {
          final OcrPhotoUploadResponse res = await repo.uploadOcrPhoto(
            batchUserId: widget.users[i].userId,
            fileBytes: _photos[i]!.bytes,
            fileName: _photos[i]!.name,
          );
          if (!mounted) return;
          setState(() {
            _status[i] = _OcrPhotoStatus.uploaded;
            _photoUrls[i] = res.photoUrl;
            _versions[i] = res.version;
          });
        } catch (e) {
          if (!mounted) return;
          setState(() {
            _status[i] = _OcrPhotoStatus.failed;
            _errors[i] = _friendlyError(e);
          });
        }
      } else {
        // Bulk — positional: ids[i] ↔ photos[i] among the ready subset,
        // preserving dialog order (trumarkz_ocr.md §5).
        final List<String> ids = <String>[
          for (final int i in indices) widget.users[i].userId,
        ];
        final List<BulkUploadDocumentInput> files = <BulkUploadDocumentInput>[
          for (final int i in indices)
            BulkUploadDocumentInput(
              fileBytes: _photos[i]!.bytes,
              fileName: _photos[i]!.name,
            ),
        ];
        try {
          final BulkOcrPhotoUploadResponse res = await repo.bulkUploadOcrPhotos(
            batchUserIds: ids,
            photos: files,
          );
          if (!mounted) return;
          final Map<String, OcrPhotoUploadResult> okById =
              <String, OcrPhotoUploadResult>{
                for (final OcrPhotoUploadResult r in res.successfulUsers)
                  r.batchUserId: r,
              };
          final Map<String, String> errById = <String, String>{
            for (final OcrPhotoUploadError e in res.failedUsers)
              e.batchUserId: e.error,
          };
          setState(() {
            for (final int i in indices) {
              final String id = widget.users[i].userId;
              final OcrPhotoUploadResult? ok = okById[id];
              if (ok != null) {
                _status[i] = _OcrPhotoStatus.uploaded;
                _photoUrls[i] = ok.photoUrl;
                _versions[i] = ok.version;
                _errors[i] = '';
              } else {
                _status[i] = _OcrPhotoStatus.failed;
                _errors[i] = (errById[id] ?? 'Upload failed').trim().isEmpty
                    ? 'Upload failed'
                    : errById[id]!.trim();
              }
            }
          });
          if (!mounted) return;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(res.message)));
        } catch (e) {
          if (!mounted) return;
          setState(() {
            for (final int i in indices) {
              _status[i] = _OcrPhotoStatus.failed;
              _errors[i] = _friendlyError(e);
            }
          });
        }
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  String _friendlyError(Object e) {
    if (e is ApiException) return e.message;
    if (e is DioException) {
      final dynamic data = e.response?.data;
      if (data is Map && data['message'] is String) {
        final String m = (data['message'] as String).trim();
        if (m.isNotEmpty) return m;
      }
      if (e.response?.statusCode == 404) return 'User not found (404)';
      if (e.response?.statusCode == 403) return 'Not your organization (403)';
      if (e.response?.statusCode == 400) return 'Invalid photo (400)';
      return e.message ?? 'Upload failed. Please try again.';
    }
    return e.toString();
  }

  Widget _statusChip(int index) {
    final _OcrPhotoStatus s = _status[index];
    switch (s) {
      case _OcrPhotoStatus.uploaded:
        return TMZBadge.complete(
          label: _versions[index] > 0
              ? 'Uploaded • v${_versions[index]}'
              : 'Uploaded',
        );
      case _OcrPhotoStatus.ready:
        return TMZBadge.pending(label: 'Ready');
      case _OcrPhotoStatus.uploading:
        return TMZBadge.processing(label: 'Uploading');
      case _OcrPhotoStatus.failed:
        return TMZBadge.failed(label: 'Failed — retry');
      case _OcrPhotoStatus.pending:
        return TMZBadge.manual(label: 'No photo');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Step-aware: documents + review are already done (2/3), so the bar
    // opens part-filled and reaches full as photos upload — never gray-empty.
    final double progress = widget.users.isEmpty
        ? 2 / 3
        : (2 + _uploadedCount / widget.users.length) / 3;
    final bool hasResult = _uploadedCount > 0 || _failedCount > 0;
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      backgroundColor: AppColors.cardSurface,
      surfaceTintColor: AppColors.cardSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 720),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Text(
                    'STEP 3 OF 3 • PHOTOS',
                    style: AppTypography.label.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '$_uploadedCount/${widget.users.length} done',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.brandBlue,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  IconButton(
                    onPressed: _isUploading
                        ? null
                        : () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                    tooltip: 'Skip for now',
                    color: AppColors.textSecondary,
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: SizedBox(
                  height: 4,
                  child: Stack(
                    fit: StackFit.expand,
                    children: <Widget>[
                      const DecoratedBox(
                        decoration: BoxDecoration(color: AppColors.divider),
                      ),
                      FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: progress.clamp(0.0, 1.0),
                        child: const DecoratedBox(
                          decoration: BoxDecoration(color: AppColors.brandBlue),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Add photos',
                style: AppTypography.heading1.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Documents are saved — photos are optional. Pairing follows the order below, never filenames. Saved as 350×350 PNG; re-upload keeps history as a new version.',
                style: AppTypography.body2.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              if (widget.skippedCount > 0 ||
                  widget.skipped.isNotEmpty) ...<Widget>[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.warningBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.warning.withAlpha(70)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          const Icon(
                            Icons.info_rounded,
                            size: 14,
                            color: AppColors.warning,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '${widget.skippedCount > 0 ? widget.skippedCount : widget.skipped.length} skipped — no photo slot needed.',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.warning,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      for (final BulkUploadSkippedUser s in widget.skipped.take(
                        4,
                      ))
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            'Doc ${s.row > 0 ? '#${s.row} ' : ''}• ${s.reason}',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.warning,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
              if (widget.docErrors.isNotEmpty) ...<Widget>[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.dangerBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.danger.withAlpha(60)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          const Icon(
                            Icons.error_outline_rounded,
                            size: 14,
                            color: AppColors.danger,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '${widget.docErrors.length} document error(s) — no photo slot.',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.danger,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      for (final BulkUploadErrorRow e in widget.docErrors.take(
                        4,
                      ))
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            'Doc ${e.row > 0 ? '#${e.row} ' : ''}• ${e.field.isNotEmpty ? '${e.field}: ' : ''}${e.error}',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.danger,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 14),
              Row(
                children: <Widget>[
                  Expanded(
                    child: TMZButton(
                      label: 'Add photos',
                      icon: Icons.photo_library_rounded,
                      variant: TMZButtonVariant.secondary,
                      onPressed: _isUploading ? null : _pickMultiple,
                      showShadow: false,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TMZButton(
                      label: 'Skip',
                      icon: Icons.skip_next_rounded,
                      variant: TMZButtonVariant.secondary,
                      onPressed: _isUploading
                          ? null
                          : () => Navigator.of(context).pop(),
                      showShadow: false,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.separated(
                  itemCount: widget.users.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (BuildContext context, int i) {
                    final BulkUploadSuccessUser u = widget.users[i];
                    final PickedFile? photo = _photos[i];
                    final bool uploading =
                        _status[i] == _OcrPhotoStatus.uploading;
                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.cardSurface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.divider),
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: Colors.black.withAlpha(10),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Stack(
                            children: <Widget>[
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: AppColors.blueTint,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: AppColors.divider),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: photo != null
                                    ? Image.memory(
                                        photo.bytes,
                                        fit: BoxFit.cover,
                                        cacheWidth: 256,
                                        cacheHeight: 256,
                                        filterQuality: FilterQuality.low,
                                      )
                                    : const Icon(
                                        Icons.person_rounded,
                                        color: AppColors.textTertiary,
                                        size: 28,
                                      ),
                              ),
                              Positioned(
                                left: 0,
                                top: 0,
                                child: Container(
                                  width: 22,
                                  height: 22,
                                  decoration: const BoxDecoration(
                                    color: AppColors.brandBlue,
                                    shape: BoxShape.circle,
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    '${i + 1}',
                                    style: AppTypography.caption.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: <Widget>[
                                          Text(
                                            widget.displayNameFor(u),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: AppTypography.body2.copyWith(
                                              color: AppColors.textPrimary,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          Text(
                                            'Slot ${i + 1} of ${widget.users.length}',
                                            style: AppTypography.caption
                                                .copyWith(
                                                  color: AppColors.textTertiary,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    _statusChip(i),
                                  ],
                                ),
                                if (_status[i] == _OcrPhotoStatus.failed &&
                                    _errors[i].isNotEmpty) ...<Widget>[
                                  const SizedBox(height: 6),
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      const Icon(
                                        Icons.error_rounded,
                                        size: 13,
                                        color: AppColors.danger,
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          _errors[i],
                                          style: AppTypography.caption.copyWith(
                                            color: AppColors.danger,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                                const SizedBox(height: 10),
                                Row(
                                  children: <Widget>[
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: uploading
                                            ? null
                                            : () => _pickSingle(i),
                                        icon: Icon(
                                          photo == null
                                              ? Icons.add_a_photo_rounded
                                              : Icons
                                                    .photo_camera_front_rounded,
                                          size: 15,
                                        ),
                                        label: Text(
                                          photo == null ? 'Add' : 'Retake',
                                          style: AppTypography.caption.copyWith(
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: AppColors.brandBlue,
                                          side: const BorderSide(
                                            color: AppColors.brandBlue,
                                            width: 1.2,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 9,
                                          ),
                                          visualDensity: VisualDensity.compact,
                                        ),
                                      ),
                                    ),
                                    if (photo != null &&
                                        !uploading) ...<Widget>[
                                      const SizedBox(width: 8),
                                      IconButton(
                                        onPressed: () => _removeAt(i),
                                        icon: const Icon(
                                          Icons.delete_outline_rounded,
                                          size: 18,
                                        ),
                                        color: AppColors.textSecondary,
                                        tooltip: 'Remove photo',
                                        visualDensity: VisualDensity.compact,
                                        style: IconButton.styleFrom(
                                          backgroundColor: AppColors.offWhite,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 14),
              TMZButton(
                label: _isUploading
                    ? 'Uploading…'
                    : hasResult
                    ? 'Continue • $_uploadedCount uploaded'
                    : _readyCount == 0
                    ? 'Upload'
                    : 'Upload ($_readyCount)',
                icon: hasResult
                    ? Icons.arrow_forward_rounded
                    : Icons.cloud_upload_rounded,
                isLoading: _isUploading,
                onPressed: _isUploading
                    ? null
                    : hasResult
                    ? () => Navigator.of(context).pop()
                    : _readyCount == 0
                    ? null
                    : _uploadAll,
              ),
              const SizedBox(height: 6),
              Center(
                child: Text(
                  hasResult
                      ? (_failedCount > 0
                            ? '($_failedCount failed — you can retry after continue)'
                            : '(photos saved — continue to costing)')
                      : '(or Skip above to continue without photos)',
                  textAlign: TextAlign.center,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ),
            ],
          ),
        ),
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

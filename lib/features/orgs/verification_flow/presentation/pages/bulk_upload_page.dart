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
  ];

  String? _lastRouteSignature;

  late final TextEditingController _batchNameController;
  late final TextEditingController _columnsController;
  List<String> _savedTemplateHeaders = <String>[];

  String _industry = '';
  String _credentialVisibility = 'public_searchable';
  Set<String> _checks = <String>{};
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
    final List<String> nextColumns =
        _parseCsvList(qp['columns']) ?? _templateColumnsForChecks(nextChecks);

    setState(() {
      _industry = nextIndustry;
      if (nextVisibility.isNotEmpty) {
        _credentialVisibility = nextVisibility;
      }
      _checks = nextChecks;
      _seededDefaultChecks = false;
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
    // Keep the human template seeded with the exact default fields requested
    // for first-time download. Users can still remove any of them in the
    // template dialog before generating the file.
    return List<String>.from(_defaultHumanTemplateHeaders);
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
    final List<String> initialHeaders = _savedTemplateHeaders.isNotEmpty
        ? List<String>.from(_savedTemplateHeaders)
        : _columns();
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black54,
      builder: (BuildContext dialogContext) {
        final String verificationFilter = _verificationFilter(
          category: 'human',
        );
        return _HumanTemplateDialog(
          initialHeaders: initialHeaders,
          selectedChecks: _checks,
          verificationFilter: verificationFilter,
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
    if (response is Map<String, dynamic>) return response;
    if (response is Map) {
      return Map<String, dynamic>.from(response);
    }
    if (response is String) {
      final String raw = response.trim();
      if (raw.startsWith('{') && raw.endsWith('}')) {
        try {
          final dynamic decoded = jsonDecode(raw);
          if (decoded is Map) {
            return Map<String, dynamic>.from(decoded);
          }
        } catch (_) {
          // Fall through to raw string wrapper.
        }
      }
      return <String, dynamic>{'raw_text': raw};
    }
    return <String, dynamic>{'raw_text': response.toString()};
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
        fields:
            'full_name,email,phone_number,dob,aadhar_number,pan_number,address_line1,address_line2,address_line3,pincode,state,country',
        docType: docs.first.label,
      );
      return _normalizeOcrMap(res);
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

    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, void Function(void Function()) setDialogState) {
            Future<void> addDocuments() async {
              if (isProcessing) return;
              setDialogState(() => isProcessing = true);
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
                  setDialogState(() => isProcessing = false);
                }
              }
            }

            Future<void> reviewAndContinue() async {
              Navigator.of(dialogContext).pop();
              await Future<void>.delayed(Duration.zero);
              if (!mounted) return;
              await _confirmAndCreateBatch();
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

            return Dialog(
              insetPadding: const EdgeInsets.all(16),
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Padding(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              'Documents',
                              style: AppTypography.heading1.copyWith(
                                color: AppColors.brandBlue,
                              ),
                            ),
                          ),
                          if (_parsedUsers.length > 1) ...<Widget>[
                            IconButton(
                              onPressed: selectedIndex > 0
                                  ? goToPreviousUser
                                  : null,
                              icon: const Icon(
                                Icons.arrow_back_ios_new_rounded,
                              ),
                            ),
                            IconButton(
                              onPressed: selectedIndex < _parsedUsers.length - 1
                                  ? goToNextUser
                                  : null,
                              icon: const Icon(Icons.arrow_forward_ios_rounded),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _parsedUsers.length > 1
                            ? 'Use the arrows to move between users, then attach document(s) for each person.'
                            : 'Attach document(s) for this user.',
                        style: AppTypography.body2.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: <Widget>[
                          if (_parsedUsers.length > 1)
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: InkWell(
                                onTap: removeCurrentUser,
                                borderRadius: BorderRadius.circular(999),
                                child: Container(
                                  width: 22,
                                  height: 22,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFEF4444),
                                    shape: BoxShape.circle,
                                  ),
                                  alignment: Alignment.center,
                                  child: const Text(
                                    '−',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      height: 1,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          Expanded(
                            child: Text(
                              _displayUserLabel(
                                _parsedUsers[selectedIndex],
                                selectedIndex,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.heading2.copyWith(
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          if (_parsedUsers.length > 1)
                            Text(
                              '${selectedIndex + 1}/${_parsedUsers.length}',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Center(
                        child: SizedBox(
                          width: 220,
                          child: TextButton.icon(
                            onPressed: isProcessing ? null : addDocuments,
                            icon: isProcessing
                                ? SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.brandBlue,
                                    ),
                                  )
                                : const Icon(Icons.attach_file_rounded),
                            label: Text(
                              isProcessing ? 'Uploading...' : 'Add Document',
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Preview',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 188,
                        child: currentDocs.isEmpty
                            ? DecoratedBox(
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: const Color(0xFFE5E7EB),
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    'Add a document to see the preview here.',
                                    textAlign: TextAlign.center,
                                    style: AppTypography.body2.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
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
                                itemBuilder: (BuildContext context, int index) {
                                  final _HumanDocumentDraft draft =
                                      currentDocs[index];
                                  return _DocumentPreviewTile(
                                    fileName: draft.file.name,
                                    fileBytes: draft.file.bytes,
                                    onRemove: () => removeDocument(index),
                                  );
                                },
                              ),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: Row(
                          children: <Widget>[
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: addUser,
                                icon: const Icon(
                                  Icons.person_add_alt_1_rounded,
                                ),
                                label: const Text('Add User'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.brandBlue,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: reviewAndContinue,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.brandBlue,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                ),
                                child: const Text('Continue'),
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
    final String resolvedIndustry = _industry.trim().isNotEmpty
        ? _industry.trim()
        : apiIndustry.isNotEmpty
        ? apiIndustry
        : profileIndustry;
    final String displayIndustry = _prettyIndustry(resolvedIndustry);
    final String verificationFilter = resolvedIndustry.isNotEmpty
        ? 'human::$resolvedIndustry'
        : 'human';
    final AsyncValue<List<VerificationTypeDefinition>> humanTypesAsync = ref
        .watch(verificationTypesProvider(verificationFilter));
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
                            industryLabel: displayIndustry,
                            onTap: () async {
                              final String? picked = await _pickIndustry(
                                scale: scale,
                                current: resolvedIndustry,
                              );
                              if (!mounted || picked == null) return;
                              setState(() => _industry = picked);
                            },
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
                                    _DropZone(
                                      scale: scale,
                                      onTap: _pickExcelFile,
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
                                                'Attach supporting documents for reference alongside the batch upload.',
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
                                    _DropZone(
                                      scale: scale,
                                      onTap: _openAttachDocumentsDialog,
                                      title: 'Add documents for users',
                                      subtitle:
                                          'Tap to attach docs for each user in the batch.',
                                      iconAsset:
                                          'assets/icons/figma/bulk_upload_icon_file_attach.svg',
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
                              child: _UploadButton(
                                scale: scale,
                                isLoading: _isUploading,
                                enabled:
                                    _parsedUsers.isNotEmpty &&
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

  Future<String?> _pickIndustry({
    required double scale,
    required String current,
  }) async {
    final Set<String> selected = _industrySelectionFromRaw(current);
    double s(double v) => v * scale;

    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder:
              (
                BuildContext context,
                void Function(void Function()) setDialogState,
              ) {
                final List<String> options = _industryOptions
                    .where((String e) => e != 'All')
                    .toList();
                final bool allSelected = selected.length >= options.length;

                void toggle(String label) {
                  setDialogState(() {
                    if (label == 'All') {
                      selected
                        ..clear()
                        ..addAll(options);
                      return;
                    }
                    if (selected.contains(label)) {
                      selected.remove(label);
                    } else {
                      selected.add(label);
                    }
                  });
                }

                return Dialog(
                  insetPadding: EdgeInsets.fromLTRB(s(18), s(18), s(18), s(18)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(s(16)),
                    side: BorderSide(
                      color: const Color(0xFFE5E7EB),
                      width: s(1),
                    ),
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: s(520)),
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(s(16), s(16), s(16), s(16)),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Text(
                                'Select Industry',
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
                                child: Icon(
                                  Icons.close_rounded,
                                  size: s(20),
                                  color: const Color(0xFF9CA3AF),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: s(10)),
                          Text(
                            'Choose one or more industries, then tap Update.',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: s(12),
                              fontWeight: FontWeight.w500,
                              height: 18 / 12,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                          SizedBox(height: s(10)),
                          Expanded(
                            child: ListView.separated(
                              itemCount: _industryOptions.length,
                              separatorBuilder:
                                  (BuildContext context, int index) => Divider(
                                    height: s(1),
                                    color: const Color(0xFFF1F5F9),
                                  ),
                              itemBuilder: (BuildContext context, int index) {
                                final String label = _industryOptions[index];
                                final bool isSelected = label == 'All'
                                    ? allSelected
                                    : selected.contains(label);
                                return InkWell(
                                  onTap: () => toggle(label),
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                      vertical: s(12),
                                      horizontal: s(2),
                                    ),
                                    child: Row(
                                      children: <Widget>[
                                        Container(
                                          width: s(18),
                                          height: s(18),
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: isSelected
                                                ? AppColors.brandBlue
                                                : const Color(0xFFE5E7EB),
                                          ),
                                          child: isSelected
                                              ? Icon(
                                                  Icons.check_rounded,
                                                  size: s(12),
                                                  color: Colors.white,
                                                )
                                              : null,
                                        ),
                                        SizedBox(width: s(12)),
                                        Expanded(
                                          child: Text(
                                            label,
                                            style: TextStyle(
                                              fontFamily: 'Inter',
                                              fontSize: s(14),
                                              fontWeight: FontWeight.w600,
                                              height: 20 / 14,
                                              color: isSelected
                                                  ? AppColors.brandBlue
                                                  : const Color(0xFF334155),
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
                          SizedBox(height: s(12)),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.brandBlue,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: EdgeInsets.symmetric(vertical: s(14)),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(s(12)),
                                ),
                              ),
                              onPressed: selected.isEmpty
                                  ? null
                                  : () {
                                      final List<String> sorted =
                                          selected.toList()..sort();
                                      Navigator.of(
                                        context,
                                      ).pop(sorted.join(', '));
                                    },
                              child: Text(
                                'Update',
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
                  ),
                );
              },
        );
      },
    );
  }

  Set<String> _industrySelectionFromRaw(String raw) {
    final Set<String> selected = <String>{};
    final List<String> parts = _parseIndustryParts(raw);
    if (parts.isEmpty) return selected;

    final List<String> options = _industryOptions
        .where((String e) => e != 'All')
        .toList();
    final Set<String> normalizedParts = parts
        .map((String e) => e.trim().toLowerCase())
        .where((String e) => e.isNotEmpty)
        .toSet();
    final Set<String> normalizedOptions = options
        .map((String e) => e.toLowerCase())
        .toSet();

    if (normalizedParts.containsAll(normalizedOptions)) {
      selected.addAll(options);
      return selected;
    }

    for (final String option in options) {
      if (normalizedParts.contains(option.toLowerCase())) {
        selected.add(option);
      }
    }
    return selected;
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

  String _verificationFilter({required String category, String? industry}) {
    final String selectedIndustry = (industry ?? _effectiveIndustry()).trim();
    if (selectedIndustry.isEmpty) return category;
    return '$category::$selectedIndustry';
  }
}

class _HumanTemplateDialog extends ConsumerStatefulWidget {
  const _HumanTemplateDialog({
    required this.initialHeaders,
    required this.selectedChecks,
    required this.verificationFilter,
    required this.onSave,
  });

  final List<String> initialHeaders;
  final Set<String> selectedChecks;
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
      final List<String> sortedChecks = widget.selectedChecks.toList()..sort();
      final List<String> headers = <String>[
        for (final String header in _headers)
          if (header.trim().isNotEmpty) header.trim(),
      ];
      final String headersCsv = headers.join(',');
      final String verificationTypesCsv = sortedChecks.join(',');
      debugPrint(
        '[HumanTemplate] headers=$headersCsv verification_types=$verificationTypesCsv',
      );
      final VerificationBinaryResponse res = await repo.generateHumanTemplate(
        headers: headersCsv,
        verificationTypes: verificationTypesCsv,
      );
      if (!mounted) return;

      final Uint8List templateBytes = _replaceVerificationIdsWithNames(
        res.bytes,
        verificationTypesById,
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
                  debugPrint('[HumanTemplate] open failed: $e');
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
                  debugPrint('[HumanTemplate] share failed: $e');
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

  Uint8List _replaceVerificationIdsWithNames(
    Uint8List bytes,
    Map<String, VerificationTypeDefinition> verificationTypesById,
  ) {
    if (verificationTypesById.isEmpty) return bytes;

    final Map<String, String> replacements = <String, String>{
      for (final MapEntry<String, VerificationTypeDefinition> entry
          in verificationTypesById.entries)
        entry.key.trim().toLowerCase(): _verificationTypeDisplayName(
          entry.value,
        ),
    }..removeWhere((String key, String value) => key.isEmpty || value.isEmpty);

    if (replacements.isEmpty) return bytes;

    try {
      final Excel excel = Excel.decodeBytes(bytes);
      for (final String sheetName in excel.tables.keys) {
        final Sheet? sheet = excel.tables[sheetName];
        if (sheet == null) continue;

        final List<List<Data?>> rows = sheet.rows;
        for (int rowIndex = 0; rowIndex < rows.length; rowIndex++) {
          final List<Data?> row = rows[rowIndex];
          for (int columnIndex = 0; columnIndex < row.length; columnIndex++) {
            final Data? cell = row[columnIndex];
            if (cell == null) continue;

            final String raw = (cell.value?.toString() ?? '').trim();
            if (raw.isEmpty) continue;

            final String? replacement = _remapVerificationCell(
              raw,
              replacements,
            );
            if (replacement == null || replacement == raw) continue;

            sheet.updateCell(
              CellIndex.indexByColumnRow(
                columnIndex: columnIndex,
                rowIndex: rowIndex,
              ),
              TextCellValue(replacement),
            );
          }
        }
      }

      final List<int>? encoded = excel.encode();
      if (encoded == null || encoded.isEmpty) return bytes;
      return Uint8List.fromList(encoded);
    } catch (e) {
      debugPrint('[HumanTemplate] could not remap verification names: $e');
      return bytes;
    }
  }

  String? _remapVerificationCell(String raw, Map<String, String> replacements) {
    final String normalized = raw.trim();
    final String? direct = replacements[normalized.toLowerCase()];
    if (direct != null) return direct;

    String remapped = normalized;
    bool changed = false;

    final List<String> ids = replacements.keys.toList()
      ..sort((String a, String b) => b.length.compareTo(a.length));
    for (final String id in ids) {
      final String replacement = replacements[id]!;
      final RegExp pattern = RegExp(RegExp.escape(id), caseSensitive: false);
      final String next = remapped.replaceAll(pattern, replacement);
      if (next == remapped) continue;
      remapped = next;
      changed = true;
    }

    if (!changed) return null;
    return remapped;
  }

  static String _verificationTypeDisplayName(VerificationTypeDefinition item) {
    final String name = item.name.trim();
    if (name.isNotEmpty) return name;

    final String label = item.label.trim();
    if (label.isNotEmpty) return label;

    final String fallback = item.id.trim();
    if (fallback.isEmpty) return '';

    return fallback
        .replaceAll(RegExp(r'[_\-]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
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

class _IndustryPill extends StatelessWidget {
  const _IndustryPill({
    required this.scale,
    required this.industryLabel,
    required this.onTap,
  });

  final double scale;
  final String industryLabel;
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
                    ? Image.memory(fileBytes, fit: BoxFit.cover)
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
  });

  final List<Map<String, dynamic>> users;
  final Map<int, List<_HumanDocumentDraft>> documentsByUser;

  @override
  State<_HumanReviewDialog> createState() => _HumanReviewDialogState();
}

class _HumanReviewDialogState extends State<_HumanReviewDialog> {
  static const List<String> _fieldKeys = <String>[
    'full_name',
    'email',
    'phone_number',
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
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      'Review OCR data',
                      style: AppTypography.heading1.copyWith(
                        color: AppColors.brandBlue,
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
                              Expanded(child: field('email', 'Email')),
                              const SizedBox(width: 12),
                              Expanded(
                                child: field('phone_number', 'Phone number'),
                              ),
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
                                child: field('aadhar_number', 'Aadhaar'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: <Widget>[
                              Expanded(child: field('pan_number', 'PAN')),
                              const SizedBox(width: 12),
                              Expanded(child: field('pincode', 'Pincode')),
                            ],
                          ),
                          const SizedBox(height: 12),
                          field('address_line1', 'Address line 1'),
                          const SizedBox(height: 12),
                          field('address_line2', 'Address line 2'),
                          const SizedBox(height: 12),
                          field('address_line3', 'Address line 3'),
                          const SizedBox(height: 12),
                          Row(
                            children: <Widget>[
                              Expanded(child: field('state', 'State')),
                              const SizedBox(width: 12),
                              Expanded(child: field('country', 'Country')),
                            ],
                          ),
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

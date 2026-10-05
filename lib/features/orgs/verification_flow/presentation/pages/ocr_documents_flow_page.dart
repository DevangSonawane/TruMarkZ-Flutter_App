import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/models/verification_models.dart';
import '../../../../../core/network/api_client.dart';
import '../../../../../core/router/app_router.dart';
import '../../../../../core/services/batch_name_store.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/utils/file_picker_util.dart';
import '../../../../../core/widgets/tmz_badge.dart';
import '../../../../../core/widgets/tmz_button.dart';
import '../../../data/verification_repository.dart';

/// Full-page OCR Human flow (trumarkz_ocr.md): documents → review → photos.
///
/// A dedicated page instead of the stacked popup sheets: one step visible at
/// a time with a real app bar, step progress, and a pinned footer. Same
/// backend sequence as the dialog flow (bulk-upload/documents → review PATCH
/// → ocr-photo/ocr-photos → costing) — only the presentation differs.
class OcrDocumentsFlowPage extends ConsumerStatefulWidget {
  const OcrDocumentsFlowPage({super.key});

  @override
  ConsumerState<OcrDocumentsFlowPage> createState() =>
      _OcrDocumentsFlowPageState();
}

class _OcrDocDraft {
  _OcrDocDraft({required this.label, required this.file});

  final String label;
  final PickedFile file;
}

enum _OcrPhotoStatus { pending, ready, uploading, uploaded, failed }

/// Single = 1 document -> 1 BatchUser. Bulk = N documents -> N BatchUsers
/// (1 image = 1 user). Same endpoint, only the count differs (trumarkz_ocr.md).
enum _OcrFlowMode { single, bulk }

class _OcrDocumentsFlowPageState extends ConsumerState<OcrDocumentsFlowPage> {
  static const double _referenceWidth = 402;
  static const Color _panelBg = Color(0xFFF7F9FC);

  static const String _humanDocumentFieldsCsv =
      'full_name,name,email,phone_number,dob,license_number,dl_number,dl_no,doi,valid_till,cov_lmv_doi,cov_mcwg_doi,blood_group,sdw_of,issuing_authority,aadhar_number,pan_number,address_line1,address_line2,address_line3,address,pincode,pin,state,country';

  static const List<String> _reviewFieldKeys = <String>[
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

  String? _lastRouteSignature;
  late final TextEditingController _batchNameController;

  int _step = 0;

  String _industry = '';
  String _credentialVisibility = 'public_searchable';
  Set<String> _checks = <String>{};

  // Step 0 — documents.
  _OcrFlowMode _docMode = _OcrFlowMode.single;
  List<Map<String, dynamic>> _parsedUsers = <Map<String, dynamic>>[];
  final Map<int, List<_OcrDocDraft>> _documentsByUser =
      <int, List<_OcrDocDraft>>{};
  int _selectedUserIndex = 0;
  bool _isAddingDocs = false;
  bool _isUploadingDocs = false;
  String _docsStatus = '';

  // Step 1 — review.
  List<Map<String, dynamic>> _reviewUsers = <Map<String, dynamic>>[];
  List<Map<String, TextEditingController>> _reviewControllers =
      <Map<String, TextEditingController>>[];
  int _reviewIndex = 0;

  BulkUploadResponse? _uploadRes;
  Map<int, String> _userIdsByIndex = <int, String>{};
  bool _isSavingReview = false;

  // Step 2 — photos.
  List<BulkUploadSuccessUser> _serverUsers = <BulkUploadSuccessUser>[];
  List<PickedFile?> _photos = <PickedFile?>[];
  List<_OcrPhotoStatus> _photoStatus = <_OcrPhotoStatus>[];
  List<String> _photoErrors = <String>[];
  List<int> _photoVersions = <int>[];
  bool _isUploadingPhotos = false;
  // Case A: extra supporting docs for the SAME person, added from photo step.
  // Uses POST /verification/humans/upload-doc (append, no new batch/user).
  List<int> _extraDocCounts = <int>[];
  List<bool> _uploadingExtraDoc = <bool>[];
  List<String> _extraDocErrors = <String>[];

  @override
  void initState() {
    super.initState();
    _batchNameController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final Uri uri = GoRouterState.of(context).uri;
    final String signature = uri.query;
    if (_lastRouteSignature == signature) return;
    _lastRouteSignature = signature;

    final Map<String, String> qp = uri.queryParameters;
    List<String>? split(String? raw) {
      if (raw == null) return null;
      final List<String> list = raw
          .split(',')
          .map((String s) => s.trim())
          .where((String s) => s.isNotEmpty)
          .toList();
      return list.isEmpty ? null : list;
    }

    setState(() {
      final String? batch = qp['batch']?.trim();
      if (batch != null &&
          batch.isNotEmpty &&
          _batchNameController.text.isEmpty) {
        _batchNameController.text = batch;
      }
      _industry = (qp['industry'] ?? _industry).trim();
      final String access = (qp['access'] ?? '').trim().toLowerCase();
      if (access.isNotEmpty) _credentialVisibility = access;
      final List<String>? checks = split(qp['checks']);
      if (checks != null) _checks = checks.toSet();
      if (_parsedUsers.isEmpty) {
        _parsedUsers = <Map<String, dynamic>>[
          <String, dynamic>{'full_name': 'User 1'},
        ];
      }
    });
  }

  @override
  void dispose() {
    _batchNameController.dispose();
    _disposeReviewControllers();
    super.dispose();
  }

  void _disposeReviewControllers() {
    for (final Map<String, TextEditingController> entry in _reviewControllers) {
      for (final TextEditingController c in entry.values) {
        c.dispose();
      }
    }
    _reviewControllers = <Map<String, TextEditingController>>[];
  }

  String _verificationTypesCsv() {
    final List<String> sorted = _checks.toList()..sort();
    return sorted.join(',');
  }

  // ---------------------------------------------------------------- docs ---

  List<_OcrDocDraft> _docsForUser(int index) {
    return _documentsByUser[index] ?? <_OcrDocDraft>[];
  }

  String _displayUserLabel(Map<String, dynamic> user, int index) {
    final String fullName = (user['full_name'] ?? '').toString().trim();
    if (fullName.isNotEmpty) return fullName;
    final String email = (user['email'] ?? '').toString().trim();
    if (email.isNotEmpty) return email;
    return 'User ${index + 1}';
  }

  List<BulkUploadDocumentInput> _documentFiles() {
    final List<BulkUploadDocumentInput> files = <BulkUploadDocumentInput>[];
    final List<int> indices = _documentsByUser.keys.toList()..sort();
    for (final int userIndex in indices) {
      for (final _OcrDocDraft draft in _documentsByUser[userIndex]!) {
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

  Future<void> _addDocuments() async {
    if (_isAddingDocs || _isUploadingDocs) return;
    if (_batchNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a batch name first.')),
      );
      return;
    }
    setState(() => _isAddingDocs = true);
    // Single mode: pick exactly one document (1 image = 1 user).
    // Bulk mode: multi-select, N images = N users in one request.
    List<PickedFile> picked;
    if (_docMode == _OcrFlowMode.single) {
      final PickedFile? one = await FilePickerUtil.pickDocument();
      picked = one == null ? <PickedFile>[] : <PickedFile>[one];
    } else {
      picked = await FilePickerUtil.pickDocuments();
    }
    try {
      if (!mounted || picked.isEmpty) return;
      if (_docMode == _OcrFlowMode.single) {
        if (picked.length > 1) picked = picked.sublist(0, 1);
        final int target = _selectedUserIndex.clamp(0, _parsedUsers.length - 1);
        final List<_OcrDocDraft> drafts = picked
            .map(
              (PickedFile file) => _OcrDocDraft(label: 'document', file: file),
            )
            .toList();
        setState(() {
          _documentsByUser
              .putIfAbsent(target, () => <_OcrDocDraft>[])
              .addAll(drafts);
          _selectedUserIndex = target;
        });
        final Map<String, dynamic>? ocr = await _extractOcrForDocs(drafts);
        if (ocr != null && mounted) {
          setState(() => _mergeOcrIntoUser(target, ocr));
        }
        return;
      }
      // Bulk: 1 image = 1 user. The first image goes to the selected user,
      // every extra image creates its own user. Non-images ride along on the
      // selected user as supporting docs (never OCR'd, never uploaded).
      bool isImageFile(PickedFile f) {
        final String ext = f.extension.toLowerCase();
        return ext.contains('jpg') ||
            ext.contains('jpeg') ||
            ext.contains('png') ||
            ext.contains('webp');
      }

      final List<PickedFile> images = picked.where(isImageFile).toList();
      final List<PickedFile> others = picked
          .where((f) => !isImageFile(f))
          .toList();
      final int firstTarget = _selectedUserIndex.clamp(
        0,
        _parsedUsers.length - 1,
      );
      if (images.isEmpty) {
        setState(() {
          for (final PickedFile f in others) {
            _documentsByUser
                .putIfAbsent(firstTarget, () => <_OcrDocDraft>[])
                .add(_OcrDocDraft(label: 'document', file: f));
          }
          _selectedUserIndex = firstTarget;
        });
        return;
      }
      final List<int> targets = <int>[firstTarget];
      setState(() {
        for (int k = 1; k < images.length; k++) {
          _parsedUsers.add(<String, dynamic>{
            'full_name': 'User ${_parsedUsers.length + 1}',
          });
          targets.add(_parsedUsers.length - 1);
        }
        for (int k = 0; k < images.length; k++) {
          _documentsByUser
              .putIfAbsent(targets[k], () => <_OcrDocDraft>[])
              .add(_OcrDocDraft(label: 'document', file: images[k]));
        }
        for (final PickedFile f in others) {
          _documentsByUser
              .putIfAbsent(firstTarget, () => <_OcrDocDraft>[])
              .add(_OcrDocDraft(label: 'document', file: f));
        }
        _selectedUserIndex = firstTarget;
      });
      // OCR each image into its own user so names never bleed across users.
      for (int k = 0; k < images.length; k++) {
        if (!mounted) return;
        final Map<String, dynamic>? ocr = await _extractOcrForDocs(
          <_OcrDocDraft>[_OcrDocDraft(label: 'document', file: images[k])],
        );
        if (ocr != null && mounted) {
          setState(() => _mergeOcrIntoUser(targets[k], ocr));
        }
      }
    } finally {
      if (mounted) setState(() => _isAddingDocs = false);
    }
  }

  Future<Map<String, dynamic>?> _extractOcrForDocs(
    List<_OcrDocDraft> docs,
  ) async {
    final List<PickedFile> images = docs
        .where((_OcrDocDraft draft) {
          final String ext = draft.file.extension.toLowerCase();
          return ext.contains('jpg') ||
              ext.contains('jpeg') ||
              ext.contains('png') ||
              ext.contains('webp');
        })
        .map((_OcrDocDraft draft) => draft.file)
        .toList();
    if (images.isEmpty) return null;
    try {
      final VerificationRepository repo = ref.read(
        verificationRepositoryProvider,
      );
      final dynamic res = await repo.extractHumanOcr(
        files: images.map((PickedFile f) => f.bytes).toList(),
        fields: _humanDocumentFieldsCsv,
        docType: docs.first.label,
      );
      return _applyOcrFieldAliases(_normalizeOcrMap(res));
    } catch (_) {
      return null;
    }
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
    for (final MapEntry<String, dynamic> entry in responseMap.entries) {
      final String key = entry.key.trim();
      if (key.isEmpty || key == 'extracted' || key == 'per_file') continue;
      if (!flattened.containsKey(key)) flattened[key] = entry.value;
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

  void _mergeOcrIntoUser(int index, Map<String, dynamic> ocrData) {
    if (index < 0 || index >= _parsedUsers.length) return;
    final Map<String, dynamic> current = Map<String, dynamic>.from(
      _parsedUsers[index],
    );
    for (final MapEntry<String, dynamic> entry in ocrData.entries) {
      final String key = entry.key.trim();
      final dynamic value = entry.value;
      if (key.isEmpty || value == null) continue;
      final String str = value.toString().trim();
      if (str.isEmpty) continue;
      current[key] = str;
    }
    _parsedUsers[index] = current;
  }

  int _findMatchingDraftIndex(BulkUploadSuccessUser serverUser, int fallback) {
    final String targetName = serverUser.fullName.trim().toLowerCase();
    final String targetEmail = serverUser.email.trim().toLowerCase();
    final String targetPhone = serverUser.phoneNumber.replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );
    for (int i = 0; i < _parsedUsers.length; i++) {
      final Map<String, dynamic> user = _parsedUsers[i];
      final String name = (user['full_name'] ?? '')
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
      if (targetName.isNotEmpty && name == targetName) return i;
    }
    if (fallback >= 0 && fallback < _parsedUsers.length) return fallback;
    return -1;
  }

  void _addManualUser() {
    setState(() {
      _parsedUsers = <Map<String, dynamic>>[
        ..._parsedUsers,
        <String, dynamic>{'full_name': 'User ${_parsedUsers.length + 1}'},
      ];
      _selectedUserIndex = _parsedUsers.length - 1;
    });
  }

  void _removeUserAt(int index) {
    if (_parsedUsers.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Keep at least one user in the batch.')),
      );
      return;
    }
    if (index < 0 || index >= _parsedUsers.length) return;
    setState(() {
      _parsedUsers.removeAt(index);
      _documentsByUser.remove(index);
      final Map<int, List<_OcrDocDraft>> shifted = <int, List<_OcrDocDraft>>{};
      for (final MapEntry<int, List<_OcrDocDraft>> entry
          in _documentsByUser.entries.toList()) {
        shifted[entry.key > index ? entry.key - 1 : entry.key] = entry.value;
      }
      _documentsByUser
        ..clear()
        ..addAll(shifted);
      if (_selectedUserIndex >= _parsedUsers.length) {
        _selectedUserIndex = _parsedUsers.length - 1;
      }
    });
  }

  Future<void> _continueFromDocs() async {
    if (_isUploadingDocs || _isAddingDocs) return;
    if (_batchNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a batch name first.')),
      );
      return;
    }
    if (_documentFiles().isEmpty && _parsedUsers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one document first.')),
      );
      return;
    }
    // Manual path (users but no document images): create batch directly.
    if (_documentFiles().isEmpty) {
      _startManualReview();
      return;
    }
    setState(() {
      _isUploadingDocs = true;
      _docsStatus = 'Uploading ${_documentFiles().length} document(s)…';
    });
    try {
      final VerificationRepository repo = ref.read(
        verificationRepositoryProvider,
      );
      final String verificationTypesCsv = _verificationTypesCsv();
      final BulkUploadResponse res = await repo.bulkUploadDocuments(
        batchName: _batchNameController.text.trim(),
        industryType: _industry.trim().isNotEmpty ? _industry.trim() : null,
        verificationTypes: verificationTypesCsv.isNotEmpty
            ? verificationTypesCsv
            : null,
        credentialVisibility: _credentialVisibility.trim().isNotEmpty
            ? _credentialVisibility.trim()
            : null,
        docType: 'document',
        fields: _humanDocumentFieldsCsv,
        files: _documentFiles(),
      );
      final Map<int, String> idsByIndex = <int, String>{};
      for (int i = 0; i < res.successfulUsers.length; i++) {
        final BulkUploadSuccessUser serverUser = res.successfulUsers[i];
        final int localIndex = _findMatchingDraftIndex(serverUser, i);
        if (localIndex < 0) continue;
        idsByIndex[localIndex] = serverUser.userId;
        if (serverUser.extracted.isNotEmpty) {
          _mergeOcrIntoUser(
            localIndex,
            _applyOcrFieldAliases(_normalizeOcrMap(serverUser.extracted)),
          );
        }
      }
      if (!mounted) return;
      setState(() {
        _uploadRes = res;
        _userIdsByIndex = idsByIndex;
        _buildReviewState();
        _isUploadingDocs = false;
        _docsStatus = '';
        _step = 1;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isUploadingDocs = false;
        _docsStatus = '';
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_friendlyError(e))));
    }
  }

  void _startManualReview() {
    setState(() {
      _uploadRes = null;
      _userIdsByIndex = <int, String>{};
      _buildReviewState();
      _step = 1;
    });
  }

  // --------------------------------------------------------------- review ---

  void _buildReviewState() {
    _disposeReviewControllers();
    _reviewUsers = _parsedUsers
        .map((Map<String, dynamic> user) => Map<String, dynamic>.from(user))
        .toList();
    _reviewControllers = _reviewUsers.map((Map<String, dynamic> user) {
      return <String, TextEditingController>{
        for (final String key in _reviewFieldKeys)
          key: TextEditingController(text: user[key]?.toString() ?? ''),
      };
    }).toList();
  }

  Map<String, dynamic> _reviewPayload(Map<String, dynamic> user) {
    final Map<String, dynamic> payload = <String, dynamic>{
      'full_name': (user['full_name'] ?? '').toString().trim(),
      'email': (user['email'] ?? '').toString().trim(),
      'phone_number': (user['phone_number'] ?? '').toString().trim(),
    };
    for (final String key in _reviewFieldKeys) {
      if (payload.containsKey(key)) continue;
      final String value = (user[key] ?? '').toString().trim();
      if (value.isNotEmpty) payload[key] = value;
    }
    return payload;
  }

  Future<void> _confirmReview() async {
    if (_isSavingReview) return;
    final List<Map<String, dynamic>> reviewed = _reviewUsers;
    if (reviewed.isEmpty) return;
    // Manual path — no OCR batch yet.
    if (_uploadRes == null) {
      setState(() => _isSavingReview = true);
      try {
        final VerificationRepository repo = ref.read(
          verificationRepositoryProvider,
        );
        final BulkUploadResponse res = await repo.createHumanBatch(
          batchName: _batchNameController.text.trim(),
          users: reviewed.map(_reviewPayload).toList(),
        );
        if (!mounted) return;
        await ref
            .read(batchNameStoreProvider.notifier)
            .setBatchName(res.batchId, _batchNameController.text.trim());
        if (!mounted) return;
        context.push(
          Uri(
            path: AppRouter.batchCreatedSuccessPath,
            queryParameters: <String, String>{
              'batch_id': res.batchId,
              'total_uploaded': reviewed.length.toString(),
              'total_skipped': '0',
              'errors': '0',
              'batch': _batchNameController.text.trim(),
            },
          ).toString(),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_friendlyError(e))));
      } finally {
        if (mounted) setState(() => _isSavingReview = false);
      }
      return;
    }
    // OCR path — persist corrections, then photos step.
    setState(() => _isSavingReview = true);
    try {
      final VerificationRepository repo = ref.read(
        verificationRepositoryProvider,
      );
      for (final MapEntry<int, String> entry in _userIdsByIndex.entries) {
        await repo.updateBatchUser(
          userId: entry.value,
          fullName: reviewed[entry.key]['full_name']?.toString(),
          email: reviewed[entry.key]['email']?.toString(),
          phoneNumber: reviewed[entry.key]['phone_number']?.toString(),
          dob: reviewed[entry.key]['dob']?.toString(),
          aadharNumber: reviewed[entry.key]['aadhar_number']?.toString(),
          panNumber: reviewed[entry.key]['pan_number']?.toString(),
          addressLine1: reviewed[entry.key]['address_line1']?.toString(),
          addressLine2: reviewed[entry.key]['address_line2']?.toString(),
          addressLine3: reviewed[entry.key]['address_line3']?.toString(),
          pincode: reviewed[entry.key]['pincode']?.toString(),
          state: reviewed[entry.key]['state']?.toString(),
          country: reviewed[entry.key]['country']?.toString(),
          customFields: reviewed[entry.key],
          markReviewed: true,
        );
      }
      if (!mounted) return;
      final BulkUploadResponse res = _uploadRes!;
      setState(() {
        _serverUsers = res.successfulUsers;
        _photos = List<PickedFile?>.filled(res.successfulUsers.length, null);
        _photoStatus = List<_OcrPhotoStatus>.filled(
          res.successfulUsers.length,
          _OcrPhotoStatus.pending,
        );
        _photoErrors = List<String>.filled(res.successfulUsers.length, '');
        _photoVersions = List<int>.filled(res.successfulUsers.length, 0);
        _extraDocCounts = List<int>.filled(res.successfulUsers.length, 0);
        _uploadingExtraDoc = List<bool>.filled(
          res.successfulUsers.length,
          false,
        );
        _extraDocErrors = List<String>.filled(res.successfulUsers.length, '');
        _isSavingReview = false;
        _step = 2;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSavingReview = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_friendlyError(e))));
    }
  }

  // --------------------------------------------------------------- photos ---

  String _photoDisplayName(BulkUploadSuccessUser u) {
    final Map<String, int> reverse = <String, int>{
      for (final MapEntry<int, String> e in _userIdsByIndex.entries)
        e.value: e.key,
    };
    final int? local = reverse[u.userId];
    if (local != null && local >= 0 && local < _reviewUsers.length) {
      final String name = (_reviewUsers[local]['full_name'] ?? '')
          .toString()
          .trim();
      if (name.isNotEmpty) return name;
    }
    if (u.fullName.trim().isNotEmpty) return u.fullName.trim();
    if (u.email.trim().isNotEmpty) return u.email.trim();
    return 'User';
  }

  int get _readyPhotoCount =>
      _photoStatus.where((s) => s == _OcrPhotoStatus.ready).length;
  int get _uploadedPhotoCount =>
      _photoStatus.where((s) => s == _OcrPhotoStatus.uploaded).length;
  int get _failedPhotoCount =>
      _photoStatus.where((s) => s == _OcrPhotoStatus.failed).length;

  /// Gallery-first pick: tapping a slot opens the gallery (multi-select).
  /// The first photo fills the tapped slot, the rest auto-fill the following
  /// empty slots in order, then wrap to earlier empties — pairing stays
  /// strictly positional without any per-row buttons.
  Future<void> _pickPhotosForSlot(int index) async {
    if (_isUploadingPhotos) return;
    final List<PickedFile> picked = await FilePickerUtil.pickImages();
    if (!mounted || picked.isEmpty) return;
    setState(() {
      int p = 0;
      void fill(int i) {
        _photos[i] = picked[p++];
        _photoStatus[i] = _OcrPhotoStatus.ready;
        _photoErrors[i] = '';
      }

      fill(index);
      for (int i = index + 1; i < _photos.length && p < picked.length; i++) {
        if (_photos[i] == null && _photoStatus[i] != _OcrPhotoStatus.uploaded) {
          fill(i);
        }
      }
      for (int i = 0; i < index && p < picked.length; i++) {
        if (_photos[i] == null && _photoStatus[i] != _OcrPhotoStatus.uploaded) {
          fill(i);
        }
      }
      if (p < picked.length) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${picked.length - p} extra photo(s) ignored — ${_photos.length} slot(s), pairing is by order shown.',
            ),
          ),
        );
      }
    });
  }

  /// Case A: extra supporting doc for the SAME person from the photo step.
  /// Appends via `POST /verification/humans/upload-doc` — never creates a
  /// new batch or new user.
  Future<void> _addExtraDocument(int index) async {
    if (index < 0 || index >= _serverUsers.length) return;
    if (_uploadingExtraDoc[index] || _isUploadingPhotos) return;
    final PickedFile? picked = await FilePickerUtil.pickDocument();
    if (!mounted || picked == null || picked.bytes.isEmpty) return;
    setState(() {
      _uploadingExtraDoc[index] = true;
      _extraDocErrors[index] = '';
    });
    try {
      final VerificationRepository repo = ref.read(
        verificationRepositoryProvider,
      );
      await repo.uploadHumanDocument(
        userId: _serverUsers[index].userId,
        documentLabel: 'document',
        fileBytes: picked.bytes,
        fileName: picked.name,
      );
      if (!mounted) return;
      setState(() {
        _uploadingExtraDoc[index] = false;
        _extraDocCounts[index] = _extraDocCounts[index] + 1;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Extra document added for ${_photoDisplayName(_serverUsers[index])}.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _uploadingExtraDoc[index] = false;
        _extraDocErrors[index] = _friendlyError(e);
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_friendlyError(e))));
    }
  }

  Future<void> _uploadPhotos() async {
    if (_isUploadingPhotos) return;
    final List<int> indices = <int>[];
    for (int i = 0; i < _photos.length; i++) {
      if (_photos[i] != null &&
          _photoStatus[i] != _OcrPhotoStatus.uploaded &&
          _photoStatus[i] != _OcrPhotoStatus.uploading) {
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
      _isUploadingPhotos = true;
      for (final int i in indices) {
        _photoStatus[i] = _OcrPhotoStatus.uploading;
        _photoErrors[i] = '';
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
            batchUserId: _serverUsers[i].userId,
            fileBytes: _photos[i]!.bytes,
            fileName: _photos[i]!.name,
          );
          if (!mounted) return;
          setState(() {
            _photoStatus[i] = _OcrPhotoStatus.uploaded;
            _photoVersions[i] = res.version;
          });
        } catch (e) {
          if (!mounted) return;
          setState(() {
            _photoStatus[i] = _OcrPhotoStatus.failed;
            _photoErrors[i] = _friendlyError(e);
          });
        }
      } else {
        final List<String> ids = <String>[
          for (final int i in indices) _serverUsers[i].userId,
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
              final String id = _serverUsers[i].userId;
              final OcrPhotoUploadResult? ok = okById[id];
              if (ok != null) {
                _photoStatus[i] = _OcrPhotoStatus.uploaded;
                _photoVersions[i] = ok.version;
                _photoErrors[i] = '';
              } else {
                _photoStatus[i] = _OcrPhotoStatus.failed;
                final String err = (errById[id] ?? 'Upload failed').trim();
                _photoErrors[i] = err.isEmpty ? 'Upload failed' : err;
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
              _photoStatus[i] = _OcrPhotoStatus.failed;
              _photoErrors[i] = _friendlyError(e);
            }
          });
        }
      }
    } finally {
      if (mounted) setState(() => _isUploadingPhotos = false);
    }
  }

  Future<void> _finishToCosting() async {
    final BulkUploadResponse? res = _uploadRes;
    if (res == null) return;
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

  String _friendlyError(Object e) {
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
      return 'Something went wrong. Please try again.';
    }
    return 'Something went wrong. Please try again.';
  }

  static String _prettyIndustry(String raw) {
    final String v = raw.trim();
    if (v.isEmpty) return 'Real Estate';
    final List<String> parts = v
        .replaceAll(RegExp(r'[_-]+'), ' ')
        .split(' ')
        .where((String p) => p.trim().isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'Real Estate';
    return parts
        .map(
          (String token) => token.isEmpty
              ? token
              : '${token[0].toUpperCase()}${token.substring(1).toLowerCase()}',
        )
        .join(' ');
  }

  // ----------------------------------------------------------------- ui ---

  /// Dark-background mode toggle for the page header.
  Widget _modeIconToggleLight() {
    const double optionWidth = 82;
    const double optionHeight = 34;
    const double padding = 3;
    final bool disabled = _isAddingDocs || _isUploadingDocs;
    final bool isSingle = _docMode == _OcrFlowMode.single;

    Widget opt(_OcrFlowMode m, IconData icon, String label) {
      final bool selected = _docMode == m;
      return Tooltip(
        message: label,
        child: InkWell(
          onTap: disabled ? null : () => setState(() => _docMode = m),
          borderRadius: BorderRadius.circular(999),
          child: SizedBox(
            width: optionWidth,
            height: optionHeight,
            child: Center(
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                style: AppTypography.caption.copyWith(
                  color: selected
                      ? AppColors.brandBlue
                      : Colors.white.withAlpha(disabled ? 95 : 175),
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Icon(
                      icon,
                      size: 15,
                      color: selected
                          ? AppColors.brandBlue
                          : Colors.white.withAlpha(disabled ? 95 : 175),
                    ),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 180),
      opacity: disabled ? 0.65 : 1,
      child: Container(
        width: optionWidth * 2 + padding * 2 + 2,
        height: optionHeight + padding * 2 + 2,
        padding: const EdgeInsets.all(padding),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(25),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white.withAlpha(70)),
        ),
        child: Stack(
          children: <Widget>[
            AnimatedAlign(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutBack,
              alignment: isSingle
                  ? Alignment.centerLeft
                  : Alignment.centerRight,
              child: Container(
                width: optionWidth,
                height: optionHeight,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: Colors.black.withAlpha(18),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                opt(_OcrFlowMode.single, Icons.person_rounded, 'Single'),
                opt(_OcrFlowMode.bulk, Icons.groups_2_rounded, 'Bulk'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const List<String> stepTitles = <String>[
      'Add documents',
      'Review OCR data',
      'Add photos',
    ];
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
                          InkWell(
                            onTap: () {
                              final GoRouter router = GoRouter.of(context);
                              if (router.canPop()) {
                                context.pop();
                              } else {
                                context.go(AppRouter.dashboardPath);
                              }
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: const SizedBox(
                              width: 32,
                              height: 32,
                              child: Icon(
                                Icons.arrow_back_ios_new_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Document Flow',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                height: 19.5 / 20,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          if (_step == 0) _modeIconToggleLight(),
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
                                  s(24),
                                  s(16),
                                  s(16),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Row(
                                      children: <Widget>[
                                        Text(
                                          'STEP ${_step + 1} OF 3',
                                          style: AppTypography.label.copyWith(
                                            color: AppColors.textTertiary,
                                          ),
                                        ),
                                        const Spacer(),
                                        if (_step == 2 &&
                                            _serverUsers.isNotEmpty)
                                          Text(
                                            '$_uploadedPhotoCount/${_serverUsers.length} done',
                                            style: AppTypography.caption
                                                .copyWith(
                                                  color: AppColors.brandBlue,
                                                  fontWeight: FontWeight.w800,
                                                ),
                                          ),
                                      ],
                                    ),
                                    SizedBox(height: s(8)),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(999),
                                      child: SizedBox(
                                        height: s(4),
                                        child: Stack(
                                          fit: StackFit.expand,
                                          children: <Widget>[
                                            const DecoratedBox(
                                              decoration: BoxDecoration(
                                                color: AppColors.divider,
                                              ),
                                            ),
                                            FractionallySizedBox(
                                              alignment: Alignment.centerLeft,
                                              widthFactor: (_step + 1) / 3,
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
                                    SizedBox(height: s(14)),
                                    Row(
                                      children: <Widget>[
                                        Expanded(
                                          child: Text(
                                            stepTitles[_step],
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: AppTypography.heading1
                                                .copyWith(
                                                  color: AppColors.textPrimary,
                                                ),
                                          ),
                                        ),
                                        if (_step == 0)
                                          Tooltip(
                                            message: 'Add user',
                                            child: InkWell(
                                              onTap:
                                                  (_isAddingDocs ||
                                                      _isUploadingDocs)
                                                  ? null
                                                  : _addManualUser,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              child: Container(
                                                width: 40,
                                                height: 40,
                                                decoration: BoxDecoration(
                                                  color: AppColors.blueTint,
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  border: Border.all(
                                                    color: AppColors.brandBlue
                                                        .withAlpha(90),
                                                  ),
                                                ),
                                                alignment: Alignment.center,
                                                child: Icon(
                                                  Icons
                                                      .person_add_alt_1_rounded,
                                                  size: 20,
                                                  color:
                                                      (_isAddingDocs ||
                                                          _isUploadingDocs)
                                                      ? AppColors.textTertiary
                                                            .withAlpha(120)
                                                      : AppColors.brandBlue,
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    SizedBox(height: s(16)),
                                    if (_step == 0) _docsSection(s),
                                    if (_step == 1) _reviewSection(),
                                    if (_step == 2) _photosSection(),
                                  ],
                                ),
                              ),
                            ),
                            _footer(s),
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

  Widget _footer(double Function(double v) s) {
    final bool busy = _isAddingDocs || _isUploadingDocs || _isSavingReview;
    if (_step == 0) {
      return Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.divider)),
        ),
        padding: EdgeInsets.fromLTRB(s(16), s(12), s(16), s(12)),
        child: SafeArea(
          top: false,
          child: TMZButton(
            label: _isUploadingDocs ? 'Uploading…' : 'Continue',
            icon: Icons.arrow_forward_rounded,
            isLoading: _isUploadingDocs,
            onPressed: busy ? null : _continueFromDocs,
          ),
        ),
      );
    }
    if (_step == 1) {
      return _footerBar(
        s,
        backLabel: 'Back',
        onBack: _isSavingReview ? null : () => setState(() => _step = 0),
        primary: TMZButton(
          label: _isSavingReview ? 'Saving…' : 'Confirm & continue',
          icon: Icons.check_rounded,
          isLoading: _isSavingReview,
          onPressed: _isSavingReview ? null : _confirmReview,
        ),
      );
    }
    final bool hasResult = _uploadedPhotoCount > 0 || _failedPhotoCount > 0;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      padding: EdgeInsets.fromLTRB(s(16), s(12), s(16), s(12)),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TMZButton(
              label: _isUploadingPhotos
                  ? 'Uploading…'
                  : hasResult
                  ? 'Continue • $_uploadedPhotoCount uploaded'
                  : _readyPhotoCount == 0
                  ? 'Skip photos'
                  : 'Upload ($_readyPhotoCount)',
              icon: hasResult
                  ? Icons.arrow_forward_rounded
                  : _readyPhotoCount == 0
                  ? Icons.skip_next_rounded
                  : Icons.cloud_upload_rounded,
              isLoading: _isUploadingPhotos,
              onPressed: _isUploadingPhotos
                  ? null
                  : hasResult
                  ? _finishToCosting
                  : _readyPhotoCount == 0
                  ? _finishToCosting
                  : _uploadPhotos,
            ),
            SizedBox(height: s(6)),
            Center(
              child: Text(
                hasResult
                    ? (_failedPhotoCount > 0
                          ? '($_failedPhotoCount failed — you can retry after continue)'
                          : '(photos saved — continue to costing)')
                    : '(photos are optional)',
                textAlign: TextAlign.center,
                style: AppTypography.caption.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _footerBar(
    double Function(double v) s, {
    required String backLabel,
    required VoidCallback? onBack,
    required TMZButton primary,
  }) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      padding: EdgeInsets.fromLTRB(s(16), s(12), s(16), s(12)),
      child: SafeArea(
        top: false,
        child: Row(
          children: <Widget>[
            Expanded(
              child: TMZButton(
                label: backLabel,
                icon: Icons.arrow_back_rounded,
                variant: TMZButtonVariant.secondary,
                onPressed: onBack,
                showShadow: false,
              ),
            ),
            SizedBox(width: s(10)),
            Expanded(flex: 2, child: primary),
          ],
        ),
      ),
    );
  }

  Widget _sectionBanner({
    required IconData icon,
    required Color color,
    required Color bg,
    required String title,
    required List<String> lines,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withAlpha(70)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.caption.copyWith(
                    color: color,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          for (final String line in lines.take(4))
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                line,
                style: AppTypography.caption.copyWith(color: color),
              ),
            ),
          if (lines.length > 4)
            Text(
              '+${lines.length - 4} more',
              style: AppTypography.caption.copyWith(color: color),
            ),
        ],
      ),
    );
  }

  // ------------------------------------------------------- step 0 docs ---

  Widget _docsSection(double Function(double v) s) {
    final bool busy = _isAddingDocs || _isUploadingDocs;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          '${_parsedUsers.length} user${_parsedUsers.length == 1 ? '' : 's'} — tap to select for attach',
          style: AppTypography.caption.copyWith(
            color: AppColors.textTertiary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _parsedUsers.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (BuildContext context, int i) {
            final bool selected = i == _selectedUserIndex;
            final List<_OcrDocDraft> userDocs = _docsForUser(i);
            final int docCount = userDocs.length;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                InkWell(
                  onTap: busy
                      ? null
                      : () => setState(() => _selectedUserIndex = i),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.blueTint.withAlpha(140)
                          : AppColors.offWhite,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: selected
                            ? AppColors.brandBlue
                            : AppColors.divider,
                        width: selected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: <Widget>[
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: selected
                                ? AppColors.brandBlue
                                : AppColors.blueTint,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${i + 1}',
                            style: AppTypography.heading2.copyWith(
                              color: selected
                                  ? Colors.white
                                  : AppColors.brandBlue,
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
                                _displayUserLabel(_parsedUsers[i], i),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.body2.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                docCount == 0
                                    ? 'No docs yet'
                                    : '$docCount doc${docCount == 1 ? '' : 's'} attached',
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.textTertiary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (selected)
                          const Icon(
                            Icons.check_circle_rounded,
                            size: 20,
                            color: AppColors.brandBlue,
                          ),
                        if (_parsedUsers.length > 1) ...<Widget>[
                          const SizedBox(width: 6),
                          IconButton(
                            onPressed: busy ? null : () => _removeUserAt(i),
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
                ),
                if (userDocs.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 8),
                  Column(
                    children: <Widget>[
                      for (int di = 0; di < userDocs.length; di++) ...<Widget>[
                        _ocrDocumentPreviewCard(
                          draft: userDocs[di],
                          busy: busy,
                          onRemove: () => setState(() {
                            final List<_OcrDocDraft>? docs =
                                _documentsByUser[i];
                            docs?.removeAt(di);
                            if (docs != null && docs.isEmpty) {
                              _documentsByUser.remove(i);
                            }
                          }),
                        ),
                        if (di < userDocs.length - 1)
                          const SizedBox(height: 10),
                      ],
                    ],
                  ),
                ],
              ],
            );
          },
        ),
        const SizedBox(height: 12),
        TMZButton(
          label: _isAddingDocs
              ? 'Reading…'
              : _docMode == _OcrFlowMode.single
              ? 'Add document (Single)'
              : 'Add documents (Bulk)',
          icon: Icons.attach_file_rounded,
          variant: TMZButtonVariant.secondary,
          isLoading: _isAddingDocs,
          onPressed: (_isAddingDocs || _isUploadingDocs) ? null : _addDocuments,
          showShadow: false,
        ),
        if (_isUploadingDocs && _docsStatus.isNotEmpty) ...<Widget>[
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.blueTint,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.divider),
            ),
            child: Row(
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
                    _docsStatus,
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
      ],
    );
  }

  Widget _ocrDocumentPreviewCard({
    required _OcrDocDraft draft,
    required bool busy,
    required VoidCallback onRemove,
  }) {
    final bool image = _isDocImage(draft.file.name);
    final String ext = draft.file.extension.trim().isNotEmpty
        ? draft.file.extension.trim().toUpperCase()
        : 'FILE';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.divider),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Stack(
            children: <Widget>[
              AspectRatio(
                aspectRatio: 16 / 10,
                child: Container(
                  width: double.infinity,
                  color: AppColors.blueTint.withAlpha(120),
                  alignment: Alignment.center,
                  child: image
                      ? Image.memory(
                          draft.file.bytes,
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.contain,
                          cacheWidth: 900,
                          filterQuality: FilterQuality.medium,
                        )
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            const Icon(
                              Icons.description_rounded,
                              size: 44,
                              color: AppColors.textTertiary,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              ext,
                              style: AppTypography.caption.copyWith(
                                color: AppColors.brandBlue,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              Positioned(
                right: 10,
                top: 10,
                child: InkWell(
                  onTap: busy ? null : onRemove,
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Row(
              children: <Widget>[
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.blueTint,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    image ? Icons.image_rounded : Icons.description_rounded,
                    size: 17,
                    color: AppColors.brandBlue,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    draft.file.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.brandBlue.withAlpha(14),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    ext,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.brandBlue,
                      fontWeight: FontWeight.w900,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _isDocImage(String fileName) {
    final String safe = fileName.toLowerCase();
    if (!safe.contains('.')) return false;
    return <String>{
      'jpg',
      'jpeg',
      'png',
      'webp',
      'gif',
    }.contains(safe.split('.').last);
  }

  // ----------------------------------------------------- step 1 review ---

  Widget _rfield(int pageIndex, String key, String label, {String? hint}) {
    final Map<String, TextEditingController> controllers =
        _reviewControllers[pageIndex];
    return TextFormField(
      controller: controllers[key],
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
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
      ),
      onChanged: (String value) => _reviewUsers[pageIndex][key] = value,
    );
  }

  Widget _reviewSection() {
    final BulkUploadResponse? res = _uploadRes;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (res != null && res.skippedUsers.isNotEmpty) ...<Widget>[
          _sectionBanner(
            icon: Icons.info_rounded,
            color: AppColors.warning,
            bg: AppColors.warningBg,
            title: 'Skipped ${res.skippedUsers.length} — excluded from photos',
            lines: <String>[
              for (final BulkUploadSkippedUser s in res.skippedUsers.take(5))
                'Doc ${s.row > 0 ? '#${s.row} ' : ''}• ${s.reason}',
            ],
          ),
          const SizedBox(height: 10),
        ],
        if (res != null && res.errors.isNotEmpty) ...<Widget>[
          _sectionBanner(
            icon: Icons.error_outline_rounded,
            color: AppColors.danger,
            bg: AppColors.dangerBg,
            title: '${res.errors.length} error(s)',
            lines: <String>[
              for (final BulkUploadErrorRow e in res.errors.take(5))
                'Doc ${e.row > 0 ? '#${e.row} ' : ''}• ${e.field.isNotEmpty ? '${e.field}: ' : ''}${e.error}',
            ],
          ),
          const SizedBox(height: 10),
        ],
        Text(
          _reviewUsers.length > 1
              ? 'Swipe sideways — ${_reviewUsers.length} users'
              : 'Review the details below',
          style: AppTypography.caption.copyWith(
            color: AppColors.textTertiary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        if (_reviewUsers.isEmpty)
          const Center(child: Text('No users to review.'))
        else
          SizedBox(
            height: 520,
            child: PageView.builder(
              itemCount: _reviewUsers.length,
              onPageChanged: (int v) => setState(() => _reviewIndex = v),
              itemBuilder: (BuildContext context, int pageIndex) {
                return SingleChildScrollView(child: _reviewCard(pageIndex));
              },
            ),
          ),
        if (_reviewUsers.length > 1) ...<Widget>[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              for (int d = 0; d < _reviewUsers.length; d++)
                Container(
                  width: d == _reviewIndex ? 22 : 7,
                  height: 7,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: d == _reviewIndex
                        ? AppColors.brandBlue
                        : AppColors.divider,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _reviewCard(int pageIndex) {
    final TextEditingController nameController =
        _reviewControllers[pageIndex]['full_name']!;
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.blueTint,
                  borderRadius: BorderRadius.circular(11),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${pageIndex + 1}',
                  style: AppTypography.heading2.copyWith(
                    color: AppColors.brandBlue,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    ValueListenableBuilder<TextEditingValue>(
                      valueListenable: nameController,
                      builder: (_, TextEditingValue v, _) {
                        final String name = v.text.trim();
                        return Text(
                          name.isEmpty ? 'User ${pageIndex + 1}' : name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.body2.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        );
                      },
                    ),
                    Text(
                      'User ${pageIndex + 1} of ${_reviewUsers.length}',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _rfield(pageIndex, 'full_name', 'Full name'),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: _rfield(pageIndex, 'phone_number', 'Phone number'),
              ),
              const SizedBox(width: 12),
              Expanded(child: _rfield(pageIndex, 'email', 'Email')),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: _rfield(pageIndex, 'dob', 'DOB', hint: 'YYYY-MM-DD'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _rfield(pageIndex, 'license_number', 'License number'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(child: _rfield(pageIndex, 'aadhar_number', 'Aadhaar')),
              const SizedBox(width: 12),
              Expanded(child: _rfield(pageIndex, 'pan_number', 'PAN')),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(child: _rfield(pageIndex, 'pincode', 'Pincode')),
              const SizedBox(width: 12),
              Expanded(child: _rfield(pageIndex, 'state', 'State')),
            ],
          ),
          const SizedBox(height: 12),
          _rfield(pageIndex, 'address_line1', 'Address line 1'),
          const SizedBox(height: 12),
          _rfield(pageIndex, 'address_line2', 'Address line 2'),
          const SizedBox(height: 12),
          _rfield(pageIndex, 'address_line3', 'Address line 3'),
          const SizedBox(height: 12),
          _rfield(pageIndex, 'country', 'Country'),
        ],
      ),
    );
  }

  // ----------------------------------------------------- step 2 photos ---

  Widget _photosSection() {
    final BulkUploadResponse? res = _uploadRes;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (res != null && res.totalSkipped > 0) ...<Widget>[
          _sectionBanner(
            icon: Icons.info_rounded,
            color: AppColors.warning,
            bg: AppColors.warningBg,
            title: '${res.totalSkipped} skipped — no photo slot needed.',
            lines: <String>[
              for (final BulkUploadSkippedUser s in res.skippedUsers.take(4))
                'Doc ${s.row > 0 ? '#${s.row} ' : ''}• ${s.reason}',
            ],
          ),
          const SizedBox(height: 10),
        ],
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _serverUsers.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (BuildContext context, int i) {
            final BulkUploadSuccessUser u = _serverUsers[i];
            final PickedFile? photo = _photos[i];
            final bool uploading = _photoStatus[i] == _OcrPhotoStatus.uploading;
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
                  Tooltip(
                    message: uploading
                        ? 'Uploading…'
                        : photo == null
                        ? 'Tap to add photo'
                        : 'Tap to change photo',
                    child: InkWell(
                      onTap: uploading ? null : () => _pickPhotosForSlot(i),
                      borderRadius: BorderRadius.circular(16),
                      child: Stack(
                        children: <Widget>[
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: AppColors.blueTint,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: photo != null
                                    ? AppColors.brandBlue.withAlpha(120)
                                    : AppColors.divider,
                              ),
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
                                    Icons.add_a_photo_rounded,
                                    color: AppColors.textTertiary,
                                    size: 24,
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
                          if (photo != null && !uploading)
                            Positioned(
                              right: 0,
                              top: 0,
                              child: InkWell(
                                onTap: () => setState(() {
                                  _photos[i] = null;
                                  if (_photoStatus[i] !=
                                      _OcrPhotoStatus.uploaded) {
                                    _photoStatus[i] = _OcrPhotoStatus.pending;
                                  }
                                  _photoErrors[i] = '';
                                }),
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
                        ],
                      ),
                    ),
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
                              child: InkWell(
                                onTap: uploading
                                    ? null
                                    : () => _showPhotoUserSheet(i),
                                borderRadius: BorderRadius.circular(12),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 2,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(
                                        _photoDisplayName(u),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppTypography.body2.copyWith(
                                          color: AppColors.textPrimary,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      Text(
                                        'Slot ${i + 1} of ${_serverUsers.length} • tap for details',
                                        style: AppTypography.caption.copyWith(
                                          color: AppColors.textTertiary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right_rounded,
                              size: 18,
                              color: AppColors.textTertiary,
                            ),
                            const SizedBox(width: 4),
                            _photoBadge(i),
                          ],
                        ),
                        if (_photoStatus[i] == _OcrPhotoStatus.failed &&
                            _photoErrors[i].isNotEmpty) ...<Widget>[
                          const SizedBox(height: 6),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              const Icon(
                                Icons.error_rounded,
                                size: 13,
                                color: AppColors.danger,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  _photoErrors[i],
                                  style: AppTypography.caption.copyWith(
                                    color: AppColors.danger,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 2),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed:
                                (_uploadingExtraDoc.length > i &&
                                    _uploadingExtraDoc[i])
                                ? null
                                : () => _addExtraDocument(i),
                            icon: Icon(
                              _uploadingExtraDoc.length > i &&
                                      _uploadingExtraDoc[i]
                                  ? Icons.sync_rounded
                                  : Icons.attach_file_rounded,
                              size: 15,
                            ),
                            label: Text(
                              (_uploadingExtraDoc.length > i &&
                                      _uploadingExtraDoc[i])
                                  ? 'Adding…'
                                  : (_extraDocCounts.length > i &&
                                        _extraDocCounts[i] > 0)
                                  ? 'Add doc (+${_extraDocCounts[i]})'
                                  : 'Add documents',
                              style: AppTypography.caption.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.textSecondary,
                              side: const BorderSide(
                                color: AppColors.divider,
                                width: 1.2,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 9),
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                        ),
                        if (_extraDocErrors.length > i &&
                            _extraDocErrors[i].isNotEmpty) ...<Widget>[
                          const SizedBox(height: 4),
                          Text(
                            _extraDocErrors[i],
                            style: AppTypography.caption.copyWith(
                              color: AppColors.danger,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  /// User preview sheet: tapped from a photo row. Shows the reviewed info
  /// plus the source document(s) that created this user (small thumbs).
  Future<void> _showPhotoUserSheet(int index) async {
    final BulkUploadSuccessUser u = _serverUsers[index];
    final Map<String, int> reverse = <String, int>{
      for (final MapEntry<int, String> e in _userIdsByIndex.entries)
        e.value: e.key,
    };
    final int? local = reverse[u.userId];
    final Map<String, dynamic> info =
        (local != null && local >= 0 && local < _reviewUsers.length)
        ? _reviewUsers[local]
        : <String, dynamic>{};
    final List<_OcrDocDraft> docs = local == null
        ? <_OcrDocDraft>[]
        : List<_OcrDocDraft>.of(_docsForUser(local));

    String v(String key) => (info[key] ?? '').toString().trim();
    final String address = <String>[
      v('address_line1'),
      v('address_line2'),
      v('address_line3'),
      v('pincode'),
      v('state'),
      v('country'),
    ].where((String e) => e.isNotEmpty).join(', ');
    final List<MapEntry<String, String>> rows = <MapEntry<String, String>>[
      if (v('email').isNotEmpty) MapEntry('Email', v('email')),
      if (v('phone_number').isNotEmpty) MapEntry('Phone', v('phone_number')),
      if (v('dob').isNotEmpty) MapEntry('DOB', v('dob')),
      if (v('aadhar_number').isNotEmpty)
        MapEntry('Aadhaar', v('aadhar_number')),
      if (v('pan_number').isNotEmpty) MapEntry('PAN', v('pan_number')),
      if (address.isNotEmpty) MapEntry('Address', address),
    ];
    final PickedFile? photo = _photos[index];

    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: AppColors.cardSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext sheetContext) => SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: <Widget>[
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.blueTint,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.divider),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: photo != null
                        ? Image.memory(
                            photo.bytes,
                            fit: BoxFit.cover,
                            cacheWidth: 128,
                            cacheHeight: 128,
                            filterQuality: FilterQuality.low,
                          )
                        : const Icon(
                            Icons.person_rounded,
                            color: AppColors.textTertiary,
                            size: 26,
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          _photoDisplayName(u),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.heading2.copyWith(fontSize: 16),
                        ),
                        Text(
                          'Slot ${index + 1} of ${_serverUsers.length}',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _photoBadge(index),
                ],
              ),
              if (rows.isNotEmpty) ...<Widget>[
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.offWhite,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Column(
                    children: <Widget>[
                      for (int r = 0; r < rows.length; r++) ...<Widget>[
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Expanded(
                                flex: 2,
                                child: Text(
                                  rows[r].key,
                                  style: AppTypography.caption.copyWith(
                                    color: AppColors.textTertiary,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: Text(
                                  rows[r].value,
                                  style: AppTypography.body2.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (r < rows.length - 1)
                          const Divider(height: 1, color: AppColors.divider),
                      ],
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 14),
              Text(
                'SOURCE DOCUMENTS (${docs.length})',
                style: AppTypography.label.copyWith(
                  color: AppColors.textTertiary,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 8),
              if (docs.isEmpty)
                Text(
                  'No source documents found for this user.',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                )
              else
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: <Widget>[
                    for (final _OcrDocDraft d in docs)
                      SizedBox(
                        width: 72,
                        child: Column(
                          children: <Widget>[
                            Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                color: AppColors.blueTint,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.divider),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: _isPreviewImage(d.file.name)
                                  ? Image.memory(
                                      d.file.bytes,
                                      fit: BoxFit.cover,
                                      cacheWidth: 144,
                                      cacheHeight: 144,
                                      filterQuality: FilterQuality.low,
                                    )
                                  : const Icon(
                                      Icons.description_rounded,
                                      color: AppColors.textTertiary,
                                    ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              d.file.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: AppTypography.caption.copyWith(
                                color: AppColors.textTertiary,
                                fontSize: 10,
                              ),
                            ),
                          ],
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

  bool _isPreviewImage(String fileName) {
    final String safe = fileName.toLowerCase();
    if (!safe.contains('.')) return false;
    return <String>{
      'jpg',
      'jpeg',
      'png',
      'webp',
      'gif',
    }.contains(safe.split('.').last);
  }

  Widget _photoBadge(int index) {
    switch (_photoStatus[index]) {
      case _OcrPhotoStatus.uploaded:
        return TMZBadge.complete(
          label: _photoVersions[index] > 0
              ? 'Uploaded • v${_photoVersions[index]}'
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
}

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/tmz_button.dart';
import '../../../../core/widgets/tmz_card.dart';

class MapCredentialFieldsPage extends StatefulWidget {
  const MapCredentialFieldsPage({super.key});

  @override
  State<MapCredentialFieldsPage> createState() =>
      _MapCredentialFieldsPageState();
}

class _MapCredentialFieldsPageState extends State<MapCredentialFieldsPage> {
  bool _didInitFromRoute = false;

  String _templateId = 't1';
  List<String> _columns = <String>[
    'full_name',
    'dob',
    'id_number',
    'phone',
    'email',
    'address',
  ];
  List<_CredentialField> _fields = const <_CredentialField>[];

  final Map<String, String?> _mapping = <String, String?>{};
  final Set<String> _faceFieldIds = <String>{};
  bool _previewApproved = false;

  @override
  void initState() {
    super.initState();
    _fields = _fieldsForTemplate(_templateId);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInitFromRoute) return;
    _didInitFromRoute = true;

    final Map<String, String> qp = GoRouterState.of(
      context,
    ).uri.queryParameters;
    _templateId = (qp['template'] ?? 't1').toLowerCase();
    _columns = _parseColumns(qp['columns']) ?? _columns;
    _fields = _fieldsForTemplate(_templateId);

    // Pre-fill mapping for common headers.
    _mapping.clear();
    for (final _CredentialField f in _fields) {
      _mapping[f.id] = _bestMatchColumn(f.suggestedColumns);
    }

    // Default face fields: 5–6 best candidates.
    _faceFieldIds
      ..clear()
      ..addAll(<String>[
        for (final _CredentialField f in _fields)
          if (f.defaultOnFace) f.id,
      ]);
    while (_faceFieldIds.length > 6) {
      _faceFieldIds.remove(_faceFieldIds.last);
    }
    for (final _CredentialField f in _fields) {
      if (_faceFieldIds.length >= 5) break;
      _faceFieldIds.add(f.id);
    }
    while (_faceFieldIds.length > 6) {
      _faceFieldIds.remove(_faceFieldIds.last);
    }

    setState(() {});
  }

  static List<String>? _parseColumns(String? raw) {
    if (raw == null) return null;
    final List<String> columns =
        raw
            .split(',')
            .map((String s) => s.trim())
            .where((String s) => s.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    return columns.isEmpty ? null : columns;
  }

  String? _bestMatchColumn(List<String> candidates) {
    for (final String c in candidates) {
      final String match = _columns.firstWhere(
        (String col) => col.toLowerCase() == c.toLowerCase(),
        orElse: () => '',
      );
      if (match.isNotEmpty) return match;
    }
    return null;
  }

  bool get _requiredMapped => _fields
      .where((f) => f.required)
      .every((f) => (_mapping[f.id] ?? '').trim().isNotEmpty);

  bool get _faceCountValid =>
      _faceFieldIds.length >= 5 && _faceFieldIds.length <= 6;

  bool get _canGenerate =>
      _previewApproved && _requiredMapped && _faceCountValid;

  void _toggleFaceField(String fieldId, bool value) {
    setState(() {
      if (value) {
        if (_faceFieldIds.length >= 6) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'You can show at most 6 fields on the credential face.',
              ),
            ),
          );
          return;
        }
        _faceFieldIds.add(fieldId);
      } else {
        if (_faceFieldIds.length <= 5) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Select at least 5 fields for the credential face.',
              ),
            ),
          );
          return;
        }
        _faceFieldIds.remove(fieldId);
      }
    });
  }

  void _generate(BuildContext context) {
    if (!_canGenerate) return;

    final Map<String, String> qp = Map<String, String>.from(
      GoRouterState.of(context).uri.queryParameters,
    );
    qp['template'] = _templateId;
    qp['face'] = _faceFieldIds.join(',');
    qp.putIfAbsent('created', () => qp['records'] ?? '80');
    final String qs = qp.entries
        .map(
          (MapEntry<String, String> e) =>
              '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}',
        )
        .join('&');
    context.push(
      qs.isEmpty
          ? AppRouter.batchJobRunningPath
          : '${AppRouter.batchJobRunningPath}?$qs',
    );
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: <Widget>[
            SvgPicture.asset(
              'assets/icons/trumarkz_shield.svg',
              height: 22,
              colorFilter: ColorFilter.mode(scheme.primary, BlendMode.srcIn),
            ),
            const SizedBox(width: AppSpacing.x2),
            const Text('Map Credential Fields'),
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
                  Text('Map fields', style: AppTypography.display2),
                  const SizedBox(height: AppSpacing.x2),
                  Text(
                    'Map your uploaded columns to credential fields, choose 5–6 fields for the credential face, and approve the preview.',
                    style: AppTypography.body2.copyWith(
                      color: scheme.onSurface.withAlpha(160),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.x4),
                  LayoutBuilder(
                    builder:
                        (BuildContext context, BoxConstraints constraints) {
                          final bool wide = constraints.maxWidth >= 980;
                          final Widget mapping = _MappingList(
                            columns: _columns,
                            fields: _fields,
                            mapping: _mapping,
                            faceFieldIds: _faceFieldIds,
                            onMappingChanged: (String fieldId, String? column) {
                              setState(() => _mapping[fieldId] = column);
                            },
                            onFaceChanged: _toggleFaceField,
                          );
                          final Widget preview = _PreviewCard(
                            templateId: _templateId,
                            fields: _fields,
                            mapping: _mapping,
                            faceFieldIds: _faceFieldIds,
                            columns: _columns,
                            requiredMapped: _requiredMapped,
                            faceCountValid: _faceCountValid,
                            approved: _previewApproved,
                            onApprovedChanged: (bool value) =>
                                setState(() => _previewApproved = value),
                          );

                          if (!wide) {
                            return Column(
                              children: <Widget>[
                                mapping,
                                const SizedBox(height: AppSpacing.x4),
                                preview,
                              ],
                            );
                          }

                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Expanded(flex: 3, child: mapping),
                              const SizedBox(width: AppSpacing.x4),
                              Expanded(flex: 2, child: preview),
                            ],
                          );
                        },
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
                  label: 'Generate Credentials',
                  icon: Icons.rocket_launch_rounded,
                  onPressed: _canGenerate ? () => _generate(context) : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MappingList extends StatelessWidget {
  const _MappingList({
    required this.columns,
    required this.fields,
    required this.mapping,
    required this.faceFieldIds,
    required this.onMappingChanged,
    required this.onFaceChanged,
  });

  final List<String> columns;
  final List<_CredentialField> fields;
  final Map<String, String?> mapping;
  final Set<String> faceFieldIds;
  final void Function(String fieldId, String? column) onMappingChanged;
  final void Function(String fieldId, bool value) onFaceChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        for (final _CredentialField field in fields) ...<Widget>[
          TMZCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(field.label, style: AppTypography.heading2),
                    ),
                    if (field.required)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.error.withAlpha(18),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: AppColors.error.withAlpha(60),
                          ),
                        ),
                        child: Text(
                          'REQUIRED',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.error,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.x2),
                DropdownButtonFormField<String?>(
                  key: ValueKey<String?>(mapping[field.id]),
                  initialValue: mapping[field.id],
                  isExpanded: true,
                  items: <DropdownMenuItem<String?>>[
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Select column'),
                    ),
                    ...columns.map(
                      (String c) =>
                          DropdownMenuItem<String?>(value: c, child: Text(c)),
                    ),
                  ],
                  onChanged: (String? value) =>
                      onMappingChanged(field.id, value),
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.x2),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        'Show on credential face',
                        style: AppTypography.body2.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Switch.adaptive(
                      value: faceFieldIds.contains(field.id),
                      onChanged: (bool v) => onFaceChanged(field.id, v),
                      activeTrackColor: AppColors.brandBlue,
                      activeThumbColor: Colors.white,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.x3),
        ],
      ],
    );
  }
}

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({
    required this.templateId,
    required this.fields,
    required this.mapping,
    required this.faceFieldIds,
    required this.columns,
    required this.requiredMapped,
    required this.faceCountValid,
    required this.approved,
    required this.onApprovedChanged,
  });

  final String templateId;
  final List<_CredentialField> fields;
  final Map<String, String?> mapping;
  final Set<String> faceFieldIds;
  final List<String> columns;
  final bool requiredMapped;
  final bool faceCountValid;
  final bool approved;
  final ValueChanged<bool> onApprovedChanged;

  Map<String, String> get _sampleValues => <String, String>{
    'full_name': 'Ravi Kumar',
    'name': 'Ravi Kumar',
    'dob': '1997-06-12',
    'id_number': 'ID-298172',
    'phone': '+91 98XXXXXX21',
    'email': 'admin@org.com',
    'address': 'Bengaluru, IN',
    'employer': 'TruMarkZ Logistics',
    'role': 'Driver',
    'license': 'RN-88312',
    'institute': 'National College',
    'course': 'B.Sc',
    'product_id': 'PRD-9921',
  };

  String _valueForColumn(String? column) {
    if (column == null || column.isEmpty) return '—';
    return _sampleValues[column] ?? 'Sample';
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final List<_CredentialField> faceFields = <_CredentialField>[
      for (final _CredentialField f in fields)
        if (faceFieldIds.contains(f.id)) f,
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outlineVariant.withAlpha(160)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withAlpha(6),
            blurRadius: 18,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppSpacing.x4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(Icons.preview_rounded, color: AppColors.brandBlue),
              const SizedBox(width: AppSpacing.x2),
              Text('Live Preview', style: AppTypography.heading2),
            ],
          ),
          const SizedBox(height: AppSpacing.x3),
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[Color(0xFF2D6BFF), Color(0xFF0B45C8)],
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            padding: const EdgeInsets.all(AppSpacing.x4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Template ${templateId.toUpperCase()}',
                  style: AppTypography.caption.copyWith(
                    color: Colors.white.withAlpha(220),
                    letterSpacing: 1,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.x2),
                ...faceFields.map((f) {
                  final String? col = mapping[f.id];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            f.label,
                            style: AppTypography.body2.copyWith(
                              color: Colors.white.withAlpha(210),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.x2),
                        Text(
                          _valueForColumn(col),
                          style: AppTypography.body2.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                if (faceFields.isEmpty)
                  Text(
                    'Select 5–6 fields to show on the credential face.',
                    style: AppTypography.body2.copyWith(
                      color: Colors.white.withAlpha(210),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.x3),
          _StatusLine(
            ok: requiredMapped,
            text: requiredMapped
                ? 'Required fields mapped'
                : 'Map all required fields to continue',
          ),
          const SizedBox(height: AppSpacing.x2),
          _StatusLine(
            ok: faceCountValid,
            text: faceCountValid
                ? 'Credential face fields selected (${faceFieldIds.length}/6)'
                : 'Select 5–6 fields for the credential face (${faceFieldIds.length}/6)',
          ),
          const SizedBox(height: AppSpacing.x3),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFEFF3FF),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFD9E3FF)),
            ),
            padding: const EdgeInsets.all(AppSpacing.x3),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Checkbox.adaptive(
                  value: approved,
                  onChanged: (bool? v) => onApprovedChanged(v ?? false),
                  activeColor: AppColors.brandBlue,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                const SizedBox(width: AppSpacing.x1),
                Expanded(
                  child: Text(
                    'I reviewed and approve the credential preview.',
                    style: AppTypography.body2.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.3,
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
}

class _StatusLine extends StatelessWidget {
  const _StatusLine({required this.ok, required this.text});

  final bool ok;
  final String text;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Color color = ok
        ? AppColors.success
        : scheme.onSurface.withAlpha(140);

    return Row(
      children: <Widget>[
        Icon(
          ok ? Icons.check_circle_rounded : Icons.info_outline_rounded,
          size: 18,
          color: color,
        ),
        const SizedBox(width: AppSpacing.x2),
        Expanded(
          child: Text(
            text,
            style: AppTypography.body2.copyWith(
              color: scheme.onSurface.withAlpha(170),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _CredentialField {
  const _CredentialField({
    required this.id,
    required this.label,
    required this.required,
    required this.suggestedColumns,
    this.defaultOnFace = false,
  });

  final String id;
  final String label;
  final bool required;
  final List<String> suggestedColumns;
  final bool defaultOnFace;
}

List<_CredentialField> _fieldsForTemplate(String templateId) {
  switch (templateId) {
    case 't2':
      return const <_CredentialField>[
        _CredentialField(
          id: 'full_name',
          label: 'Full Name',
          required: true,
          suggestedColumns: <String>['full_name', 'name'],
          defaultOnFace: true,
        ),
        _CredentialField(
          id: 'license',
          label: 'License / Registration ID',
          required: true,
          suggestedColumns: <String>['license', 'license_id', 'reg_id'],
          defaultOnFace: true,
        ),
        _CredentialField(
          id: 'role',
          label: 'Role',
          required: false,
          suggestedColumns: <String>['role', 'designation'],
          defaultOnFace: true,
        ),
        _CredentialField(
          id: 'email',
          label: 'Email',
          required: false,
          suggestedColumns: <String>['email'],
          defaultOnFace: true,
        ),
        _CredentialField(
          id: 'phone',
          label: 'Phone',
          required: false,
          suggestedColumns: <String>['phone', 'mobile'],
          defaultOnFace: true,
        ),
        _CredentialField(
          id: 'address',
          label: 'Address',
          required: false,
          suggestedColumns: <String>['address'],
        ),
      ];
    case 't3':
      return const <_CredentialField>[
        _CredentialField(
          id: 'full_name',
          label: 'Full Name',
          required: true,
          suggestedColumns: <String>['full_name', 'name'],
          defaultOnFace: true,
        ),
        _CredentialField(
          id: 'id_number',
          label: 'Student ID',
          required: true,
          suggestedColumns: <String>['id_number', 'student_id'],
          defaultOnFace: true,
        ),
        _CredentialField(
          id: 'institute',
          label: 'Institute',
          required: true,
          suggestedColumns: <String>['institute', 'college', 'school'],
          defaultOnFace: true,
        ),
        _CredentialField(
          id: 'course',
          label: 'Course',
          required: false,
          suggestedColumns: <String>['course', 'program'],
          defaultOnFace: true,
        ),
        _CredentialField(
          id: 'dob',
          label: 'Date of Birth',
          required: false,
          suggestedColumns: <String>['dob', 'date_of_birth'],
          defaultOnFace: true,
        ),
        _CredentialField(
          id: 'email',
          label: 'Email',
          required: false,
          suggestedColumns: <String>['email'],
        ),
      ];
    case 't4':
      return const <_CredentialField>[
        _CredentialField(
          id: 'product_id',
          label: 'Product ID',
          required: true,
          suggestedColumns: <String>['product_id', 'sku'],
          defaultOnFace: true,
        ),
        _CredentialField(
          id: 'id_number',
          label: 'Batch / Lot',
          required: true,
          suggestedColumns: <String>['batch', 'lot', 'id_number'],
          defaultOnFace: true,
        ),
        _CredentialField(
          id: 'full_name',
          label: 'Manufacturer',
          required: false,
          suggestedColumns: <String>['manufacturer', 'org', 'full_name'],
          defaultOnFace: true,
        ),
        _CredentialField(
          id: 'dob',
          label: 'MFG Date',
          required: false,
          suggestedColumns: <String>['mfg_date', 'dob'],
          defaultOnFace: true,
        ),
        _CredentialField(
          id: 'address',
          label: 'Origin',
          required: false,
          suggestedColumns: <String>['origin', 'address'],
          defaultOnFace: true,
        ),
        _CredentialField(
          id: 'email',
          label: 'Compliance Doc URL',
          required: false,
          suggestedColumns: <String>['doc_url', 'email'],
        ),
      ];
    case 't5':
      return const <_CredentialField>[
        _CredentialField(
          id: 'full_name',
          label: 'Full Name',
          required: true,
          suggestedColumns: <String>['full_name', 'name'],
          defaultOnFace: true,
        ),
        _CredentialField(
          id: 'role',
          label: 'Profession',
          required: true,
          suggestedColumns: <String>['profession', 'role'],
          defaultOnFace: true,
        ),
        _CredentialField(
          id: 'id_number',
          label: 'Professional ID',
          required: true,
          suggestedColumns: <String>['id_number', 'pro_id'],
          defaultOnFace: true,
        ),
        _CredentialField(
          id: 'email',
          label: 'Email',
          required: false,
          suggestedColumns: <String>['email'],
          defaultOnFace: true,
        ),
        _CredentialField(
          id: 'phone',
          label: 'Phone',
          required: false,
          suggestedColumns: <String>['phone', 'mobile'],
          defaultOnFace: true,
        ),
        _CredentialField(
          id: 'address',
          label: 'Location',
          required: false,
          suggestedColumns: <String>['location', 'address'],
        ),
      ];
    case 't6':
      return const <_CredentialField>[
        _CredentialField(
          id: 'full_name',
          label: 'Full Name',
          required: true,
          suggestedColumns: <String>['full_name', 'name'],
          defaultOnFace: true,
        ),
        _CredentialField(
          id: 'role',
          label: 'Skill',
          required: true,
          suggestedColumns: <String>['skill', 'role'],
          defaultOnFace: true,
        ),
        _CredentialField(
          id: 'id_number',
          label: 'Level',
          required: true,
          suggestedColumns: <String>['level', 'id_number'],
          defaultOnFace: true,
        ),
        _CredentialField(
          id: 'email',
          label: 'Issuer',
          required: false,
          suggestedColumns: <String>['issuer', 'email'],
          defaultOnFace: true,
        ),
        _CredentialField(
          id: 'dob',
          label: 'Issued On',
          required: false,
          suggestedColumns: <String>['issued_on', 'dob'],
          defaultOnFace: true,
        ),
        _CredentialField(
          id: 'address',
          label: 'Endorsements',
          required: false,
          suggestedColumns: <String>['endorsements', 'address'],
        ),
      ];
    case 't1':
    default:
      return const <_CredentialField>[
        _CredentialField(
          id: 'full_name',
          label: 'Full Name',
          required: true,
          suggestedColumns: <String>['full_name', 'name'],
          defaultOnFace: true,
        ),
        _CredentialField(
          id: 'dob',
          label: 'Date of Birth',
          required: true,
          suggestedColumns: <String>['dob', 'date_of_birth'],
          defaultOnFace: true,
        ),
        _CredentialField(
          id: 'id_number',
          label: 'ID Number',
          required: true,
          suggestedColumns: <String>['id_number', 'employee_id'],
          defaultOnFace: true,
        ),
        _CredentialField(
          id: 'role',
          label: 'Role',
          required: false,
          suggestedColumns: <String>['role', 'designation'],
          defaultOnFace: true,
        ),
        _CredentialField(
          id: 'phone',
          label: 'Phone',
          required: false,
          suggestedColumns: <String>['phone', 'mobile'],
          defaultOnFace: true,
        ),
        _CredentialField(
          id: 'email',
          label: 'Email',
          required: false,
          suggestedColumns: <String>['email'],
        ),
        _CredentialField(
          id: 'address',
          label: 'Address',
          required: false,
          suggestedColumns: <String>['address'],
        ),
      ];
  }
}

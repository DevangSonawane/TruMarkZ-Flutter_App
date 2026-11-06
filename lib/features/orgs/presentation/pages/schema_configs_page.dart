import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../../../../core/models/schema_config_models.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/services/token_storage.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/tmz_button.dart';
import '../../../../core/widgets/tmz_input.dart';
import '../../../../core/widgets/tmz_sheets.dart';
import '../../../auth/application/auth_notifier.dart';
import '../../data/verification_repository.dart';

/// Settings → Custom Schemas. The organization's dynamic schema
/// configurations (`/auth/organizations/{org_id}/schema-configs`,
/// dynamic_schema_flutter_trumarkz.md §15–§16): list, create from a pasted
/// sample record, edit (new version), set default and deactivate.
///
/// Configurations a SuperAdmin created or last edited are read-only here —
/// the backend answers 403 for any change to them.
///
/// Styled like the other Settings sub-pages (white app bar, bordered cards).
/// These pages sit inside the org shell, so scroll content keeps clearance
/// for the floating bottom nav.
class SchemaConfigsPage extends ConsumerStatefulWidget {
  const SchemaConfigsPage({super.key});

  @override
  ConsumerState<SchemaConfigsPage> createState() => _SchemaConfigsPageState();
}

const Color _navy = Color(0xFF1B3387);
const Color _ink = Color(0xFF0F172A);
const Color _rowTitle = Color(0xFF202124);
const Color _muted = Color(0xFF64748B);
const Color _hairline = Color(0xFFF1F5F9);

/// Room for the floating bottom nav pill (71px) plus breathing space.
const double _navClearance = 120;

/// Semantic fields `input_map` may target per space type (backend
/// `INPUT_SEMANTIC_FIELDS`). `warrenty_period` is the API's real spelling.
const Map<String, List<String>> _semanticFields = <String, List<String>>{
  'human': <String>[
    'full_name',
    'email',
    'phone_number',
    'dob',
    'dl_number',
    'nationality',
  ],
  'product': <String>['product_name', 'model_no', 'brand', 'sku_no'],
  'warranty': <String>[
    'product_name',
    'model_no',
    'brand',
    'manufactured_by',
    'manufactured_date',
    'warrenty_period',
    'coverage',
    'product_details',
  ],
};

const Map<String, String> _spaceTypeLabels = <String, String>{
  'human': 'People',
  'product': 'Product',
  'warranty': 'Warranty',
};

const Map<String, IconData> _spaceTypeIcons = <String, IconData>{
  'human': Icons.badge_outlined,
  'product': Icons.inventory_2_outlined,
  'warranty': Icons.verified_outlined,
};

const Map<String, String> _exampleRecords = <String, String>{
  'human':
      '{\n  "name": "Asha Rao",\n  "email": "asha@example.com",\n'
      '  "phone": "+919800000000",\n  "employee_id": "EMP-1042"\n}',
  'product':
      '{\n  "product_name": "Steel Bottle",\n  "sku_no": "SB-750",\n'
      '  "brand": "Acme",\n  "colour": "Silver"\n}',
  'warranty':
      '{\n  "product_name": "Air Purifier",\n  "model_no": "AP-200",\n'
      '  "warrenty_period": "24 months"\n}',
};

String _orgId(WidgetRef ref) =>
    ref.read(authNotifierProvider).valueOrNull?.userProfile?.id ?? '';

PreferredSizeWidget _settingsAppBar(
  BuildContext context, {
  required String title,
  List<Widget> actions = const <Widget>[],
  VoidCallback? onBack,
}) {
  return AppBar(
    backgroundColor: Colors.white,
    elevation: 0,
    scrolledUnderElevation: 0,
    leading: IconButton(
      onPressed: onBack ?? () => context.pop(),
      icon: const Icon(Icons.chevron_left_rounded, color: _ink),
    ),
    title: Text(
      title,
      style: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: _ink,
      ),
    ),
    actions: actions,
  );
}

class _SchemaConfigsPageState extends ConsumerState<SchemaConfigsPage> {
  AsyncValue<List<SchemaConfig>> _configs = const AsyncLoading();
  bool _showInactive = false;
  final Set<String> _busy = <String>{};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final String orgId = _orgId(ref);
    if (orgId.isEmpty) {
      setState(
        () => _configs = AsyncError(
          const ApiException(
            statusCode: null,
            message: 'Sign in again to manage schemas.',
          ),
          StackTrace.current,
        ),
      );
      return;
    }
    try {
      final List<SchemaConfig> list = await ref
          .read(verificationRepositoryProvider)
          .getSchemaConfigs(orgId: orgId, activeOnly: false);
      if (!mounted) return;
      setState(() => _configs = AsyncData(list));
    } catch (e, st) {
      if (!mounted) return;
      setState(() => _configs = AsyncError(e, st));
    }
    // Upload screens read the cached active list for the default schema.
    for (final String type in _semanticFields.keys) {
      ref.invalidate(schemaConfigsProvider('$orgId::$type'));
    }
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openEditor({SchemaConfig? existing}) async {
    // A real shell route, so the bottom nav (Dashboard/Profile) still works.
    final bool? saved = await context.push<bool>(
      AppRouter.settingsSchemaEditorPath,
      extra: existing,
    );
    if (saved == true) await _load();
  }

  Future<void> _showSchemaInfo() => showDialog<void>(
    context: context,
    barrierColor: const Color(0x330F172A),
    builder: (BuildContext dialogContext) => Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 20, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  width: 38,
                  height: 38,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEFF3FF),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.info_outline_rounded, color: _navy),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'About custom schemas',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: _ink,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  icon: const Icon(Icons.close_rounded),
                  color: _muted,
                  tooltip: 'Close',
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.only(top: 18, right: 6),
              child: _SchemaInfoContent(),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                style: FilledButton.styleFrom(
                  backgroundColor: _navy,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Got it',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Future<void> _run(
    SchemaConfig config,
    Future<void> Function() action,
    String success,
  ) async {
    if (_busy.contains(config.id)) return;
    setState(() => _busy.add(config.id));
    try {
      await action();
      _toast(success);
    } on ApiException catch (e) {
      _toast(switch (e.statusCode) {
        404 => 'This schema no longer exists. Refreshing…',
        409 => '${e.message}\nPlease try again.',
        _ => e.message,
      });
    } catch (_) {
      _toast('Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _busy.remove(config.id));
      await _load();
    }
  }

  Future<void> _setDefault(SchemaConfig config) => _run(
    config,
    () => ref
        .read(verificationRepositoryProvider)
        .setDefaultSchemaConfig(orgId: _orgId(ref), configId: config.id),
    '"${config.label}" is now the default.',
  );

  Future<void> _deactivate(SchemaConfig config) async {
    final bool confirmed = await showConfirmSheet(
      context,
      icon: LucideIcons.archive,
      tone: AppColors.danger,
      title: 'Switch off "${config.label}"?',
      message:
          'New batches can no longer use this schema. Batches already '
          'created with it keep working.',
      confirmLabel: 'Switch off',
    );
    if (!confirmed) return;
    await _run(
      config,
      () => ref
          .read(verificationRepositoryProvider)
          .deactivateSchemaConfig(orgId: _orgId(ref), configId: config.id),
      '"${config.label}" switched off.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _settingsAppBar(
        context,
        title: 'Custom Schemas',
        actions: <Widget>[
          IconButton(
            onPressed: _showSchemaInfo,
            icon: const Icon(Icons.info_outline_rounded),
            color: _navy,
            tooltip: 'About custom schemas',
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton.icon(
              style: TextButton.styleFrom(
                foregroundColor: _navy,
                backgroundColor: AppColors.blueTint,
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(horizontal: 14),
              ),
              onPressed: () => _openEditor(),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text(
                'New',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
      body: _configs.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object err, _) => ListView(
          padding: _listPadding(context),
          children: <Widget>[
            _EmptyCard(
              icon: Icons.cloud_off_outlined,
              title: 'Could not load schemas',
              message: err is ApiException ? err.message : '$err',
              actionLabel: 'Try again',
              onAction: _load,
            ),
          ],
        ),
        data: _list,
      ),
    );
  }

  EdgeInsets _listPadding(BuildContext context) => EdgeInsets.fromLTRB(
    16,
    8,
    16,
    24 + MediaQuery.viewPaddingOf(context).bottom + _navClearance,
  );

  Widget _list(List<SchemaConfig> all) {
    final List<SchemaConfig> visible = all
        .where((SchemaConfig c) => _showInactive || c.isActive)
        .toList();
    final int inactiveCount = all.where((SchemaConfig c) => !c.isActive).length;

    return RefreshIndicator(
      color: _navy,
      onRefresh: _load,
      child: ListView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        padding: _listPadding(context),
        children: <Widget>[
          if (visible.isEmpty)
            _EmptyCard(
              icon: Icons.schema_outlined,
              title: 'No custom schemas yet',
              message:
                  'Batches use the standard layout. Create a schema from one '
                  'sample record to use your own fields.',
              actionLabel: 'Create schema',
              onAction: () => _openEditor(),
            ),
          for (final String type in _semanticFields.keys)
            if (visible.any(
              (SchemaConfig c) => c.spaceType == type,
            )) ...<Widget>[
              _SectionTitle(_spaceTypeLabels[type] ?? type),
              _Card(
                child: Column(
                  children: <Widget>[
                    for (final (int i, SchemaConfig c)
                        in visible
                            .where((SchemaConfig c) => c.spaceType == type)
                            .indexed) ...<Widget>[
                      if (i > 0) const Divider(height: 1, color: _hairline),
                      _SchemaRow(
                        config: c,
                        busy: _busy.contains(c.id),
                        onEdit: () => _openEditor(existing: c),
                        onSetDefault: () => _setDefault(c),
                        onDeactivate: () => _deactivate(c),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          if (inactiveCount > 0)
            Center(
              child: TextButton(
                style: TextButton.styleFrom(foregroundColor: _muted),
                onPressed: () => setState(() => _showInactive = !_showInactive),
                child: Text(
                  _showInactive
                      ? 'Hide switched-off schemas'
                      : 'Show switched-off schemas ($inactiveCount)',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SchemaRow extends ConsumerWidget {
  const _SchemaRow({
    required this.config,
    required this.busy,
    required this.onEdit,
    required this.onSetDefault,
    required this.onDeactivate,
  });

  final SchemaConfig config;
  final bool busy;
  final VoidCallback onEdit;
  final VoidCallback onSetDefault;
  final VoidCallback onDeactivate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool editable = config.isActive && !config.isSuperAdminManaged;
    final int fields = config.localFields.length;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: editable && !busy ? onEdit : null,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 15, 10, 15),
          child: Row(
            children: <Widget>[
              _SchemaImage(config: config),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      config.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        height: 20 / 15,
                        color: config.isActive
                            ? _rowTitle
                            : const Color(0xFF9CA3AF),
                      ),
                    ),
                    if (config.outputMapSources.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 3),
                      Text(
                        'Output mapping: ${config.outputMapSources.values.toSet().join(', ')}',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                    const SizedBox(height: 3),
                    Text(
                      'For ${(_spaceTypeLabels[config.spaceType] ?? config.spaceType).toLowerCase()} batches • '
                      '$fields field${fields == 1 ? '' : 's'} • v${config.version}',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                    if (config.isDefault ||
                        !config.isActive ||
                        config.isSuperAdminManaged) ...<Widget>[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: <Widget>[
                          if (config.isDefault)
                            const _Tag(
                              'Default',
                              bg: AppColors.badgeValidBg,
                              fg: AppColors.badgeValidFg,
                            ),
                          if (!config.isActive)
                            const _Tag(
                              'Switched off',
                              bg: AppColors.badgeManualBg,
                              fg: _muted,
                            ),
                          if (config.isSuperAdminManaged)
                            const _Tag(
                              'Managed by TruMarkZ',
                              bg: AppColors.blueTint,
                              fg: _navy,
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              if (busy)
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else if (editable)
                // Anchored pop-up menu: a bottom sheet would open underneath
                // the floating bottom nav.
                PopupMenuButton<String>(
                  tooltip: 'Schema actions',
                  icon: const Icon(
                    Icons.more_horiz_rounded,
                    color: Color(0xFFB3B3B3),
                  ),
                  color: Colors.white,
                  elevation: 6,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  position: PopupMenuPosition.under,
                  onSelected: (String choice) => switch (choice) {
                    'default' => onSetDefault(),
                    'off' => onDeactivate(),
                    _ => onEdit(),
                  },
                  itemBuilder: (BuildContext context) =>
                      <PopupMenuEntry<String>>[
                        const PopupMenuItem<String>(
                          value: 'edit',
                          child: _MenuRow(Icons.edit_outlined, 'Edit schema'),
                        ),
                        if (!config.isDefault)
                          const PopupMenuItem<String>(
                            value: 'default',
                            child: _MenuRow(
                              Icons.star_outline_rounded,
                              'Make default',
                            ),
                          ),
                        const PopupMenuItem<String>(
                          value: 'off',
                          child: _MenuRow(
                            Icons.archive_outlined,
                            'Switch off',
                            danger: true,
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

class _MenuRow extends StatelessWidget {
  const _MenuRow(this.icon, this.label, {this.danger = false});

  final IconData icon;
  final String label;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final Color color = danger ? AppColors.danger : _rowTitle;
    return Row(
      children: <Widget>[
        Icon(icon, size: 20, color: danger ? AppColors.danger : _navy),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14.5,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}

/// Details shown from the info button in the app bar.
class _SchemaInfoContent extends StatelessWidget {
  const _SchemaInfoContent();

  @override
  Widget build(BuildContext context) {
    Widget point(IconData icon, String title, String text) => Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, size: 18, color: _navy),
          const SizedBox(width: 10),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: <InlineSpan>[
                  TextSpan(
                    text: '$title ',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: _rowTitle,
                    ),
                  ),
                  TextSpan(text: text),
                ],
              ),
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12.5,
                height: 1.4,
                color: _muted,
              ),
            ),
          ),
        ],
      ),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text(
          'They decide which details each record in a batch carries — '
          'for example an employee ID or a product colour — on top of '
          'TruMarkZ\'s standard fields.',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12.5,
            height: 1.4,
            color: _muted,
          ),
        ),
        point(
          Icons.category_outlined,
          'One type each:',
          'a schema is for People, Product or Warranty batches.',
        ),
        point(
          Icons.star_outline_rounded,
          'Default is automatic:',
          'new batches of that type use the default schema.',
        ),
        point(
          Icons.table_view_outlined,
          'Uploads follow it:',
          'Excel templates and uploads use its fields.',
        ),
      ],
    );
  }
}

/// Schema images are protected by the organization bearer token. Uploading or
/// changing one remains a SuperAdmin web operation; this is the app preview.
class _SchemaImage extends ConsumerWidget {
  const _SchemaImage({required this.config});

  final SchemaConfig config;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Widget fallback = Icon(
      _spaceTypeIcons[config.spaceType] ?? Icons.schema_outlined,
      size: 18,
      color: config.isActive ? _navy : const Color(0xFF9CA3AF),
    );
    return Container(
      width: 34,
      height: 34,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      alignment: Alignment.center,
      child: config.imageUrl == null
          ? fallback
          : FutureBuilder<String?>(
              future: ref.read(tokenStorageProvider).getToken(),
              builder: (BuildContext context, AsyncSnapshot<String?> snapshot) {
                final String? token = snapshot.data?.trim();
                return Image.network(
                  config.imageUrl!,
                  width: 34,
                  height: 34,
                  fit: BoxFit.cover,
                  headers: token == null || token.isEmpty
                      ? null
                      : <String, String>{'Authorization': 'Bearer $token'},
                  errorBuilder: (_, _, _) => fallback,
                );
              },
            ),
    );
  }
}

/// Settings → Custom Schemas → New / Edit (route
/// [AppRouter.settingsSchemaEditorPath], `extra` = the config to edit).
class SchemaConfigEditorPage extends ConsumerStatefulWidget {
  const SchemaConfigEditorPage({super.key, this.existing});

  /// Editing saves a new version; null creates version 1.
  final SchemaConfig? existing;

  @override
  ConsumerState<SchemaConfigEditorPage> createState() =>
      _SchemaConfigEditorPageState();
}

class _SchemaConfigEditorPageState
    extends ConsumerState<SchemaConfigEditorPage> {
  late String _spaceType;
  late final TextEditingController _label;
  late final TextEditingController _schemaId;
  late final TextEditingController _spaceId;
  final TextEditingController _sample = TextEditingController();
  final Map<String, TextEditingController> _mapping =
      <String, TextEditingController>{};
  bool _isDefault = false;
  bool _saving = false;
  bool _showAdvanced = false;
  String? _labelError;
  String? _schemaIdError;
  String? _sampleError;
  List<String> _inlineWarnings = const <String>[];
  List<String> _serverErrors = const <String>[];

  bool get _editing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final SchemaConfig? c = widget.existing;
    _spaceType = c?.spaceType.isNotEmpty == true ? c!.spaceType : 'human';
    _label = TextEditingController(text: c?.label ?? '');
    _schemaId = TextEditingController(text: c?.schemaId ?? '');
    _spaceId = TextEditingController(text: c?.spaceId ?? '');
    _isDefault = c?.isDefault ?? false;
    _resetMapping();
    _showAdvanced = _mapping.values.any(
      (TextEditingController t) => t.text.isNotEmpty,
    );
  }

  /// Input mapping holds only the user's own choices; nothing is guessed.
  void _resetMapping() {
    for (final TextEditingController c in _mapping.values) {
      c.dispose();
    }
    _mapping.clear();
    final Map<String, dynamic> saved =
        widget.existing?.inputMap ?? const <String, dynamic>{};
    for (final String field in _semanticFields[_spaceType]!) {
      _mapping[field] = TextEditingController(
        text: saved[field]?.toString() ?? '',
      );
    }
  }

  @override
  void dispose() {
    _label.dispose();
    _schemaId.dispose();
    _spaceId.dispose();
    _sample.dispose();
    for (final TextEditingController c in _mapping.values) {
      c.dispose();
    }
    super.dispose();
  }

  /// The pasted record, verbatim; null when the box is empty.
  Map<String, dynamic>? _parseSample() {
    final String raw = _sample.text.trim();
    if (raw.isEmpty) return null;
    final dynamic decoded = jsonDecode(raw);
    if (decoded is! Map) {
      throw const FormatException('Paste one JSON object, like {"name": …}.');
    }
    return Map<String, dynamic>.from(decoded);
  }

  Future<void> _save() async {
    if (_saving) return;
    final String label = _label.text.trim();
    Map<String, dynamic>? sample;
    String? sampleError;
    try {
      sample = _parseSample();
    } on FormatException catch (e) {
      sampleError = e.message.contains('JSON object')
          ? e.message
          : 'This isn\'t valid JSON. Check quotes, commas and brackets.';
    }
    if (sampleError == null && !_editing && sample == null) {
      sampleError = 'Paste one sample record so we can find its fields.';
    }
    setState(() {
      _labelError = label.isEmpty ? 'Give the schema a name.' : null;
      _schemaIdError = _schemaId.text.trim().isEmpty
          ? 'Schema ID is required.'
          : null;
      _sampleError = sampleError;
      _serverErrors = const <String>[];
    });
    if (_labelError != null || _schemaIdError != null || sampleError != null) {
      return;
    }

    final Map<String, dynamic> inputMap = <String, dynamic>{
      for (final MapEntry<String, TextEditingController> e in _mapping.entries)
        if (e.value.text.trim().isNotEmpty) e.key: e.value.text.trim(),
    };
    final VerificationRepository repo = ref.read(
      verificationRepositoryProvider,
    );
    final String orgId = _orgId(ref);
    setState(() => _saving = true);
    try {
      final SchemaConfigSaveResponse res = _editing
          ? await repo.createSchemaConfigVersion(
              orgId: orgId,
              configId: widget.existing!.id,
              spaceType: _spaceType,
              schemaVariant: '',
              schemaId: _schemaId.text,
              spaceId: _spaceId.text,
              label: label,
              isDefault: _isDefault,
              sampleRecord: sample,
              inputMap: inputMap,
              // Keep output mappings this screen doesn't edit.
              outputMap: widget.existing!.outputMap,
            )
          : await repo.createSchemaConfig(
              orgId: orgId,
              spaceType: _spaceType,
              schemaVariant: '',
              schemaId: _schemaId.text,
              spaceId: _spaceId.text,
              label: label,
              isDefault: _isDefault,
              sampleRecord: sample,
              // Nothing matched by hand: let the server link exact names.
              inputMap: inputMap.isEmpty ? null : inputMap,
            );
      if (!mounted) return;
      final List<String> warnings = <String>[
        ...res.warnings,
        ...res.warningDetails.map((SchemaWarningDetail warning) {
          final String fields = warning.fields.isEmpty
              ? ''
              : ' (${warning.fields.join(', ')})';
          return '${warning.message}$fields';
        }),
      ].where((String value) => value.trim().isNotEmpty).toList();
      if (warnings.isNotEmpty) {
        setState(() => _inlineWarnings = warnings);
      } else {
        context.pop(true);
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _serverErrors = e.errors.isNotEmpty ? e.errors : <String>[e.message];
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Something went wrong. Please try again.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final double bottom = MediaQuery.viewPaddingOf(context).bottom;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _settingsAppBar(
        context,
        title: _editing ? 'Edit Schema' : 'New Schema',
        onBack: () => context.pop(false),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: ListView(
          physics: const BouncingScrollPhysics(),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.fromLTRB(16, 8, 16, 24 + bottom + _navClearance),
          children: <Widget>[
            if (_serverErrors.isNotEmpty || _inlineWarnings.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _Card(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      if (_serverErrors.isNotEmpty) ...<Widget>[
                        const Text(
                          'Please correct the following',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.danger,
                          ),
                        ),
                        for (final String error in _serverErrors)
                          Text(
                            '• $error',
                            style: const TextStyle(color: AppColors.danger),
                          ),
                      ],
                      if (_inlineWarnings.isNotEmpty) ...<Widget>[
                        const Text(
                          'Saved with mapping warnings',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: _navy,
                          ),
                        ),
                        for (final String warning in _inlineWarnings)
                          Text('• $warning'),
                      ],
                    ],
                  ),
                ),
              ),
            const _SectionTitle('Used for'),
            _TypeSelector(
              value: _spaceType,
              locked: _editing,
              onChanged: (String t) => setState(() {
                _spaceType = t;
                _resetMapping();
              }),
            ),
            if (_editing)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'The type can\'t change on a new version.',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: _muted,
                  ),
                ),
              ),
            const SizedBox(height: 24),
            const _SectionTitle('Details'),
            _Card(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  TMZInput(
                    label: 'Schema name',
                    hint: 'e.g. Staff onboarding',
                    controller: _label,
                    enabled: !_saving,
                    errorText: _labelError,
                  ),
                  const SizedBox(height: 14),
                  TMZInput(
                    label: 'Dhiway schema ID',
                    hint: 'Schema ID',
                    controller: _schemaId,
                    enabled: !_saving,
                    errorText: _schemaIdError,
                  ),
                  const SizedBox(height: 14),
                  TMZInput(
                    label: 'Dhiway space ID',
                    hint: 'Space ID',
                    controller: _spaceId,
                    enabled: !_saving,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: <Widget>[
                const Expanded(child: _SectionTitle('Sample record')),
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: _navy,
                    visualDensity: VisualDensity.compact,
                  ),
                  onPressed: _saving
                      ? null
                      : () => setState(
                          () => _sample.text = _exampleRecords[_spaceType]!,
                        ),
                  child: const Text('Use example'),
                ),
              ],
            ),
            _Card(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    _editing
                        ? 'Optional. Paste a new record to replace the fields, '
                              'or leave it empty to keep them.'
                        : 'Paste one record as JSON. Its fields become this '
                              'schema\'s fields.',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12.5,
                      height: 1.4,
                      color: _muted,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _CodeBox(
                    controller: _sample,
                    enabled: !_saving,
                    errorText: _sampleError,
                    hint: _exampleRecords[_spaceType]!,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _Card(
              child: Column(
                children: <Widget>[
                  _ToggleRow(
                    icon: Icons.star_outline_rounded,
                    title: 'Use as default',
                    subtitle:
                        'New ${(_spaceTypeLabels[_spaceType] ?? '').toLowerCase()} '
                        'batches use this schema automatically.',
                    value: _isDefault,
                    onChanged: _saving
                        ? null
                        : (bool v) => setState(() => _isDefault = v),
                  ),
                  const Divider(height: 1, color: _hairline),
                  _ToggleRow(
                    icon: Icons.link_rounded,
                    title: 'Advanced settings',
                    subtitle:
                        'Set optional field mappings and review advanced '
                        'schema details.',
                    value: _showAdvanced,
                    onChanged: (bool v) => setState(() => _showAdvanced = v),
                  ),
                  if (_showAdvanced)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                      child: Column(
                        children: <Widget>[
                          for (final MapEntry<String, TextEditingController> e
                              in _mapping.entries)
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: TMZInput(
                                label: e.key.replaceAll('_', ' '),
                                hint: 'Your field name (optional)',
                                controller: e.value,
                                enabled: !_saving,
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            TMZButton(
              label: _editing ? 'Save new version' : 'Save schema',
              isLoading: _saving,
              onPressed: _saving ? null : _save,
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeSelector extends StatelessWidget {
  const _TypeSelector({
    required this.value,
    required this.locked,
    required this.onChanged,
  });

  final String value;
  final bool locked;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        for (final (int i, MapEntry<String, String> t)
            in _spaceTypeLabels.entries.indexed) ...<Widget>[
          if (i > 0) const SizedBox(width: 10),
          Expanded(
            child: _TypeOption(
              icon: _spaceTypeIcons[t.key]!,
              label: t.value,
              selected: value == t.key,
              enabled: !locked || value == t.key,
              onTap: locked ? null : () => onChanged(t.key),
            ),
          ),
        ],
      ],
    );
  }
}

class _TypeOption extends StatelessWidget {
  const _TypeOption({
    required this.icon,
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Color fg = selected
        ? _navy
        : (enabled ? _muted : const Color(0xFFCBD5E1));
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFFEFF3FF) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selected ? _navy : const Color(0xFFE2E8F0),
          width: selected ? 1.5 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Column(
              children: <Widget>[
                Icon(icon, color: fg, size: 22),
                const SizedBox(height: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: fg,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Multi-line JSON box styled like [TMZInput].
class _CodeBox extends StatefulWidget {
  const _CodeBox({
    required this.controller,
    required this.enabled,
    required this.hint,
    this.errorText,
  });

  final TextEditingController controller;
  final bool enabled;
  final String hint;
  final String? errorText;

  @override
  State<_CodeBox> createState() => _CodeBoxState();
}

class _CodeBoxState extends State<_CodeBox> {
  final FocusNode _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool hasError = (widget.errorText ?? '').isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          decoration: BoxDecoration(
            color: AppColors.offWhite,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: hasError
                  ? AppColors.error
                  : (_focus.hasFocus
                        ? AppColors.brandBlue
                        : Colors.transparent),
              width: 1.25,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          child: TextField(
            controller: widget.controller,
            focusNode: _focus,
            enabled: widget.enabled,
            minLines: 6,
            maxLines: 14,
            keyboardType: TextInputType.multiline,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 13,
              height: 1.45,
              color: _ink,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: widget.hint,
              hintStyle: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                height: 1.45,
                color: Color(0xFFB0BAC9),
              ),
            ),
          ),
        ),
        if (hasError) ...<Widget>[
          const SizedBox(height: 6),
          Text(
            widget.errorText!,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: AppColors.error,
            ),
          ),
        ],
      ],
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 10, 14),
      child: Row(
        children: <Widget>[
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 18, color: _navy),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _rowTitle,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    height: 1.35,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeTrackColor: _navy,
            activeThumbColor: Colors.white,
          ),
        ],
      ),
    );
  }
}

/// White card with the Settings hairline border and soft shadow.
class _Card extends StatelessWidget {
  const _Card({required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _hairline),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Grey group heading, as used for "Manage Account" in Settings.
class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 16,
          fontWeight: FontWeight.w500,
          height: 22 / 16,
          color: Color(0xFF8A8A8A),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.label, {required this.bg, required this.fg});

  final String label;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return _Card(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
      child: Column(
        children: <Widget>[
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: Color(0xFFEFF3FF),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: _navy, size: 26),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              height: 1.45,
              color: _muted,
            ),
          ),
          const SizedBox(height: 18),
          TMZButton(label: actionLabel, onPressed: onAction, showShadow: false),
        ],
      ),
    );
  }
}

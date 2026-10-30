/// Organization-specific dynamic schema configuration
/// (`/auth/organizations/{org_id}/schema-configs`).
///
/// The app only selects configurations by `label` today, so `local_fields`
/// and the maps are kept as raw JSON rather than fully typed.
class SchemaConfig {
  const SchemaConfig({
    required this.id,
    required this.orgId,
    required this.spaceType,
    required this.schemaVariant,
    required this.schemaId,
    required this.spaceId,
    required this.label,
    required this.localFields,
    required this.inputMap,
    required this.outputMap,
    required this.version,
    required this.isActive,
    required this.isDefault,
    required this.previousVersionId,
    required this.createdBy,
    required this.createdByRole,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String orgId;

  /// `human`, `product` or `warranty`.
  final String spaceType;
  final String schemaVariant;
  final String schemaId;
  final String spaceId;

  /// Sent back as `schema_name` on batch creation.
  final String label;
  final List<SchemaLocalField> localFields;
  final Map<String, dynamic> inputMap;
  final Map<String, dynamic> outputMap;
  final int version;
  final bool isActive;
  final bool isDefault;
  final String? previousVersionId;
  final String? createdBy;
  final String createdByRole;
  final String createdAt;
  final String updatedAt;

  /// Organization accounts get a 403 when editing, re-defaulting or
  /// deactivating a SuperAdmin-managed configuration.
  bool get isSuperAdminManaged =>
      createdByRole.trim().toLowerCase() == 'super_admin';

  factory SchemaConfig.fromJson(Map<String, dynamic> json) {
    final dynamic fieldsRaw = json['local_fields'];
    return SchemaConfig(
      id: (json['id'] ?? '').toString().trim(),
      orgId: (json['org_id'] ?? '').toString().trim(),
      spaceType: (json['space_type'] ?? '').toString().trim().toLowerCase(),
      schemaVariant: (json['schema_variant'] ?? '').toString().trim(),
      schemaId: (json['schema_id'] ?? '').toString().trim(),
      spaceId: (json['space_id'] ?? '').toString().trim(),
      label: (json['label'] ?? '').toString().trim(),
      localFields: fieldsRaw is List
          ? fieldsRaw
                .whereType<Map>()
                .map(
                  (Map e) =>
                      SchemaLocalField.fromJson(Map<String, dynamic>.from(e)),
                )
                .toList()
          : const <SchemaLocalField>[],
      inputMap: json['input_map'] is Map
          ? Map<String, dynamic>.from(json['input_map'] as Map)
          : <String, dynamic>{},
      outputMap: json['output_map'] is Map
          ? Map<String, dynamic>.from(json['output_map'] as Map)
          : <String, dynamic>{},
      version: int.tryParse((json['version'] ?? '').toString()) ?? 1,
      isActive: json['is_active'] != false,
      isDefault: json['is_default'] == true,
      previousVersionId: json['previous_version_id']?.toString(),
      createdBy: json['created_by']?.toString(),
      createdByRole: (json['created_by_role'] ?? '').toString(),
      createdAt: (json['created_at'] ?? '').toString(),
      updatedAt: (json['updated_at'] ?? '').toString(),
    );
  }
}

class SchemaLocalField {
  const SchemaLocalField({
    required this.name,
    required this.type,
    required this.required,
    required this.nullable,
    required this.aliases,
    required this.path,
    this.description,
  });

  /// Display as-is (`address.city`, `items[].sku`, `["a.b"]`); never split.
  final String name;

  /// string/number/... plus `object`, `array`, `null`, `mixed`.
  final String type;
  final bool required;
  final bool nullable;
  final List<String> aliases;

  /// Object keys as written; `null` means "each array item".
  final List<String?> path;
  final String? description;

  factory SchemaLocalField.fromJson(Map<String, dynamic> json) {
    final dynamic aliasesRaw = json['aliases'];
    final dynamic pathRaw = json['path'];
    return SchemaLocalField(
      name: (json['name'] ?? '').toString(),
      type: (json['type'] ?? 'string').toString(),
      required: json['required'] == true,
      nullable: json['nullable'] == true,
      aliases: aliasesRaw is List
          ? aliasesRaw.map((dynamic e) => e.toString()).toList()
          : const <String>[],
      path: pathRaw is List
          ? pathRaw.map((dynamic e) => e?.toString()).toList()
          : const <String?>[],
      description: json['description']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'name': name,
    'type': type,
    'required': required,
    'nullable': nullable,
    'aliases': aliases,
    if (path.isNotEmpty) 'path': path,
    if (description != null) 'description': description,
  };
}

/// Response of create / new-version calls.
class SchemaConfigSaveResponse {
  const SchemaConfigSaveResponse({
    required this.config,
    required this.warnings,
    required this.dhiwaySchemaProperties,
  });

  final SchemaConfig config;

  /// Advisory only; text is not stable, display it without parsing.
  final List<String> warnings;

  /// Always `null` today: means "not verified against Dhiway".
  final List<String>? dhiwaySchemaProperties;

  factory SchemaConfigSaveResponse.fromJson(Map<String, dynamic> json) {
    final dynamic warningsRaw = json['warnings'];
    final dynamic propsRaw = json['dhiway_schema_properties'];
    return SchemaConfigSaveResponse(
      config: SchemaConfig.fromJson(
        json['config'] is Map
            ? Map<String, dynamic>.from(json['config'] as Map)
            : <String, dynamic>{},
      ),
      warnings: warningsRaw is List
          ? warningsRaw.map((dynamic e) => e.toString()).toList()
          : const <String>[],
      dhiwaySchemaProperties: propsRaw is List
          ? propsRaw.map((dynamic e) => e.toString()).toList()
          : null,
    );
  }
}

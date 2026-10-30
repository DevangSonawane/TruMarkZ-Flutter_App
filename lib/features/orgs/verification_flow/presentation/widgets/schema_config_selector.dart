import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../core/models/schema_config_models.dart';
import '../../../../../core/network/api_client.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/tmz_select.dart';
import '../../../../auth/application/auth_notifier.dart';
import '../../../data/verification_repository.dart';

/// Optional `schema_name` picker for batch creation.
///
/// Renders nothing for organizations without schema configurations, so the
/// legacy flow is unchanged. `null` means "use the organization default",
/// which is the same as omitting `schema_name`.
class SchemaConfigSelector extends ConsumerWidget {
  const SchemaConfigSelector({
    super.key,
    required this.spaceType,
    required this.value,
    required this.onChanged,
    this.enabled = true,
    this.padding = const EdgeInsets.only(bottom: 16),
  });

  /// `human`, `product` or `warranty`.
  final String spaceType;
  final String? value;
  final ValueChanged<String?> onChanged;
  final bool enabled;
  final EdgeInsetsGeometry padding;

  static const String _defaultOption = '';

  static String providerKey(WidgetRef ref, String spaceType) {
    final String orgId =
        ref.watch(authNotifierProvider).valueOrNull?.userProfile?.id ?? '';
    return '$orgId::$spaceType';
  }

  /// Call after a stale-selection 400 so the list is fetched again.
  static void refresh(WidgetRef ref, String spaceType) {
    ref.invalidate(schemaConfigsProvider(providerKey(ref, spaceType)));
  }

  /// Handles the unknown/ambiguous `schema_name` 400: clears the selection,
  /// re-fetches the list and returns a message asking the user to re-select.
  /// Returns null when [error] is unrelated to schema selection.
  static String? handleStaleSelection(
    WidgetRef ref,
    String spaceType,
    Object error,
    ValueChanged<String?> clearSelection,
  ) {
    final ApiException? apiError = error is ApiException ? error : null;
    if (apiError == null || !apiError.isStaleSchemaSelection) return null;
    clearSelection(null);
    refresh(ref, spaceType);
    return '${apiError.message}\nThe schema list has been refreshed — please '
        'choose a schema again.';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<SchemaConfig>> configs = ref.watch(
      schemaConfigsProvider(providerKey(ref, spaceType)),
    );

    return configs.when(
      loading: () => const SizedBox.shrink(),
      // The list is optional: a failure must never block batch creation.
      error: (Object _, StackTrace _) => const SizedBox.shrink(),
      data: (List<SchemaConfig> items) {
        final List<SchemaConfig> active = items
            .where((SchemaConfig c) => c.isActive && c.spaceType == spaceType)
            .toList();
        if (active.isEmpty) return const SizedBox.shrink();

        final SchemaConfig? defaultConfig = active
            .where((SchemaConfig c) => c.isDefault)
            .firstOrNull;
        final bool selectionStillValid =
            value == null || active.any((SchemaConfig c) => c.label == value);
        if (!selectionStillValid) {
          WidgetsBinding.instance.addPostFrameCallback((_) => onChanged(null));
        }

        return Padding(
          padding: padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              TMZSelect<String>(
                label: 'Data schema',
                enabled: enabled,
                value: selectionStillValid
                    ? (value ?? _defaultOption)
                    : _defaultOption,
                options: <TMZSelectOption<String>>[
                  TMZSelectOption<String>(
                    value: _defaultOption,
                    label: defaultConfig != null
                        ? 'Organization default (${defaultConfig.label})'
                        : 'Standard format (no custom schema)',
                  ),
                  for (final SchemaConfig c in active)
                    TMZSelectOption<String>(
                      value: c.label,
                      label: c.isDefault ? '${c.label}  •  Default' : c.label,
                    ),
                ],
                onChanged: (String? next) => onChanged(
                  next == null || next == _defaultOption ? null : next,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Records are validated against the selected schema.',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

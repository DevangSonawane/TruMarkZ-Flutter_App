/// Organization-level consent default for Human batches.
///
/// Wire values (new_flutter_trumarkz.md §12a):
///  - `open_search`         — credentials are publicly searchable.
///  - `permission_required` — the end recipient must explicitly consent.
///
/// A `null` value on the wire means [OrgPermissionMode.openSearch] — that is
/// the mode every pre-existing organization runs in.
enum OrgPermissionMode {
  openSearch('open_search', 'Open Search'),
  permissionRequired('permission_required', 'Permission Required');

  const OrgPermissionMode(this.wireValue, this.label);

  /// Value sent to / received from the backend.
  final String wireValue;

  /// Short label shown in the org settings UI.
  final String label;

  /// Longer explanation shown next to the option in the org settings UI.
  String get description => switch (this) {
    OrgPermissionMode.openSearch =>
      'Credentials are publicly searchable. Email stays optional for the '
          'people you add.',
    OrgPermissionMode.permissionRequired =>
      'People must approve before their credential is processed. Email '
          'becomes required for every person you add.',
  };

  /// Parses a backend `permission_mode` value.
  ///
  /// Accepts the canonical wire values plus the `public` / `private`
  /// aliases the backend also tolerates. Returns `null` for an empty or
  /// unrecognised value — callers treat that as [OrgPermissionMode.openSearch].
  static OrgPermissionMode? fromWire(String? raw) {
    final String value = (raw ?? '').trim().toLowerCase();
    if (value.isEmpty) return null;
    switch (value) {
      case 'open_search':
      case 'open search':
      case 'public':
        return OrgPermissionMode.openSearch;
      case 'permission_required':
      case 'permission required':
      case 'private':
        return OrgPermissionMode.permissionRequired;
    }
    return null;
  }

  /// Parses a batch's own `credential_visibility` value.
  ///
  /// The batch-level choice always wins over the organization default, so
  /// this needs to recognise the access-mode names the app sends
  /// (`publicSearchable` / `permissionBasedAccess`) as well as the raw
  /// backend spellings. Returns `null` when the batch has no visibility set
  /// (or an unknown one), which means "fall back to the org default".
  static OrgPermissionMode? fromBatchVisibility(String? raw) {
    final String value = (raw ?? '').trim().toLowerCase();
    if (value.isEmpty) return null;
    if (value.contains('permission') ||
        value.contains('private') ||
        value.contains('restricted')) {
      return OrgPermissionMode.permissionRequired;
    }
    if (value.contains('public') ||
        value.contains('open_search') ||
        value.contains('opensearch')) {
      return OrgPermissionMode.openSearch;
    }
    return null;
  }
}

/// Resolves the effective consent mode for a single Human batch.
///
/// The batch's own `credential_visibility` wins when it is set; otherwise the
/// organization's `permission_mode` default applies. Product and Warranty
/// batches are unaffected by this entirely and never call this.
OrgPermissionMode resolvePermissionMode({
  required OrgPermissionMode? organizationDefault,
  String? credentialVisibility,
}) {
  final OrgPermissionMode? fromBatch = OrgPermissionMode.fromBatchVisibility(
    credentialVisibility,
  );
  if (fromBatch != null) return fromBatch;
  return organizationDefault ?? OrgPermissionMode.openSearch;
}
